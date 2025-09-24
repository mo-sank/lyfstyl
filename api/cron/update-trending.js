// Vercel Cron Job for updating trending music data
import { initializeApp, getApps } from 'firebase/app';
import { getFirestore, collection, addDoc, serverTimestamp } from 'firebase/firestore';

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyB4WUwvk1TNOb0sa69twI3Cyxc7Y3K3Mbs",
  authDomain: "lyfstyl-f0070.firebaseapp.com",
  projectId: "lyfstyl-f0070",
  storageBucket: "lyfstyl-f0070.firebasestorage.app",
  messagingSenderId: "965287268170",
  appId: "1:965287268170:web:b7bc950ec94868cd487bb3",
  measurementId: "G-4D7WXLZD0V"
};

// Initialize Firebase
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
const db = getFirestore(app);

// API Keys (set these as Vercel environment variables)
const LASTFM_API_KEY = process.env.LASTFM_API_KEY || 'a56da6ca8f0fcd0d15dc18e43be048c9';
const DEEZER_APP_ID = process.env.DEEZER_APP_ID;

export default async function handler(req, res) {
  // Only allow GET requests (Vercel Cron)
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    console.log('Starting trending music aggregation...');
    
    const allItems = [];
    
    // Fetch from Last.fm
    try {
      const lastfmItems = await fetchLastFmData();
      allItems.push(...lastfmItems);
      console.log(`Fetched ${lastfmItems.length} items from Last.fm`);
    } catch (error) {
      console.error('Last.fm error:', error);
    }

    // Fetch from Deezer (if API key available)
    if (DEEZER_APP_ID) {
      try {
        const deezerItems = await fetchDeezerData();
        allItems.push(...deezerItems);
        console.log(`Fetched ${deezerItems.length} items from Deezer`);
      } catch (error) {
        console.error('Deezer error:', error);
      }
    }

    // Fetch from Apple Music RSS
    try {
      const appleItems = await fetchAppleMusicData();
      allItems.push(...appleItems);
      console.log(`Fetched ${appleItems.length} items from Apple Music`);
    } catch (error) {
      console.error('Apple Music error:', error);
    }

    if (allItems.length === 0) {
      return res.json({ error: 'No data fetched from any source' });
    }

    // Normalize and deduplicate
    const normalizedItems = normalizeAndDeduplicate(allItems);
    console.log(`Normalized to ${normalizedItems.length} unique items`);

    // Store individual items
    const itemIds = [];
    for (const item of normalizedItems) {
      try {
        const docRef = await addDoc(collection(db, 'trendingItems'), {
          ...item,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        });
        itemIds.push(docRef.id);
      } catch (error) {
        console.error('Error storing item:', error);
      }
    }

    // Store aggregate
    const aggregateData = {
      type: 'music',
      window: 'daily',
      periodStart: new Date().toISOString().split('T')[0], // YYYY-MM-DD
      topMediaIds: itemIds.slice(0, 50), // Top 50
      generatedAt: serverTimestamp(),
      totalItems: normalizedItems.length,
      sources: ['lastfm', ...(DEEZER_APP_ID ? ['deezer'] : []), 'apple']
    };

    await addDoc(collection(db, 'trending'), aggregateData);
    console.log('Stored trending aggregate');

    res.json({ 
      success: true, 
      itemsProcessed: normalizedItems.length,
      itemIds: itemIds.length
    });

  } catch (error) {
    console.error('Cron job error:', error);
    res.status(500).json({ error: 'Cron job failed' });
  }
}

async function fetchLastFmData() {
  const response = await fetch(
    `http://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=${LASTFM_API_KEY}&format=json&limit=50`
  );
  const data = await response.json();
  
  return (data.tracks?.track || []).map(track => ({
    type: 'music',
    title: track.name || '',
    artist: track.artist?.name || '',
    coverUrl: getLargestImage(track.image),
    genres: [], // Last.fm doesn't provide genres in this endpoint
    sources: ['lastfm'],
    score: parseInt(track.playcount) || 0,
    externalIds: {
      lastfm: track.mbid || track.name
    }
  }));
}

async function fetchDeezerData() {
  const response = await fetch(
    `https://api.deezer.com/chart/0/tracks?limit=50`
  );
  const data = await response.json();
  
  return (data.data || []).map(track => ({
    type: 'music',
    title: track.title || '',
    artist: track.artist?.name || '',
    coverUrl: track.album?.cover_medium,
    genres: track.genres?.data?.map(g => g.name) || [],
    sources: ['deezer'],
    score: track.nb_fan || 0,
    externalIds: {
      deezer: track.id?.toString()
    }
  }));
}

async function fetchAppleMusicData() {
  const response = await fetch(
    'https://rss.apple.com/music/top-songs/rss.xml'
  );
  const text = await response.text();
  
  // Simple XML parsing (you might want to use a proper XML parser)
  const items = [];
  const titleRegex = /<title><!\[CDATA\[(.*?)\]\]><\/title>/g;
  const artistRegex = /<itunes:artist><!\[CDATA\[(.*?)\]\]><\/itunes:artist>/g;
  
  let titleMatch, artistMatch;
  while ((titleMatch = titleRegex.exec(text)) !== null && (artistMatch = artistRegex.exec(text)) !== null) {
    items.push({
      type: 'music',
      title: titleMatch[1],
      artist: artistMatch[1],
      coverUrl: null,
      genres: [],
      sources: ['apple'],
      score: 0,
      externalIds: {
        apple: titleMatch[1]
      }
    });
  }
  
  return items.slice(0, 50);
}

function normalizeAndDeduplicate(items) {
  const seen = new Map();
  
  for (const item of items) {
    const key = `${item.title.toLowerCase()}-${item.artist.toLowerCase()}`;
    
    if (!seen.has(key)) {
      seen.set(key, item);
    } else {
      // Merge sources
      const existing = seen.get(key);
      existing.sources = [...new Set([...existing.sources, ...item.sources])];
      existing.score = Math.max(existing.score, item.score);
    }
  }
  
  return Array.from(seen.values())
    .sort((a, b) => b.score - a.score)
    .slice(0, 100); // Top 100
}

function getLargestImage(images) {
  if (!Array.isArray(images) || images.length === 0) return null;
  
  // Get the largest image (usually the last one)
  for (let i = images.length - 1; i >= 0; i--) {
    const url = images[i]?.['#text'];
    if (url && url.trim()) return url;
  }
  
  return null;
}

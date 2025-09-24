// Script to manually populate trending music data
const { initializeApp, getApps } = require('firebase/app');
const { getFirestore, collection, addDoc, serverTimestamp } = require('firebase/firestore');

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

async function populateTrendingData() {
  try {
    console.log('Fetching trending music data...');
    
    // Fetch from Last.fm
    const lastfmResponse = await fetch(
      'http://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=a56da6ca8f0fcd0d15dc18e43be048c9&format=json&limit=20'
    );
    const lastfmData = await lastfmResponse.json();
    
    const tracks = lastfmData.tracks?.track || [];
    console.log(`Fetched ${tracks.length} tracks from Last.fm`);
    
    if (tracks.length === 0) {
      console.log('No tracks found from Last.fm');
      return;
    }
    
    // Store individual items
    const itemIds = [];
    for (const track of tracks) {
      try {
        const itemData = {
          type: 'music',
          title: track.name || '',
          artist: track.artist?.name || '',
          coverUrl: getLargestImage(track.image),
          genres: [],
          sources: ['lastfm'],
          score: parseInt(track.playcount) || 0,
          externalIds: {
            lastfm: track.mbid || track.name
          },
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        };
        
        const docRef = await addDoc(collection(db, 'trendingItems'), itemData);
        itemIds.push(docRef.id);
        console.log(`Stored: ${track.name} by ${track.artist?.name}`);
      } catch (error) {
        console.error('Error storing item:', error);
      }
    }
    
    // Store aggregate
    const aggregateData = {
      type: 'music',
      window: 'daily',
      periodStart: new Date().toISOString().split('T')[0],
      topMediaIds: itemIds,
      generatedAt: serverTimestamp(),
      totalItems: itemIds.length,
      sources: ['lastfm']
    };
    
    await addDoc(collection(db, 'trending'), aggregateData);
    console.log('Stored trending aggregate');
    console.log(`Successfully populated ${itemIds.length} trending music items!`);
    
  } catch (error) {
    console.error('Error populating trending data:', error);
  }
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

// Run the script
populateTrendingData().then(() => {
  console.log('Done!');
  process.exit(0);
}).catch(error => {
  console.error('Script failed:', error);
  process.exit(1);
});

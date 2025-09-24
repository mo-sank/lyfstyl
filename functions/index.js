import functions from 'firebase-functions';
import admin from 'firebase-admin';
import fetch from 'node-fetch';

admin.initializeApp();
const db = admin.firestore();

// Read API keys from environment config: firebase functions:config:set lastfm.key="YOUR_KEY"
const LASTFM_KEY = process.env.LASTFM_KEY || process.env.lastfm_key || functions.config().lastfm?.key;

async function fetchLastFmTop(limit = 50) {
  if (!LASTFM_KEY) return [];
  const url = `https://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key=${LASTFM_KEY}&format=json&limit=${limit}`;
  const res = await fetch(url);
  if (!res.ok) return [];
  const data = await res.json();
  return (data.tracks?.track ?? []).map((t, i) => ({
    source: 'lastfm',
    title: t.name,
    artist: t.artist?.name,
    coverUrl: t.image?.[t.image.length - 1]?.['#text'] || null,
    rank: i + 1,
  }));
}

async function fetchDeezerTop(limit = 50) {
  const res = await fetch('https://api.deezer.com/chart');
  if (!res.ok) return [];
  const data = await res.json();
  const tracks = data.tracks?.data ?? [];
  return tracks.slice(0, limit).map((t, i) => ({
    source: 'deezer',
    title: t.title,
    artist: t.artist?.name,
    coverUrl: t.album?.cover_medium ?? null,
    previewUrl: t.preview ?? null,
    rank: i + 1,
  }));
}

async function fetchAppleRssTop(country = 'us', limit = 100) {
  const url = `https://rss.applemarketingtools.com/api/v2/${country}/music/most-played/${limit}/songs.json`;
  const res = await fetch(url);
  if (!res.ok) return [];
  const data = await res.json();
  const items = data.feed?.results ?? [];
  return items.map((t, i) => ({
    source: 'apple',
    title: t.name,
    artist: t.artistName,
    coverUrl: t.artworkUrl100 ?? null,
    rank: i + 1,
  }));
}

function normalizeKey(title, artist) {
  const strip = (s) => (s || '')
    .toLowerCase()
    .replace(/\([^)]*\)/g, '')
    .replace(/\[[^\]]*\]/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
  return `${strip(title)}__${strip(artist)}`;
}

function scoreItem(item) {
  const sourceWeight = item.source === 'lastfm' ? 1.0 : item.source === 'deezer' ? 0.9 : 0.8;
  const rankWeight = 1 / (item.rank + 1);
  return sourceWeight + rankWeight;
}

export const aggregateTrendingMusic = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('UTC')
  .onRun(async () => {
    const [lastfm, deezer, apple] = await Promise.all([
      fetchLastFmTop(100),
      fetchDeezerTop(100),
      fetchAppleRssTop('us', 100),
    ]);

    const map = new Map();
    for (const item of [...lastfm, ...deezer, ...apple]) {
      const key = normalizeKey(item.title, item.artist);
      const prev = map.get(key);
      const merged = prev ? { ...prev, score: prev.score + scoreItem(item), sources: [...prev.sources, item.source] }
                          : { ...item, score: scoreItem(item), sources: [item.source] };
      map.set(key, merged);
    }

    const sorted = Array.from(map.values()).sort((a, b) => b.score - a.score).slice(0, 100);

    const periodStart = new Date();
    periodStart.setUTCHours(0, 0, 0, 0);

    // Option A: write a denormalized trendingItems collection and reference ids in trending aggregate
    const batch = db.batch();
    const itemsCol = db.collection('trendingItems');
    const itemIds = [];
    for (const item of sorted.slice(0, 50)) {
      const ref = itemsCol.doc();
      itemIds.push(ref.id);
      batch.set(ref, {
        type: 'music',
        title: item.title,
        artist: item.artist,
        coverUrl: item.coverUrl || null,
        previewUrl: item.previewUrl || null,
        sources: item.sources,
        score: item.score,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    const trendingRef = db.collection('trending').doc();
    batch.set(trendingRef, {
      window: 'day',
      periodStart: admin.firestore.Timestamp.fromDate(periodStart),
      type: 'music',
      genre: null,
      topMediaIds: itemIds,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return null;
  });

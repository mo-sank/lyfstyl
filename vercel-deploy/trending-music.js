// Vercel API route for fetching trending music
import { initializeApp, getApps } from 'firebase/app';
import { getFirestore, collection, query, where, orderBy, limit, getDocs } from 'firebase/firestore';

// Firebase config (same as your Flutter app)
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

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { limit: limitParam = 20, keywords = '' } = req.query;
    const limitNum = parseInt(limitParam);

    // Get latest trending aggregate
    const trendingRef = collection(db, 'trending');
    const trendingQuery = query(
      trendingRef,
      where('type', '==', 'music'),
      orderBy('generatedAt', 'desc'),
      limit(1)
    );

    const trendingSnapshot = await getDocs(trendingQuery);
    
    if (trendingSnapshot.empty) {
      return res.json({ items: [], message: 'No trending data available' });
    }

    const trendingData = trendingSnapshot.docs[0].data();
    const mediaIds = trendingData.topMediaIds.slice(0, limitNum);

    if (mediaIds.length === 0) {
      return res.json({ items: [], message: 'No trending items found' });
    }

    // Get trending items
    const itemsRef = collection(db, 'trendingItems');
    const itemsQuery = query(
      itemsRef,
      where('__name__', 'in', mediaIds)
    );

    const itemsSnapshot = await getDocs(itemsQuery);
    const items = itemsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Preserve order based on topMediaIds
    const orderedItems = mediaIds
      .map(id => items.find(item => item.id === id))
      .filter(Boolean);

    // Apply keyword filtering if provided
    let filteredItems = orderedItems;
    if (keywords) {
      const keywordList = keywords.split(',').map(k => k.trim().toLowerCase()).filter(k => k);
      filteredItems = orderedItems.filter(item => {
        const searchText = `${item.title} ${item.artist} ${(item.genres || []).join(' ')}`.toLowerCase();
        return keywordList.some(keyword => searchText.includes(keyword));
      });
    }

    res.json({ 
      items: filteredItems,
      total: filteredItems.length,
      generatedAt: trendingData.generatedAt
    });

  } catch (error) {
    console.error('Error fetching trending music:', error);
    res.status(500).json({ error: 'Failed to fetch trending music' });
  }
}

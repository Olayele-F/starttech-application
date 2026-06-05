import React, { useEffect, useState } from 'react';

const API_URL = process.env.REACT_APP_API_URL || '';

export default function App() {
  const [health, setHealth] = useState(null);
  const [items, setItems]   = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]   = useState(null);

  useEffect(() => {
    Promise.all([
      fetch(`${API_URL}/health`).then(r => r.json()),
      fetch(`${API_URL}/api/v1/items`).then(r => r.json()),
    ])
      .then(([h, i]) => { setHealth(h); setItems(i.items || []); })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div style={{ fontFamily: 'sans-serif', maxWidth: 800, margin: '0 auto', padding: 32 }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1 style={{ margin: 0 }}>StartTech</h1>
        <span style={{
          padding: '4px 12px', borderRadius: 20,
          background: health?.status === 'ok' ? '#22c55e' : '#ef4444',
          color: '#fff', fontSize: 14,
        }}>
          {health ? `API ${health.status}` : 'connecting…'}
        </span>
      </header>

      <main style={{ marginTop: 32 }}>
        {loading && <p>Loading…</p>}
        {error   && <p style={{ color: 'red' }}>Error: {error}</p>}
        {!loading && !error && (
          <>
            <h2>Items ({items.length})</h2>
            <ul style={{ listStyle: 'none', padding: 0 }}>
              {items.map(item => (
                <li key={item.id} style={{
                  padding: '12px 16px', marginBottom: 8,
                  background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: 8,
                  display: 'flex', justifyContent: 'space-between',
                }}>
                  <strong>{item.name}</strong>
                  <time style={{ color: '#94a3b8', fontSize: 13 }}>
                    {new Date(item.created_at).toLocaleString()}
                  </time>
                </li>
              ))}
            </ul>
          </>
        )}
      </main>
    </div>
  );
}

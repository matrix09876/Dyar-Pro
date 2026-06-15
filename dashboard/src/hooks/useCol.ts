// اشتراك لحظي بمجموعة Firestore — قلب "اللوحة الحية".
import { useEffect, useMemo, useState } from 'react';
import {
  collection, onSnapshot, query, type QueryConstraint,
} from 'firebase/firestore';
import { db, isConfigured } from '../lib/firebase';

export function useCol<T>(path: string, ...constraints: QueryConstraint[]) {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // المفتاح يعاد بناؤه فقط عند تغيّر الاستعلام فعليًا
  const key = useMemo(
    () => path + JSON.stringify(constraints.map((c) => String(c.type))),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [path, constraints.length]
  );

  useEffect(() => {
    if (!isConfigured) { setLoading(false); return; }
    setLoading(true);
    const q = query(collection(db, path), ...constraints);
    const unsub = onSnapshot(
      q,
      (snap) => {
        setData(snap.docs.map((d) => ({ id: d.id, ...d.data() }) as T));
        setLoading(false);
      },
      (err) => { setError(err.message); setLoading(false); }
    );
    return unsub;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  return { data, loading, error };
}

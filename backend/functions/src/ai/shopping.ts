// ديار AI Shopping Assistant — المساعد الذكي يتسوّق عنك.
// المستخدم يكتب نيّته بالعربي/العبري/الإنجليزي، فنجلب الكاتالوج الحقيقي من
// Firestore (متاجر معتمدة + أصنافها بأسعارها الفعلية)، ونطلب من Claude اختيار
// متجر واحد وأصنافًا منه فقط (tool-use = مخرجات JSON صارمة). ثم نتحقّق خادميًا
// أن كل itemId حقيقي ويعود للمتجر، ونحسب الإجمالي من الأسعار الفعلية.
//
// قواعد صارمة: لا يخترع منتجات/أسعار (نتحقق من كل id) · لا يطلب بلا تأكيد
// (يعيد اقتراحًا فقط؛ الطلب يمرّ عبر createOrder بعد تأكيد المستخدم).
import { getFirestore } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');
const MODEL = 'claude-sonnet-4-6';
const db = () => getFirestore();

type CatalogItem = { itemId: string; name: string; price: number; dietary: string[] };
type CatalogStore = {
  storeId: string; name: string; type: string; rating: number;
  deliveryFee: number; minOrder: number; prepTimeMins: number;
  dietary: string[]; items: CatalogItem[];
};

/** يبني كاتالوجًا مضغوطًا من متاجر معتمدة + أصنافها (محدود لضبط الكلفة). */
async function buildCatalog(opts: { city: string | null; type: string | null }): Promise<CatalogStore[]> {
  const snap = await db().collection('stores').where('status', '==', 'approved').limit(60).get();
  let stores = snap.docs
    .map((d): { id: string; [k: string]: unknown } => ({ id: d.id, ...(d.data() as Record<string, unknown>) }))
    .filter((s) => s['isOpen'] !== false);
  if (opts.city) stores = stores.filter((s) => (s['location'] as { city?: string } | undefined)?.city === opts.city);
  if (opts.type) stores = stores.filter((s) => s['type'] === opts.type);
  // الأعلى تقييمًا أولًا، ثم نأخذ أفضل 10 متاجر لضبط حجم البرومبت/القراءات
  stores.sort((a, b) => ((b['rating'] as number) ?? 0) - ((a['rating'] as number) ?? 0));
  stores = stores.slice(0, 10);

  const menus = await Promise.all(
    stores.map((s) =>
      db().collection(`stores/${s.id}/menu`).where('available', '==', true).limit(18).get()),
  );

  const catalog: CatalogStore[] = stores.map((s, i) => ({
    storeId: s.id as string,
    name: (s['name'] as string) ?? '',
    type: (s['type'] as string) ?? 'store',
    rating: (s['rating'] as number) ?? 0,
    deliveryFee: (s['deliveryFee'] as number) ?? 0,
    minOrder: (s['minOrder'] as number) ?? 0,
    prepTimeMins: (s['prepTimeMins'] as number) ?? 20,
    dietary: Array.isArray(s['dietary']) ? (s['dietary'] as string[]) : [],
    items: menus[i].docs.map((m) => {
      const d = m.data();
      return {
        itemId: m.id,
        name: (d['name'] as string) ?? '',
        price: (d['price'] as number) ?? 0,
        dietary: Array.isArray(d['dietary']) ? (d['dietary'] as string[]) : [],
      };
    }),
  }));
  return catalog.filter((s) => s.items.length > 0);
}

/** اختيار احتياطي بلا AI: أعلى متجر تقييمًا + أرخص الأصناف ضمن الميزانية. */
function heuristicPick(catalog: CatalogStore[], budget: number | null) {
  const store = catalog[0];
  if (!store) return null;
  const items = [...store.items].sort((a, b) => a.price - b.price);
  const picked: { itemId: string; qty: number }[] = [];
  let sum = 0;
  for (const it of items) {
    if (budget && sum + it.price > budget) continue;
    picked.push({ itemId: it.itemId, qty: 1 });
    sum += it.price;
    if (picked.length >= 3) break;
  }
  if (picked.length === 0 && items[0]) picked.push({ itemId: items[0].itemId, qty: 1 });
  return { storeId: store.storeId, items: picked, explanation: '' };
}

/** يستدعي Claude بـ tool-use للحصول على اقتراح JSON صارم من الكاتالوج فقط. */
async function askClaude(
  query: string, lang: string, budget: number | null, catalog: CatalogStore[],
): Promise<{ storeId: string; items: { itemId: string; qty: number }[]; explanation: string } | null> {
  const budgetLine = budget ? `\nميزانية المستخدم: ${(budget / 100).toFixed(0)} شيكل (لا تتجاوزها).` : '';
  const sys =
    'أنت مساعد تسوّق ديار. مهمتك: اختيار متجر واحد وأصناف منه فقط لتلبية طلب ' +
    'المستخدم بأفضل قيمة. التزم بالكاتالوج المعطى حصراً — ممنوع منعاً باتاً ' +
    'اختراع أصناف أو أسعار أو معرّفات. استخدم أداة propose_cart فقط. اشرح ' +
    `سبب اختيارك بإيجاز وبلغة المستخدم (${lang}). احترم القيود الغذائية إن ذُكرت.`;
  const userMsg =
    `طلب المستخدم: «${query}».${budgetLine}\n\nالكاتالوج (JSON):\n` +
    JSON.stringify(catalog);

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_API_KEY.value(),
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 1024,
      system: sys,
      tools: [{
        name: 'propose_cart',
        description: 'اقترح متجراً واحداً وأصنافاً منه من الكاتالوج المعطى فقط.',
        input_schema: {
          type: 'object',
          properties: {
            storeId: { type: 'string', description: 'storeId من الكاتالوج' },
            items: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  itemId: { type: 'string' },
                  qty: { type: 'integer', minimum: 1, maximum: 20 },
                },
                required: ['itemId', 'qty'],
              },
            },
            explanation: { type: 'string', description: 'سبب الاختيار بلغة المستخدم' },
          },
          required: ['storeId', 'items', 'explanation'],
        },
      }],
      tool_choice: { type: 'tool', name: 'propose_cart' },
      messages: [{ role: 'user', content: userMsg }],
    }),
  });
  const data = (await res.json()) as {
    content?: { type: string; name?: string; input?: Record<string, unknown> }[];
  };
  const block = data?.content?.find((c) => c.type === 'tool_use' && c.name === 'propose_cart');
  if (!block?.input) return null;
  const inp = block.input as { storeId?: string; items?: { itemId: string; qty: number }[]; explanation?: string };
  if (!inp.storeId || !Array.isArray(inp.items)) return null;
  return { storeId: inp.storeId, items: inp.items, explanation: String(inp.explanation ?? '') };
}

/**
 * المساعد الذكي يبني سلة مقترحة. يعيد اقتراحاً فقط (لا يطلب) — التأكيد والطلب
 * في تطبيق العميل عبر createOrder. كل صنف مُتحقَّق منه بسعره الحقيقي.
 */
export const aiBuildCart = onCall({ secrets: [ANTHROPIC_API_KEY] }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const query = String(req.data?.query ?? '').trim();
  if (!query || query.length > 500) {
    throw new HttpsError('invalid-argument', 'query required (≤500 chars)');
  }
  const lang = ['ar', 'he', 'en'].includes(req.data?.lang) ? String(req.data.lang) : 'ar';
  const city = req.data?.city ? String(req.data.city) : null;
  const type = req.data?.type ? String(req.data.type) : null;
  const budget = req.data?.budget != null ? Math.round(Number(req.data.budget)) : null; // أغورة

  const catalog = await buildCatalog({ city, type });
  if (catalog.length === 0) {
    throw new HttpsError('failed-precondition', 'no open stores');
  }

  // تحقق صارم: المتجر موجود في الكاتالوج، وكل صنف يعود له بسعره الحقيقي.
  // يعيد null إن كان الاقتراح غير صالح (متجر مُختلَق/أصناف غير موجودة).
  type Proposal = { storeId: string; items: { itemId: string; qty: number }[]; explanation: string };
  const validate = (p: Proposal | null) => {
    if (!p) return null;
    const store = catalog.find((st) => st.storeId === p.storeId);
    if (!store) return null;
    const byId = new Map(store.items.map((it) => [it.itemId, it]));
    const items = p.items
      .map((line) => {
        const it = byId.get(line.itemId);
        if (!it) return null;
        const qty = Math.min(20, Math.max(1, Math.round(line.qty)));
        return { itemId: it.itemId, name: it.name, price: it.price, qty, lineTotal: it.price * qty };
      })
      .filter((x): x is NonNullable<typeof x> => x != null);
    if (items.length === 0) return null;
    return { store, items, explanation: p.explanation };
  };

  // 1) محاولة Claude، 2) احتياطي حسابي عند أي خطأ/غياب مفتاح/اقتراح غير صالح
  let usedAi = false;
  let valid: ReturnType<typeof validate> = null;
  try {
    const aiProposal = await askClaude(query, lang, budget, catalog);
    valid = validate(aiProposal);
    usedAi = valid != null;
  } catch {
    valid = null;
  }
  if (!valid) valid = validate(heuristicPick(catalog, budget));
  if (!valid) throw new HttpsError('internal', 'could not build cart');

  const { store, items, explanation } = valid;
  const subtotal = items.reduce((s, it) => s + it.lineTotal, 0);
  return {
    ok: true,
    usedAi,
    storeId: store.storeId,
    storeName: store.name,
    storeType: store.type,
    deliveryFee: store.deliveryFee,
    items, // [{itemId,name,price,qty,lineTotal}]
    subtotal,
    estimatedTotal: subtotal + store.deliveryFee,
    explanation,
    overBudget: budget != null && subtotal > budget,
  };
});

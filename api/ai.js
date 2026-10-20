import Anthropic from '@anthropic-ai/sdk';
import { supabaseOrigin } from './config.js';

const client = new Anthropic(); // reads ANTHROPIC_API_KEY

// Only signed-in users of this app may spend the API key.
async function verifyUser(token) {
  const base = supabaseOrigin();
  if (!token || !base) return null;
  try {
    const r = await fetch(`${base}/auth/v1/user`, {
      headers: { apikey: (process.env.SUPABASE_ANON_KEY || '').trim(), Authorization: `Bearer ${token}` },
    });
    if (!r.ok) return null;
    return await r.json();
  } catch {
    return null;
  }
}

function extractJson(text) {
  const t = text.replace(/^```(?:json)?\s*/i, '').replace(/```\s*$/, '').trim();
  try { return JSON.parse(t); } catch {}
  const a = t.indexOf('{'), b = t.lastIndexOf('}');
  if (a >= 0 && b > a) return JSON.parse(t.slice(a, b + 1));
  throw new Error('invalid_json');
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ code: 'method_not_allowed' });
  if (!process.env.ANTHROPIC_API_KEY) return res.status(503).json({ code: 'ai_disabled' });

  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  const user = await verifyUser(token);
  if (!user?.id) return res.status(401).json({ code: 'not_signed_in' });

  const { prompt, image, effort } = req.body || {};
  if (typeof prompt !== 'string' || !prompt || prompt.length > 20000) return res.status(400).json({ code: 'bad_prompt' });
  if (image && (typeof image !== 'string' || image.length > 6_000_000)) return res.status(400).json({ code: 'bad_image' });

  const content = [];
  if (image) content.push({ type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: image } });
  content.push({ type: 'text', text: prompt });

  try {
    const response = await client.beta.messages.create({
      model: 'claude-opus-5-5',
      max_tokens: 16000,
      output_config: { effort: effort === 'medium' ? 'medium' : 'low' },
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      messages: [{ role: 'user', content }],
    });
    if (response.stop_reason === 'refusal') return res.status(422).json({ code: 'refusal' });
    const text = response.content.filter(b => b.type === 'text').map(b => b.text).join('');
    return res.status(200).json(extractJson(text));
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) return res.status(429).json({ code: 'rate_limited' });
    if (e instanceof Anthropic.APIError) {
      console.error('anthropic error', e.status, e.message);
      return res.status(502).json({ code: 'ai_error' });
    }
    if (e?.message === 'invalid_json' || e instanceof SyntaxError) return res.status(502).json({ code: 'invalid_json' });
    console.error(e);
    return res.status(500).json({ code: 'server_error' });
  }
}

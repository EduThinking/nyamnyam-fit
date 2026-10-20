// Public client config. The Supabase anon key is designed to be public; row-level security protects the data.
// Accept a URL copied with extra path (e.g. ".../rest/v1/") and keep only the origin.
export function supabaseOrigin() {
  try { return new URL((process.env.SUPABASE_URL || '').trim()).origin; } catch { return ''; }
}

export default function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({
    supabaseUrl: supabaseOrigin(),
    supabaseAnonKey: (process.env.SUPABASE_ANON_KEY || '').trim(),
    ai: Boolean(process.env.ANTHROPIC_API_KEY),
  });
}

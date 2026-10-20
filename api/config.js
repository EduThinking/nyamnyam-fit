// Public client config. The Supabase anon key is designed to be public; row-level security protects the data.
export default function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({
    supabaseUrl: process.env.SUPABASE_URL || '',
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
    ai: Boolean(process.env.ANTHROPIC_API_KEY),
  });
}

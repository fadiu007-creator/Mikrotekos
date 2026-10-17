(function () {
  const url = window.MIKROTEKOS_SUPABASE_URL;
  const key = window.MIKROTEKOS_SUPABASE_KEY;
  window.MT_READY = (async function () {
    if (!url || !key) throw new Error("MikroTekos Supabase configuration is missing.");
    const mod = await import("https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm");
    const client = mod.createClient(url, key, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
    window.MT = client;
    return client;
  })();
  window.MT_READY.catch(function (e) { console.error("MikroTekos backend initialization failed", e); });
})();

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
  window.MT_SYNC_WORKSPACE = function (state) {
    if (window.__mtSyncTimer) clearTimeout(window.__mtSyncTimer);
    window.__mtSyncTimer = setTimeout(async function () {
      try {
        const db = await window.MT_READY;
        const { data: { user } } = await db.auth.getUser();
        if (!user) return;
        const { error } = await db.from("mikrotekos_workspaces").upsert(
          { user_id: user.id, data: JSON.parse(JSON.stringify(state)), updated_at: new Date().toISOString() },
          { onConflict: "user_id" }
        );
        if (error) console.warn("MikroTekos cloud save failed:", error.message);
      } catch (e) { console.warn("MikroTekos cloud save failed:", e); }
    }, 700);
  };
  window.MT_READY.catch(function (e) { console.error("MikroTekos backend initialization failed", e); });
})();

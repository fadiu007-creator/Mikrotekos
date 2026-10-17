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
        if (error) throw error;
        const projects = Array.isArray(state.projects) ? state.projects : [];
        const rows = projects.map(function (p) {
          const allowed = ["content", "social_content", "budget", "cv", "website", "automation", "seo"];
          return {
            user_id: user.id,
            local_id: String(p.id),
            project_type: allowed.includes(p.type) ? p.type : "content",
            title: String(p.title || "Untitled project").slice(0, 200),
            content: p.content === undefined ? {} : p.content,
            updated_at: p.updated || new Date().toISOString()
          };
        });
        if (rows.length) {
          const { error: projectError } = await db.from("mikrotekos_projects").upsert(rows, { onConflict: "user_id,local_id" });
          if (projectError) throw projectError;
        }
        const { data: existing, error: listError } = await db.from("mikrotekos_projects").select("local_id").eq("user_id", user.id);
        if (listError) throw listError;
        const wanted = new Set(rows.map(function (p) { return p.local_id; }));
        const removed = (existing || []).map(function (p) { return p.local_id; }).filter(function (id) { return !wanted.has(id); });
        if (removed.length) {
          const { error: deleteError } = await db.from("mikrotekos_projects").delete().eq("user_id", user.id).in("local_id", removed);
          if (deleteError) throw deleteError;
        }
      } catch (e) { console.warn("MikroTekos cloud save failed:", e); }
    }, 700);
  };
  window.MT_READY.catch(function (e) { console.error("MikroTekos backend initialization failed", e); });
})();

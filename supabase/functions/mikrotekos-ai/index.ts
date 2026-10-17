import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: cors });

  const auth = req.headers.get("Authorization") || "";
  if (!auth.startsWith("Bearer ")) return new Response(JSON.stringify({ error: "Sign in required" }), { status: 401, headers: cors });

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) return new Response(JSON.stringify({ error: "AI provider is not configured. Add OPENAI_API_KEY to Supabase Edge Function secrets." }), { status: 503, headers: cors });

  let body: { task?: string; prompt?: string; business?: Record<string, unknown>; question?: string; language?: string };
  try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: "Invalid JSON body" }), { status: 400, headers: cors }); }

  const task = String(body.task || "content");
  const prompt = String(body.prompt || body.question || "").trim();
  if (!["content", "faq", "seo", "automation"].includes(task)) return new Response(JSON.stringify({ error: "Unsupported task" }), { status: 400, headers: cors });
  if (!prompt || prompt.length > 12000) return new Response(JSON.stringify({ error: "Prompt must contain 1–12000 characters" }), { status: 400, headers: cors });

  const lang = body.language === "en" ? "English" : "Albanian (Kosovo)";
  const system = [
    "You are MikroTekos, a practical digital assistant for small businesses in Kosovo and the Balkans.",
    "Write in " + lang + " unless the user explicitly requests otherwise.",
    "Never invent business facts, prices, addresses, opening hours, guarantees, testimonials, or legal requirements.",
    "When facts are missing, use clear placeholders or ask a short clarifying question.",
    "Avoid discriminatory, deceptive, or unsafe recommendations. Keep outputs practical and ready for a human to review.",
    "Task: " + task
  ].join("\n");

  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": "Bearer " + apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") || "gpt-4.1-mini",
        temperature: 0.6,
        max_tokens: 1400,
        messages: [{ role: "system", content: system }, { role: "user", content: prompt }]
      })
    });
    const result = await response.json();
    if (!response.ok) return new Response(JSON.stringify({ error: "AI provider request failed", provider_status: response.status, details: result?.error?.message || "Unknown provider error" }), { status: 502, headers: cors });
    const output = result?.choices?.[0]?.message?.content;
    if (!output) return new Response(JSON.stringify({ error: "AI provider returned an empty response" }), { status: 502, headers: cors });
    return new Response(JSON.stringify({ output, model: result.model || Deno.env.get("OPENAI_MODEL") || "gpt-4.1-mini" }), { status: 200, headers: cors });
  } catch (error) {
    return new Response(JSON.stringify({ error: "AI request failed", details: String(error?.message || error) }), { status: 502, headers: cors });
  }
});

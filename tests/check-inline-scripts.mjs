import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const root = process.cwd();
const files = fs.readdirSync(root).filter(name => name.endsWith(".html"));
let checked = 0;
const errors = [];
for (const file of files) {
  const html = fs.readFileSync(path.join(root, file), "utf8");
  const scriptTag = /<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi;
  let match;
  let index = 0;
  while ((match = scriptTag.exec(html))) {
    const attrs = match[1] || "";
    const source = match[2] || "";
    if (/\bsrc\s*=/.test(attrs) || !source.trim()) continue;
    if (/\btype\s*=\s*["']application\/(?:ld\+)?json["']/i.test(attrs)) continue;
    try {
      new vm.Script(source, { filename: file + ":inline-script-" + (++index) });
      checked++;
    } catch (error) {
      errors.push(file + " inline script " + (index + 1) + ": " + error.message);
    }
  }
}
const workspace = fs.readFileSync(path.join(root, "workspace.html"), "utf8");
for (const required of ["mikrotekos_invoices", "mikrotekos_analysis_reports", "mikrotekos_leads", "mikrotekos_campaigns", "printInvoice", "analyzeFile", "leadForm", "socialForm"]) {
  if (!workspace.includes(required)) errors.push("workspace.html missing expected workflow marker: " + required);
}
if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}
console.log("Validated " + checked + " inline JavaScript blocks across " + files.length + " HTML pages.");
console.log("Workspace workflow markers present.");

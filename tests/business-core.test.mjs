import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

globalThis.window = {};
vm.runInThisContext(fs.readFileSync("business-core.js", "utf8"), { filename: "business-core.js" });
const core = window.MTBusinessCore;
assert.ok(core, "business core exports should load");

const result = core.calculateInvoice([
  { description: "A", quantity: 3, unit_price: 0.1 },
  { description: "B", quantity: 2, unit_price: 12.34 }
], 1, 10);
assert.equal(result.subtotal, 24.94);
assert.equal(result.discount, 1);
assert.equal(result.tax, 2.39);
assert.equal(result.total, 26.33);
assert.equal(core.calculateInvoice([{quantity: 1, unit_price: 10}], 99, 20).total, 0);
assert.throws(() => core.parseCSV('a,b\n"unfinished,2'), /unclosed quoted field/i);
assert.deepEqual(core.parseCSV('name,notes\n"Tea, green","line 1\nline 2"'), [
  ["name", "notes"], ["Tea, green", "line 1\nline 2"]
]);
assert.equal(core.csvEscape("=1+1"), '"\'=1+1"');
assert.equal(core.csvEscape(12.5), '"12.5"');
console.log("Business core tests passed: invoice math, discount/tax rounding, quoted CSV, and CSV formula injection.");

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
assert.equal(result.subtotal, 24.98);
assert.equal(result.discount, 1);
assert.equal(result.tax, 2.4);
assert.equal(result.total, 26.38);
assert.equal(core.calculateInvoice([{quantity: 1, unit_price: 10}], 99, 20).total, 0);
assert.throws(() => core.parseCSV('a,b\n"unfinished,2'), /unclosed quoted field/i);
assert.deepEqual(core.parseCSV('name,notes\n"Tea, green","line 1\nline 2"'), [
  ["name", "notes"], ["Tea, green", "line 1\nline 2"]
]);
assert.equal(core.csvEscape("=1+1"), '"\'=1+1"');
assert.equal(core.csvEscape(12.5), '"12.5"');
console.log("Business core tests passed: invoice math, discount/tax rounding, quoted CSV, and CSV formula injection.");

const trading = core.calculateTradingTax([1000, 2000, -5000, 500]);
assert.deepEqual(trading, {gains: 3500, losses: 5000, net: -1500, taxable: 0, tax: 0});
assert.equal(core.calculateTradingTax([3000]).tax, 0);
assert.equal(core.calculateTradingTax([5400]).tax, 192);
assert.equal(core.calculateTradingTax([7000]).tax, 352);
assert.equal(core.calculateTradingTax([10000]).tax, 652);
assert.throws(() => core.calculateTradingTax([]), /at least one/i);
assert.throws(() => core.calculateTradingTax([100, "bad"]), /finite number/i);
console.log("Trading tax tests passed: loss scenario, tax brackets, cent precision, and invalid inputs.");

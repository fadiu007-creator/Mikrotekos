(function(root){
"use strict";
function cents(value){const n=Number(value);if(!Number.isFinite(n))return 0;return Math.round(n*100)}
function calculateInvoice(items,discount,taxRate){
 const normalized=(Array.isArray(items)?items:[]).map(item=>{const quantity=Number(item.quantity),unitPrice=Number(item.unit_price);const valid=Number.isFinite(quantity)&&quantity>0&&Number.isFinite(unitPrice)&&unitPrice>=0;const lineCents=valid?Math.round(quantity*cents(unitPrice)):0;return {...item,quantity,unit_price:unitPrice,line_total:lineCents/100,valid}});
 const subtotalCents=normalized.reduce((sum,item)=>sum+Math.round(item.line_total*100),0);
 const discountCents=Math.min(subtotalCents,Math.max(0,cents(discount)));
 const rate=Math.max(0,Math.min(100,Number(taxRate)||0));
 const taxableCents=Math.max(0,subtotalCents-discountCents);
 const taxCents=Math.round(taxableCents*rate/100);
 return {items:normalized,subtotal:subtotalCents/100,discount:discountCents/100,tax:taxCents/100,total:(taxableCents+taxCents)/100,currency:null};
}
function parseCSV(text){
 const rows=[];let row=[],field="",quoted=false;const source=String(text||"");
 for(let i=0;i<source.length;i++){const c=source[i];if(quoted){if(c==='"'&&source[i+1]==='"'){field+='"';i++}else if(c==='"')quoted=false;else field+=c}else if(c==='"')quoted=true;else if(c===","){row.push(field);field=""}else if(c==="\n"){row.push(field.replace(/\r$/,""));rows.push(row);row=[];field=""}else field+=c}
 if(quoted)throw new Error("CSV contains an unclosed quoted field.");
 if(field.length||row.length){row.push(field.replace(/\r$/,""));rows.push(row)}
 return rows.filter(r=>r.some(v=>String(v).trim()!==""));
}
function csvEscape(value){const s=String(value==null?"":value);const safe=typeof value==="number"?s:(/^[=+\-@\t\r]/.test(s)?"'"+s:s);return '"'+safe.replace(/"/g,'""')+'"'}
function calculateTradingTax(values){if(!Array.isArray(values)||values.length===0)throw new TypeError("At least one realized trade result is required.");const cents=values.map(value=>{const n=Number(value);if(!Number.isFinite(n))throw new TypeError("Every trade result must be a finite number.");return Math.round(n*100)});const gains=cents.filter(v=>v>0).reduce((a,b)=>a+b,0),losses=-cents.filter(v=>v<0).reduce((a,b)=>a+b,0),net=gains-losses,taxable=Math.max(0,net);const tax=Math.round(Math.min(Math.max(taxable-300000,0),240000)*.08+Math.max(taxable-540000,0)*.10);return{gains:gains/100,losses:losses/100,net:net/100,taxable:taxable/100,tax:tax/100}}
root.MTBusinessCore={calculateInvoice,parseCSV,csvEscape,calculateTradingTax};
})(typeof window!=="undefined"?window:globalThis);

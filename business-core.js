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
root.MTBusinessCore={calculateInvoice,parseCSV,csvEscape};
})(typeof window!=="undefined"?window:globalThis);

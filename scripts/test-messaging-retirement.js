const vm = require('vm'), fs = require('fs'), assert = require('assert');
const root = process.cwd();
const html = fs.readFileSync(root+'/web/index.html','utf8');
assert(!html.includes('serviceWorker.register('));
const cleanup = html.match(/<script>\s*(\/\/ Retire[\s\S]*?)<\/script>/)[1];
const updated=[];
const registrations=['/firebase-messaging-sw.js','/flutter_service_worker.js','/other-app-worker.js'].map(path=>({active:{scriptURL:'https://example.test'+path},update:async()=>updated.push(path)}));
const pending=[];
vm.runInNewContext(cleanup,{navigator:{serviceWorker:{getRegistrations:()=>{const p=Promise.resolve(registrations);pending.push(p);return p;}}},URL});
Promise.all(pending).then(async()=>{
 assert.deepEqual(updated,['/firebase-messaging-sw.js','/flutter_service_worker.js']);
 const events={}; let unregistered=0, completion;
 vm.runInNewContext(fs.readFileSync(root+'/web/firebase-messaging-sw.js','utf8'),{self:{addEventListener:(n,f)=>events[n]=f,skipWaiting:()=>{},registration:{unregister:async()=>unregistered++}}});
 events.install();events.activate({waitUntil:p=>completion=p});await completion;
 assert.equal(unregistered,1);
 console.log('Messaging retirement: targeted registrations only, no SDK or navigation.');
});

// Retirement worker for previously installed messaging registrations.
// No SDK, notification handler, cache creation or page navigation.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  await self.registration.unregister();
})()));

self.addEventListener("push", (event) => {
  let message = {
    title: "Een spel start bij jou in de buurt",
    body: "Open Verstobbertje om de details te bekijken.",
    url: "/",
  };
  if (event.data) {
    try {
      message = { ...message, ...event.data.json() };
    } catch (_) {
      message.body = event.data.text();
    }
  }
  event.waitUntil(self.registration.showNotification(message.title, {
    body: message.body,
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    tag: message.tag || "nearby-game-start",
    data: { url: message.url || "/" },
  }));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || "/", self.location.origin).href;
  event.waitUntil((async () => {
    const clients = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
    for (const client of clients) {
      if (new URL(client.url).origin === self.location.origin) {
        await client.navigate(target);
        return client.focus();
      }
    }
    return self.clients.openWindow(target);
  })());
});

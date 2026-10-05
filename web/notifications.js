window.VerstobbertjePush = (() => {
  const workerPath = "/notifications/push-worker.js";
  const scope = "/notifications/";

  const ready = async () => {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      throw new Error("push_not_supported");
    }
    return navigator.serviceWorker.register(workerPath, { scope });
  };

  const locate = () => new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error("location_not_supported"));
      return;
    }
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => resolve({
        latitude: Math.round(coords.latitude * 100) / 100,
        longitude: Math.round(coords.longitude * 100) / 100,
      }),
      () => reject(new Error("location_permission_required")),
      { enableHighAccuracy: false, timeout: 12000, maximumAge: 300000 },
    );
  });

  const decodeKey = (value) => {
    const padding = "=".repeat((4 - value.length % 4) % 4);
    const bytes = atob((value + padding).replace(/-/g, "+").replace(/_/g, "/"));
    return Uint8Array.from(bytes, (character) => character.charCodeAt(0));
  };

  return {
    async enable(publicKey) {
      if (!("Notification" in window)) throw new Error("notifications_not_supported");
      const permission = await Notification.requestPermission();
      if (permission !== "granted") throw new Error("notification_permission_denied");
      const position = await locate();
      const registration = await ready();
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: decodeKey(publicKey),
      });
      return JSON.stringify({
        endpoint: subscription.endpoint,
        keys: subscription.toJSON().keys,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 25,
      });
    },
    async current() {
      const registration = await ready();
      const subscription = await registration.pushManager.getSubscription();
      if (!subscription) return "";
      const position = await locate();
      return JSON.stringify({
        endpoint: subscription.endpoint,
        keys: subscription.toJSON().keys,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 25,
      });
    },
    async disable() {
      const registration = await ready();
      const subscription = await registration.pushManager.getSubscription();
      if (!subscription) return "";
      const endpoint = subscription.endpoint;
      await subscription.unsubscribe();
      return endpoint;
    },
    async hasSubscription() {
      try {
        const registration = await ready();
        return Boolean(await registration.pushManager.getSubscription());
      } catch (_) {
        return false;
      }
    },
  };
})();

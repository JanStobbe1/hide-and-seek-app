const encoder = new TextEncoder();

const fromBase64Url = (value: string) => {
  const padded = value.replaceAll("-", "+").replaceAll("_", "/")
    + "=".repeat((4 - value.length % 4) % 4);
  return Uint8Array.from(atob(padded), (character) => character.charCodeAt(0));
};

const toBase64Url = (value: Uint8Array) =>
  btoa(String.fromCharCode(...value))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");

const concat = (...items: Uint8Array[]) => {
  const result = new Uint8Array(items.reduce((sum, item) => sum + item.length, 0));
  let offset = 0;
  for (const item of items) {
    result.set(item, offset);
    offset += item.length;
  }
  return result;
};

const hkdf = async (
  input: Uint8Array,
  salt: Uint8Array,
  info: Uint8Array,
  length: number,
) => {
  const key = await crypto.subtle.importKey("raw", input, "HKDF", false, ["deriveBits"]);
  return new Uint8Array(await crypto.subtle.deriveBits({
    name: "HKDF",
    hash: "SHA-256",
    salt,
    info,
  }, key, length * 8));
};

const uint32 = (value: number) => new Uint8Array([
  value >>> 24,
  value >>> 16,
  value >>> 8,
  value,
]);

const vapidJwt = async (
  endpoint: string,
  publicKey: string,
  privateKey: string,
) => {
  const origin = new URL(endpoint).origin;
  const encodedHeader = toBase64Url(encoder.encode(JSON.stringify({ typ: "JWT", alg: "ES256" })));
  const encodedPayload = toBase64Url(encoder.encode(JSON.stringify({
    aud: origin,
    exp: Math.floor(Date.now() / 1000) + 60 * 60,
    sub: "mailto:info@jsadministratieenadvies.nl",
  })));
  const unsigned = `${encodedHeader}.${encodedPayload}`;
  const point = fromBase64Url(publicKey);
  if (point.length !== 65 || point[0] !== 4) {
    throw new Error("Invalid VAPID public key");
  }
  const jwk = {
    kty: "EC",
    crv: "P-256",
    x: toBase64Url(point.slice(1, 33)),
    y: toBase64Url(point.slice(33, 65)),
    d: privateKey,
    ext: true,
    key_ops: ["sign"],
  };
  const key = await crypto.subtle.importKey("jwk", jwk, {
    name: "ECDSA",
    namedCurve: "P-256",
  }, false, ["sign"]);
  const signature = new Uint8Array(await crypto.subtle.sign({
    name: "ECDSA",
    hash: "SHA-256",
  }, key, encoder.encode(unsigned)));
  return `${unsigned}.${toBase64Url(signature)}`;
};

export const distanceKm = (
  latitudeA: number,
  longitudeA: number,
  latitudeB: number,
  longitudeB: number,
) => {
  const toRadians = (degrees: number) => degrees * Math.PI / 180;
  const dLatitude = toRadians(latitudeB - latitudeA);
  const dLongitude = toRadians(longitudeB - longitudeA);
  const a = Math.sin(dLatitude / 2) ** 2
    + Math.cos(toRadians(latitudeA)) * Math.cos(toRadians(latitudeB))
    * Math.sin(dLongitude / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

export const gameCenter = (boundary: unknown): [number, number] | null => {
  let points: unknown = boundary;
  if (typeof points === "string") {
    try {
      points = JSON.parse(points);
    } catch {
      return null;
    }
  }
  if (!Array.isArray(points) || points.length === 0) return null;
  const coordinates = points.filter((point) =>
    Array.isArray(point) && point.length >= 2
    && Number.isFinite(Number(point[0])) && Number.isFinite(Number(point[1]))
  ) as unknown[][];
  if (coordinates.length === 0) return null;
  const latitude = coordinates.reduce((sum, point) => sum + Number(point[0]), 0)
    / coordinates.length;
  const longitude = coordinates.reduce((sum, point) => sum + Number(point[1]), 0)
    / coordinates.length;
  return [latitude, longitude];
};

export interface WebPushSubscription {
  endpoint: string;
  p256dh: string;
  auth: string;
}

export const sendWebPush = async (
  subscription: WebPushSubscription,
  payload: unknown,
  publicKey: string,
  privateKey: string,
) => {
  const receiverPublicBytes = fromBase64Url(subscription.p256dh);
  const authSecret = fromBase64Url(subscription.auth);
  if (receiverPublicBytes.length !== 65 || authSecret.length !== 16) {
    throw new Error("Invalid browser push subscription keys");
  }

  const serverKeys = await crypto.subtle.generateKey({
    name: "ECDH",
    namedCurve: "P-256",
  }, true, ["deriveBits"]) as CryptoKeyPair;
  const publicKeyBuffer = await crypto.subtle.exportKey(
    "raw",
    serverKeys.publicKey,
  ) as ArrayBuffer;
  const serverPublic = new Uint8Array(publicKeyBuffer);
  const receiverPublic = await crypto.subtle.importKey(
    "raw",
    receiverPublicBytes,
    { name: "ECDH", namedCurve: "P-256" },
    false,
    [],
  ) as CryptoKey;
  const sharedSecretBuffer = await crypto.subtle.deriveBits({
    name: "ECDH",
    $public: receiverPublic,
  }, serverKeys.privateKey, 256);
  const sharedSecret = new Uint8Array(sharedSecretBuffer);
  const keyInfo = concat(
    encoder.encode("WebPush: info\0"),
    receiverPublicBytes,
    serverPublic,
  );
  const inputKey = await hkdf(sharedSecret, authSecret, keyInfo, 32);
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const contentKey = await hkdf(
    inputKey,
    salt,
    encoder.encode("Content-Encoding: aes128gcm\0"),
    16,
  );
  const nonce = await hkdf(
    inputKey,
    salt,
    encoder.encode("Content-Encoding: nonce\0"),
    12,
  );
  const aesKey = await crypto.subtle.importKey(
    "raw",
    contentKey,
    "AES-GCM",
    false,
    ["encrypt"],
  );
  const message = concat(encoder.encode(JSON.stringify(payload)), new Uint8Array([2]));
  const encrypted = new Uint8Array(await crypto.subtle.encrypt({
    name: "AES-GCM",
    iv: nonce,
  }, aesKey, message));
  const body = concat(salt, uint32(4096), new Uint8Array([serverPublic.length]), serverPublic, encrypted);
  const jwt = await vapidJwt(subscription.endpoint, publicKey, privateKey);

  return fetch(subscription.endpoint, {
    method: "POST",
    headers: {
      Authorization: `vapid t=${jwt}, k=${publicKey}`,
      "Content-Encoding": "aes128gcm",
      "Content-Type": "application/octet-stream",
      TTL: "86400",
      Urgency: "normal",
    },
    body,
  });
};

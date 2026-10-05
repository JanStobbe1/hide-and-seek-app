import 'dart:convert';
import 'dart:js_interop';

@JS('VerstobbertjePush.enable')
external JSPromise<JSString> _enableNearbyPush(JSString publicKey);

@JS('VerstobbertjePush.current')
external JSPromise<JSString> _refreshNearbyPushLocation();

@JS('VerstobbertjePush.hasSubscription')
external JSPromise<JSBoolean> _hasNearbyPushSubscription();

@JS('VerstobbertjePush.endpoint')
external JSPromise<JSString> _nearbyPushEndpoint();

@JS('VerstobbertjePush.disable')
external JSPromise<JSString> _disableNearbyPush();

Future<Map<String, dynamic>> enableNearbyPush(String publicKey) async {
  final value = await _enableNearbyPush(publicKey.toJS).toDart;
  return jsonDecode(value.toDart) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> refreshNearbyPushLocation() async {
  final value = await _refreshNearbyPushLocation().toDart;
  return jsonDecode(value.toDart) as Map<String, dynamic>;
}

Future<bool> hasNearbyPushSubscription() async =>
    (await _hasNearbyPushSubscription().toDart).toDart;

Future<String?> nearbyPushEndpoint() async {
  final value = (await _nearbyPushEndpoint().toDart).toDart;
  return value.isEmpty ? null : value;
}

Future<String?> disableNearbyPush() async {
  final value = (await _disableNearbyPush().toDart).toDart;
  return value.isEmpty ? null : value;
}

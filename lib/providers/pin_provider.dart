import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satsails_wallet/models/pin_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final pinProvider = FutureProvider<PinModel>((ref) async {
  final storage = FlutterSecureStorage();
  final pin = await storage.read(key: 'pin');

  return PinModel(pin: pin ?? '');
});
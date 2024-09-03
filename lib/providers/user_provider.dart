import 'package:Satsails/handlers/response_handlers.dart';
import 'package:Satsails/models/affiliate_model.dart';
import 'package:Satsails/models/transfer_model.dart';
import 'package:Satsails/models/user_model.dart';
import 'package:Satsails/providers/liquid_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

final FlutterSecureStorage _storage = const FlutterSecureStorage();

final initializeUserProvider = FutureProvider<User>((ref) async {
  final box = await Hive.openBox('user');
  final affiliateCode = box.get('affiliateCode', defaultValue: '');
  final hasInsertedAffiliate = box.get('hasInsertedAffiliate', defaultValue: false);
  final hasCreatedAffiliate = box.get('hasCreatedAffiliate', defaultValue: false);
  final paymentId = box.get('paymentId', defaultValue: '');
  final recoveryCode = await _storage.read(key: 'recoveryCode') ?? '';
  final onboarded = box.get('onboarding', defaultValue: false);

  return User(
    affiliateCode: affiliateCode,
    hasInsertedAffiliate: hasInsertedAffiliate,
    hasCreatedAffiliate: hasCreatedAffiliate,
    recoveryCode: recoveryCode,
    paymentId: paymentId,
    onboarded: onboarded,
  );
});

final userProvider = StateNotifierProvider<UserModel, User>((ref) {
  final initialUser = ref.watch(initializeUserProvider);

  return UserModel(initialUser.when(
    data: (user) => user,
    loading: () => User(
      affiliateCode: '',
      hasInsertedAffiliate: false,
      hasCreatedAffiliate: false,
      recoveryCode: '',
      paymentId: '',
      onboarded: false,
    ),
    error: (Object error, StackTrace stackTrace) {
      throw error;
    },
  ));
});

final createUserProvider = FutureProvider.autoDispose<void>((ref) async {
  final liquidAddress = await ref.read(liquidAddressProvider.future);
  final result = await UserService.createUserRequest(liquidAddress.confidential);

  if (result.isSuccess && result.data != null) {
    final user = result.data!;
    await ref.read(userProvider.notifier).setPaymentId(user.paymentId);
    await ref.read(userProvider.notifier).setRecoveryCode(user.recoveryCode);
  } else {
    throw result.error!;
  }
});

final getUserTransactionsProvider = FutureProvider.autoDispose<List<Transfer>>((ref) async {
  final paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  final transactions = await UserService.getUserTransactions(paymentId, auth);

  if (transactions.isSuccess && transactions.data != null) {
    return transactions.data!;
  } else {
    throw transactions.error!;
  }
});

final getAmountTransferredProvider = FutureProvider.autoDispose<String>((ref) async {
  final paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  final amountTransferred = await UserService.getAmountTransferred(paymentId, auth);

  if (amountTransferred.isSuccess && amountTransferred.data != null) {
    return amountTransferred.data!;
  } else {
    throw amountTransferred.error!;
  }
});

final addAffiliateCodeProvider = FutureProvider.autoDispose.family<void, String>((ref, affiliateCode) async {
  var paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  final result = await UserService.addAffiliateCode(paymentId, affiliateCode, auth);

  if (result.isSuccess && result.data == true) {
    await ref.read(userProvider.notifier).sethasInsertedAffiliate(true);
    await ref.read(userProvider.notifier).setAffiliateCode(affiliateCode);
  } else {
    throw result.error!;
  }
});

final createAffiliateCodeProvider = FutureProvider.autoDispose.family<void, Affiliate>((ref, affiliate) async {
  var paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  final result = await UserService.createAffiliateCode(paymentId, affiliate.code, affiliate.liquidAddress, auth);

  if (result.isSuccess && result.data == true) {
    await ref.read(userProvider.notifier).setHasCreatedAffiliate(true);
    await ref.read(userProvider.notifier).setAffiliateCode(affiliate.code);
  } else {
    throw result.error!;
  }
});

final numberOfAffiliateInstallsProvider = FutureProvider.autoDispose<int>((ref) async {
  final affiliateCode = ref.watch(userProvider).affiliateCode ?? '';
  final auth = ref.read(userProvider).recoveryCode;
  final numberOfUsers = await UserService.affiliateNumberOfUsers(affiliateCode, auth);

  if (numberOfUsers.isSuccess && numberOfUsers.data != null) {
    return numberOfUsers.data!;
  } else {
    throw numberOfUsers.error!;
  }
});

final affiliateEarningsProvider = FutureProvider.autoDispose<String>((ref) async {
  final affiliateCode = ref.watch(userProvider).affiliateCode ?? '';
  final auth = ref.read(userProvider).recoveryCode;
  final result = await UserService.affiliateEarnings(affiliateCode, auth);

  if (result.isSuccess && result.data != null) {
    return result.data!;
  } else {
    throw result.error!;
  }
});

final updateLiquidAddressProvider = FutureProvider.autoDispose<String>((ref) async {
  final liquidAddress = await ref.read(liquidAddressProvider.future);
  final auth = ref.read(userProvider).recoveryCode;
  final result = await UserService.updateLiquidAddress(liquidAddress.confidential, auth);

  if (result.isSuccess && result.data != null) {
    return result.data!;
  } else {
    throw result.error!;
  }
});

final setUserProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.read(updateLiquidAddressProvider.future);
  final auth = ref.read(userProvider).recoveryCode;
  final userResult = await UserService.showUser(auth);

  if (userResult.isSuccess && userResult.data != null) {
    final user = userResult.data!;
    await ref.read(userProvider.notifier).setPaymentId(user.paymentId);
    await ref.read(userProvider.notifier).setRecoveryCode(user.recoveryCode);
    await ref.read(userProvider.notifier).setAffiliateCode(user.affiliateCode ?? '');
  } else {
    throw userResult.error!;
  }
});

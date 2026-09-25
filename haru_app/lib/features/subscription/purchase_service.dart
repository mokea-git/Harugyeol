import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_api.dart';

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();
  bool _configured = false;

  /// App 시작 시 1회 호출 (main.dart)
  Future<void> configure() async {
    if (_configured) return;
    if (kIsWeb) return;
    final String apiKey;
    if (Platform.isIOS) {
      apiKey = dotenv.env['REVENUECAT_IOS_KEY'] ?? '';
    } else {
      apiKey = dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
    }
    if (apiKey.isEmpty || apiKey.startsWith('REPLACE')) return;

    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
  }

  /// 로그인 후 유저 식별
  Future<void> identifyUser(String userId) async {
    if (!_configured) return;
    await Purchases.logIn(userId);
  }

  /// 로그아웃 시 초기화
  Future<void> logout() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  /// Offerings 가져오기 (상품 목록 + 가격)
  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  /// 패키지 구매
  Future<PurchaseResult> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      final isPro = info.entitlements.active.containsKey('pro');
      if (isPro) {
        // 서버에도 즉시 동기화
        try {
          await SubscriptionApi.instance.activate();
        } catch (_) {}
      }
      return PurchaseResult(success: isPro, customerInfo: info);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult(success: false, cancelled: true);
      }
      return PurchaseResult(success: false, error: e.message);
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  /// 구매 복원
  Future<PurchaseResult> restorePurchases() async {
    if (!_configured) return PurchaseResult(success: false, error: 'not configured');
    try {
      final info = await Purchases.restorePurchases();
      final isPro = info.entitlements.active.containsKey('pro');
      if (isPro) {
        try {
          await SubscriptionApi.instance.activate();
        } catch (_) {}
      }
      return PurchaseResult(success: isPro, customerInfo: info, restored: true);
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  /// 현재 entitlement 체크
  Future<bool> checkIsPro() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('pro');
    } catch (_) {
      return false;
    }
  }
}

class PurchaseResult {
  final bool success;
  final bool cancelled;
  final bool restored;
  final String? error;
  final CustomerInfo? customerInfo;

  const PurchaseResult({
    required this.success,
    this.cancelled = false,
    this.restored = false,
    this.error,
    this.customerInfo,
  });
}

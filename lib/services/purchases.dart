import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app_state.dart';

/// Aylık ve yıllık abonelik. Ürün kimlikleri Google Play Console ve
/// App Store Connect'te aynı adlarla tanımlanmalıdır.
class Purchases extends ChangeNotifier {
  Purchases._();
  static final Purchases I = Purchases._();

  static const monthlyId = 'minik_kasif_monthly';
  static const yearlyId = 'minik_kasif_yearly';
  static const _ids = {monthlyId, yearlyId};

  /// Testlerde mağaza eklentisine dokunmamak için kapatılır.
  static bool enabled = true;

  bool available = false;
  bool loading = false;
  String? error;
  List<ProductDetails> products = [];

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _sawActivePurchase = false;

  ProductDetails? get monthly => _find(monthlyId);
  ProductDetails? get yearly => _find(yearlyId);

  ProductDetails? _find(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> init() async {
    if (!enabled || kIsWeb) return;
    try {
      final iap = InAppPurchase.instance;
      _sub ??= iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          error = e.toString();
          notifyListeners();
        },
      );
      available = await iap.isAvailable();
      if (!available) return;
      await loadProducts();
      // Android'de geçmiş satın alımlar sessizce sorgulanabilir; böylece süresi
      // dolan ya da iptal edilen abonelik açılışta fark edilir.
      if (defaultTargetPlatform == TargetPlatform.android) {
        await iap.restorePurchases();
        Future.delayed(const Duration(seconds: 5), () {
          if (!_sawActivePurchase) AppState.I.setPremium(false);
        });
      }
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadProducts() async {
    loading = true;
    notifyListeners();
    try {
      final response = await InAppPurchase.instance.queryProductDetails(_ids);
      products = response.productDetails;
      error = response.error?.message;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    error = null;
    notifyListeners();
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (!available) return;
    error = null;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!_ids.contains(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _sawActivePurchase = true;
          AppState.I.setPremium(true);
        case PurchaseStatus.error:
          error = purchase.error?.message;
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
    notifyListeners();
  }
}

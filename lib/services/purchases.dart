import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../app_state.dart';
import '../l10n.dart';

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

  /// Son satın alma ya da geri yükleme anı. Hemen ardından gelen sorgu,
  /// mağaza kaydı henüz yansımadıysa aboneliği yanlışlıkla kapatmasın.
  DateTime? _lastGrant;

  static bool get _apple => defaultTargetPlatform == TargetPlatform.iOS;

  /// Ödemeyi alan mağazanın adı.
  static String get storeName => _apple ? 'Apple' : 'Google Play';

  /// Aboneliğin cihazda nereden iptal edileceği (menü yolu).
  static String get whereToCancel =>
      L.t(_apple ? 'sub_where_ios' : 'sub_where_android');

  /// Mağaza adı ve iptal yolu yerleştirilmiş abonelik metni.
  static String legalText(String key) => L
      .t(key)
      .replaceAll('{store}', storeName)
      .replaceAll('{where}', whereToCancel);

  /// iOS'ta App Store'un "abonelikleri yönet" penceresini açar. Açılamadıysa
  /// (başka platform, eski sürüm, hata) false döner; çağıran yol tarifini
  /// gösterir.
  Future<bool> manage() async {
    if (!enabled || kIsWeb || !_apple) return false;
    try {
      await AppStore().showManageSubscriptions();
      // Pencerede iptal edilmiş ya da plan değişmiş olabilir.
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

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
      await refresh();
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

  /// iOS'ta App Store'daki güncel hakkı sorar: süresi dolan, iptal edilip
  /// biten ya da iade edilen abonelik artık listede olmaz ve premium kapanır.
  /// Sorgu sessizdir (şifre sormaz) ve çevrimdışı da çalışır. Açılışta ve
  /// uygulamaya her dönüşte çağrılır.
  Future<void> refresh() async {
    if (!enabled || kIsWeb || !available) return;
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final owned = await SK2Transaction.currentEntitlements();
      final active = entitled(owned.map((t) => t.productId));
      final grant = _lastGrant;
      final justBought =
          grant != null &&
          DateTime.now().difference(grant) < const Duration(minutes: 2);
      if (active || !justBought) AppState.I.setPremium(active);
    } catch (_) {
      // Mağazaya ulaşılamadı: mevcut durum korunur.
    }
  }

  /// Kullanıcının şu an hak sahibi olduğu ürünler arasında bir Minik Kaşif
  /// aboneliği var mı?
  static bool entitled(Iterable<String> productIds) =>
      productIds.any(_ids.contains);

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
          _lastGrant = DateTime.now();
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

import 'package:flutter_test/flutter_test.dart';
import 'package:minik_kasif/services/purchases.dart';

void main() {
  test('Google Play deneme süresi (ISO 8601) güne çevrilir', () {
    expect(Purchases.isoPeriodDays('P3D'), 3);
    expect(Purchases.isoPeriodDays('P1W'), 7);
    expect(Purchases.isoPeriodDays('P2W'), 14);
    expect(Purchases.isoPeriodDays('P1M'), 30);
    expect(Purchases.isoPeriodDays('P1Y'), 365);
    expect(Purchases.isoPeriodDays('bozuk'), 0);
  });
}

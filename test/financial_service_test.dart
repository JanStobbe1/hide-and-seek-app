import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/services/financial_service.dart';

void main() {
  group('FinancialService', () {
    test('calculates gross pool, platform fee and displayed prize pool', () {
      final result = const FinancialService().calculate(players: 10, entryFee: 10);
      expect(result.grossPool, 100);
      expect(result.platformFee, 10);
      expect(result.prizePool, 90);
    });
    test('supports a configurable platform fee', () {
      final result = const FinancialService(
        platformFeeRate: .2,
      ).calculate(players: 5, entryFee: 4);
      expect(result.platformFee, 4);
      expect(result.prizePool, 16);
    });
    test('rejects negative inputs', () {
      expect(
        () => const FinancialService().calculate(players: -1, entryFee: 1),
        throwsArgumentError,
      );
    });
  });
}

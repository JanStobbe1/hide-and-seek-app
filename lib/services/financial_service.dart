import '../config/app_config.dart';
import '../domain/models.dart';

class FinancialService {
  const FinancialService({this.platformFeeRate = AppConfig.platformFeeRate}) : assert(platformFeeRate >= 0 && platformFeeRate <= 1);
  final double platformFeeRate;

  FinancialSummary calculate({required int players, required double entryFee}) {
    if (players < 0 || entryFee < 0) throw ArgumentError('Players and entry fee cannot be negative.');
    final gross = players * entryFee;
    final fee = gross * platformFeeRate;
    return FinancialSummary(grossPool: gross, platformFee: fee, prizePool: gross - fee);
  }
}

abstract final class AppConfig {
  static const appName = 'Verstobbertje';
  static const demoMode = true;
  static const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');

  static const joinGrace = Duration(minutes: 5);
  static const shrinkDuration = Duration(minutes: 5);
  static const shrinkAreaFactor = .95;
  // CFG-04: circular activation area centered on the question marker.
  static const questionRangeMeters = 20.0;
  static const questionReturnGrace = Duration(seconds: 5);
  static const hintDuration = Duration(seconds: 60);
  static const hintShrinkStart = Duration(seconds: 30);
  static const hintCooldown = Duration(minutes: 10);
  static const hintBaseCost = 5;
  static const hintResultPenalty = 1;
  static const hintQuarterMultiplier = 1.2;
  static const rankStartValueIncrement = 5.0;
  static const finderRewardRate = .8;
  static const otherSeekerRewardRate = .2;
  static const survivingHiderBonus = 10.0;
  static const returnSafetyFactor = 1.5;
  static const minReturnTime = Duration(minutes: 2);
  static const maxReturnTimeFraction = .1;
  static const outsideConfirmationSamples = 2;

  static const findDistanceRadiusRatio = .01;
  static const minFindDistanceMeters = 10.0;
  static const minZoneRadiusForHintsAndQuestionsMeters = 100.0;
}

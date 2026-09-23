import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/config/app_theme.dart';
import 'package:verstobbertje/domain/profile_models.dart';

void main() {
  test('theme choices use muted names', () {
    expect(ThemePreference.values, hasLength(6));
    expect(AppTheme.labelFor(ThemePreference.forest), 'Mat saliegroen');
    expect(AppTheme.labelFor(ThemePreference.ocean), 'Leisteenblauw');
    expect(AppTheme.labelFor(ThemePreference.violet), 'Fluweelpaars');
    expect(AppTheme.labelFor(ThemePreference.graphite), 'Zacht grafiet');
    expect(AppTheme.labelFor(ThemePreference.rosewood), 'Mat rozenhout');
  });
}

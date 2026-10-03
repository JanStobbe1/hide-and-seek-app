import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/game_setup.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/presentation/create_game_screen.dart';
import 'package:verstobbertje/presentation/play_area_editor.dart';

void main() {
  testWidgets('empty play area opens on mainland Belgium Netherlands Germany', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const area = SearchArea(
      country: 'Nederland',
      province: 'Alle',
      city: 'Alle',
      neighbourhood: 'Alle',
      specificArea: '',
    );
    await tester.pumpWidget(
      const MaterialApp(home: PlayAreaEditor(area: area)),
    );
    await tester.pump();
    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera;
    expect(camera.visibleBounds.contains(const LatLng(47.2, 2.5)), isTrue);
    expect(camera.visibleBounds.contains(const LatLng(55.1, 15.1)), isTrue);
    expect(camera.center.longitude, inInclusiveRange(2.5, 15.1));
    expect(find.byTooltip('Vraag het de Stobbedetective'), findsOneWidget);
    await tester.tap(find.byTooltip('Vraag het de Stobbedetective'));
    await tester.pumpAndSettle();
    expect(find.text('Je speelgrens kiezen'), findsOneWidget);
    await tester.tap(find.text('Begrepen, detective!'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PolygonLayer>(find.byType(PolygonLayer)).polygons,
      isEmpty,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'question choice preserves draft when switching between three and five',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CreateGameScreen(state: AppState())),
      );
      final field = find.byKey(const ValueKey('custom-question-0'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Ben je op de fiets?');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await Scrollable.ensureVisible(
        tester.element(find.text('5 vragen')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 vragen'));
      await tester.pump();
      expect(find.byKey(const ValueKey('custom-question-4')), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(find.text('3 vragen')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 vragen'));
      await tester.pump();
      expect(find.byKey(const ValueKey('custom-question-4')), findsNothing);
      expect(
        tester.widget<TextField>(field).controller!.text,
        'Ben je op de fiets?',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'mobile editor can resize, draw, undo and cancel without losing saved border',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const area = SearchArea(
        country: 'Nederland',
        province: 'Flevoland',
        city: 'Dronten',
        neighbourhood: 'Alle',
        specificArea: '',
        boundary: [
          AreaPoint(52.50, 5.70),
          AreaPoint(52.50, 5.72),
          AreaPoint(52.52, 5.72),
          AreaPoint(52.52, 5.70),
        ],
      );
      await tester.pumpWidget(
        const MaterialApp(home: PlayAreaEditor(area: area)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final boundaryLayer = tester.widget<PolygonLayer>(
        find.byType(PolygonLayer),
      );
      expect(boundaryLayer.polygons.single.color?.a, lessThan(0.1));
      final before = tester
          .widget<PolygonLayer>(find.byType(PolygonLayer))
          .polygons
          .single
          .points
          .first
          .latitude;
      await tester.tap(find.text('Gebied kleiner'));
      await tester.pump();
      final smaller = tester
          .widget<PolygonLayer>(find.byType(PolygonLayer))
          .polygons
          .single
          .points
          .first
          .latitude;
      expect(smaller, greaterThan(before));
      await tester.tap(find.text('Teken grens'));
      await tester.pump();
      final rect = tester.getRect(find.byType(FlutterMap));
      await tester.dragFrom(rect.center, const Offset(40, 30));
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );

      for (final offset in [
        const Offset(90, 80),
        const Offset(230, 80),
        const Offset(170, 160),
      ]) {
        final gesture = await tester.startGesture(rect.topLeft + offset);
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
      }
      expect(
        tester
            .widget<PolygonLayer>(find.byType(PolygonLayer))
            .polygons
            .single
            .points
            .length,
        3,
      );
      await tester.tap(find.text('Punt terug'));
      await tester.pump();
      expect(
        tester.widget<PolygonLayer>(find.byType(PolygonLayer)).polygons,
        isEmpty,
      );
      await tester.tap(find.text('Tekenen annuleren'));
      await tester.pump();
      expect(
        tester
            .widget<PolygonLayer>(find.byType(PolygonLayer))
            .polygons
            .single
            .points
            .first
            .latitude,
        smaller,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

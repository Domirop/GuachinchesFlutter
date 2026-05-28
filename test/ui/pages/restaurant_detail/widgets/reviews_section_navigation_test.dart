import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_reviews_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/reviews_section.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

Restaurant _fakeRestaurantWith4Reviews() {
  final reviews = [
    Review(id: '1', rating: '5', review: 'Muy bueno', usuario: User(nombre: 'Ana')),
    Review(id: '2', rating: '4', review: 'Bueno', usuario: User(nombre: 'Ben')),
    Review(id: '3', rating: '3', review: 'Regular', usuario: User(nombre: 'Carlos')),
    Review(id: '4', rating: '2', review: 'Malo', usuario: User(nombre: 'Diana')),
  ];
  return Restaurant(
    id: 'r2',
    nombre: 'Restaurante Navegación',
    valoraciones: reviews,
    avgRating: 3.5,
  );
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _secureStorageChannel,
      (MethodCall methodCall) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  testWidgets(
      'tap restaurant-reviews-see-all-button pushes RestaurantReviewsScreen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: appDarkTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReviewsSection(
            restaurant: _fakeRestaurantWith4Reviews(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final ctaButton = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.identifier == 'restaurant-reviews-see-all-button',
    );
    expect(ctaButton, findsOneWidget);

    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    expect(find.byType(RestaurantReviewsScreen), findsOneWidget);
  });
}

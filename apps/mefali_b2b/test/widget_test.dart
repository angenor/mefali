import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_b2b/app.dart';
import 'package:mefali_b2b/features/auth/phone_screen.dart';
import 'package:mefali_b2b/features/catalogue/product_form_screen.dart';
import 'package:mefali_b2b/features/catalogue/product_list_screen.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

void main() {
  testWidgets('MefaliB2bApp renders login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2bApp()));
    await tester.pumpAndSettle();

    // Should show the login screen by default
    expect(find.text('Connexion Marchand'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('B2bPhoneScreen has phone field and submit button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const B2bPhoneScreen()),
      ),
    );

    expect(find.text('Numero de telephone'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('B2bPhoneScreen validates empty phone', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const B2bPhoneScreen()),
      ),
    );

    // Tap submit without entering phone
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Veuillez entrer votre numero'), findsOneWidget);
  });

  testWidgets('ProductListScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(<Product>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aucun produit'), findsOneWidget);
    expect(find.text('Ajouter un produit'), findsOneWidget);
  });

  testWidgets('ProductListScreen shows product grid', (tester) async {
    final products = [
      Product(
        id: '00000000-0000-0000-0000-000000000001',
        merchantId: '00000000-0000-0000-0000-000000000002',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 50,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '00000000-0000-0000-0000-000000000003',
        merchantId: '00000000-0000-0000-0000-000000000002',
        name: 'Alloco',
        price: 300,
        stock: 30,
        initialStock: 30,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Garba'), findsOneWidget);
    expect(find.text('500 FCFA'), findsOneWidget);
    expect(find.text('Alloco'), findsOneWidget);
    expect(find.text('300 FCFA'), findsOneWidget);
  });

  testWidgets('ProductFormScreen create mode has correct fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const ProductFormScreen()),
      ),
    );

    expect(find.text('Ajouter un produit'), findsOneWidget);
    expect(find.text('Nom du produit'), findsOneWidget);
    expect(find.text('Prix (FCFA)'), findsOneWidget);
    expect(find.text('Description (optionnel)'), findsOneWidget);
    expect(find.text('Stock (optionnel)'), findsOneWidget);
    expect(find.text('Ajouter'), findsOneWidget);
  });

  testWidgets('ProductFormScreen edit mode shows product data', (tester) async {
    final product = Product(
      id: '00000000-0000-0000-0000-000000000001',
      merchantId: '00000000-0000-0000-0000-000000000002',
      name: 'Garba',
      price: 500,
      stock: 50,
      initialStock: 50,
      description: 'Attieke + thon',
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: ProductFormScreen(product: product)),
      ),
    );

    expect(find.text('Modifier le produit'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    // Delete icon in app bar
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('ProductFormScreen validates empty name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const ProductFormScreen()),
      ),
    );

    // Find and tap the FilledButton (submit)
    final submitButton = find.widgetWithText(FilledButton, 'Ajouter');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Le nom est requis'), findsOneWidget);
    expect(find.text('Le prix est requis'), findsOneWidget);
  });
}

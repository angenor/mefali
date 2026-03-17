import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_admin/app.dart';
import 'package:mefali_admin/features/kyc/pending_drivers_screen.dart';
import 'package:mefali_admin/features/kyc/kyc_capture_screen.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_admin/features/onboarding/onboarding_wizard_screen.dart';
import 'package:mefali_core/mefali_core.dart';

void main() {
  testWidgets('MefaliAdminApp renders login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliAdminApp()));
    await tester.pumpAndSettle();
    // Should show auth/phone screen (not authenticated)
    expect(find.text('Connexion Agent'), findsOneWidget);
    expect(find.text('+225 '), findsOneWidget);
  });

  testWidgets('OnboardingWizardScreen shows progress bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingWizardScreen(),
        ),
      ),
    );
    await tester.pump();
    // Progress bar labels
    expect(find.text('Infos'), findsOneWidget);
    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Horaires'), findsOneWidget);
    expect(find.text('Paiement'), findsOneWidget);
    expect(find.text('Validation'), findsOneWidget);
  });

  testWidgets('OnboardingWizardScreen shows step 1 content', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingWizardScreen(),
        ),
      ),
    );
    await tester.pump();
    // Should show step 1 title and form fields
    expect(find.text('Etape 1/5 — Infos commerce'), findsOneWidget);
    expect(find.text('Telephone du marchand'), findsOneWidget);
    expect(find.text('Nom du commerce'), findsOneWidget);
    expect(find.text('Adresse'), findsOneWidget);
    expect(find.text('Categorie'), findsOneWidget);
    expect(find.text('Envoyer OTP'), findsOneWidget);
  });

  testWidgets('PendingDriversScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingDriversProvider.overrideWith((_) async => <User>[]),
        ],
        child: const MaterialApp(
          home: PendingDriversScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('KYC Livreurs'), findsOneWidget);
    expect(find.text('Aucun livreur en attente de KYC'), findsOneWidget);
  });

  testWidgets('PendingDriversScreen shows driver list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingDriversProvider.overrideWith((_) async => [
                User.fromJson({
                  'id': 'u1',
                  'phone': '+2250700000001',
                  'name': 'Koffi',
                  'role': 'driver',
                  'status': 'pending_kyc',
                  'city_id': null,
                  'fcm_token': null,
                  'created_at': '2026-03-17T10:00:00.000Z',
                  'updated_at': '2026-03-17T10:00:00.000Z',
                }),
              ]),
        ],
        child: const MaterialApp(
          home: PendingDriversScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Koffi'), findsOneWidget);
    expect(find.text('+2250700000001'), findsOneWidget);
  });

  test('KycDocument model serde roundtrip', () {
    final json = {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'user_id': '660e8400-e29b-41d4-a716-446655440001',
      'document_type': 'cni',
      'encrypted_path': 'kyc/user123/cni_abc.jpeg',
      'verified_by': null,
      'status': 'pending',
      'created_at': '2026-03-17T10:00:00.000Z',
      'updated_at': '2026-03-17T10:00:00.000Z',
    };

    final doc = KycDocument.fromJson(json);
    expect(doc.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(doc.documentType, KycDocumentType.cni);
    expect(doc.status, KycStatus.pending);
    expect(doc.verifiedBy, isNull);

    final back = doc.toJson();
    expect(back['document_type'], 'cni');
    expect(back['encrypted_path'], 'kyc/user123/cni_abc.jpeg');
  });

  test('KycDocumentType enum values', () {
    expect(KycDocumentType.cni.label, 'CNI');
    expect(KycDocumentType.permis.label, 'Permis');
    expect(KycDocumentType.cni.name, 'cni');
    expect(KycDocumentType.permis.name, 'permis');
  });

  test('KycStatus enum values', () {
    expect(KycStatus.pending.label, 'En attente');
    expect(KycStatus.verified.label, 'Verifie');
    expect(KycStatus.rejected.label, 'Rejete');
  });

  testWidgets('KycCaptureScreen shows driver info and disabled button when no documents', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kycSummaryProvider('user1').overrideWith(
            (_) async => KycSummaryResponse(
              user: User.fromJson({
                'id': 'user1',
                'phone': '+2250700000001',
                'name': 'Koffi',
                'role': 'driver',
                'status': 'pending_kyc',
                'city_id': null,
                'fcm_token': null,
                'created_at': '2026-03-17T10:00:00.000Z',
                'updated_at': '2026-03-17T10:00:00.000Z',
              }),
              documents: [],
              sponsor: User.fromJson({
                'id': 'sponsor1',
                'phone': '+2250700000099',
                'name': 'Mamadou',
                'role': 'driver',
                'status': 'active',
                'city_id': null,
                'fcm_token': null,
                'created_at': '2026-03-17T10:00:00.000Z',
                'updated_at': '2026-03-17T10:00:00.000Z',
              }),
            ),
          ),
        ],
        child: const MaterialApp(
          home: KycCaptureScreen(userId: 'user1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Driver info displayed
    expect(find.text('Koffi'), findsOneWidget);
    expect(find.text('Tel: +2250700000001'), findsOneWidget);
    expect(find.text('Parrain: Mamadou'), findsOneWidget);

    // Activate button is disabled (no documents — AC6)
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('KycCaptureScreen shows enabled button when documents exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kycSummaryProvider('user1').overrideWith(
            (_) async => KycSummaryResponse(
              user: User.fromJson({
                'id': 'user1',
                'phone': '+2250700000001',
                'name': 'Koffi',
                'role': 'driver',
                'status': 'pending_kyc',
                'city_id': null,
                'fcm_token': null,
                'created_at': '2026-03-17T10:00:00.000Z',
                'updated_at': '2026-03-17T10:00:00.000Z',
              }),
              documents: [
                KycDocument.fromJson({
                  'id': 'doc1',
                  'user_id': 'user1',
                  'document_type': 'cni',
                  'encrypted_path': 'kyc/user1/cni_abc.jpeg',
                  'verified_by': null,
                  'status': 'pending',
                  'created_at': '2026-03-17T10:00:00.000Z',
                  'updated_at': '2026-03-17T10:00:00.000Z',
                }),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: KycCaptureScreen(userId: 'user1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // CNI slot shows uploaded
    expect(find.text('Uploade'), findsOneWidget);
    expect(find.text('Non capture'), findsOneWidget);

    // Activate button is enabled (has document)
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Admin app phone screen validates input', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliAdminApp()));
    await tester.pumpAndSettle();

    // Try to submit empty form
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    // Should show validation error
    expect(find.text('Veuillez entrer votre numero'), findsOneWidget);
  });
}

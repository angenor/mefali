import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_admin/app.dart';
import 'package:mefali_admin/features/kyc/pending_drivers_screen.dart';
import 'package:mefali_admin/features/kyc/kyc_capture_screen.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_admin/features/dashboard/admin_dashboard_screen.dart';
import 'package:mefali_admin/features/dashboard/agent_performance_screen.dart';
import 'package:mefali_admin/features/accounts/account_list_screen.dart';
import 'package:mefali_admin/features/accounts/account_detail_screen.dart';
import 'package:mefali_admin/features/cities/city_list_screen.dart';
import 'package:mefali_admin/features/cities/city_form_screen.dart';
import 'package:mefali_admin/features/disputes/dispute_list_screen.dart';
import 'package:mefali_admin/features/disputes/dispute_detail_screen.dart';
import 'package:mefali_admin/features/merchants/merchant_list_screen.dart';
import 'package:mefali_admin/features/merchants/merchant_detail_screen.dart';
import 'package:mefali_admin/features/drivers/driver_list_screen.dart';
import 'package:mefali_admin/features/drivers/driver_detail_screen.dart';
import 'package:mefali_admin/features/onboarding/onboarding_wizard_screen.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

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

  // --- Agent Performance Dashboard tests ---

  testWidgets('AgentPerformanceScreen shows stats with data', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentPerformanceProvider.overrideWith(
            (_) async => AgentPerformanceState(
              stats: const AgentPerformanceStats(
                merchantsOnboarded: PeriodCount(today: 3, thisWeek: 11, total: 47),
                kycValidated: PeriodCount(today: 1, thisWeek: 4, total: 19),
                merchantsWithFirstOrder: FirstOrderCount(thisWeek: 6, total: 38),
                recentMerchants: [
                  RecentMerchant(
                    id: 'rm1',
                    name: 'Chez Dramane',
                    createdAt: '2026-03-19T09:00:00Z',
                    hasFirstOrder: true,
                  ),
                  RecentMerchant(
                    id: 'rm2',
                    name: 'Maquis Central',
                    createdAt: '2026-03-18T14:00:00Z',
                    hasFirstOrder: false,
                  ),
                ],
              ),
              lastSync: DateTime.now(),
            ),
          ),
        ],
        child: const MaterialApp(home: AgentPerformanceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Stats cards present
    expect(find.text('Marchands onboardes'), findsOneWidget);
    expect(find.text('KYC valides'), findsOneWidget);
    expect(find.text('Premieres commandes'), findsOneWidget);

    // Unique values from stats
    expect(find.text('47'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);

    // Recent merchants
    expect(find.text('Chez Dramane'), findsOneWidget);
    expect(find.text('Maquis Central'), findsOneWidget);
    expect(find.text('Commande recue'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
  });

  testWidgets('AgentPerformanceScreen shows skeleton loading', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Use a Completer that never completes to keep loading state
    final completer = Completer<AgentPerformanceState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentPerformanceProvider.overrideWith((_) => completer.future),
        ],
        child: const MaterialApp(home: AgentPerformanceScreen()),
      ),
    );
    await tester.pump();

    // Should NOT find a CircularProgressIndicator (skeleton instead)
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // AppBar still visible
    expect(find.text('Mes performances'), findsOneWidget);
  });

  testWidgets('AgentPerformanceScreen shows error with retry', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentPerformanceProvider.overrideWith(
            (_) => Future<AgentPerformanceState>.error(
              Exception('Network error'),
            ),
          ),
        ],
        child: const MaterialApp(home: AgentPerformanceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Erreur'), findsOneWidget);
    expect(find.text('Reessayer'), findsOneWidget);
  });

  testWidgets('AgentPerformanceScreen shows cache banner when offline', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lastSync = DateTime.now().subtract(const Duration(minutes: 15));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentPerformanceProvider.overrideWith(
            (_) async => AgentPerformanceState(
              stats: const AgentPerformanceStats(
                merchantsOnboarded: PeriodCount(today: 0, thisWeek: 5, total: 30),
                kycValidated: PeriodCount(today: 0, thisWeek: 2, total: 13),
                merchantsWithFirstOrder: FirstOrderCount(thisWeek: 1, total: 22),
                recentMerchants: [],
              ),
              lastSync: lastSync,
              isCached: true,
            ),
          ),
        ],
        child: const MaterialApp(home: AgentPerformanceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Cache banner visible
    expect(find.textContaining('hors ligne'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);

    // Data still shows
    expect(find.text('Marchands onboardes'), findsOneWidget);
  });

  // --- Admin Dashboard tests ---

  testWidgets('AdminDashboardScreen shows KPI cards with data', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardProvider.overrideWith(
            (_) async => AdminDashboardState(
              stats: const DashboardStats(
                ordersToday: 42,
                activeMerchants: 87,
                driversOnline: 15,
                pendingDisputes: 3,
              ),
              lastSync: DateTime.now(),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    // Use pump() instead of pumpAndSettle() — Timer.periodic never settles
    await tester.pump();
    await tester.pump();

    expect(find.text('42'), findsOneWidget);
    expect(find.text('87'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Commandes du jour'), findsOneWidget);
    expect(find.text('Marchands actifs'), findsOneWidget);
    expect(find.text('Livreurs en ligne'), findsOneWidget);
    expect(find.text('Litiges en attente'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen shows skeleton on loading', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completer = Completer<AdminDashboardState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardProvider.overrideWith((_) => completer.future),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pump();

    // Skeleton loading — no CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('AdminDashboardScreen shows cache banner when offline', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardProvider.overrideWith(
            (_) async => AdminDashboardState(
              stats: const DashboardStats(
                ordersToday: 10,
                activeMerchants: 20,
                driversOnline: 5,
                pendingDisputes: 1,
              ),
              lastSync: DateTime.now().subtract(const Duration(minutes: 10)),
              isCached: true,
            ),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    // Use pump() instead of pumpAndSettle() — Timer.periodic never settles
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Derniere mise a jour'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    // Data still shows
    expect(find.text('10'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
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

  // --- Dispute List Screen tests ---

  testWidgets('DisputeListScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDisputesProvider(const DisputeListParams())
              .overrideWith((_) async => (items: <AdminDisputeListItem>[], total: 0)),
        ],
        child: const MaterialApp(home: Scaffold(body: DisputeListScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun litige en attente'), findsOneWidget);
  });

  testWidgets('DisputeListScreen shows dispute cards', (tester) async {
    final items = [
      AdminDisputeListItem.fromJson({
        'id': 'd1',
        'order_id': 'o1',
        'reporter_id': 'u1',
        'dispute_type': 'quality',
        'status': 'open',
        'description': 'Nourriture froide',
        'created_at': '2026-03-21T12:00:00.000Z',
        'reporter_name': 'Kouadio',
        'reporter_phone': '+2250700000001',
        'merchant_name': 'Chez Adjoua',
        'order_total': 2500,
      }),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDisputesProvider(const DisputeListParams())
              .overrideWith((_) async => (items: items, total: 1)),
        ],
        child: const MaterialApp(home: Scaffold(body: DisputeListScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Probleme de qualite'), findsOneWidget);
    expect(find.text('Chez Adjoua'), findsOneWidget);
    expect(find.text('2500 FCFA'), findsOneWidget);
  });

  testWidgets('DisputeListScreen shows filter chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDisputesProvider(const DisputeListParams())
              .overrideWith((_) async => (items: <AdminDisputeListItem>[], total: 0)),
        ],
        child: const MaterialApp(home: Scaffold(body: DisputeListScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('Ouverts'), findsOneWidget);
    expect(find.text('En traitement'), findsOneWidget);
    expect(find.text('Resolus'), findsOneWidget);
  });

  testWidgets('DisputeListScreen filters disputes when chip tapped', (tester) async {
    final allItems = [
      AdminDisputeListItem.fromJson({
        'id': 'd1',
        'order_id': 'o1',
        'reporter_id': 'u1',
        'dispute_type': 'quality',
        'status': 'open',
        'description': 'Nourriture froide',
        'created_at': '2026-03-21T12:00:00.000Z',
        'reporter_name': 'Kouadio',
        'reporter_phone': '+2250700000001',
        'merchant_name': 'Chez Adjoua',
        'order_total': 2500,
      }),
    ];

    // Track which params the provider was called with
    DisputeListParams? lastParams;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDisputesProvider(const DisputeListParams())
              .overrideWith((_) async => (items: allItems, total: 1)),
          adminDisputesProvider(const DisputeListParams(status: 'open'))
              .overrideWith((_) async {
            lastParams = const DisputeListParams(status: 'open');
            return (items: allItems, total: 1);
          }),
          adminDisputesProvider(const DisputeListParams(status: 'resolved'))
              .overrideWith((_) async {
            lastParams = const DisputeListParams(status: 'resolved');
            return (items: <AdminDisputeListItem>[], total: 0);
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: DisputeListScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // Initially shows all items
    expect(find.text('Chez Adjoua'), findsOneWidget);

    // Tap "Resolus" filter
    await tester.tap(find.text('Resolus'));
    await tester.pumpAndSettle();

    // Should show empty state after filter
    expect(lastParams?.status, 'resolved');
  });

  // --- Dispute Detail Screen tests ---

  testWidgets('DisputeDetailScreen shows timeline and stats', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disputeDetailProvider('d1').overrideWith(
            (_) async => DisputeDetail.fromJson({
              'dispute': {
                'id': 'd1',
                'order_id': 'o1',
                'reporter_id': 'u1',
                'dispute_type': 'incomplete',
                'status': 'open',
                'description': 'Il manque le alloco',
                'resolution': null,
                'created_at': '2026-03-21T12:00:00.000Z',
                'updated_at': '2026-03-21T12:00:00.000Z',
              },
              'timeline': [
                {'label': 'Commande placee', 'timestamp': '2026-03-21T12:14:00.000Z'},
                {'label': 'Collectee par livreur', 'timestamp': '2026-03-21T12:28:00.000Z'},
                {'label': 'Livree au client', 'timestamp': '2026-03-21T12:41:00.000Z'},
                {'label': 'Litige signale', 'timestamp': '2026-03-21T12:45:00.000Z'},
              ],
              'merchant_stats': {
                'name': 'Chez Adjoua',
                'total_orders': 47,
                'total_disputes': 2,
              },
              'driver_stats': {
                'name': 'Kone',
                'total_orders': 83,
                'total_disputes': 0,
              },
            }),
          ),
        ],
        child: const MaterialApp(
          home: DisputeDetailScreen(disputeId: 'd1'),
        ),
      ),
    );
    // Use pump() instead of pumpAndSettle() — OrderTimeline has repeating animation
    await tester.pump();
    await tester.pump();

    // Header
    expect(find.text('Commande incomplete'), findsOneWidget);

    // Description
    expect(find.text('Il manque le alloco'), findsOneWidget);

    // Timeline events
    expect(find.text('Commande placee'), findsOneWidget);
    expect(find.text('Collectee par livreur'), findsOneWidget);
    expect(find.text('Livree au client'), findsOneWidget);
    expect(find.text('Litige signale'), findsOneWidget);

    // Stats
    expect(find.text('Chez Adjoua'), findsOneWidget);
    expect(find.text('47 commandes'), findsOneWidget);
    expect(find.text('2 litiges'), findsOneWidget);
    expect(find.text('Kone'), findsOneWidget);
    expect(find.text('83 livraisons'), findsOneWidget);

    // Resolve button
    expect(find.text('Resoudre ce litige'), findsOneWidget);
  });

  // --- DisputeResolutionSheet tests ---

  testWidgets('DisputeResolutionSheet shows action choices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisputeResolutionSheet(
            onSubmit: ({
              required ResolveAction action,
              required String resolution,
              int? creditAmount,
            }) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resoudre le litige'), findsOneWidget);
    expect(find.text('Crediter le client'), findsOneWidget);
    expect(find.text('Avertir'), findsOneWidget);
    expect(find.text('Classer sans suite'), findsOneWidget);
    expect(find.text('Notes de resolution'), findsOneWidget);
    expect(find.text('Confirmer la resolution'), findsOneWidget);
  });

  testWidgets('DisputeResolutionSheet shows credit field when credit selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisputeResolutionSheet(
            onSubmit: ({
              required ResolveAction action,
              required String resolution,
              int? creditAmount,
            }) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Montant field should NOT be visible initially (dismiss is default)
    expect(find.text('Montant (FCFA)'), findsNothing);

    // Select "Crediter le client"
    await tester.tap(find.text('Crediter le client'));
    await tester.pumpAndSettle();

    // Montant field should now be visible
    expect(find.text('Montant (FCFA)'), findsOneWidget);
  });

  testWidgets('DisputeResolutionSheet calls onSubmit with correct params', (tester) async {
    ResolveAction? submittedAction;
    String? submittedResolution;
    int? submittedCredit;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisputeResolutionSheet(
            onSubmit: ({
              required ResolveAction action,
              required String resolution,
              int? creditAmount,
            }) async {
              submittedAction = action;
              submittedResolution = resolution;
              submittedCredit = creditAmount;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select "Crediter le client"
    await tester.tap(find.text('Crediter le client'));
    await tester.pumpAndSettle();

    // Enter credit amount
    await tester.enterText(find.widgetWithText(TextField, 'Montant (FCFA)'), '1500');

    // Enter resolution notes
    await tester.enterText(find.widgetWithText(TextField, 'Notes de resolution'), 'Remboursement partiel accorde');

    // Submit
    await tester.tap(find.text('Confirmer la resolution'));
    await tester.pumpAndSettle();

    expect(submittedAction, ResolveAction.credit);
    expect(submittedResolution, 'Remboursement partiel accorde');
    expect(submittedCredit, 1500);
  });

  testWidgets('DisputeResolutionSheet does not submit with empty resolution', (tester) async {
    bool wasSubmitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisputeResolutionSheet(
            onSubmit: ({
              required ResolveAction action,
              required String resolution,
              int? creditAmount,
            }) async {
              wasSubmitted = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Try to submit without entering resolution text
    await tester.tap(find.text('Confirmer la resolution'));
    await tester.pumpAndSettle();

    // Should NOT have called onSubmit
    expect(wasSubmitted, false);
  });

  // --- OrderTimeline widget test ---

  testWidgets('OrderTimeline renders events correctly', (tester) async {
    final events = [
      const OrderTimelineEvent(
        label: 'Commande placee',
        timestamp: null,
      ),
      OrderTimelineEvent(
        label: 'Livree',
        timestamp: DateTime.parse('2026-03-21T14:30:00.000Z'),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderTimeline(events: events),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Timeline commande'), findsOneWidget);
    expect(find.text('Commande placee'), findsOneWidget);
    expect(find.text('Livree'), findsOneWidget);
    // Commande placee has no timestamp → first pending = "en cours" (access_time_filled)
    expect(find.byIcon(Icons.access_time_filled), findsOneWidget);
    // Livree has timestamp → completed (check_circle)
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('OrderTimeline shows in-progress state for first pending event', (tester) async {
    final events = [
      OrderTimelineEvent(
        label: 'Commande placee',
        timestamp: DateTime.parse('2026-03-21T12:00:00.000Z'),
      ),
      const OrderTimelineEvent(
        label: 'Collectee par livreur',
        timestamp: null,
      ),
      const OrderTimelineEvent(
        label: 'Livree au client',
        timestamp: null,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderTimeline(events: events),
        ),
      ),
    );
    await tester.pump();

    // Commande placee → completed
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    // Collectee par livreur → in progress (first pending)
    expect(find.byIcon(Icons.access_time_filled), findsOneWidget);
    expect(find.text('En cours...'), findsOneWidget);
    // Livree au client → future (grey)
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  // --- City Config tests ---

  testWidgets('CityListScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCitiesProvider.overrideWith((_) async => <CityConfig>[]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CityListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucune ville configuree'), findsOneWidget);
    expect(find.text('Ajoutez une ville pour commencer'), findsOneWidget);
    expect(find.byIcon(Icons.location_city), findsWidgets);
  });

  testWidgets('CityListScreen shows city cards with data', (tester) async {
    final cities = [
      CityConfig.fromJson({
        'id': 'c1',
        'city_name': 'Bouake',
        'delivery_multiplier': 1.5,
        'zones_geojson': {'type': 'FeatureCollection', 'features': [1, 2]},
        'is_active': true,
        'created_at': '2026-03-21T10:00:00.000Z',
        'updated_at': '2026-03-21T10:00:00.000Z',
      }),
      CityConfig.fromJson({
        'id': 'c2',
        'city_name': 'Abidjan',
        'delivery_multiplier': 2.0,
        'zones_geojson': null,
        'is_active': false,
        'created_at': '2026-03-21T10:00:00.000Z',
        'updated_at': '2026-03-21T10:00:00.000Z',
      }),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCitiesProvider.overrideWith((_) async => cities),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CityListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bouake'), findsOneWidget);
    expect(find.text('Abidjan'), findsOneWidget);
    expect(find.textContaining('x1.50'), findsOneWidget);
    expect(find.textContaining('x2.00'), findsOneWidget);
    expect(find.textContaining('2 zones'), findsOneWidget);
    expect(find.textContaining('Zones non definies'), findsOneWidget);
    // FAB
    expect(find.text('Ajouter une ville'), findsOneWidget);
  });

  // --- Account Management tests ---

  testWidgets('AccountListScreen shows user cards with data', (tester) async {
    final items = [
      AdminUserListItem.fromJson({
        'id': 'u1',
        'phone': '+2250700000001',
        'name': 'Koffi',
        'role': 'client',
        'status': 'active',
        'city_name': 'Bouake',
        'created_at': '2026-03-21T10:00:00.000Z',
      }),
      AdminUserListItem.fromJson({
        'id': 'u2',
        'phone': '+2250700000002',
        'name': 'Adjoua',
        'role': 'merchant',
        'status': 'suspended',
        'city_name': null,
        'created_at': '2026-03-20T08:00:00.000Z',
      }),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUsersProvider(const AdminUserListParams())
              .overrideWith((_) async => (items: items, total: 2)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AccountListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Koffi'), findsOneWidget);
    expect(find.text('Adjoua'), findsOneWidget);
    expect(find.text('Actif'), findsOneWidget);
    expect(find.text('Suspendu'), findsOneWidget);
  });

  testWidgets('AccountListScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUsersProvider(const AdminUserListParams())
              .overrideWith((_) async => (items: <AdminUserListItem>[], total: 0)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AccountListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun utilisateur trouve'), findsOneWidget);
  });

  testWidgets('AccountDetailScreen shows profile and stats', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserDetailProvider('u1').overrideWith(
            (_) async => AdminUserDetail.fromJson({
              'id': 'u1',
              'phone': '+2250700000001',
              'name': 'Koffi Kouadio',
              'role': 'client',
              'status': 'active',
              'city_name': 'Bouake',
              'referral_code': 'ABC123',
              'created_at': '2026-03-01T10:00:00.000Z',
              'updated_at': '2026-03-21T10:00:00.000Z',
              'total_orders': 12,
              'completion_rate': 91.7,
              'disputes_filed': 1,
              'avg_rating': 4.5,
            }),
          ),
        ],
        child: const MaterialApp(
          home: AccountDetailScreen(userId: 'u1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Koffi Kouadio'), findsOneWidget);
    expect(find.text('+2250700000001'), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('Bouake'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Suspendre'), findsOneWidget);
    expect(find.text('Desactiver'), findsOneWidget);
  });

  testWidgets('CityFormScreen validates empty name', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CityFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ajouter une ville'), findsOneWidget);
    expect(find.text('Nom de la ville'), findsOneWidget);
    expect(find.text('Multiplicateur de livraison'), findsOneWidget);

    // Clear the name field and submit
    final nameField = find.widgetWithText(TextFormField, 'Nom de la ville');
    await tester.enterText(nameField, '');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom de la ville est requis'), findsOneWidget);
  });

  // ── Merchant List & Detail Tests ──────────────────────────────────

  testWidgets('MerchantListScreen shows loading then empty state', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminMerchantsProvider(const MerchantListParams())
              .overrideWith((_) async => (items: <AdminMerchantListItem>[], total: 0)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MerchantListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun marchand'), findsOneWidget);
    expect(find.text('Rechercher un marchand...'), findsOneWidget);
  });

  testWidgets('MerchantListScreen shows data rows', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testMerchant = AdminMerchantListItem(
      id: 'abc-123',
      name: 'Chez Amina',
      status: VendorStatus.open,
      cityName: 'Bouake',
      category: 'restaurant',
      ordersCount: 47,
      avgRating: 4.2,
      disputesCount: 2,
      createdAt: DateTime(2026, 1, 15),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminMerchantsProvider(const MerchantListParams())
              .overrideWith((_) async => (items: [testMerchant], total: 1)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MerchantListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chez Amina'), findsOneWidget);
    expect(find.text('Bouake'), findsOneWidget);
    expect(find.text('47'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
  });

  testWidgets('MerchantListScreen filter chips present', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminMerchantsProvider(const MerchantListParams())
              .overrideWith((_) async => (items: <AdminMerchantListItem>[], total: 0)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MerchantListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('Ouvert'), findsOneWidget);
    expect(find.text('Ferme'), findsOneWidget);
  });

  testWidgets('MerchantDetailScreen shows stats and profile', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testHistory = MerchantHistory(
      merchant: MerchantProfileInfo(
        id: 'abc-123',
        name: 'Chez Amina',
        address: 'Rue du Commerce',
        status: VendorStatus.open,
        category: 'restaurant',
        kycStatus: 'verified',
        createdAt: DateTime(2026, 1, 15),
      ),
      stats: const MerchantHistoryStats(
        totalOrders: 47,
        completedOrders: 44,
        completionRate: 93.6,
        avgRating: 4.2,
        totalDisputes: 2,
        resolvedDisputes: 2,
      ),
      recentOrders: PaginatedRecentOrders(
        items: [
          MerchantRecentOrder(
            id: 'order-1',
            status: 'delivered',
            total: 3500,
            customerName: 'Jean',
            createdAt: DateTime(2026, 3, 20, 12, 0),
          ),
        ],
        page: 1,
        perPage: 10,
        total: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantHistoryProvider(const MerchantHistoryParams(merchantId: 'abc-123'))
              .overrideWith((_) async => testHistory),
        ],
        child: const MaterialApp(
          home: MerchantDetailScreen(merchantId: 'abc-123'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chez Amina'), findsOneWidget);
    expect(find.text('Adresse: Rue du Commerce'), findsOneWidget);
    expect(find.text('47'), findsOneWidget);
    expect(find.text('93.6%'), findsOneWidget);
    expect(find.text('4.2'), findsAtLeast(1));
    expect(find.text('3500 FCFA'), findsOneWidget);
  });

  // ── Driver List & Detail Tests ──────────────────────────────────

  testWidgets('DriverListScreen shows loading then empty state', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDriversProvider(const DriverListParams())
              .overrideWith((_) async => (items: <AdminDriverListItem>[], total: 0)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DriverListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun livreur'), findsOneWidget);
    expect(find.text('Rechercher un livreur...'), findsOneWidget);
  });

  testWidgets('DriverListScreen shows data rows', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testDriver = AdminDriverListItem(
      id: 'drv-456',
      name: 'Moussa Traore',
      status: UserStatus.active,
      cityName: 'Bouake',
      deliveriesCount: 83,
      avgRating: 4.7,
      disputesCount: 0,
      available: true,
      createdAt: DateTime(2026, 2, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDriversProvider(const DriverListParams())
              .overrideWith((_) async => (items: [testDriver], total: 1)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DriverListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Moussa Traore'), findsOneWidget);
    expect(find.text('Bouake'), findsOneWidget);
    expect(find.text('83'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
  });

  testWidgets('DriverListScreen filter chips present', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDriversProvider(const DriverListParams())
              .overrideWith((_) async => (items: <AdminDriverListItem>[], total: 0)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DriverListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('Actif'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });

  testWidgets('DriverDetailScreen shows stats and profile', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testHistory = DriverHistory(
      driver: DriverProfileInfo(
        id: 'drv-456',
        name: 'Moussa Traore',
        phone: '+225070000001',
        status: UserStatus.active,
        kycStatus: 'verified',
        sponsorName: 'Kone Ibrahim',
        available: true,
        createdAt: DateTime(2026, 2, 1),
      ),
      stats: const DriverHistoryStats(
        totalDeliveries: 83,
        completedDeliveries: 80,
        completionRate: 96.4,
        avgRating: 4.7,
        totalDisputes: 0,
        resolvedDisputes: 0,
      ),
      recentDeliveries: PaginatedRecentDeliveries(
        items: [
          DriverRecentDelivery(
            id: 'del-1',
            orderId: 'ord-1',
            status: 'delivered',
            merchantName: 'Chez Amina',
            deliveredAt: DateTime(2026, 3, 20, 12, 45),
          ),
        ],
        page: 1,
        perPage: 10,
        total: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverHistoryProvider(const DriverHistoryParams(driverId: 'drv-456'))
              .overrideWith((_) async => testHistory),
        ],
        child: const MaterialApp(
          home: DriverDetailScreen(driverId: 'drv-456'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Moussa Traore'), findsOneWidget);
    expect(find.text('Telephone: +225070000001'), findsOneWidget);
    expect(find.text('Sponsor: Kone Ibrahim'), findsOneWidget);
    expect(find.text('83'), findsOneWidget);
    expect(find.text('96.4%'), findsOneWidget);
    expect(find.text('Chez Amina'), findsOneWidget);
  });
}

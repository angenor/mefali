// ignore_for_file: unused_import
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';

void main() {
  group('mefali_core', () {
    test('package is importable', () {
      // Import above validates package resolves correctly at compile time.
      // Real model tests will be added in subsequent stories.
      expect(true, isTrue);
    });
  });

  group('DeliveryMission', () {
    test('fromJson creates mission with all fields', () {
      final json = {
        'delivery_id': 'abc-123',
        'order_id': 'order-456',
        'merchant_name': 'Maman Adjoua',
        'merchant_address': 'Marche central',
        'delivery_address': 'Quartier Commerce',
        'delivery_lat': 7.69,
        'delivery_lng': -5.03,
        'estimated_distance_m': 800,
        'delivery_fee': 35000,
        'items_summary': 'Garba x1',
        'payment_type': 'cod',
        'order_total': 300000,
        'created_at': '2026-03-20T10:00:00Z',
      };
      final mission = DeliveryMission.fromJson(json);
      expect(mission.merchantName, 'Maman Adjoua');
      expect(mission.paymentType, 'cod');
      expect(mission.orderTotal, 300000);
      expect(mission.deliveryFee, 35000);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'delivery_id': 'abc',
        'order_id': 'order',
        'merchant_name': 'Test',
        'delivery_fee': 0,
        'items_summary': '',
        'created_at': '',
      };
      final mission = DeliveryMission.fromJson(json);
      expect(mission.paymentType, isNull);
      expect(mission.orderTotal, isNull);
      expect(mission.merchantAddress, isNull);
    });

    test('toJson includes new fields', () {
      const mission = DeliveryMission(
        deliveryId: 'abc',
        orderId: 'order',
        merchantName: 'Test',
        deliveryFee: 100,
        itemsSummary: 'test',
        paymentType: 'mobile_money',
        orderTotal: 500000,
        createdAt: '2026-01-01',
      );
      final json = mission.toJson();
      expect(json['payment_type'], 'mobile_money');
      expect(json['order_total'], 500000);
    });

    test('fromDeepLink decodes Base64 encoded mission', () {
      final missionJson = {
        'delivery_id': 'dl-1',
        'order_id': 'od-2',
        'merchant_name': 'Maman Adjoua',
        'merchant_address': 'Marche central',
        'delivery_address': 'Quartier Belleville',
        'delivery_lat': 7.69,
        'delivery_lng': -5.03,
        'estimated_distance_m': 800,
        'delivery_fee': 35000,
        'items_summary': 'Garba x1, Alloco x1',
        'payment_type': 'cod',
        'order_total': 300000,
        'created_at': '2026-03-20T10:00:00Z',
      };
      final jsonStr = jsonEncode(missionJson);
      final base64Data = base64Encode(utf8.encode(jsonStr));

      final mission = DeliveryMission.fromDeepLink(base64Data);
      expect(mission.merchantName, 'Maman Adjoua');
      expect(mission.deliveryAddress, 'Quartier Belleville');
      expect(mission.paymentType, 'cod');
      expect(mission.orderTotal, 300000);
      expect(mission.deliveryFee, 35000);
      expect(mission.itemsSummary, 'Garba x1, Alloco x1');
    });

    test('fromDeepLink handles numeric strings', () {
      final missionJson = {
        'delivery_id': 'dl-1',
        'order_id': 'od-2',
        'merchant_name': 'Test',
        'delivery_fee': '35000',
        'items_summary': 'test',
        'order_total': '300000',
        'created_at': '',
      };
      final jsonStr = jsonEncode(missionJson);
      final base64Data = base64Encode(utf8.encode(jsonStr));

      final mission = DeliveryMission.fromDeepLink(base64Data);
      expect(mission.deliveryFee, 35000);
      expect(mission.orderTotal, 300000);
    });
  });

  group('DeliveryLocationUpdate', () {
    test('fromJson creates update with all fields', () {
      final json = {
        'lat': 7.6900,
        'lng': -5.0300,
        'eta_seconds': 120,
        'updated_at': '2026-03-20T10:00:00Z',
        'driver_name': 'Kone',
        'driver_phone': '+2250700000000',
        'status': 'picked_up',
      };
      final update = DeliveryLocationUpdate.fromJson(json);
      expect(update.lat, 7.69);
      expect(update.lng, -5.03);
      expect(update.etaSeconds, 120);
      expect(update.driverName, 'Kone');
      expect(update.driverPhone, '+2250700000000');
      expect(update.status, 'picked_up');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'lat': 7.69,
        'lng': -5.03,
        'eta_seconds': 60,
        'updated_at': '2026-03-20T10:00:00Z',
      };
      final update = DeliveryLocationUpdate.fromJson(json);
      expect(update.driverName, isNull);
      expect(update.driverPhone, isNull);
      expect(update.status, isNull);
    });

    test('fromJson handles null eta_seconds', () {
      final json = {
        'lat': 7.69,
        'lng': -5.03,
        'updated_at': '',
      };
      final update = DeliveryLocationUpdate.fromJson(json);
      expect(update.etaSeconds, 0);
    });

    test('toJson roundtrips correctly', () {
      const update = DeliveryLocationUpdate(
        lat: 7.69,
        lng: -5.03,
        etaSeconds: 300,
        updatedAt: '2026-03-20T10:00:00Z',
        driverName: 'Kone',
      );
      final json = update.toJson();
      expect(json['lat'], 7.69);
      expect(json['lng'], -5.03);
      expect(json['eta_seconds'], 300);
      expect(json['driver_name'], 'Kone');
      expect(json.containsKey('driver_phone'), isFalse);
      expect(json['is_fallback'], isFalse);
    });
  });
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/ligne_exposition.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'exposition_cash.g.dart';

/// Ce que l'exploitation voit du cash en circulation (FR-075).
///
/// Properties:
/// * [au] - Instant de la lecture — l'exposition est vraie **à quelques secondes** près (délai du worker outbox, SC-010 l'accepte explicitement).
/// * [devise] - Devise ISO 4217.
/// * [parCoursier] - Détail, du plus exposé au moins exposé.
/// * [totalUnites] - Total en circulation.
@BuiltValue()
abstract class ExpositionCash implements Built<ExpositionCash, ExpositionCashBuilder> {
  /// Instant de la lecture — l'exposition est vraie **à quelques secondes** près (délai du worker outbox, SC-010 l'accepte explicitement).
  @BuiltValueField(wireName: r'au')
  DateTime get au;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Détail, du plus exposé au moins exposé.
  @BuiltValueField(wireName: r'par_coursier')
  BuiltList<LigneExposition> get parCoursier;

  /// Total en circulation.
  @BuiltValueField(wireName: r'total_unites')
  int get totalUnites;

  ExpositionCash._();

  factory ExpositionCash([void updates(ExpositionCashBuilder b)]) = _$ExpositionCash;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExpositionCashBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExpositionCash> get serializer => _$ExpositionCashSerializer();
}

class _$ExpositionCashSerializer implements PrimitiveSerializer<ExpositionCash> {
  @override
  final Iterable<Type> types = const [ExpositionCash, _$ExpositionCash];

  @override
  final String wireName = r'ExpositionCash';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExpositionCash object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'au';
    yield serializers.serialize(
      object.au,
      specifiedType: const FullType(DateTime),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'par_coursier';
    yield serializers.serialize(
      object.parCoursier,
      specifiedType: const FullType(BuiltList, [FullType(LigneExposition)]),
    );
    yield r'total_unites';
    yield serializers.serialize(
      object.totalUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ExpositionCash object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExpositionCashBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'au':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.au = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'par_coursier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LigneExposition)]),
          ) as BuiltList<LigneExposition>;
          result.parCoursier.replace(valueDes);
          break;
        case r'total_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExpositionCash deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExpositionCashBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


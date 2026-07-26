//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/arret_courant_suivi.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'progression_suivi.g.dart';

/// Progression de la course, en ARRÊTS DE COLLECTE.
///
/// Properties:
/// * [arretCourant] - Arrêt courant.
/// * [collectesFaites] - Collectes résolues (collectées ou indisponibles).
/// * [collectesTotal] - Nombre total de collectes — **la remise n'en est pas une** (P1).
@BuiltValue()
abstract class ProgressionSuivi implements Built<ProgressionSuivi, ProgressionSuiviBuilder> {
  /// Arrêt courant.
  @BuiltValueField(wireName: r'arret_courant')
  ArretCourantSuivi? get arretCourant;

  /// Collectes résolues (collectées ou indisponibles).
  @BuiltValueField(wireName: r'collectes_faites')
  int get collectesFaites;

  /// Nombre total de collectes — **la remise n'en est pas une** (P1).
  @BuiltValueField(wireName: r'collectes_total')
  int get collectesTotal;

  ProgressionSuivi._();

  factory ProgressionSuivi([void updates(ProgressionSuiviBuilder b)]) = _$ProgressionSuivi;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProgressionSuiviBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProgressionSuivi> get serializer => _$ProgressionSuiviSerializer();
}

class _$ProgressionSuiviSerializer implements PrimitiveSerializer<ProgressionSuivi> {
  @override
  final Iterable<Type> types = const [ProgressionSuivi, _$ProgressionSuivi];

  @override
  final String wireName = r'ProgressionSuivi';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProgressionSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.arretCourant != null) {
      yield r'arret_courant';
      yield serializers.serialize(
        object.arretCourant,
        specifiedType: const FullType.nullable(ArretCourantSuivi),
      );
    }
    yield r'collectes_faites';
    yield serializers.serialize(
      object.collectesFaites,
      specifiedType: const FullType(int),
    );
    yield r'collectes_total';
    yield serializers.serialize(
      object.collectesTotal,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProgressionSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProgressionSuiviBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_courant':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ArretCourantSuivi),
          ) as ArretCourantSuivi?;
          if (valueDes == null) continue;
          result.arretCourant.replace(valueDes);
          break;
        case r'collectes_faites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.collectesFaites = valueDes;
          break;
        case r'collectes_total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.collectesTotal = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProgressionSuivi deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProgressionSuiviBuilder();
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


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'arret_courant_suivi.g.dart';

/// L'arrêt où en est le coursier.
///
/// Properties:
/// * [arretId] - Arrêt.
/// * [ordre] - Rang dans l'itinéraire.
/// * [prestataireNom] - Nom du vendeur (`null` sur l'arrêt de remise).
/// * [statut] - Statut de l'arrêt.
@BuiltValue()
abstract class ArretCourantSuivi implements Built<ArretCourantSuivi, ArretCourantSuiviBuilder> {
  /// Arrêt.
  @BuiltValueField(wireName: r'arret_id')
  String get arretId;

  /// Rang dans l'itinéraire.
  @BuiltValueField(wireName: r'ordre')
  int get ordre;

  /// Nom du vendeur (`null` sur l'arrêt de remise).
  @BuiltValueField(wireName: r'prestataire_nom')
  String? get prestataireNom;

  /// Statut de l'arrêt.
  @BuiltValueField(wireName: r'statut')
  String get statut;

  ArretCourantSuivi._();

  factory ArretCourantSuivi([void updates(ArretCourantSuiviBuilder b)]) = _$ArretCourantSuivi;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ArretCourantSuiviBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ArretCourantSuivi> get serializer => _$ArretCourantSuiviSerializer();
}

class _$ArretCourantSuiviSerializer implements PrimitiveSerializer<ArretCourantSuivi> {
  @override
  final Iterable<Type> types = const [ArretCourantSuivi, _$ArretCourantSuivi];

  @override
  final String wireName = r'ArretCourantSuivi';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ArretCourantSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arret_id';
    yield serializers.serialize(
      object.arretId,
      specifiedType: const FullType(String),
    );
    yield r'ordre';
    yield serializers.serialize(
      object.ordre,
      specifiedType: const FullType(int),
    );
    if (object.prestataireNom != null) {
      yield r'prestataire_nom';
      yield serializers.serialize(
        object.prestataireNom,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ArretCourantSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ArretCourantSuiviBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.arretId = valueDes;
          break;
        case r'ordre':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ordre = valueDes;
          break;
        case r'prestataire_nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.prestataireNom = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statut = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ArretCourantSuivi deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ArretCourantSuiviBuilder();
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


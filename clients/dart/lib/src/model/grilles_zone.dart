//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/grille.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'grilles_zone.g.dart';

/// Vue d'ensemble de la tarification d'une zone.
///
/// Properties:
/// * [brouillon] - Brouillon en cours d'édition, `null` s'il n'y en a pas.
/// * [enVigueur] - Grille qui tarife aujourd'hui, `null` si la zone n'en a aucune.
@BuiltValue()
abstract class GrillesZone implements Built<GrillesZone, GrillesZoneBuilder> {
  /// Brouillon en cours d'édition, `null` s'il n'y en a pas.
  @BuiltValueField(wireName: r'brouillon')
  Grille? get brouillon;

  /// Grille qui tarife aujourd'hui, `null` si la zone n'en a aucune.
  @BuiltValueField(wireName: r'en_vigueur')
  Grille? get enVigueur;

  GrillesZone._();

  factory GrillesZone([void updates(GrillesZoneBuilder b)]) = _$GrillesZone;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GrillesZoneBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GrillesZone> get serializer => _$GrillesZoneSerializer();
}

class _$GrillesZoneSerializer implements PrimitiveSerializer<GrillesZone> {
  @override
  final Iterable<Type> types = const [GrillesZone, _$GrillesZone];

  @override
  final String wireName = r'GrillesZone';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GrillesZone object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.brouillon != null) {
      yield r'brouillon';
      yield serializers.serialize(
        object.brouillon,
        specifiedType: const FullType.nullable(Grille),
      );
    }
    if (object.enVigueur != null) {
      yield r'en_vigueur';
      yield serializers.serialize(
        object.enVigueur,
        specifiedType: const FullType.nullable(Grille),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GrillesZone object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GrillesZoneBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'brouillon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Grille),
          ) as Grille?;
          if (valueDes == null) continue;
          result.brouillon.replace(valueDes);
          break;
        case r'en_vigueur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Grille),
          ) as Grille?;
          if (valueDes == null) continue;
          result.enVigueur.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GrillesZone deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GrillesZoneBuilder();
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


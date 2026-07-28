//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'bascule_disponibilite.g.dart';

/// Bascule de disponibilité et déclaration du plafond d'avance du jour.
///
/// Properties:
/// * [enLigne] - Vrai pour entrer dans le pool, faux pour en sortir **immédiatement**.
/// * [plafondDeclareUnites] - Ce que le coursier peut avancer aujourd'hui (unités mineures). Obligatoire pour se mettre en ligne, ignoré pour en sortir.
@BuiltValue()
abstract class BasculeDisponibilite implements Built<BasculeDisponibilite, BasculeDisponibiliteBuilder> {
  /// Vrai pour entrer dans le pool, faux pour en sortir **immédiatement**.
  @BuiltValueField(wireName: r'en_ligne')
  bool get enLigne;

  /// Ce que le coursier peut avancer aujourd'hui (unités mineures). Obligatoire pour se mettre en ligne, ignoré pour en sortir.
  @BuiltValueField(wireName: r'plafond_declare_unites')
  int? get plafondDeclareUnites;

  BasculeDisponibilite._();

  factory BasculeDisponibilite([void updates(BasculeDisponibiliteBuilder b)]) = _$BasculeDisponibilite;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BasculeDisponibiliteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BasculeDisponibilite> get serializer => _$BasculeDisponibiliteSerializer();
}

class _$BasculeDisponibiliteSerializer implements PrimitiveSerializer<BasculeDisponibilite> {
  @override
  final Iterable<Type> types = const [BasculeDisponibilite, _$BasculeDisponibilite];

  @override
  final String wireName = r'BasculeDisponibilite';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BasculeDisponibilite object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'en_ligne';
    yield serializers.serialize(
      object.enLigne,
      specifiedType: const FullType(bool),
    );
    if (object.plafondDeclareUnites != null) {
      yield r'plafond_declare_unites';
      yield serializers.serialize(
        object.plafondDeclareUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BasculeDisponibilite object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BasculeDisponibiliteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'en_ligne':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enLigne = valueDes;
          break;
        case r'plafond_declare_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.plafondDeclareUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BasculeDisponibilite deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BasculeDisponibiliteBuilder();
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


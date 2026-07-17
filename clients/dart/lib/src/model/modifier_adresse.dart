//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'modifier_adresse.g.dart';

/// Champs modifiables d'une adresse (contrat).
///
/// Properties:
/// * [libelle] - Nouveau libellé — absent = inchangé.
/// * [repereTexte] - Nouveau repère écrit — absent = inchangé, `null` = effacé.  Le double `Option` porte cette nuance : sans lui, « ne touche pas » et « efface » seraient le même corps JSON.
@BuiltValue()
abstract class ModifierAdresse implements Built<ModifierAdresse, ModifierAdresseBuilder> {
  /// Nouveau libellé — absent = inchangé.
  @BuiltValueField(wireName: r'libelle')
  String? get libelle;

  /// Nouveau repère écrit — absent = inchangé, `null` = effacé.  Le double `Option` porte cette nuance : sans lui, « ne touche pas » et « efface » seraient le même corps JSON.
  @BuiltValueField(wireName: r'repere_texte')
  String? get repereTexte;

  ModifierAdresse._();

  factory ModifierAdresse([void updates(ModifierAdresseBuilder b)]) = _$ModifierAdresse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ModifierAdresseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ModifierAdresse> get serializer => _$ModifierAdresseSerializer();
}

class _$ModifierAdresseSerializer implements PrimitiveSerializer<ModifierAdresse> {
  @override
  final Iterable<Type> types = const [ModifierAdresse, _$ModifierAdresse];

  @override
  final String wireName = r'ModifierAdresse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ModifierAdresse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.libelle != null) {
      yield r'libelle';
      yield serializers.serialize(
        object.libelle,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.repereTexte != null) {
      yield r'repere_texte';
      yield serializers.serialize(
        object.repereTexte,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ModifierAdresse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ModifierAdresseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'libelle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.libelle = valueDes;
          break;
        case r'repere_texte':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.repereTexte = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ModifierAdresse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ModifierAdresseBuilder();
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


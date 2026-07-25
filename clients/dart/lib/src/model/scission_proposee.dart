//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/commande_proposee.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'scission_proposee.g.dart';

/// Proposition de scission — une seule surface pour ses deux causes (R9).
///
/// Properties:
/// * [cause] - `categorie_non_mixable` | `plafond_eclatement`.
/// * [commandesProposees] - Prévisualisation CHIFFRÉE des commandes résultantes.
/// * [messageCle] - Clé i18n du message affiché.
@BuiltValue()
abstract class ScissionProposee implements Built<ScissionProposee, ScissionProposeeBuilder> {
  /// `categorie_non_mixable` | `plafond_eclatement`.
  @BuiltValueField(wireName: r'cause')
  String get cause;

  /// Prévisualisation CHIFFRÉE des commandes résultantes.
  @BuiltValueField(wireName: r'commandes_proposees')
  BuiltList<CommandeProposee> get commandesProposees;

  /// Clé i18n du message affiché.
  @BuiltValueField(wireName: r'message_cle')
  String get messageCle;

  ScissionProposee._();

  factory ScissionProposee([void updates(ScissionProposeeBuilder b)]) = _$ScissionProposee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ScissionProposeeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ScissionProposee> get serializer => _$ScissionProposeeSerializer();
}

class _$ScissionProposeeSerializer implements PrimitiveSerializer<ScissionProposee> {
  @override
  final Iterable<Type> types = const [ScissionProposee, _$ScissionProposee];

  @override
  final String wireName = r'ScissionProposee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ScissionProposee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'cause';
    yield serializers.serialize(
      object.cause,
      specifiedType: const FullType(String),
    );
    yield r'commandes_proposees';
    yield serializers.serialize(
      object.commandesProposees,
      specifiedType: const FullType(BuiltList, [FullType(CommandeProposee)]),
    );
    yield r'message_cle';
    yield serializers.serialize(
      object.messageCle,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ScissionProposee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ScissionProposeeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'cause':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cause = valueDes;
          break;
        case r'commandes_proposees':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CommandeProposee)]),
          ) as BuiltList<CommandeProposee>;
          result.commandesProposees.replace(valueDes);
          break;
        case r'message_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.messageCle = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ScissionProposee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ScissionProposeeBuilder();
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


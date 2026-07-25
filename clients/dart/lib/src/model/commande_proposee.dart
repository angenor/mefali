//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'commande_proposee.g.dart';

/// Une commande telle qu'elle sortirait de la scission.
///
/// Properties:
/// * [articles] - Articles qui la composeraient.
/// * [libelleCle] - Clé i18n du libellé.
/// * [totalArticlesUnites] - Total des ARTICLES de cette commande (unités mineures).
@BuiltValue()
abstract class CommandeProposee implements Built<CommandeProposee, CommandeProposeeBuilder> {
  /// Articles qui la composeraient.
  @BuiltValueField(wireName: r'articles')
  BuiltList<String> get articles;

  /// Clé i18n du libellé.
  @BuiltValueField(wireName: r'libelle_cle')
  String get libelleCle;

  /// Total des ARTICLES de cette commande (unités mineures).
  @BuiltValueField(wireName: r'total_articles_unites')
  int get totalArticlesUnites;

  CommandeProposee._();

  factory CommandeProposee([void updates(CommandeProposeeBuilder b)]) = _$CommandeProposee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CommandeProposeeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CommandeProposee> get serializer => _$CommandeProposeeSerializer();
}

class _$CommandeProposeeSerializer implements PrimitiveSerializer<CommandeProposee> {
  @override
  final Iterable<Type> types = const [CommandeProposee, _$CommandeProposee];

  @override
  final String wireName = r'CommandeProposee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CommandeProposee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'articles';
    yield serializers.serialize(
      object.articles,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'libelle_cle';
    yield serializers.serialize(
      object.libelleCle,
      specifiedType: const FullType(String),
    );
    yield r'total_articles_unites';
    yield serializers.serialize(
      object.totalArticlesUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CommandeProposee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CommandeProposeeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'articles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.articles.replace(valueDes);
          break;
        case r'libelle_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.libelleCle = valueDes;
          break;
        case r'total_articles_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalArticlesUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CommandeProposee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CommandeProposeeBuilder();
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


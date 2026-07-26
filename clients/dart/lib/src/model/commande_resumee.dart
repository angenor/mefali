//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'commande_resumee.g.dart';

/// Une commande de la liste `GET /moi/commandes`.
///
/// Properties:
/// * [creeLe] - Création.
/// * [devise] - Devise ISO 4217.
/// * [etat] - État de très haut niveau.
/// * [etatCle] - Clé i18n de l'état affiché.
/// * [id] - Commande.
/// * [nbVendeurs] - Nombre de vendeurs.
/// * [totalUnites] - Total à payer.
@BuiltValue()
abstract class CommandeResumee implements Built<CommandeResumee, CommandeResumeeBuilder> {
  /// Création.
  @BuiltValueField(wireName: r'cree_le')
  DateTime get creeLe;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// État de très haut niveau.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Clé i18n de l'état affiché.
  @BuiltValueField(wireName: r'etat_cle')
  String get etatCle;

  /// Commande.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Nombre de vendeurs.
  @BuiltValueField(wireName: r'nb_vendeurs')
  int get nbVendeurs;

  /// Total à payer.
  @BuiltValueField(wireName: r'total_unites')
  int get totalUnites;

  CommandeResumee._();

  factory CommandeResumee([void updates(CommandeResumeeBuilder b)]) = _$CommandeResumee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CommandeResumeeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CommandeResumee> get serializer => _$CommandeResumeeSerializer();
}

class _$CommandeResumeeSerializer implements PrimitiveSerializer<CommandeResumee> {
  @override
  final Iterable<Type> types = const [CommandeResumee, _$CommandeResumee];

  @override
  final String wireName = r'CommandeResumee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CommandeResumee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'cree_le';
    yield serializers.serialize(
      object.creeLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'etat_cle';
    yield serializers.serialize(
      object.etatCle,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'nb_vendeurs';
    yield serializers.serialize(
      object.nbVendeurs,
      specifiedType: const FullType(int),
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
    CommandeResumee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CommandeResumeeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'cree_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.creeLe = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'etat_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etatCle = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'nb_vendeurs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbVendeurs = valueDes;
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
  CommandeResumee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CommandeResumeeBuilder();
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


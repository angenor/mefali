//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'litige_vu.g.dart';

/// Un litige en cours vu par le coursier (K5-1c).
///
/// Properties:
/// * [commandeId] - Commande concernée.
/// * [etatCle] - Clé i18n de l'état affiché.
/// * [id] - Litige.
/// * [montantUnites] - Montant en jeu (unités mineures).
/// * [ouvertLe] - Ouverture.
/// * [reference] - Référence lisible.
@BuiltValue()
abstract class LitigeVu implements Built<LitigeVu, LitigeVuBuilder> {
  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Clé i18n de l'état affiché.
  @BuiltValueField(wireName: r'etat_cle')
  String get etatCle;

  /// Litige.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Montant en jeu (unités mineures).
  @BuiltValueField(wireName: r'montant_unites')
  int get montantUnites;

  /// Ouverture.
  @BuiltValueField(wireName: r'ouvert_le')
  DateTime get ouvertLe;

  /// Référence lisible.
  @BuiltValueField(wireName: r'reference')
  String get reference;

  LitigeVu._();

  factory LitigeVu([void updates(LitigeVuBuilder b)]) = _$LitigeVu;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LitigeVuBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LitigeVu> get serializer => _$LitigeVuSerializer();
}

class _$LitigeVuSerializer implements PrimitiveSerializer<LitigeVu> {
  @override
  final Iterable<Type> types = const [LitigeVu, _$LitigeVu];

  @override
  final String wireName = r'LitigeVu';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LitigeVu object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
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
    yield r'montant_unites';
    yield serializers.serialize(
      object.montantUnites,
      specifiedType: const FullType(int),
    );
    yield r'ouvert_le';
    yield serializers.serialize(
      object.ouvertLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'reference';
    yield serializers.serialize(
      object.reference,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LitigeVu object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LitigeVuBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
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
        case r'montant_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantUnites = valueDes;
          break;
        case r'ouvert_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.ouvertLe = valueDes;
          break;
        case r'reference':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reference = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LitigeVu deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LitigeVuBuilder();
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


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'creance.g.dart';

/// Une créance de coursier (FR-094).
///
/// Properties:
/// * [commandeId] - Commande d'origine.
/// * [creeLe] - Naissance — automatique, à la livraison (FR-063).
/// * [devise] - Devise ISO 4217.
/// * [etat] - `due` | `reglee`.
/// * [id] - Identifiant.
/// * [montantUnites] - Montant dû (unités mineures).
/// * [nature] - `avance_prepayee` | `part_course`.
/// * [regleLe] - Instant du règlement, `null` tant qu'elle est due.
@BuiltValue()
abstract class Creance implements Built<Creance, CreanceBuilder> {
  /// Commande d'origine.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Naissance — automatique, à la livraison (FR-063).
  @BuiltValueField(wireName: r'cree_le')
  DateTime get creeLe;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// `due` | `reglee`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Montant dû (unités mineures).
  @BuiltValueField(wireName: r'montant_unites')
  int get montantUnites;

  /// `avance_prepayee` | `part_course`.
  @BuiltValueField(wireName: r'nature')
  String get nature;

  /// Instant du règlement, `null` tant qu'elle est due.
  @BuiltValueField(wireName: r'regle_le')
  DateTime? get regleLe;

  Creance._();

  factory Creance([void updates(CreanceBuilder b)]) = _$Creance;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreanceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Creance> get serializer => _$CreanceSerializer();
}

class _$CreanceSerializer implements PrimitiveSerializer<Creance> {
  @override
  final Iterable<Type> types = const [Creance, _$Creance];

  @override
  final String wireName = r'Creance';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Creance object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
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
    yield r'nature';
    yield serializers.serialize(
      object.nature,
      specifiedType: const FullType(String),
    );
    if (object.regleLe != null) {
      yield r'regle_le';
      yield serializers.serialize(
        object.regleLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Creance object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreanceBuilder result,
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
        case r'nature':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nature = valueDes;
          break;
        case r'regle_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.regleLe = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Creance deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreanceBuilder();
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


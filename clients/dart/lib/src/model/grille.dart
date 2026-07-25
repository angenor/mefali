//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/regle.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'grille.g.dart';

/// Grille servie à l'admin (en-tête + règles + statut de simulation).
///
/// Properties:
/// * [effetLe] - Entrée en vigueur (posée à la publication).
/// * [etat] - `brouillon` | `en_vigueur` | `historique`.
/// * [id] - Identifiant.
/// * [regles] - Règles, triées par identifiant (ordre stable).
/// * [simulee] - **Publiable** : la simulation porte sur le contenu EXACT du brouillon. Repasse à `false` dès qu'une règle est éditée (FR-021).
/// * [simuleeLe] - Dernière simulation réussie.
/// * [version] - Version.
/// * [zoneId] - Zone tarifée.
@BuiltValue()
abstract class Grille implements Built<Grille, GrilleBuilder> {
  /// Entrée en vigueur (posée à la publication).
  @BuiltValueField(wireName: r'effet_le')
  DateTime? get effetLe;

  /// `brouillon` | `en_vigueur` | `historique`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Règles, triées par identifiant (ordre stable).
  @BuiltValueField(wireName: r'regles')
  BuiltList<Regle> get regles;

  /// **Publiable** : la simulation porte sur le contenu EXACT du brouillon. Repasse à `false` dès qu'une règle est éditée (FR-021).
  @BuiltValueField(wireName: r'simulee')
  bool get simulee;

  /// Dernière simulation réussie.
  @BuiltValueField(wireName: r'simulee_le')
  DateTime? get simuleeLe;

  /// Version.
  @BuiltValueField(wireName: r'version')
  int get version;

  /// Zone tarifée.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  Grille._();

  factory Grille([void updates(GrilleBuilder b)]) = _$Grille;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GrilleBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Grille> get serializer => _$GrilleSerializer();
}

class _$GrilleSerializer implements PrimitiveSerializer<Grille> {
  @override
  final Iterable<Type> types = const [Grille, _$Grille];

  @override
  final String wireName = r'Grille';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Grille object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.effetLe != null) {
      yield r'effet_le';
      yield serializers.serialize(
        object.effetLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
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
    yield r'regles';
    yield serializers.serialize(
      object.regles,
      specifiedType: const FullType(BuiltList, [FullType(Regle)]),
    );
    yield r'simulee';
    yield serializers.serialize(
      object.simulee,
      specifiedType: const FullType(bool),
    );
    if (object.simuleeLe != null) {
      yield r'simulee_le';
      yield serializers.serialize(
        object.simuleeLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(int),
    );
    yield r'zone_id';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Grille object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GrilleBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'effet_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.effetLe = valueDes;
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
        case r'regles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Regle)]),
          ) as BuiltList<Regle>;
          result.regles.replace(valueDes);
          break;
        case r'simulee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.simulee = valueDes;
          break;
        case r'simulee_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.simuleeLe = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.version = valueDes;
          break;
        case r'zone_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Grille deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GrilleBuilder();
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


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/vehicule_declare.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'dossier_coursier.g.dart';

/// Dossier coursier tel que son titulaire le voit (contrat).  ⚠ La CLÉ de la pièce n'en fait pas partie : elle n'a de sens que pour le serveur, et l'exposer donnerait un identifiant de bucket à deviner.
///
/// Properties:
/// * [motif] - Motif de la dernière décision admin.
/// * [referentNom] - Référent local (« caution morale », cadrage §7.1).
/// * [referentTelephoneE164] - Téléphone du référent, normalisé E.164.
/// * [soumisLe] - Dernier dépôt.
/// * [statut] - Statut = celui de l'attribution `coursier` (R9).
/// * [vehicules] - Véhicules déclarés.
@BuiltValue()
abstract class DossierCoursier implements Built<DossierCoursier, DossierCoursierBuilder> {
  /// Motif de la dernière décision admin.
  @BuiltValueField(wireName: r'motif')
  String? get motif;

  /// Référent local (« caution morale », cadrage §7.1).
  @BuiltValueField(wireName: r'referent_nom')
  String get referentNom;

  /// Téléphone du référent, normalisé E.164.
  @BuiltValueField(wireName: r'referent_telephone_e164')
  String get referentTelephoneE164;

  /// Dernier dépôt.
  @BuiltValueField(wireName: r'soumis_le')
  DateTime get soumisLe;

  /// Statut = celui de l'attribution `coursier` (R9).
  @BuiltValueField(wireName: r'statut')
  String get statut;

  /// Véhicules déclarés.
  @BuiltValueField(wireName: r'vehicules')
  BuiltList<VehiculeDeclare> get vehicules;

  DossierCoursier._();

  factory DossierCoursier([void updates(DossierCoursierBuilder b)]) = _$DossierCoursier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DossierCoursierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DossierCoursier> get serializer => _$DossierCoursierSerializer();
}

class _$DossierCoursierSerializer implements PrimitiveSerializer<DossierCoursier> {
  @override
  final Iterable<Type> types = const [DossierCoursier, _$DossierCoursier];

  @override
  final String wireName = r'DossierCoursier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DossierCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.motif != null) {
      yield r'motif';
      yield serializers.serialize(
        object.motif,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'referent_nom';
    yield serializers.serialize(
      object.referentNom,
      specifiedType: const FullType(String),
    );
    yield r'referent_telephone_e164';
    yield serializers.serialize(
      object.referentTelephoneE164,
      specifiedType: const FullType(String),
    );
    yield r'soumis_le';
    yield serializers.serialize(
      object.soumisLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(String),
    );
    yield r'vehicules';
    yield serializers.serialize(
      object.vehicules,
      specifiedType: const FullType(BuiltList, [FullType(VehiculeDeclare)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DossierCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DossierCoursierBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motif = valueDes;
          break;
        case r'referent_nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.referentNom = valueDes;
          break;
        case r'referent_telephone_e164':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.referentTelephoneE164 = valueDes;
          break;
        case r'soumis_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.soumisLe = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statut = valueDes;
          break;
        case r'vehicules':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VehiculeDeclare)]),
          ) as BuiltList<VehiculeDeclare>;
          result.vehicules.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DossierCoursier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DossierCoursierBuilder();
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


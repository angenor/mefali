//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_issue_admin.g.dart';

/// Enregistrement d'une issue §7.5 **par l'exploitation**.  Volontairement distinct du DTO coursier : celui-ci exige un `uuid_client` (sa file hors-ligne rejoue), l'admin n'en a pas — chaque clic est une action neuve, sur un écran connecté. Partager le DTO aurait obligé l'exploitation à fabriquer un identifiant d'idempotence qui ne correspond à rien chez elle.
///
/// Properties:
/// * [arretId] - Arrêt concerné — absent = à la remise.
/// * [motifCle] - Clé i18n du motif — jamais du texte libre.
/// * [typeIssue] - Ligne de l'arbre §7.5 (`refus_perissable`, `faux_billet`…).
@BuiltValue()
abstract class DemandeIssueAdmin implements Built<DemandeIssueAdmin, DemandeIssueAdminBuilder> {
  /// Arrêt concerné — absent = à la remise.
  @BuiltValueField(wireName: r'arret_id')
  String? get arretId;

  /// Clé i18n du motif — jamais du texte libre.
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  /// Ligne de l'arbre §7.5 (`refus_perissable`, `faux_billet`…).
  @BuiltValueField(wireName: r'type_issue')
  String get typeIssue;

  DemandeIssueAdmin._();

  factory DemandeIssueAdmin([void updates(DemandeIssueAdminBuilder b)]) = _$DemandeIssueAdmin;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeIssueAdminBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeIssueAdmin> get serializer => _$DemandeIssueAdminSerializer();
}

class _$DemandeIssueAdminSerializer implements PrimitiveSerializer<DemandeIssueAdmin> {
  @override
  final Iterable<Type> types = const [DemandeIssueAdmin, _$DemandeIssueAdmin];

  @override
  final String wireName = r'DemandeIssueAdmin';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeIssueAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.arretId != null) {
      yield r'arret_id';
      yield serializers.serialize(
        object.arretId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'motif_cle';
    yield serializers.serialize(
      object.motifCle,
      specifiedType: const FullType(String),
    );
    yield r'type_issue';
    yield serializers.serialize(
      object.typeIssue,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeIssueAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeIssueAdminBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.arretId = valueDes;
          break;
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motifCle = valueDes;
          break;
        case r'type_issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.typeIssue = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeIssueAdmin deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeIssueAdminBuilder();
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


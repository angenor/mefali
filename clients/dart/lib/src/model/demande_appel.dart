//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_appel.g.dart';

/// Corps de déclaration d'un appel passé via l'app.
///
/// Properties:
/// * [issue] - Issue DÉCLARÉE : `inconnue` | `sans_reponse` | `repondu`. Facultative — le serveur ne voit pas l'appel, il ne peut que la recevoir (R19).
/// * [motif] - `suivi` | `substitution` | `client_absent`. **Seul `client_absent` compte** pour la preuve d'échec (FR-035).
/// * [passeLeLocal] - Horodatage de l'appareil — observation seulement.
/// * [prestataireId] - Prestataire appelé — obligatoire si `vers = vendeur`.
/// * [uuidClient] - Clé d'idempotence (UUIDv7 client, constitution V).
/// * [vers] - `client` | `vendeur`.
@BuiltValue()
abstract class DemandeAppel implements Built<DemandeAppel, DemandeAppelBuilder> {
  /// Issue DÉCLARÉE : `inconnue` | `sans_reponse` | `repondu`. Facultative — le serveur ne voit pas l'appel, il ne peut que la recevoir (R19).
  @BuiltValueField(wireName: r'issue')
  String? get issue;

  /// `suivi` | `substitution` | `client_absent`. **Seul `client_absent` compte** pour la preuve d'échec (FR-035).
  @BuiltValueField(wireName: r'motif')
  String get motif;

  /// Horodatage de l'appareil — observation seulement.
  @BuiltValueField(wireName: r'passe_le_local')
  DateTime get passeLeLocal;

  /// Prestataire appelé — obligatoire si `vers = vendeur`.
  @BuiltValueField(wireName: r'prestataire_id')
  String? get prestataireId;

  /// Clé d'idempotence (UUIDv7 client, constitution V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  /// `client` | `vendeur`.
  @BuiltValueField(wireName: r'vers')
  String get vers;

  DemandeAppel._();

  factory DemandeAppel([void updates(DemandeAppelBuilder b)]) = _$DemandeAppel;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeAppelBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeAppel> get serializer => _$DemandeAppelSerializer();
}

class _$DemandeAppelSerializer implements PrimitiveSerializer<DemandeAppel> {
  @override
  final Iterable<Type> types = const [DemandeAppel, _$DemandeAppel];

  @override
  final String wireName = r'DemandeAppel';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeAppel object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.issue != null) {
      yield r'issue';
      yield serializers.serialize(
        object.issue,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'motif';
    yield serializers.serialize(
      object.motif,
      specifiedType: const FullType(String),
    );
    yield r'passe_le_local';
    yield serializers.serialize(
      object.passeLeLocal,
      specifiedType: const FullType(DateTime),
    );
    if (object.prestataireId != null) {
      yield r'prestataire_id';
      yield serializers.serialize(
        object.prestataireId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
    yield r'vers';
    yield serializers.serialize(
      object.vers,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeAppel object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeAppelBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.issue = valueDes;
          break;
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motif = valueDes;
          break;
        case r'passe_le_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.passeLeLocal = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.prestataireId = valueDes;
          break;
        case r'uuid_client':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.uuidClient = valueDes;
          break;
        case r'vers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vers = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeAppel deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeAppelBuilder();
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


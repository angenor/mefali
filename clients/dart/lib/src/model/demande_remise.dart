//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_remise.g.dart';

/// Preuve de remise présentée par le coursier — partie `demande` du multipart.
///
/// Properties:
/// * [code] - Code à 4 chiffres dicté par le client (mode `code`).
/// * [confirmeLeLocal] - Horodatage de l'appareil. **Observation seulement**.
/// * [depotLat] - Latitude du coursier au dépôt (mode `depot`, FR-048).
/// * [depotLon] - Longitude du coursier au dépôt (mode `depot`, FR-048).
/// * [essaisHorsLigne] - Essais faux consommés **hors ligne**, consolidés en `max()` côté serveur contre le seuil de zone `commande.essais_code_livraison` (R5).
/// * [horsLigne] - La validation a-t-elle eu lieu sans réseau ? Journalisé, jamais décisif — le serveur revalide la preuve ici même (FR-046).
/// * [jeton] - Jeton lu dans le QR de réception (mode `qr`).
/// * [mode] - `qr` | `code` | `depot`.
/// * [photoCle] - Clé d'une photo **déjà** déposée (mode `depot`) — compatibilité du cycle 008 ; l'app coursier envoie la partie binaire `photo` (R18).
/// * [uuidClient] - Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : sans elle, un rejeu de la file clôturait deux fois la même course (R4).
@BuiltValue()
abstract class DemandeRemise implements Built<DemandeRemise, DemandeRemiseBuilder> {
  /// Code à 4 chiffres dicté par le client (mode `code`).
  @BuiltValueField(wireName: r'code')
  String? get code;

  /// Horodatage de l'appareil. **Observation seulement**.
  @BuiltValueField(wireName: r'confirme_le_local')
  DateTime? get confirmeLeLocal;

  /// Latitude du coursier au dépôt (mode `depot`, FR-048).
  @BuiltValueField(wireName: r'depot_lat')
  double? get depotLat;

  /// Longitude du coursier au dépôt (mode `depot`, FR-048).
  @BuiltValueField(wireName: r'depot_lon')
  double? get depotLon;

  /// Essais faux consommés **hors ligne**, consolidés en `max()` côté serveur contre le seuil de zone `commande.essais_code_livraison` (R5).
  @BuiltValueField(wireName: r'essais_hors_ligne')
  int? get essaisHorsLigne;

  /// La validation a-t-elle eu lieu sans réseau ? Journalisé, jamais décisif — le serveur revalide la preuve ici même (FR-046).
  @BuiltValueField(wireName: r'hors_ligne')
  bool? get horsLigne;

  /// Jeton lu dans le QR de réception (mode `qr`).
  @BuiltValueField(wireName: r'jeton')
  String? get jeton;

  /// `qr` | `code` | `depot`.
  @BuiltValueField(wireName: r'mode')
  String get mode;

  /// Clé d'une photo **déjà** déposée (mode `depot`) — compatibilité du cycle 008 ; l'app coursier envoie la partie binaire `photo` (R18).
  @BuiltValueField(wireName: r'photo_cle')
  String? get photoCle;

  /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : sans elle, un rejeu de la file clôturait deux fois la même course (R4).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  DemandeRemise._();

  factory DemandeRemise([void updates(DemandeRemiseBuilder b)]) = _$DemandeRemise;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeRemiseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeRemise> get serializer => _$DemandeRemiseSerializer();
}

class _$DemandeRemiseSerializer implements PrimitiveSerializer<DemandeRemise> {
  @override
  final Iterable<Type> types = const [DemandeRemise, _$DemandeRemise];

  @override
  final String wireName = r'DemandeRemise';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.code != null) {
      yield r'code';
      yield serializers.serialize(
        object.code,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.confirmeLeLocal != null) {
      yield r'confirme_le_local';
      yield serializers.serialize(
        object.confirmeLeLocal,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.depotLat != null) {
      yield r'depot_lat';
      yield serializers.serialize(
        object.depotLat,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.depotLon != null) {
      yield r'depot_lon';
      yield serializers.serialize(
        object.depotLon,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.essaisHorsLigne != null) {
      yield r'essais_hors_ligne';
      yield serializers.serialize(
        object.essaisHorsLigne,
        specifiedType: const FullType(int),
      );
    }
    if (object.horsLigne != null) {
      yield r'hors_ligne';
      yield serializers.serialize(
        object.horsLigne,
        specifiedType: const FullType(bool),
      );
    }
    if (object.jeton != null) {
      yield r'jeton';
      yield serializers.serialize(
        object.jeton,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'mode';
    yield serializers.serialize(
      object.mode,
      specifiedType: const FullType(String),
    );
    if (object.photoCle != null) {
      yield r'photo_cle';
      yield serializers.serialize(
        object.photoCle,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeRemiseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.code = valueDes;
          break;
        case r'confirme_le_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.confirmeLeLocal = valueDes;
          break;
        case r'depot_lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.depotLat = valueDes;
          break;
        case r'depot_lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.depotLon = valueDes;
          break;
        case r'essais_hors_ligne':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.essaisHorsLigne = valueDes;
          break;
        case r'hors_ligne':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.horsLigne = valueDes;
          break;
        case r'jeton':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jeton = valueDes;
          break;
        case r'mode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mode = valueDes;
          break;
        case r'photo_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.photoCle = valueDes;
          break;
        case r'uuid_client':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.uuidClient = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeRemise deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeRemiseBuilder();
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


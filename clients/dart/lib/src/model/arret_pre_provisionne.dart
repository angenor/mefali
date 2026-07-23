//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'arret_pre_provisionne.g.dart';

/// Arrêt pré-provisionné (empreintes, jamais de secret).
///
/// Properties:
/// * [arretId] - Arrêt à collecter.
/// * [devise] - Devise ISO 4217.
/// * [empreinteCode] - base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
/// * [empreinteJeton] - base16(sha256(jeton)) — match hors-ligne du QR scanné.
/// * [montantAvance] - Montant avancé (unités mineures).
/// * [photoExigee] - Photo exigée (politique résolue).
/// * [prestataireId] - Prestataire visé.
/// * [siteLat] - Position attendue du site.
/// * [siteLon] - Position attendue du site.
@BuiltValue()
abstract class ArretPreProvisionne implements Built<ArretPreProvisionne, ArretPreProvisionneBuilder> {
  /// Arrêt à collecter.
  @BuiltValueField(wireName: r'arret_id')
  String get arretId;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
  @BuiltValueField(wireName: r'empreinte_code')
  String get empreinteCode;

  /// base16(sha256(jeton)) — match hors-ligne du QR scanné.
  @BuiltValueField(wireName: r'empreinte_jeton')
  String get empreinteJeton;

  /// Montant avancé (unités mineures).
  @BuiltValueField(wireName: r'montant_avance')
  int get montantAvance;

  /// Photo exigée (politique résolue).
  @BuiltValueField(wireName: r'photo_exigee')
  bool get photoExigee;

  /// Prestataire visé.
  @BuiltValueField(wireName: r'prestataire_id')
  String get prestataireId;

  /// Position attendue du site.
  @BuiltValueField(wireName: r'site_lat')
  double get siteLat;

  /// Position attendue du site.
  @BuiltValueField(wireName: r'site_lon')
  double get siteLon;

  ArretPreProvisionne._();

  factory ArretPreProvisionne([void updates(ArretPreProvisionneBuilder b)]) = _$ArretPreProvisionne;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ArretPreProvisionneBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ArretPreProvisionne> get serializer => _$ArretPreProvisionneSerializer();
}

class _$ArretPreProvisionneSerializer implements PrimitiveSerializer<ArretPreProvisionne> {
  @override
  final Iterable<Type> types = const [ArretPreProvisionne, _$ArretPreProvisionne];

  @override
  final String wireName = r'ArretPreProvisionne';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ArretPreProvisionne object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arret_id';
    yield serializers.serialize(
      object.arretId,
      specifiedType: const FullType(String),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'empreinte_code';
    yield serializers.serialize(
      object.empreinteCode,
      specifiedType: const FullType(String),
    );
    yield r'empreinte_jeton';
    yield serializers.serialize(
      object.empreinteJeton,
      specifiedType: const FullType(String),
    );
    yield r'montant_avance';
    yield serializers.serialize(
      object.montantAvance,
      specifiedType: const FullType(int),
    );
    yield r'photo_exigee';
    yield serializers.serialize(
      object.photoExigee,
      specifiedType: const FullType(bool),
    );
    yield r'prestataire_id';
    yield serializers.serialize(
      object.prestataireId,
      specifiedType: const FullType(String),
    );
    yield r'site_lat';
    yield serializers.serialize(
      object.siteLat,
      specifiedType: const FullType(double),
    );
    yield r'site_lon';
    yield serializers.serialize(
      object.siteLon,
      specifiedType: const FullType(double),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ArretPreProvisionne object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ArretPreProvisionneBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.arretId = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'empreinte_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.empreinteCode = valueDes;
          break;
        case r'empreinte_jeton':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.empreinteJeton = valueDes;
          break;
        case r'montant_avance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantAvance = valueDes;
          break;
        case r'photo_exigee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.photoExigee = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prestataireId = valueDes;
          break;
        case r'site_lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.siteLat = valueDes;
          break;
        case r'site_lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.siteLon = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ArretPreProvisionne deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ArretPreProvisionneBuilder();
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


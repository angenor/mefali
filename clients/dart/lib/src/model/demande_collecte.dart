//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/mode_collecte.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_collecte.g.dart';

/// Corps de la demande de collecte (partie `demande` JSON du multipart).
///
/// Properties:
/// * [code] - Code à 4 chiffres saisi (mode `code_secours`).
/// * [horodatageLocal] - Horodatage local de l'action.
/// * [jeton] - Jeton lu dans le QR (mode `scan_qr`).
/// * [mode] - Scan du QR ou saisie du code de secours.
/// * [positionLat] - Position capturée du coursier.
/// * [positionLon] - Position capturée du coursier.
/// * [uuidClient] - Clé d'idempotence (UUIDv7 client, V).
@BuiltValue()
abstract class DemandeCollecte implements Built<DemandeCollecte, DemandeCollecteBuilder> {
  /// Code à 4 chiffres saisi (mode `code_secours`).
  @BuiltValueField(wireName: r'code')
  String? get code;

  /// Horodatage local de l'action.
  @BuiltValueField(wireName: r'horodatage_local')
  DateTime get horodatageLocal;

  /// Jeton lu dans le QR (mode `scan_qr`).
  @BuiltValueField(wireName: r'jeton')
  String? get jeton;

  /// Scan du QR ou saisie du code de secours.
  @BuiltValueField(wireName: r'mode')
  ModeCollecte get mode;
  // enum modeEnum {  scan_qr,  code_secours,  };

  /// Position capturée du coursier.
  @BuiltValueField(wireName: r'position_lat')
  double get positionLat;

  /// Position capturée du coursier.
  @BuiltValueField(wireName: r'position_lon')
  double get positionLon;

  /// Clé d'idempotence (UUIDv7 client, V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  DemandeCollecte._();

  factory DemandeCollecte([void updates(DemandeCollecteBuilder b)]) = _$DemandeCollecte;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeCollecteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeCollecte> get serializer => _$DemandeCollecteSerializer();
}

class _$DemandeCollecteSerializer implements PrimitiveSerializer<DemandeCollecte> {
  @override
  final Iterable<Type> types = const [DemandeCollecte, _$DemandeCollecte];

  @override
  final String wireName = r'DemandeCollecte';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeCollecte object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.code != null) {
      yield r'code';
      yield serializers.serialize(
        object.code,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'horodatage_local';
    yield serializers.serialize(
      object.horodatageLocal,
      specifiedType: const FullType(DateTime),
    );
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
      specifiedType: const FullType(ModeCollecte),
    );
    yield r'position_lat';
    yield serializers.serialize(
      object.positionLat,
      specifiedType: const FullType(double),
    );
    yield r'position_lon';
    yield serializers.serialize(
      object.positionLon,
      specifiedType: const FullType(double),
    );
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeCollecte object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeCollecteBuilder result,
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
        case r'horodatage_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.horodatageLocal = valueDes;
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
            specifiedType: const FullType(ModeCollecte),
          ) as ModeCollecte;
          result.mode = valueDes;
          break;
        case r'position_lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.positionLat = valueDes;
          break;
        case r'position_lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.positionLon = valueDes;
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
  DemandeCollecte deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeCollecteBuilder();
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


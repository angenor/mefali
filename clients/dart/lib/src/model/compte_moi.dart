//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/etat_role_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'compte_moi.g.dart';

/// Compte courant et l'état de TOUS ses rôles (contrat `CompteMoi`).
///
/// Properties:
/// * [creeLe] - Création du compte.
/// * [id] - Identifiant du compte.
/// * [roles] - Rôles et leurs statuts (tous, pas seulement les valides).
/// * [telephoneE164] - Identité Mefali — aucune donnée nominative au MVP.
/// * [zoneId] - Zone de rattachement.
@BuiltValue()
abstract class CompteMoi implements Built<CompteMoi, CompteMoiBuilder> {
  /// Création du compte.
  @BuiltValueField(wireName: r'cree_le')
  DateTime get creeLe;

  /// Identifiant du compte.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Rôles et leurs statuts (tous, pas seulement les valides).
  @BuiltValueField(wireName: r'roles')
  BuiltList<EtatRoleDto> get roles;

  /// Identité Mefali — aucune donnée nominative au MVP.
  @BuiltValueField(wireName: r'telephone_e164')
  String get telephoneE164;

  /// Zone de rattachement.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  CompteMoi._();

  factory CompteMoi([void updates(CompteMoiBuilder b)]) = _$CompteMoi;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CompteMoiBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CompteMoi> get serializer => _$CompteMoiSerializer();
}

class _$CompteMoiSerializer implements PrimitiveSerializer<CompteMoi> {
  @override
  final Iterable<Type> types = const [CompteMoi, _$CompteMoi];

  @override
  final String wireName = r'CompteMoi';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CompteMoi object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'cree_le';
    yield serializers.serialize(
      object.creeLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'roles';
    yield serializers.serialize(
      object.roles,
      specifiedType: const FullType(BuiltList, [FullType(EtatRoleDto)]),
    );
    yield r'telephone_e164';
    yield serializers.serialize(
      object.telephoneE164,
      specifiedType: const FullType(String),
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
    CompteMoi object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CompteMoiBuilder result,
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
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'roles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(EtatRoleDto)]),
          ) as BuiltList<EtatRoleDto>;
          result.roles.replace(valueDes);
          break;
        case r'telephone_e164':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.telephoneE164 = valueDes;
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
  CompteMoi deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CompteMoiBuilder();
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


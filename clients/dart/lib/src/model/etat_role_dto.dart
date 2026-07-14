//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'etat_role_dto.g.dart';

/// État d'un rôle (contrat).
///
/// Properties:
/// * [decideLe] - Horodatage de la dernière décision.
/// * [motif] - Motif de la dernière décision admin.
/// * [role] - Rôle concerné.
/// * [statut] - Statut courant.
@BuiltValue()
abstract class EtatRoleDto implements Built<EtatRoleDto, EtatRoleDtoBuilder> {
  /// Horodatage de la dernière décision.
  @BuiltValueField(wireName: r'decide_le')
  DateTime? get decideLe;

  /// Motif de la dernière décision admin.
  @BuiltValueField(wireName: r'motif')
  String? get motif;

  /// Rôle concerné.
  @BuiltValueField(wireName: r'role')
  String get role;

  /// Statut courant.
  @BuiltValueField(wireName: r'statut')
  String get statut;

  EtatRoleDto._();

  factory EtatRoleDto([void updates(EtatRoleDtoBuilder b)]) = _$EtatRoleDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EtatRoleDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EtatRoleDto> get serializer => _$EtatRoleDtoSerializer();
}

class _$EtatRoleDtoSerializer implements PrimitiveSerializer<EtatRoleDto> {
  @override
  final Iterable<Type> types = const [EtatRoleDto, _$EtatRoleDto];

  @override
  final String wireName = r'EtatRoleDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EtatRoleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.decideLe != null) {
      yield r'decide_le';
      yield serializers.serialize(
        object.decideLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.motif != null) {
      yield r'motif';
      yield serializers.serialize(
        object.motif,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(String),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EtatRoleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EtatRoleDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'decide_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.decideLe = valueDes;
          break;
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motif = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.role = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statut = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EtatRoleDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EtatRoleDtoBuilder();
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


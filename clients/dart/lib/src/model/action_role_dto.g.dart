// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_role_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ActionRoleDto _$attribuer = const ActionRoleDto._('attribuer');
const ActionRoleDto _$valider = const ActionRoleDto._('valider');
const ActionRoleDto _$refuser = const ActionRoleDto._('refuser');
const ActionRoleDto _$suspendre = const ActionRoleDto._('suspendre');
const ActionRoleDto _$retablir = const ActionRoleDto._('retablir');

ActionRoleDto _$valueOf(String name) {
  switch (name) {
    case 'attribuer':
      return _$attribuer;
    case 'valider':
      return _$valider;
    case 'refuser':
      return _$refuser;
    case 'suspendre':
      return _$suspendre;
    case 'retablir':
      return _$retablir;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ActionRoleDto> _$values =
    BuiltSet<ActionRoleDto>(const <ActionRoleDto>[
  _$attribuer,
  _$valider,
  _$refuser,
  _$suspendre,
  _$retablir,
]);

class _$ActionRoleDtoMeta {
  const _$ActionRoleDtoMeta();
  ActionRoleDto get attribuer => _$attribuer;
  ActionRoleDto get valider => _$valider;
  ActionRoleDto get refuser => _$refuser;
  ActionRoleDto get suspendre => _$suspendre;
  ActionRoleDto get retablir => _$retablir;
  ActionRoleDto valueOf(String name) => _$valueOf(name);
  BuiltSet<ActionRoleDto> get values => _$values;
}

abstract class _$ActionRoleDtoMixin {
  // ignore: non_constant_identifier_names
  _$ActionRoleDtoMeta get ActionRoleDto => const _$ActionRoleDtoMeta();
}

Serializer<ActionRoleDto> _$actionRoleDtoSerializer =
    _$ActionRoleDtoSerializer();

class _$ActionRoleDtoSerializer implements PrimitiveSerializer<ActionRoleDto> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'attribuer': 'attribuer',
    'valider': 'valider',
    'refuser': 'refuser',
    'suspendre': 'suspendre',
    'retablir': 'retablir',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'attribuer': 'attribuer',
    'valider': 'valider',
    'refuser': 'refuser',
    'suspendre': 'suspendre',
    'retablir': 'retablir',
  };

  @override
  final Iterable<Type> types = const <Type>[ActionRoleDto];
  @override
  final String wireName = 'ActionRoleDto';

  @override
  Object serialize(Serializers serializers, ActionRoleDto object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ActionRoleDto deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ActionRoleDto.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

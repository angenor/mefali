//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'action_role_dto.g.dart';

class ActionRoleDto extends EnumClass {

  /// Action d'administration sur un rôle (contrat).
  @BuiltValueEnumConst(wireName: r'attribuer')
  static const ActionRoleDto attribuer = _$attribuer;
  /// Action d'administration sur un rôle (contrat).
  @BuiltValueEnumConst(wireName: r'valider')
  static const ActionRoleDto valider = _$valider;
  /// Action d'administration sur un rôle (contrat).
  @BuiltValueEnumConst(wireName: r'refuser')
  static const ActionRoleDto refuser = _$refuser;
  /// Action d'administration sur un rôle (contrat).
  @BuiltValueEnumConst(wireName: r'suspendre')
  static const ActionRoleDto suspendre = _$suspendre;
  /// Action d'administration sur un rôle (contrat).
  @BuiltValueEnumConst(wireName: r'retablir')
  static const ActionRoleDto retablir = _$retablir;

  static Serializer<ActionRoleDto> get serializer => _$actionRoleDtoSerializer;

  const ActionRoleDto._(String name): super(name);

  static BuiltSet<ActionRoleDto> get values => _$values;
  static ActionRoleDto valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ActionRoleDtoMixin = Object with _$ActionRoleDtoMixin;


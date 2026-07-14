//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'forcage_dto.g.dart';

class ForcageDto extends EnumClass {

  /// Mode de forçage (contrat) — mappé sur [`zones::Forcage`].
  @BuiltValueEnumConst(wireName: r'automatique')
  static const ForcageDto automatique = _$automatique;
  /// Mode de forçage (contrat) — mappé sur [`zones::Forcage`].
  @BuiltValueEnumConst(wireName: r'force_actif')
  static const ForcageDto forceActif = _$forceActif;
  /// Mode de forçage (contrat) — mappé sur [`zones::Forcage`].
  @BuiltValueEnumConst(wireName: r'force_inactif')
  static const ForcageDto forceInactif = _$forceInactif;

  static Serializer<ForcageDto> get serializer => _$forcageDtoSerializer;

  const ForcageDto._(String name): super(name);

  static BuiltSet<ForcageDto> get values => _$values;
  static ForcageDto valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ForcageDtoMixin = Object with _$ForcageDtoMixin;


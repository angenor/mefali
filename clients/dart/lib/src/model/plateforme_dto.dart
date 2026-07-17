//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plateforme_dto.g.dart';

class PlateformeDto extends EnumClass {

  /// Plateforme de l'appareil (contrat).
  @BuiltValueEnumConst(wireName: r'android')
  static const PlateformeDto android = _$android;
  /// Plateforme de l'appareil (contrat).
  @BuiltValueEnumConst(wireName: r'ios')
  static const PlateformeDto ios = _$ios;

  static Serializer<PlateformeDto> get serializer => _$plateformeDtoSerializer;

  const PlateformeDto._(String name): super(name);

  static BuiltSet<PlateformeDto> get values => _$values;
  static PlateformeDto valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class PlateformeDtoMixin = Object with _$PlateformeDtoMixin;


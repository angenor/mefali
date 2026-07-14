// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plateforme_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlateformeDto _$android = const PlateformeDto._('android');
const PlateformeDto _$ios = const PlateformeDto._('ios');

PlateformeDto _$valueOf(String name) {
  switch (name) {
    case 'android':
      return _$android;
    case 'ios':
      return _$ios;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlateformeDto> _$values =
    BuiltSet<PlateformeDto>(const <PlateformeDto>[
  _$android,
  _$ios,
]);

class _$PlateformeDtoMeta {
  const _$PlateformeDtoMeta();
  PlateformeDto get android => _$android;
  PlateformeDto get ios => _$ios;
  PlateformeDto valueOf(String name) => _$valueOf(name);
  BuiltSet<PlateformeDto> get values => _$values;
}

abstract class _$PlateformeDtoMixin {
  // ignore: non_constant_identifier_names
  _$PlateformeDtoMeta get PlateformeDto => const _$PlateformeDtoMeta();
}

Serializer<PlateformeDto> _$plateformeDtoSerializer =
    _$PlateformeDtoSerializer();

class _$PlateformeDtoSerializer implements PrimitiveSerializer<PlateformeDto> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'android': 'android',
    'ios': 'ios',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'android': 'android',
    'ios': 'ios',
  };

  @override
  final Iterable<Type> types = const <Type>[PlateformeDto];
  @override
  final String wireName = 'PlateformeDto';

  @override
  Object serialize(Serializers serializers, PlateformeDto object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PlateformeDto deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PlateformeDto.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

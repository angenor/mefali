// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forcage_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ForcageDto _$automatique = const ForcageDto._('automatique');
const ForcageDto _$forceActif = const ForcageDto._('forceActif');
const ForcageDto _$forceInactif = const ForcageDto._('forceInactif');

ForcageDto _$valueOf(String name) {
  switch (name) {
    case 'automatique':
      return _$automatique;
    case 'forceActif':
      return _$forceActif;
    case 'forceInactif':
      return _$forceInactif;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ForcageDto> _$values = BuiltSet<ForcageDto>(const <ForcageDto>[
  _$automatique,
  _$forceActif,
  _$forceInactif,
]);

class _$ForcageDtoMeta {
  const _$ForcageDtoMeta();
  ForcageDto get automatique => _$automatique;
  ForcageDto get forceActif => _$forceActif;
  ForcageDto get forceInactif => _$forceInactif;
  ForcageDto valueOf(String name) => _$valueOf(name);
  BuiltSet<ForcageDto> get values => _$values;
}

abstract class _$ForcageDtoMixin {
  // ignore: non_constant_identifier_names
  _$ForcageDtoMeta get ForcageDto => const _$ForcageDtoMeta();
}

Serializer<ForcageDto> _$forcageDtoSerializer = _$ForcageDtoSerializer();

class _$ForcageDtoSerializer implements PrimitiveSerializer<ForcageDto> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'automatique': 'automatique',
    'forceActif': 'force_actif',
    'forceInactif': 'force_inactif',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'automatique': 'automatique',
    'force_actif': 'forceActif',
    'force_inactif': 'forceInactif',
  };

  @override
  final Iterable<Type> types = const <Type>[ForcageDto];
  @override
  final String wireName = 'ForcageDto';

  @override
  Object serialize(Serializers serializers, ForcageDto object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ForcageDto deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ForcageDto.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_bascule.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SourceBascule _$vendeur = const SourceBascule._('vendeur');
const SourceBascule _$coursier = const SourceBascule._('coursier');
const SourceBascule _$admin = const SourceBascule._('admin');

SourceBascule _$valueOf(String name) {
  switch (name) {
    case 'vendeur':
      return _$vendeur;
    case 'coursier':
      return _$coursier;
    case 'admin':
      return _$admin;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SourceBascule> _$values =
    BuiltSet<SourceBascule>(const <SourceBascule>[
  _$vendeur,
  _$coursier,
  _$admin,
]);

class _$SourceBasculeMeta {
  const _$SourceBasculeMeta();
  SourceBascule get vendeur => _$vendeur;
  SourceBascule get coursier => _$coursier;
  SourceBascule get admin => _$admin;
  SourceBascule valueOf(String name) => _$valueOf(name);
  BuiltSet<SourceBascule> get values => _$values;
}

abstract class _$SourceBasculeMixin {
  // ignore: non_constant_identifier_names
  _$SourceBasculeMeta get SourceBascule => const _$SourceBasculeMeta();
}

Serializer<SourceBascule> _$sourceBasculeSerializer =
    _$SourceBasculeSerializer();

class _$SourceBasculeSerializer implements PrimitiveSerializer<SourceBascule> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'vendeur': 'vendeur',
    'coursier': 'coursier',
    'admin': 'admin',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'vendeur': 'vendeur',
    'coursier': 'coursier',
    'admin': 'admin',
  };

  @override
  final Iterable<Type> types = const <Type>[SourceBascule];
  @override
  final String wireName = 'SourceBascule';

  @override
  Object serialize(Serializers serializers, SourceBascule object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  SourceBascule deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      SourceBascule.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

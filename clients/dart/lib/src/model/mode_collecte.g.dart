// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mode_collecte.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ModeCollecte _$scanQr = const ModeCollecte._('scanQr');
const ModeCollecte _$codeSecours = const ModeCollecte._('codeSecours');

ModeCollecte _$valueOf(String name) {
  switch (name) {
    case 'scanQr':
      return _$scanQr;
    case 'codeSecours':
      return _$codeSecours;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ModeCollecte> _$values =
    BuiltSet<ModeCollecte>(const <ModeCollecte>[
  _$scanQr,
  _$codeSecours,
]);

class _$ModeCollecteMeta {
  const _$ModeCollecteMeta();
  ModeCollecte get scanQr => _$scanQr;
  ModeCollecte get codeSecours => _$codeSecours;
  ModeCollecte valueOf(String name) => _$valueOf(name);
  BuiltSet<ModeCollecte> get values => _$values;
}

abstract class _$ModeCollecteMixin {
  // ignore: non_constant_identifier_names
  _$ModeCollecteMeta get ModeCollecte => const _$ModeCollecteMeta();
}

Serializer<ModeCollecte> _$modeCollecteSerializer = _$ModeCollecteSerializer();

class _$ModeCollecteSerializer implements PrimitiveSerializer<ModeCollecte> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'scanQr': 'scan_qr',
    'codeSecours': 'code_secours',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'scan_qr': 'scanQr',
    'code_secours': 'codeSecours',
  };

  @override
  final Iterable<Type> types = const <Type>[ModeCollecte];
  @override
  final String wireName = 'ModeCollecte';

  @override
  Object serialize(Serializers serializers, ModeCollecte object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ModeCollecte deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ModeCollecte.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

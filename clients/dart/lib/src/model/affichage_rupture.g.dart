// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'affichage_rupture.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AffichageRupture _$grise = const AffichageRupture._('grise');
const AffichageRupture _$masque = const AffichageRupture._('masque');

AffichageRupture _$valueOf(String name) {
  switch (name) {
    case 'grise':
      return _$grise;
    case 'masque':
      return _$masque;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AffichageRupture> _$values =
    BuiltSet<AffichageRupture>(const <AffichageRupture>[
  _$grise,
  _$masque,
]);

class _$AffichageRuptureMeta {
  const _$AffichageRuptureMeta();
  AffichageRupture get grise => _$grise;
  AffichageRupture get masque => _$masque;
  AffichageRupture valueOf(String name) => _$valueOf(name);
  BuiltSet<AffichageRupture> get values => _$values;
}

abstract class _$AffichageRuptureMixin {
  // ignore: non_constant_identifier_names
  _$AffichageRuptureMeta get AffichageRupture => const _$AffichageRuptureMeta();
}

Serializer<AffichageRupture> _$affichageRuptureSerializer =
    _$AffichageRuptureSerializer();

class _$AffichageRuptureSerializer
    implements PrimitiveSerializer<AffichageRupture> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'grise': 'grise',
    'masque': 'masque',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'grise': 'grise',
    'masque': 'masque',
  };

  @override
  final Iterable<Type> types = const <Type>[AffichageRupture];
  @override
  final String wireName = 'AffichageRupture';

  @override
  Object serialize(Serializers serializers, AffichageRupture object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AffichageRupture deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AffichageRupture.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

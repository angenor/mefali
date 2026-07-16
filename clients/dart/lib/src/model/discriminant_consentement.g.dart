// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discriminant_consentement.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DiscriminantConsentement _$consentementRequis =
    const DiscriminantConsentement._('consentementRequis');

DiscriminantConsentement _$valueOf(String name) {
  switch (name) {
    case 'consentementRequis':
      return _$consentementRequis;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DiscriminantConsentement> _$values =
    BuiltSet<DiscriminantConsentement>(const <DiscriminantConsentement>[
  _$consentementRequis,
]);

class _$DiscriminantConsentementMeta {
  const _$DiscriminantConsentementMeta();
  DiscriminantConsentement get consentementRequis => _$consentementRequis;
  DiscriminantConsentement valueOf(String name) => _$valueOf(name);
  BuiltSet<DiscriminantConsentement> get values => _$values;
}

abstract class _$DiscriminantConsentementMixin {
  // ignore: non_constant_identifier_names
  _$DiscriminantConsentementMeta get DiscriminantConsentement =>
      const _$DiscriminantConsentementMeta();
}

Serializer<DiscriminantConsentement> _$discriminantConsentementSerializer =
    _$DiscriminantConsentementSerializer();

class _$DiscriminantConsentementSerializer
    implements PrimitiveSerializer<DiscriminantConsentement> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'consentementRequis': 'consentement_requis',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'consentement_requis': 'consentementRequis',
  };

  @override
  final Iterable<Type> types = const <Type>[DiscriminantConsentement];
  @override
  final String wireName = 'DiscriminantConsentement';

  @override
  Object serialize(Serializers serializers, DiscriminantConsentement object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DiscriminantConsentement deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DiscriminantConsentement.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

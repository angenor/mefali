// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statut_prestataire.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const StatutPrestataire _$prospect = const StatutPrestataire._('prospect');
const StatutPrestataire _$agree = const StatutPrestataire._('agree');
const StatutPrestataire _$suspendu = const StatutPrestataire._('suspendu');

StatutPrestataire _$valueOf(String name) {
  switch (name) {
    case 'prospect':
      return _$prospect;
    case 'agree':
      return _$agree;
    case 'suspendu':
      return _$suspendu;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<StatutPrestataire> _$values =
    BuiltSet<StatutPrestataire>(const <StatutPrestataire>[
  _$prospect,
  _$agree,
  _$suspendu,
]);

class _$StatutPrestataireMeta {
  const _$StatutPrestataireMeta();
  StatutPrestataire get prospect => _$prospect;
  StatutPrestataire get agree => _$agree;
  StatutPrestataire get suspendu => _$suspendu;
  StatutPrestataire valueOf(String name) => _$valueOf(name);
  BuiltSet<StatutPrestataire> get values => _$values;
}

abstract class _$StatutPrestataireMixin {
  // ignore: non_constant_identifier_names
  _$StatutPrestataireMeta get StatutPrestataire =>
      const _$StatutPrestataireMeta();
}

Serializer<StatutPrestataire> _$statutPrestataireSerializer =
    _$StatutPrestataireSerializer();

class _$StatutPrestataireSerializer
    implements PrimitiveSerializer<StatutPrestataire> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'prospect': 'prospect',
    'agree': 'agree',
    'suspendu': 'suspendu',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'prospect': 'prospect',
    'agree': 'agree',
    'suspendu': 'suspendu',
  };

  @override
  final Iterable<Type> types = const <Type>[StatutPrestataire];
  @override
  final String wireName = 'StatutPrestataire';

  @override
  Object serialize(Serializers serializers, StatutPrestataire object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  StatutPrestataire deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      StatutPrestataire.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statut_boutique.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const StatutBoutique _$ouvert = const StatutBoutique._('ouvert');
const StatutBoutique _$ferme = const StatutBoutique._('ferme');
const StatutBoutique _$fermeJournee = const StatutBoutique._('fermeJournee');
const StatutBoutique _$enPause = const StatutBoutique._('enPause');

StatutBoutique _$valueOf(String name) {
  switch (name) {
    case 'ouvert':
      return _$ouvert;
    case 'ferme':
      return _$ferme;
    case 'fermeJournee':
      return _$fermeJournee;
    case 'enPause':
      return _$enPause;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<StatutBoutique> _$values =
    BuiltSet<StatutBoutique>(const <StatutBoutique>[
  _$ouvert,
  _$ferme,
  _$fermeJournee,
  _$enPause,
]);

class _$StatutBoutiqueMeta {
  const _$StatutBoutiqueMeta();
  StatutBoutique get ouvert => _$ouvert;
  StatutBoutique get ferme => _$ferme;
  StatutBoutique get fermeJournee => _$fermeJournee;
  StatutBoutique get enPause => _$enPause;
  StatutBoutique valueOf(String name) => _$valueOf(name);
  BuiltSet<StatutBoutique> get values => _$values;
}

abstract class _$StatutBoutiqueMixin {
  // ignore: non_constant_identifier_names
  _$StatutBoutiqueMeta get StatutBoutique => const _$StatutBoutiqueMeta();
}

Serializer<StatutBoutique> _$statutBoutiqueSerializer =
    _$StatutBoutiqueSerializer();

class _$StatutBoutiqueSerializer
    implements PrimitiveSerializer<StatutBoutique> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ouvert': 'ouvert',
    'ferme': 'ferme',
    'fermeJournee': 'ferme_journee',
    'enPause': 'en_pause',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ouvert': 'ouvert',
    'ferme': 'ferme',
    'ferme_journee': 'fermeJournee',
    'en_pause': 'enPause',
  };

  @override
  final Iterable<Type> types = const <Type>[StatutBoutique];
  @override
  final String wireName = 'StatutBoutique';

  @override
  Object serialize(Serializers serializers, StatutBoutique object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  StatutBoutique deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      StatutBoutique.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

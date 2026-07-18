// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_boutique_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ActionBoutiqueDto _$ouvrir = const ActionBoutiqueDto._('ouvrir');
const ActionBoutiqueDto _$fermer = const ActionBoutiqueDto._('fermer');
const ActionBoutiqueDto _$mettreEnPause =
    const ActionBoutiqueDto._('mettreEnPause');
const ActionBoutiqueDto _$prolongerPause =
    const ActionBoutiqueDto._('prolongerPause');
const ActionBoutiqueDto _$fermerPourLaJournee =
    const ActionBoutiqueDto._('fermerPourLaJournee');

ActionBoutiqueDto _$valueOf(String name) {
  switch (name) {
    case 'ouvrir':
      return _$ouvrir;
    case 'fermer':
      return _$fermer;
    case 'mettreEnPause':
      return _$mettreEnPause;
    case 'prolongerPause':
      return _$prolongerPause;
    case 'fermerPourLaJournee':
      return _$fermerPourLaJournee;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ActionBoutiqueDto> _$values =
    BuiltSet<ActionBoutiqueDto>(const <ActionBoutiqueDto>[
  _$ouvrir,
  _$fermer,
  _$mettreEnPause,
  _$prolongerPause,
  _$fermerPourLaJournee,
]);

class _$ActionBoutiqueDtoMeta {
  const _$ActionBoutiqueDtoMeta();
  ActionBoutiqueDto get ouvrir => _$ouvrir;
  ActionBoutiqueDto get fermer => _$fermer;
  ActionBoutiqueDto get mettreEnPause => _$mettreEnPause;
  ActionBoutiqueDto get prolongerPause => _$prolongerPause;
  ActionBoutiqueDto get fermerPourLaJournee => _$fermerPourLaJournee;
  ActionBoutiqueDto valueOf(String name) => _$valueOf(name);
  BuiltSet<ActionBoutiqueDto> get values => _$values;
}

abstract class _$ActionBoutiqueDtoMixin {
  // ignore: non_constant_identifier_names
  _$ActionBoutiqueDtoMeta get ActionBoutiqueDto =>
      const _$ActionBoutiqueDtoMeta();
}

Serializer<ActionBoutiqueDto> _$actionBoutiqueDtoSerializer =
    _$ActionBoutiqueDtoSerializer();

class _$ActionBoutiqueDtoSerializer
    implements PrimitiveSerializer<ActionBoutiqueDto> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ouvrir': 'ouvrir',
    'fermer': 'fermer',
    'mettreEnPause': 'mettre_en_pause',
    'prolongerPause': 'prolonger_pause',
    'fermerPourLaJournee': 'fermer_pour_la_journee',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ouvrir': 'ouvrir',
    'fermer': 'fermer',
    'mettre_en_pause': 'mettreEnPause',
    'prolonger_pause': 'prolongerPause',
    'fermer_pour_la_journee': 'fermerPourLaJournee',
  };

  @override
  final Iterable<Type> types = const <Type>[ActionBoutiqueDto];
  @override
  final String wireName = 'ActionBoutiqueDto';

  @override
  Object serialize(Serializers serializers, ActionBoutiqueDto object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ActionBoutiqueDto deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ActionBoutiqueDto.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

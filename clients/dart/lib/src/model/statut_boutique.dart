//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'statut_boutique.g.dart';

class StatutBoutique extends EnumClass {

  /// Statut de boutique DÉCLARÉ (FR-030).
  @BuiltValueEnumConst(wireName: r'ouvert')
  static const StatutBoutique ouvert = _$ouvert;
  /// Statut de boutique DÉCLARÉ (FR-030).
  @BuiltValueEnumConst(wireName: r'ferme')
  static const StatutBoutique ferme = _$ferme;
  /// Statut de boutique DÉCLARÉ (FR-030).
  @BuiltValueEnumConst(wireName: r'ferme_journee')
  static const StatutBoutique fermeJournee = _$fermeJournee;
  /// Statut de boutique DÉCLARÉ (FR-030).
  @BuiltValueEnumConst(wireName: r'en_pause')
  static const StatutBoutique enPause = _$enPause;

  static Serializer<StatutBoutique> get serializer => _$statutBoutiqueSerializer;

  const StatutBoutique._(String name): super(name);

  static BuiltSet<StatutBoutique> get values => _$values;
  static StatutBoutique valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class StatutBoutiqueMixin = Object with _$StatutBoutiqueMixin;


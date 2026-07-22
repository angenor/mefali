//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'action_boutique_dto.g.dart';

class ActionBoutiqueDto extends EnumClass {

  /// Geste de boutique (FR-033) — toujours une DÉCISION.
  @BuiltValueEnumConst(wireName: r'ouvrir')
  static const ActionBoutiqueDto ouvrir = _$ouvrir;
  /// Geste de boutique (FR-033) — toujours une DÉCISION.
  @BuiltValueEnumConst(wireName: r'fermer')
  static const ActionBoutiqueDto fermer = _$fermer;
  /// Geste de boutique (FR-033) — toujours une DÉCISION.
  @BuiltValueEnumConst(wireName: r'mettre_en_pause')
  static const ActionBoutiqueDto mettreEnPause = _$mettreEnPause;
  /// Geste de boutique (FR-033) — toujours une DÉCISION.
  @BuiltValueEnumConst(wireName: r'prolonger_pause')
  static const ActionBoutiqueDto prolongerPause = _$prolongerPause;
  /// Geste de boutique (FR-033) — toujours une DÉCISION.
  @BuiltValueEnumConst(wireName: r'fermer_pour_la_journee')
  static const ActionBoutiqueDto fermerPourLaJournee = _$fermerPourLaJournee;

  static Serializer<ActionBoutiqueDto> get serializer => _$actionBoutiqueDtoSerializer;

  const ActionBoutiqueDto._(String name): super(name);

  static BuiltSet<ActionBoutiqueDto> get values => _$values;
  static ActionBoutiqueDto valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ActionBoutiqueDtoMixin = Object with _$ActionBoutiqueDtoMixin;


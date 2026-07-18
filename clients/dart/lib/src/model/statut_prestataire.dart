//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'statut_prestataire.g.dart';

class StatutPrestataire extends EnumClass {

  /// Statut du cycle de vie (FR-004).
  @BuiltValueEnumConst(wireName: r'prospect')
  static const StatutPrestataire prospect = _$prospect;
  /// Statut du cycle de vie (FR-004).
  @BuiltValueEnumConst(wireName: r'agree')
  static const StatutPrestataire agree = _$agree;
  /// Statut du cycle de vie (FR-004).
  @BuiltValueEnumConst(wireName: r'suspendu')
  static const StatutPrestataire suspendu = _$suspendu;

  static Serializer<StatutPrestataire> get serializer => _$statutPrestataireSerializer;

  const StatutPrestataire._(String name): super(name);

  static BuiltSet<StatutPrestataire> get values => _$values;
  static StatutPrestataire valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class StatutPrestataireMixin = Object with _$StatutPrestataireMixin;


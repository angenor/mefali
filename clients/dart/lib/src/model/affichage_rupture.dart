//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'affichage_rupture.g.dart';

class AffichageRupture extends EnumClass {

  /// Mode de rendu des articles en rupture (paramètre de catégorie — FR-050).
  @BuiltValueEnumConst(wireName: r'grise')
  static const AffichageRupture grise = _$grise;
  /// Mode de rendu des articles en rupture (paramètre de catégorie — FR-050).
  @BuiltValueEnumConst(wireName: r'masque')
  static const AffichageRupture masque = _$masque;

  static Serializer<AffichageRupture> get serializer => _$affichageRuptureSerializer;

  const AffichageRupture._(String name): super(name);

  static BuiltSet<AffichageRupture> get values => _$values;
  static AffichageRupture valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AffichageRuptureMixin = Object with _$AffichageRuptureMixin;


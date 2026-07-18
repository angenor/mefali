//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'source_bascule.g.dart';

class SourceBascule extends EnumClass {

  /// Source d'une bascule de disponibilité (FR-037).
  @BuiltValueEnumConst(wireName: r'vendeur')
  static const SourceBascule vendeur = _$vendeur;
  /// Source d'une bascule de disponibilité (FR-037).
  @BuiltValueEnumConst(wireName: r'coursier')
  static const SourceBascule coursier = _$coursier;
  /// Source d'une bascule de disponibilité (FR-037).
  @BuiltValueEnumConst(wireName: r'admin')
  static const SourceBascule admin = _$admin;

  static Serializer<SourceBascule> get serializer => _$sourceBasculeSerializer;

  const SourceBascule._(String name): super(name);

  static BuiltSet<SourceBascule> get values => _$values;
  static SourceBascule valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class SourceBasculeMixin = Object with _$SourceBasculeMixin;


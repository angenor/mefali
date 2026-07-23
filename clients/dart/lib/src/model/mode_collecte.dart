//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mode_collecte.g.dart';

class ModeCollecte extends EnumClass {

  /// Mode de collecte (contrat).
  @BuiltValueEnumConst(wireName: r'scan_qr')
  static const ModeCollecte scanQr = _$scanQr;
  /// Mode de collecte (contrat).
  @BuiltValueEnumConst(wireName: r'code_secours')
  static const ModeCollecte codeSecours = _$codeSecours;

  static Serializer<ModeCollecte> get serializer => _$modeCollecteSerializer;

  const ModeCollecte._(String name): super(name);

  static BuiltSet<ModeCollecte> get values => _$values;
  static ModeCollecte valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ModeCollecteMixin = Object with _$ModeCollecteMixin;


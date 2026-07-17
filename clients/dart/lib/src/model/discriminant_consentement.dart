//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'discriminant_consentement.g.dart';

class DiscriminantConsentement extends EnumClass {

  /// Discriminant de [`ConsentementRequisDto`].
  @BuiltValueEnumConst(wireName: r'consentement_requis')
  static const DiscriminantConsentement consentementRequis = _$consentementRequis;

  static Serializer<DiscriminantConsentement> get serializer => _$discriminantConsentementSerializer;

  const DiscriminantConsentement._(String name): super(name);

  static BuiltSet<DiscriminantConsentement> get values => _$values;
  static DiscriminantConsentement valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DiscriminantConsentementMixin = Object with _$DiscriminantConsentementMixin;


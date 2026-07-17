//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'discriminant_session.g.dart';

class DiscriminantSession extends EnumClass {

  /// Discriminant de [`SessionOuverteDto`] — une seule valeur possible.  Un type à UNE variante, et non un `String` : la valeur du discriminant ne peut alors pas diverger du schéma, et ce n'est pas à l'appelant de penser à l'écrire juste.
  @BuiltValueEnumConst(wireName: r'session')
  static const DiscriminantSession session = _$session;

  static Serializer<DiscriminantSession> get serializer => _$discriminantSessionSerializer;

  const DiscriminantSession._(String name): super(name);

  static BuiltSet<DiscriminantSession> get values => _$values;
  static DiscriminantSession valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DiscriminantSessionMixin = Object with _$DiscriminantSessionMixin;


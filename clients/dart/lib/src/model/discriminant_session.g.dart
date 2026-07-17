// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discriminant_session.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DiscriminantSession _$session = const DiscriminantSession._('session');

DiscriminantSession _$valueOf(String name) {
  switch (name) {
    case 'session':
      return _$session;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DiscriminantSession> _$values =
    BuiltSet<DiscriminantSession>(const <DiscriminantSession>[
  _$session,
]);

class _$DiscriminantSessionMeta {
  const _$DiscriminantSessionMeta();
  DiscriminantSession get session => _$session;
  DiscriminantSession valueOf(String name) => _$valueOf(name);
  BuiltSet<DiscriminantSession> get values => _$values;
}

abstract class _$DiscriminantSessionMixin {
  // ignore: non_constant_identifier_names
  _$DiscriminantSessionMeta get DiscriminantSession =>
      const _$DiscriminantSessionMeta();
}

Serializer<DiscriminantSession> _$discriminantSessionSerializer =
    _$DiscriminantSessionSerializer();

class _$DiscriminantSessionSerializer
    implements PrimitiveSerializer<DiscriminantSession> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'session': 'session',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'session': 'session',
  };

  @override
  final Iterable<Type> types = const <Type>[DiscriminantSession];
  @override
  final String wireName = 'DiscriminantSession';

  @override
  Object serialize(Serializers serializers, DiscriminantSession object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DiscriminantSession deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DiscriminantSession.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

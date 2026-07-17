//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_rafraichissement.g.dart';

/// Corps de `POST /auth/rafraichir`.
///
/// Properties:
/// * [rafraichissement] - Jeton de renouvellement opaque courant.
@BuiltValue()
abstract class DemandeRafraichissement implements Built<DemandeRafraichissement, DemandeRafraichissementBuilder> {
  /// Jeton de renouvellement opaque courant.
  @BuiltValueField(wireName: r'rafraichissement')
  String get rafraichissement;

  DemandeRafraichissement._();

  factory DemandeRafraichissement([void updates(DemandeRafraichissementBuilder b)]) = _$DemandeRafraichissement;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeRafraichissementBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeRafraichissement> get serializer => _$DemandeRafraichissementSerializer();
}

class _$DemandeRafraichissementSerializer implements PrimitiveSerializer<DemandeRafraichissement> {
  @override
  final Iterable<Type> types = const [DemandeRafraichissement, _$DemandeRafraichissement];

  @override
  final String wireName = r'DemandeRafraichissement';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeRafraichissement object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'rafraichissement';
    yield serializers.serialize(
      object.rafraichissement,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeRafraichissement object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeRafraichissementBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'rafraichissement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.rafraichissement = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeRafraichissement deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeRafraichissementBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


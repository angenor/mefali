//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'preuve_presence.g.dart';

/// Preuve « présence » — durée mesurée, trous exclus (FR-056).
///
/// Properties:
/// * [motifCle] - Pourquoi elle ne l'est pas — clé i18n.
/// * [ok] - Preuve réunie.
/// * [requis] - Durée exigée par la zone.
/// * [secondes] - Durée retenue (s), recalculée par le serveur.
@BuiltValue()
abstract class PreuvePresence implements Built<PreuvePresence, PreuvePresenceBuilder> {
  /// Pourquoi elle ne l'est pas — clé i18n.
  @BuiltValueField(wireName: r'motif_cle')
  String? get motifCle;

  /// Preuve réunie.
  @BuiltValueField(wireName: r'ok')
  bool get ok;

  /// Durée exigée par la zone.
  @BuiltValueField(wireName: r'requis')
  int get requis;

  /// Durée retenue (s), recalculée par le serveur.
  @BuiltValueField(wireName: r'secondes')
  int get secondes;

  PreuvePresence._();

  factory PreuvePresence([void updates(PreuvePresenceBuilder b)]) = _$PreuvePresence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PreuvePresenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PreuvePresence> get serializer => _$PreuvePresenceSerializer();
}

class _$PreuvePresenceSerializer implements PrimitiveSerializer<PreuvePresence> {
  @override
  final Iterable<Type> types = const [PreuvePresence, _$PreuvePresence];

  @override
  final String wireName = r'PreuvePresence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PreuvePresence object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.motifCle != null) {
      yield r'motif_cle';
      yield serializers.serialize(
        object.motifCle,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'ok';
    yield serializers.serialize(
      object.ok,
      specifiedType: const FullType(bool),
    );
    yield r'requis';
    yield serializers.serialize(
      object.requis,
      specifiedType: const FullType(int),
    );
    yield r'secondes';
    yield serializers.serialize(
      object.secondes,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PreuvePresence object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PreuvePresenceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motifCle = valueDes;
          break;
        case r'ok':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ok = valueDes;
          break;
        case r'requis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.requis = valueDes;
          break;
        case r'secondes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.secondes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PreuvePresence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PreuvePresenceBuilder();
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


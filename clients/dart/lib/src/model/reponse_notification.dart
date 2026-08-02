//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reponse_notification.g.dart';

/// Ce que le webhook répond — **toujours `200`, sauf signature invalide**.
///
/// Properties:
/// * [motif] - Pourquoi elle n'en a produit aucun : `rejeu`, `en_cours`, `orpheline`, `etat_incompatible`, `divergence`. Absent quand `traite` vaut `true`.
/// * [traite] - Vrai si la notification a produit un effet.
@BuiltValue()
abstract class ReponseNotification implements Built<ReponseNotification, ReponseNotificationBuilder> {
  /// Pourquoi elle n'en a produit aucun : `rejeu`, `en_cours`, `orpheline`, `etat_incompatible`, `divergence`. Absent quand `traite` vaut `true`.
  @BuiltValueField(wireName: r'motif')
  String? get motif;

  /// Vrai si la notification a produit un effet.
  @BuiltValueField(wireName: r'traite')
  bool get traite;

  ReponseNotification._();

  factory ReponseNotification([void updates(ReponseNotificationBuilder b)]) = _$ReponseNotification;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReponseNotificationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReponseNotification> get serializer => _$ReponseNotificationSerializer();
}

class _$ReponseNotificationSerializer implements PrimitiveSerializer<ReponseNotification> {
  @override
  final Iterable<Type> types = const [ReponseNotification, _$ReponseNotification];

  @override
  final String wireName = r'ReponseNotification';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReponseNotification object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.motif != null) {
      yield r'motif';
      yield serializers.serialize(
        object.motif,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'traite';
    yield serializers.serialize(
      object.traite,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReponseNotification object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReponseNotificationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motif = valueDes;
          break;
        case r'traite':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.traite = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReponseNotification deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReponseNotificationBuilder();
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


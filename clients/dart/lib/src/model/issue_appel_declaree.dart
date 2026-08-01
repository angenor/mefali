//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'issue_appel_declaree.g.dart';

/// Corps de mise à jour de l'issue déclarée d'un appel.
///
/// Properties:
/// * [issue] - `inconnue` | `sans_reponse` | `repondu`.
/// * [uuidClient] - Clé d'idempotence de l'appel à mettre à jour.
@BuiltValue()
abstract class IssueAppelDeclaree implements Built<IssueAppelDeclaree, IssueAppelDeclareeBuilder> {
  /// `inconnue` | `sans_reponse` | `repondu`.
  @BuiltValueField(wireName: r'issue')
  String get issue;

  /// Clé d'idempotence de l'appel à mettre à jour.
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  IssueAppelDeclaree._();

  factory IssueAppelDeclaree([void updates(IssueAppelDeclareeBuilder b)]) = _$IssueAppelDeclaree;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IssueAppelDeclareeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IssueAppelDeclaree> get serializer => _$IssueAppelDeclareeSerializer();
}

class _$IssueAppelDeclareeSerializer implements PrimitiveSerializer<IssueAppelDeclaree> {
  @override
  final Iterable<Type> types = const [IssueAppelDeclaree, _$IssueAppelDeclaree];

  @override
  final String wireName = r'IssueAppelDeclaree';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IssueAppelDeclaree object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'issue';
    yield serializers.serialize(
      object.issue,
      specifiedType: const FullType(String),
    );
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IssueAppelDeclaree object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IssueAppelDeclareeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.issue = valueDes;
          break;
        case r'uuid_client':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.uuidClient = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IssueAppelDeclaree deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IssueAppelDeclareeBuilder();
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


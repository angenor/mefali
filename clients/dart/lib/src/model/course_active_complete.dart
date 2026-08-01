//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/remise_preprovisionnee.dart';
import 'package:mefali_api_client/src/model/arret_course.dart';
import 'package:mefali_api_client/src/model/client_course.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'course_active_complete.g.dart';

/// La course active, pré-provisionnée pour fonctionner hors ligne.
///
/// Properties:
/// * [arrets] - Arrêts de collecte, dans l'ordre de passage.
/// * [client] - Le client et son repère.
/// * [commandeId] - Commande portée.
/// * [devise] - Devise ISO 4217.
/// * [etat] - `assignee` | `en_collecte` | `en_livraison`.
/// * [livraisonId] - Livraison active.
/// * [remise] - De quoi confirmer la remise hors ligne.
@BuiltValue()
abstract class CourseActiveComplete implements Built<CourseActiveComplete, CourseActiveCompleteBuilder> {
  /// Arrêts de collecte, dans l'ordre de passage.
  @BuiltValueField(wireName: r'arrets')
  BuiltList<ArretCourse> get arrets;

  /// Le client et son repère.
  @BuiltValueField(wireName: r'client')
  ClientCourse get client;

  /// Commande portée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// `assignee` | `en_collecte` | `en_livraison`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Livraison active.
  @BuiltValueField(wireName: r'livraison_id')
  String get livraisonId;

  /// De quoi confirmer la remise hors ligne.
  @BuiltValueField(wireName: r'remise')
  RemisePreprovisionnee get remise;

  CourseActiveComplete._();

  factory CourseActiveComplete([void updates(CourseActiveCompleteBuilder b)]) = _$CourseActiveComplete;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CourseActiveCompleteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CourseActiveComplete> get serializer => _$CourseActiveCompleteSerializer();
}

class _$CourseActiveCompleteSerializer implements PrimitiveSerializer<CourseActiveComplete> {
  @override
  final Iterable<Type> types = const [CourseActiveComplete, _$CourseActiveComplete];

  @override
  final String wireName = r'CourseActiveComplete';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CourseActiveComplete object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arrets';
    yield serializers.serialize(
      object.arrets,
      specifiedType: const FullType(BuiltList, [FullType(ArretCourse)]),
    );
    yield r'client';
    yield serializers.serialize(
      object.client,
      specifiedType: const FullType(ClientCourse),
    );
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'livraison_id';
    yield serializers.serialize(
      object.livraisonId,
      specifiedType: const FullType(String),
    );
    yield r'remise';
    yield serializers.serialize(
      object.remise,
      specifiedType: const FullType(RemisePreprovisionnee),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CourseActiveComplete object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CourseActiveCompleteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arrets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ArretCourse)]),
          ) as BuiltList<ArretCourse>;
          result.arrets.replace(valueDes);
          break;
        case r'client':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ClientCourse),
          ) as ClientCourse;
          result.client.replace(valueDes);
          break;
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.livraisonId = valueDes;
          break;
        case r'remise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RemisePreprovisionnee),
          ) as RemisePreprovisionnee;
          result.remise.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CourseActiveComplete deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CourseActiveCompleteBuilder();
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


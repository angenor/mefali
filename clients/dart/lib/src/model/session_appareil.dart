//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/plateforme_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_appareil.g.dart';

/// Session/appareil du compte (contrat `SessionAppareil`).
///
/// Properties:
/// * [appareilNom] - Nom déclaré par l'app.
/// * [appareilPlateforme] - Plateforme.
/// * [courante] - Session de l'appareil appelant — celle qu'on ne se coupe pas par erreur.
/// * [creeLe] - Ouverture.
/// * [derniereActiviteLe] - Dernier rafraîchissement.
/// * [id] - Identifiant de session.
@BuiltValue()
abstract class SessionAppareil implements Built<SessionAppareil, SessionAppareilBuilder> {
  /// Nom déclaré par l'app.
  @BuiltValueField(wireName: r'appareil_nom')
  String get appareilNom;

  /// Plateforme.
  @BuiltValueField(wireName: r'appareil_plateforme')
  PlateformeDto get appareilPlateforme;
  // enum appareilPlateformeEnum {  android,  ios,  };

  /// Session de l'appareil appelant — celle qu'on ne se coupe pas par erreur.
  @BuiltValueField(wireName: r'courante')
  bool get courante;

  /// Ouverture.
  @BuiltValueField(wireName: r'cree_le')
  DateTime get creeLe;

  /// Dernier rafraîchissement.
  @BuiltValueField(wireName: r'derniere_activite_le')
  DateTime get derniereActiviteLe;

  /// Identifiant de session.
  @BuiltValueField(wireName: r'id')
  String get id;

  SessionAppareil._();

  factory SessionAppareil([void updates(SessionAppareilBuilder b)]) = _$SessionAppareil;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionAppareilBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionAppareil> get serializer => _$SessionAppareilSerializer();
}

class _$SessionAppareilSerializer implements PrimitiveSerializer<SessionAppareil> {
  @override
  final Iterable<Type> types = const [SessionAppareil, _$SessionAppareil];

  @override
  final String wireName = r'SessionAppareil';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionAppareil object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'appareil_nom';
    yield serializers.serialize(
      object.appareilNom,
      specifiedType: const FullType(String),
    );
    yield r'appareil_plateforme';
    yield serializers.serialize(
      object.appareilPlateforme,
      specifiedType: const FullType(PlateformeDto),
    );
    yield r'courante';
    yield serializers.serialize(
      object.courante,
      specifiedType: const FullType(bool),
    );
    yield r'cree_le';
    yield serializers.serialize(
      object.creeLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'derniere_activite_le';
    yield serializers.serialize(
      object.derniereActiviteLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionAppareil object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionAppareilBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'appareil_nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.appareilNom = valueDes;
          break;
        case r'appareil_plateforme':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlateformeDto),
          ) as PlateformeDto;
          result.appareilPlateforme = valueDes;
          break;
        case r'courante':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.courante = valueDes;
          break;
        case r'cree_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.creeLe = valueDes;
          break;
        case r'derniere_activite_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.derniereActiviteLe = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SessionAppareil deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionAppareilBuilder();
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


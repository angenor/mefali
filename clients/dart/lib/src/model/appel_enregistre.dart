//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'appel_enregistre.g.dart';

/// Ce que le serveur rend après avoir journalisé un appel.
///
/// Properties:
/// * [appelId] - Appel journalisé.
/// * [comptePourPreuve] - Cet appel compte-t-il pour la preuve d'échec ?
@BuiltValue()
abstract class AppelEnregistre implements Built<AppelEnregistre, AppelEnregistreBuilder> {
  /// Appel journalisé.
  @BuiltValueField(wireName: r'appel_id')
  String get appelId;

  /// Cet appel compte-t-il pour la preuve d'échec ?
  @BuiltValueField(wireName: r'compte_pour_preuve')
  bool get comptePourPreuve;

  AppelEnregistre._();

  factory AppelEnregistre([void updates(AppelEnregistreBuilder b)]) = _$AppelEnregistre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AppelEnregistreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AppelEnregistre> get serializer => _$AppelEnregistreSerializer();
}

class _$AppelEnregistreSerializer implements PrimitiveSerializer<AppelEnregistre> {
  @override
  final Iterable<Type> types = const [AppelEnregistre, _$AppelEnregistre];

  @override
  final String wireName = r'AppelEnregistre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AppelEnregistre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'appel_id';
    yield serializers.serialize(
      object.appelId,
      specifiedType: const FullType(String),
    );
    yield r'compte_pour_preuve';
    yield serializers.serialize(
      object.comptePourPreuve,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AppelEnregistre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AppelEnregistreBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'appel_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.appelId = valueDes;
          break;
        case r'compte_pour_preuve':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.comptePourPreuve = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AppelEnregistre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AppelEnregistreBuilder();
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


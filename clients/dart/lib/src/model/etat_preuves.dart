//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/preuve_photos.dart';
import 'package:mefali_api_client/src/model/preuve_appels.dart';
import 'package:mefali_api_client/src/model/preuve_presence.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'etat_preuves.g.dart';

/// L'état des trois preuves, et **ce qui manque** (contrat §1.4).
///
/// Properties:
/// * [appels] - Preuve « appels ».
/// * [photos] - Preuve « photo ».
/// * [presence] - Preuve « présence ».
/// * [reunies] - Les trois sont réunies — l'échec devient déclarable.
/// * [reuniesSur] - Compteur « N sur 3 » de K4-1e.
/// * [total] - Toujours 3 — le compteur n'a de sens que si le total est explicite.
@BuiltValue()
abstract class EtatPreuves implements Built<EtatPreuves, EtatPreuvesBuilder> {
  /// Preuve « appels ».
  @BuiltValueField(wireName: r'appels')
  PreuveAppels get appels;

  /// Preuve « photo ».
  @BuiltValueField(wireName: r'photos')
  PreuvePhotos get photos;

  /// Preuve « présence ».
  @BuiltValueField(wireName: r'presence')
  PreuvePresence get presence;

  /// Les trois sont réunies — l'échec devient déclarable.
  @BuiltValueField(wireName: r'reunies')
  bool get reunies;

  /// Compteur « N sur 3 » de K4-1e.
  @BuiltValueField(wireName: r'reunies_sur')
  int get reuniesSur;

  /// Toujours 3 — le compteur n'a de sens que si le total est explicite.
  @BuiltValueField(wireName: r'total')
  int get total;

  EtatPreuves._();

  factory EtatPreuves([void updates(EtatPreuvesBuilder b)]) = _$EtatPreuves;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EtatPreuvesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EtatPreuves> get serializer => _$EtatPreuvesSerializer();
}

class _$EtatPreuvesSerializer implements PrimitiveSerializer<EtatPreuves> {
  @override
  final Iterable<Type> types = const [EtatPreuves, _$EtatPreuves];

  @override
  final String wireName = r'EtatPreuves';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EtatPreuves object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'appels';
    yield serializers.serialize(
      object.appels,
      specifiedType: const FullType(PreuveAppels),
    );
    yield r'photos';
    yield serializers.serialize(
      object.photos,
      specifiedType: const FullType(PreuvePhotos),
    );
    yield r'presence';
    yield serializers.serialize(
      object.presence,
      specifiedType: const FullType(PreuvePresence),
    );
    yield r'reunies';
    yield serializers.serialize(
      object.reunies,
      specifiedType: const FullType(bool),
    );
    yield r'reunies_sur';
    yield serializers.serialize(
      object.reuniesSur,
      specifiedType: const FullType(int),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EtatPreuves object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EtatPreuvesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'appels':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PreuveAppels),
          ) as PreuveAppels;
          result.appels.replace(valueDes);
          break;
        case r'photos':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PreuvePhotos),
          ) as PreuvePhotos;
          result.photos.replace(valueDes);
          break;
        case r'presence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PreuvePresence),
          ) as PreuvePresence;
          result.presence.replace(valueDes);
          break;
        case r'reunies':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.reunies = valueDes;
          break;
        case r'reunies_sur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.reuniesSur = valueDes;
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EtatPreuves deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EtatPreuvesBuilder();
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


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'remise_bloquee.g.dart';

/// Une commande dont le code de remise est bloqué.
///
/// Properties:
/// * [bloqueLe] - Instant du blocage — **l'ordre de la liste**, le plus ancien d'abord.
/// * [commandeId] - Commande verrouillée.
/// * [coursierId] - Coursier assigné, s'il l'est encore.
/// * [essaisCode] - Essais consommés au blocage.
/// * [livraisonId] - Livraison portée — celle où le coursier est resté devant la porte.
/// * [reference] - Référence courte, pour se parler au téléphone.
/// * [zoneId] - Zone de la commande.
@BuiltValue()
abstract class RemiseBloquee implements Built<RemiseBloquee, RemiseBloqueeBuilder> {
  /// Instant du blocage — **l'ordre de la liste**, le plus ancien d'abord.
  @BuiltValueField(wireName: r'bloque_le')
  DateTime get bloqueLe;

  /// Commande verrouillée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Coursier assigné, s'il l'est encore.
  @BuiltValueField(wireName: r'coursier_id')
  String? get coursierId;

  /// Essais consommés au blocage.
  @BuiltValueField(wireName: r'essais_code')
  int get essaisCode;

  /// Livraison portée — celle où le coursier est resté devant la porte.
  @BuiltValueField(wireName: r'livraison_id')
  String? get livraisonId;

  /// Référence courte, pour se parler au téléphone.
  @BuiltValueField(wireName: r'reference')
  String get reference;

  /// Zone de la commande.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  RemiseBloquee._();

  factory RemiseBloquee([void updates(RemiseBloqueeBuilder b)]) = _$RemiseBloquee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RemiseBloqueeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RemiseBloquee> get serializer => _$RemiseBloqueeSerializer();
}

class _$RemiseBloqueeSerializer implements PrimitiveSerializer<RemiseBloquee> {
  @override
  final Iterable<Type> types = const [RemiseBloquee, _$RemiseBloquee];

  @override
  final String wireName = r'RemiseBloquee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RemiseBloquee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'bloque_le';
    yield serializers.serialize(
      object.bloqueLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    if (object.coursierId != null) {
      yield r'coursier_id';
      yield serializers.serialize(
        object.coursierId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'essais_code';
    yield serializers.serialize(
      object.essaisCode,
      specifiedType: const FullType(int),
    );
    if (object.livraisonId != null) {
      yield r'livraison_id';
      yield serializers.serialize(
        object.livraisonId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'reference';
    yield serializers.serialize(
      object.reference,
      specifiedType: const FullType(String),
    );
    yield r'zone_id';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RemiseBloquee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RemiseBloqueeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'bloque_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.bloqueLe = valueDes;
          break;
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'coursier_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.coursierId = valueDes;
          break;
        case r'essais_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.essaisCode = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.livraisonId = valueDes;
          break;
        case r'reference':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reference = valueDes;
          break;
        case r'zone_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RemiseBloquee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RemiseBloqueeBuilder();
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


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/commande_resumee.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mes_commandes.g.dart';

/// La liste des commandes du compte.
///
/// Properties:
/// * [commandes] - Commandes, les plus récentes d'abord.
@BuiltValue()
abstract class MesCommandes implements Built<MesCommandes, MesCommandesBuilder> {
  /// Commandes, les plus récentes d'abord.
  @BuiltValueField(wireName: r'commandes')
  BuiltList<CommandeResumee> get commandes;

  MesCommandes._();

  factory MesCommandes([void updates(MesCommandesBuilder b)]) = _$MesCommandes;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MesCommandesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MesCommandes> get serializer => _$MesCommandesSerializer();
}

class _$MesCommandesSerializer implements PrimitiveSerializer<MesCommandes> {
  @override
  final Iterable<Type> types = const [MesCommandes, _$MesCommandes];

  @override
  final String wireName = r'MesCommandes';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MesCommandes object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandes';
    yield serializers.serialize(
      object.commandes,
      specifiedType: const FullType(BuiltList, [FullType(CommandeResumee)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MesCommandes object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MesCommandesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commandes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CommandeResumee)]),
          ) as BuiltList<CommandeResumee>;
          result.commandes.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MesCommandes deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MesCommandesBuilder();
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


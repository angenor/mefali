//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mes_vehicules.g.dart';

/// Flotte déclarée — remplacement INTÉGRAL.
///
/// Properties:
/// * [vehicules] - Slugs de `zones.type_transport` ACTIFS dans la zone du compte.  La liste remplace la précédente ; elle ne s'y ajoute pas. Une liste vide est refusée : pour cesser de rouler on passe hors ligne, on ne se prive pas de véhicule — sinon le coursier se recrée l'impasse que cette route existe pour ouvrir.
@BuiltValue()
abstract class MesVehicules implements Built<MesVehicules, MesVehiculesBuilder> {
  /// Slugs de `zones.type_transport` ACTIFS dans la zone du compte.  La liste remplace la précédente ; elle ne s'y ajoute pas. Une liste vide est refusée : pour cesser de rouler on passe hors ligne, on ne se prive pas de véhicule — sinon le coursier se recrée l'impasse que cette route existe pour ouvrir.
  @BuiltValueField(wireName: r'vehicules')
  BuiltList<String> get vehicules;

  MesVehicules._();

  factory MesVehicules([void updates(MesVehiculesBuilder b)]) = _$MesVehicules;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MesVehiculesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MesVehicules> get serializer => _$MesVehiculesSerializer();
}

class _$MesVehiculesSerializer implements PrimitiveSerializer<MesVehicules> {
  @override
  final Iterable<Type> types = const [MesVehicules, _$MesVehicules];

  @override
  final String wireName = r'MesVehicules';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MesVehicules object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'vehicules';
    yield serializers.serialize(
      object.vehicules,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MesVehicules object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MesVehiculesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'vehicules':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.vehicules.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MesVehicules deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MesVehiculesBuilder();
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


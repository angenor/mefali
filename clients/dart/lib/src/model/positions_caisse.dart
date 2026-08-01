//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'positions_caisse.g.dart';

/// Les trois positions de la caisse — « où est cet argent ? » (FR-060).  Elles ne se recouvrent pas : avancé non récupéré (Yao a sorti l'argent), dû par Mefali (une dette formelle, qui se règle), détenu pour Mefali (il a de l'argent qui n'est PAS à lui).
///
/// Properties:
/// * [avanceNonRecupereeUnites] - Σ avances non compensées par un remboursement.
/// * [detenuPourMefaliUnites] - Marge encaissée non reversée — **0 au MVP** (marge nulle jusqu'à M4). S'affiche quand même : une position absente se lirait comme une position oubliée.
/// * [duParMefaliUnites] - Σ créances dues.
@BuiltValue()
abstract class PositionsCaisse implements Built<PositionsCaisse, PositionsCaisseBuilder> {
  /// Σ avances non compensées par un remboursement.
  @BuiltValueField(wireName: r'avance_non_recuperee_unites')
  int get avanceNonRecupereeUnites;

  /// Marge encaissée non reversée — **0 au MVP** (marge nulle jusqu'à M4). S'affiche quand même : une position absente se lirait comme une position oubliée.
  @BuiltValueField(wireName: r'detenu_pour_mefali_unites')
  int get detenuPourMefaliUnites;

  /// Σ créances dues.
  @BuiltValueField(wireName: r'du_par_mefali_unites')
  int get duParMefaliUnites;

  PositionsCaisse._();

  factory PositionsCaisse([void updates(PositionsCaisseBuilder b)]) = _$PositionsCaisse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PositionsCaisseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PositionsCaisse> get serializer => _$PositionsCaisseSerializer();
}

class _$PositionsCaisseSerializer implements PrimitiveSerializer<PositionsCaisse> {
  @override
  final Iterable<Type> types = const [PositionsCaisse, _$PositionsCaisse];

  @override
  final String wireName = r'PositionsCaisse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PositionsCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'avance_non_recuperee_unites';
    yield serializers.serialize(
      object.avanceNonRecupereeUnites,
      specifiedType: const FullType(int),
    );
    yield r'detenu_pour_mefali_unites';
    yield serializers.serialize(
      object.detenuPourMefaliUnites,
      specifiedType: const FullType(int),
    );
    yield r'du_par_mefali_unites';
    yield serializers.serialize(
      object.duParMefaliUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PositionsCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PositionsCaisseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'avance_non_recuperee_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.avanceNonRecupereeUnites = valueDes;
          break;
        case r'detenu_pour_mefali_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.detenuPourMefaliUnites = valueDes;
          break;
        case r'du_par_mefali_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.duParMefaliUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PositionsCaisse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PositionsCaisseBuilder();
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


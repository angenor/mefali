//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'paiement_commande.g.dart';

/// État du paiement d'une commande créée.
///
/// Properties:
/// * [appointExactUnites] - Appoint exact à préparer (cash) — le total, en une fois. Aucun chemin de règlement fractionné n'existe (constitution III).
/// * [etat] - `du` | `en_attente` | `regle` | `rembourse`.
/// * [mode] - Mode retenu.
@BuiltValue()
abstract class PaiementCommande implements Built<PaiementCommande, PaiementCommandeBuilder> {
  /// Appoint exact à préparer (cash) — le total, en une fois. Aucun chemin de règlement fractionné n'existe (constitution III).
  @BuiltValueField(wireName: r'appoint_exact_unites')
  int get appointExactUnites;

  /// `du` | `en_attente` | `regle` | `rembourse`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Mode retenu.
  @BuiltValueField(wireName: r'mode')
  String get mode;

  PaiementCommande._();

  factory PaiementCommande([void updates(PaiementCommandeBuilder b)]) = _$PaiementCommande;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaiementCommandeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaiementCommande> get serializer => _$PaiementCommandeSerializer();
}

class _$PaiementCommandeSerializer implements PrimitiveSerializer<PaiementCommande> {
  @override
  final Iterable<Type> types = const [PaiementCommande, _$PaiementCommande];

  @override
  final String wireName = r'PaiementCommande';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaiementCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'appoint_exact_unites';
    yield serializers.serialize(
      object.appointExactUnites,
      specifiedType: const FullType(int),
    );
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'mode';
    yield serializers.serialize(
      object.mode,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PaiementCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaiementCommandeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'appoint_exact_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.appointExactUnites = valueDes;
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'mode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PaiementCommande deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaiementCommandeBuilder();
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


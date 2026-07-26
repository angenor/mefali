//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'paiement_panier.g.dart';

/// Décision d'encaissement (maquette C3-3b).
///
/// Properties:
/// * [cashAutorise] - Le paiement en espèces est possible.
/// * [motifCle] - Clé i18n de la RAISON du refus (`null` si autorisé) — le client voit pourquoi le cash est grisé, jamais un bouton mort.
/// * [plafondUnites] - Plafond appliqué (unités mineures).
@BuiltValue()
abstract class PaiementPanier implements Built<PaiementPanier, PaiementPanierBuilder> {
  /// Le paiement en espèces est possible.
  @BuiltValueField(wireName: r'cash_autorise')
  bool get cashAutorise;

  /// Clé i18n de la RAISON du refus (`null` si autorisé) — le client voit pourquoi le cash est grisé, jamais un bouton mort.
  @BuiltValueField(wireName: r'motif_cle')
  String? get motifCle;

  /// Plafond appliqué (unités mineures).
  @BuiltValueField(wireName: r'plafond_unites')
  int get plafondUnites;

  PaiementPanier._();

  factory PaiementPanier([void updates(PaiementPanierBuilder b)]) = _$PaiementPanier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaiementPanierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaiementPanier> get serializer => _$PaiementPanierSerializer();
}

class _$PaiementPanierSerializer implements PrimitiveSerializer<PaiementPanier> {
  @override
  final Iterable<Type> types = const [PaiementPanier, _$PaiementPanier];

  @override
  final String wireName = r'PaiementPanier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaiementPanier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'cash_autorise';
    yield serializers.serialize(
      object.cashAutorise,
      specifiedType: const FullType(bool),
    );
    if (object.motifCle != null) {
      yield r'motif_cle';
      yield serializers.serialize(
        object.motifCle,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'plafond_unites';
    yield serializers.serialize(
      object.plafondUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PaiementPanier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaiementPanierBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'cash_autorise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.cashAutorise = valueDes;
          break;
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motifCle = valueDes;
          break;
        case r'plafond_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.plafondUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PaiementPanier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaiementPanierBuilder();
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


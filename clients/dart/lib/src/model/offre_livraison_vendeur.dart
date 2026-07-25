//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offre_livraison_vendeur.g.dart';

/// Offre de livraison du vendeur (VND-08) — **entrée** simulée du calcul ; sa configuration relève de VND, son financement de PAY (hors périmètre).
///
/// Properties:
/// * [auDela] - Prise en charge à partir de ce montant de panier (unités mineures). Ignoré si `toujours`.
/// * [toujours] - Le vendeur prend la livraison en charge quel que soit le panier.
@BuiltValue()
abstract class OffreLivraisonVendeur implements Built<OffreLivraisonVendeur, OffreLivraisonVendeurBuilder> {
  /// Prise en charge à partir de ce montant de panier (unités mineures). Ignoré si `toujours`.
  @BuiltValueField(wireName: r'au_dela')
  int? get auDela;

  /// Le vendeur prend la livraison en charge quel que soit le panier.
  @BuiltValueField(wireName: r'toujours')
  bool get toujours;

  OffreLivraisonVendeur._();

  factory OffreLivraisonVendeur([void updates(OffreLivraisonVendeurBuilder b)]) = _$OffreLivraisonVendeur;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OffreLivraisonVendeurBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OffreLivraisonVendeur> get serializer => _$OffreLivraisonVendeurSerializer();
}

class _$OffreLivraisonVendeurSerializer implements PrimitiveSerializer<OffreLivraisonVendeur> {
  @override
  final Iterable<Type> types = const [OffreLivraisonVendeur, _$OffreLivraisonVendeur];

  @override
  final String wireName = r'OffreLivraisonVendeur';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OffreLivraisonVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.auDela != null) {
      yield r'au_dela';
      yield serializers.serialize(
        object.auDela,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'toujours';
    yield serializers.serialize(
      object.toujours,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OffreLivraisonVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OffreLivraisonVendeurBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'au_dela':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.auDela = valueDes;
          break;
        case r'toujours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.toujours = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OffreLivraisonVendeur deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OffreLivraisonVendeurBuilder();
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


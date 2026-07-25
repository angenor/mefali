//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'composantes.g.dart';

/// Détail des composantes (unités mineures) — FR-020.
///
/// Properties:
/// * [arrondi] - Reliquat d'arrondi — abonde la part coursier.
/// * [base_] - Prix client de base de la règle.
/// * [effortArrets] - Effort — suppléments d'arrêt (100 % coursier).
/// * [effortAttente] - Effort — prime d'attente (100 % coursier).
/// * [effortPaliers] - Effort — paliers d'articles (100 % coursier).
/// * [km] - Composante kilométrique au-delà du seuil.
/// * [retenueVendeur] - Montant pris en charge par le vendeur (VND-08).
/// * [supplements] - Suppléments activés (pluie…).
@BuiltValue()
abstract class Composantes implements Built<Composantes, ComposantesBuilder> {
  /// Reliquat d'arrondi — abonde la part coursier.
  @BuiltValueField(wireName: r'arrondi')
  int get arrondi;

  /// Prix client de base de la règle.
  @BuiltValueField(wireName: r'base')
  int get base_;

  /// Effort — suppléments d'arrêt (100 % coursier).
  @BuiltValueField(wireName: r'effort_arrets')
  int get effortArrets;

  /// Effort — prime d'attente (100 % coursier).
  @BuiltValueField(wireName: r'effort_attente')
  int get effortAttente;

  /// Effort — paliers d'articles (100 % coursier).
  @BuiltValueField(wireName: r'effort_paliers')
  int get effortPaliers;

  /// Composante kilométrique au-delà du seuil.
  @BuiltValueField(wireName: r'km')
  int get km;

  /// Montant pris en charge par le vendeur (VND-08).
  @BuiltValueField(wireName: r'retenue_vendeur')
  int get retenueVendeur;

  /// Suppléments activés (pluie…).
  @BuiltValueField(wireName: r'supplements')
  int get supplements;

  Composantes._();

  factory Composantes([void updates(ComposantesBuilder b)]) = _$Composantes;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ComposantesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Composantes> get serializer => _$ComposantesSerializer();
}

class _$ComposantesSerializer implements PrimitiveSerializer<Composantes> {
  @override
  final Iterable<Type> types = const [Composantes, _$Composantes];

  @override
  final String wireName = r'Composantes';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Composantes object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arrondi';
    yield serializers.serialize(
      object.arrondi,
      specifiedType: const FullType(int),
    );
    yield r'base';
    yield serializers.serialize(
      object.base_,
      specifiedType: const FullType(int),
    );
    yield r'effort_arrets';
    yield serializers.serialize(
      object.effortArrets,
      specifiedType: const FullType(int),
    );
    yield r'effort_attente';
    yield serializers.serialize(
      object.effortAttente,
      specifiedType: const FullType(int),
    );
    yield r'effort_paliers';
    yield serializers.serialize(
      object.effortPaliers,
      specifiedType: const FullType(int),
    );
    yield r'km';
    yield serializers.serialize(
      object.km,
      specifiedType: const FullType(int),
    );
    yield r'retenue_vendeur';
    yield serializers.serialize(
      object.retenueVendeur,
      specifiedType: const FullType(int),
    );
    yield r'supplements';
    yield serializers.serialize(
      object.supplements,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Composantes object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ComposantesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arrondi':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.arrondi = valueDes;
          break;
        case r'base':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.base_ = valueDes;
          break;
        case r'effort_arrets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.effortArrets = valueDes;
          break;
        case r'effort_attente':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.effortAttente = valueDes;
          break;
        case r'effort_paliers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.effortPaliers = valueDes;
          break;
        case r'km':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.km = valueDes;
          break;
        case r'retenue_vendeur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.retenueVendeur = valueDes;
          break;
        case r'supplements':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.supplements = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Composantes deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ComposantesBuilder();
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


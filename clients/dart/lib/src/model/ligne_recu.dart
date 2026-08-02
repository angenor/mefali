//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ligne_recu.g.dart';

/// Une ligne du reçu, prix VERROUILLÉ.
///
/// Properties:
/// * [libelle] - Libellé de l'article (celui du remplaçant si un remplacement a été accepté).
/// * [prixUnitaire] - Prix unitaire figé à la création (unités mineures).
/// * [quantite] - Quantité commandée.
/// * [sousTotalUnites] - Sous-total — **0** sur une ligne retirée.
/// * [statut] - `presente` | `remplacee` | `retiree`.
@BuiltValue()
abstract class LigneRecu implements Built<LigneRecu, LigneRecuBuilder> {
  /// Libellé de l'article (celui du remplaçant si un remplacement a été accepté).
  @BuiltValueField(wireName: r'libelle')
  String get libelle;

  /// Prix unitaire figé à la création (unités mineures).
  @BuiltValueField(wireName: r'prix_unitaire')
  int get prixUnitaire;

  /// Quantité commandée.
  @BuiltValueField(wireName: r'quantite')
  int get quantite;

  /// Sous-total — **0** sur une ligne retirée.
  @BuiltValueField(wireName: r'sous_total_unites')
  int get sousTotalUnites;

  /// `presente` | `remplacee` | `retiree`.
  @BuiltValueField(wireName: r'statut')
  String get statut;

  LigneRecu._();

  factory LigneRecu([void updates(LigneRecuBuilder b)]) = _$LigneRecu;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LigneRecuBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LigneRecu> get serializer => _$LigneRecuSerializer();
}

class _$LigneRecuSerializer implements PrimitiveSerializer<LigneRecu> {
  @override
  final Iterable<Type> types = const [LigneRecu, _$LigneRecu];

  @override
  final String wireName = r'LigneRecu';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LigneRecu object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'libelle';
    yield serializers.serialize(
      object.libelle,
      specifiedType: const FullType(String),
    );
    yield r'prix_unitaire';
    yield serializers.serialize(
      object.prixUnitaire,
      specifiedType: const FullType(int),
    );
    yield r'quantite';
    yield serializers.serialize(
      object.quantite,
      specifiedType: const FullType(int),
    );
    yield r'sous_total_unites';
    yield serializers.serialize(
      object.sousTotalUnites,
      specifiedType: const FullType(int),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LigneRecu object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LigneRecuBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'libelle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.libelle = valueDes;
          break;
        case r'prix_unitaire':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixUnitaire = valueDes;
          break;
        case r'quantite':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.quantite = valueDes;
          break;
        case r'sous_total_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sousTotalUnites = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statut = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LigneRecu deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LigneRecuBuilder();
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


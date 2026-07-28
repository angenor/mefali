//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/seuils_preuves.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'remise_preprovisionnee.g.dart';

/// De quoi confirmer la remise **sans réseau** (K4).
///
/// Properties:
/// * [codeBloque] - Saisie du code bloquée (K4-1d).
/// * [empreinteCode] - Empreinte salée du code à 4 chiffres — **jamais le code** (FR-037).
/// * [empreinteJeton] - Empreinte du jeton de réception — **jamais le jeton**.
/// * [essaisConsommes] - Essais faux déjà comptés côté serveur.
/// * [essaisMax] - Seuil de zone `commande.essais_code_livraison` (cycle 008, réutilisé).
/// * [modePaiement] - `cash` | `mobile_money`.
/// * [montantAEncaisserUnites] - Total à encaisser chez le client (unités mineures).
/// * [preuves] - Seuils de preuve de la zone.
@BuiltValue()
abstract class RemisePreprovisionnee implements Built<RemisePreprovisionnee, RemisePreprovisionneeBuilder> {
  /// Saisie du code bloquée (K4-1d).
  @BuiltValueField(wireName: r'code_bloque')
  bool get codeBloque;

  /// Empreinte salée du code à 4 chiffres — **jamais le code** (FR-037).
  @BuiltValueField(wireName: r'empreinte_code')
  String get empreinteCode;

  /// Empreinte du jeton de réception — **jamais le jeton**.
  @BuiltValueField(wireName: r'empreinte_jeton')
  String get empreinteJeton;

  /// Essais faux déjà comptés côté serveur.
  @BuiltValueField(wireName: r'essais_consommes')
  int get essaisConsommes;

  /// Seuil de zone `commande.essais_code_livraison` (cycle 008, réutilisé).
  @BuiltValueField(wireName: r'essais_max')
  int get essaisMax;

  /// `cash` | `mobile_money`.
  @BuiltValueField(wireName: r'mode_paiement')
  String get modePaiement;

  /// Total à encaisser chez le client (unités mineures).
  @BuiltValueField(wireName: r'montant_a_encaisser_unites')
  int get montantAEncaisserUnites;

  /// Seuils de preuve de la zone.
  @BuiltValueField(wireName: r'preuves')
  SeuilsPreuves get preuves;

  RemisePreprovisionnee._();

  factory RemisePreprovisionnee([void updates(RemisePreprovisionneeBuilder b)]) = _$RemisePreprovisionnee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RemisePreprovisionneeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RemisePreprovisionnee> get serializer => _$RemisePreprovisionneeSerializer();
}

class _$RemisePreprovisionneeSerializer implements PrimitiveSerializer<RemisePreprovisionnee> {
  @override
  final Iterable<Type> types = const [RemisePreprovisionnee, _$RemisePreprovisionnee];

  @override
  final String wireName = r'RemisePreprovisionnee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RemisePreprovisionnee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code_bloque';
    yield serializers.serialize(
      object.codeBloque,
      specifiedType: const FullType(bool),
    );
    yield r'empreinte_code';
    yield serializers.serialize(
      object.empreinteCode,
      specifiedType: const FullType(String),
    );
    yield r'empreinte_jeton';
    yield serializers.serialize(
      object.empreinteJeton,
      specifiedType: const FullType(String),
    );
    yield r'essais_consommes';
    yield serializers.serialize(
      object.essaisConsommes,
      specifiedType: const FullType(int),
    );
    yield r'essais_max';
    yield serializers.serialize(
      object.essaisMax,
      specifiedType: const FullType(int),
    );
    yield r'mode_paiement';
    yield serializers.serialize(
      object.modePaiement,
      specifiedType: const FullType(String),
    );
    yield r'montant_a_encaisser_unites';
    yield serializers.serialize(
      object.montantAEncaisserUnites,
      specifiedType: const FullType(int),
    );
    yield r'preuves';
    yield serializers.serialize(
      object.preuves,
      specifiedType: const FullType(SeuilsPreuves),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RemisePreprovisionnee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RemisePreprovisionneeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code_bloque':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.codeBloque = valueDes;
          break;
        case r'empreinte_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.empreinteCode = valueDes;
          break;
        case r'empreinte_jeton':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.empreinteJeton = valueDes;
          break;
        case r'essais_consommes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.essaisConsommes = valueDes;
          break;
        case r'essais_max':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.essaisMax = valueDes;
          break;
        case r'mode_paiement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.modePaiement = valueDes;
          break;
        case r'montant_a_encaisser_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantAEncaisserUnites = valueDes;
          break;
        case r'preuves':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SeuilsPreuves),
          ) as SeuilsPreuves;
          result.preuves.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RemisePreprovisionnee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RemisePreprovisionneeBuilder();
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


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/capacite_coursier.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'etat_disponibilite.g.dart';

/// État de disponibilité, tel que l'écran K1 l'affiche.  Les DEUX plafonds sont rendus : Yao voit toujours **lequel** s'applique (`plafond_source`) et **pourquoi** (`palier_note_cle`). Un coursier à qui l'on refuse une course sans lui dire que son palier le limite croira à un bug.
///
/// Properties:
/// * [capacites] - Capacités déclarées au dossier coursier.
/// * [dansLePool] - Vrai seulement après une position publiée : l'intention ne suffit pas.
/// * [devise] - Devise ISO 4217 de la zone.
/// * [enLigne] - Intention déclarée aujourd'hui.
/// * [jour] - Jour civil de la déclaration.
/// * [noteCentiemes] - Note du coursier, ou `null` tant qu'AVI n'existe pas.
/// * [palierNoteCle] - Clé i18n du palier appliqué.
/// * [periodePositionS] - Période de publication attendue (paramètre de zone du cycle 008).
/// * [plafondDeclareUnites] - Plafond déclaré du jour, ou `null` si rien n'a été déclaré (FR-011 : jamais reporté — l'app le redemande au nouveau jour).
/// * [plafondRetenuUnites] - Ce qui s'applique : `min(déclaré, palier de la grille)`.
/// * [plafondSource] - `grille_note` | `declaration`.
@BuiltValue()
abstract class EtatDisponibilite implements Built<EtatDisponibilite, EtatDisponibiliteBuilder> {
  /// Capacités déclarées au dossier coursier.
  @BuiltValueField(wireName: r'capacites')
  BuiltList<CapaciteCoursier> get capacites;

  /// Vrai seulement après une position publiée : l'intention ne suffit pas.
  @BuiltValueField(wireName: r'dans_le_pool')
  bool get dansLePool;

  /// Devise ISO 4217 de la zone.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Intention déclarée aujourd'hui.
  @BuiltValueField(wireName: r'en_ligne')
  bool get enLigne;

  /// Jour civil de la déclaration.
  @BuiltValueField(wireName: r'jour')
  String get jour;

  /// Note du coursier, ou `null` tant qu'AVI n'existe pas.
  @BuiltValueField(wireName: r'note_centiemes')
  int? get noteCentiemes;

  /// Clé i18n du palier appliqué.
  @BuiltValueField(wireName: r'palier_note_cle')
  String get palierNoteCle;

  /// Période de publication attendue (paramètre de zone du cycle 008).
  @BuiltValueField(wireName: r'periode_position_s')
  int get periodePositionS;

  /// Plafond déclaré du jour, ou `null` si rien n'a été déclaré (FR-011 : jamais reporté — l'app le redemande au nouveau jour).
  @BuiltValueField(wireName: r'plafond_declare_unites')
  int? get plafondDeclareUnites;

  /// Ce qui s'applique : `min(déclaré, palier de la grille)`.
  @BuiltValueField(wireName: r'plafond_retenu_unites')
  int get plafondRetenuUnites;

  /// `grille_note` | `declaration`.
  @BuiltValueField(wireName: r'plafond_source')
  String get plafondSource;

  EtatDisponibilite._();

  factory EtatDisponibilite([void updates(EtatDisponibiliteBuilder b)]) = _$EtatDisponibilite;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EtatDisponibiliteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EtatDisponibilite> get serializer => _$EtatDisponibiliteSerializer();
}

class _$EtatDisponibiliteSerializer implements PrimitiveSerializer<EtatDisponibilite> {
  @override
  final Iterable<Type> types = const [EtatDisponibilite, _$EtatDisponibilite];

  @override
  final String wireName = r'EtatDisponibilite';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EtatDisponibilite object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'capacites';
    yield serializers.serialize(
      object.capacites,
      specifiedType: const FullType(BuiltList, [FullType(CapaciteCoursier)]),
    );
    yield r'dans_le_pool';
    yield serializers.serialize(
      object.dansLePool,
      specifiedType: const FullType(bool),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'en_ligne';
    yield serializers.serialize(
      object.enLigne,
      specifiedType: const FullType(bool),
    );
    yield r'jour';
    yield serializers.serialize(
      object.jour,
      specifiedType: const FullType(String),
    );
    if (object.noteCentiemes != null) {
      yield r'note_centiemes';
      yield serializers.serialize(
        object.noteCentiemes,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'palier_note_cle';
    yield serializers.serialize(
      object.palierNoteCle,
      specifiedType: const FullType(String),
    );
    yield r'periode_position_s';
    yield serializers.serialize(
      object.periodePositionS,
      specifiedType: const FullType(int),
    );
    if (object.plafondDeclareUnites != null) {
      yield r'plafond_declare_unites';
      yield serializers.serialize(
        object.plafondDeclareUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'plafond_retenu_unites';
    yield serializers.serialize(
      object.plafondRetenuUnites,
      specifiedType: const FullType(int),
    );
    yield r'plafond_source';
    yield serializers.serialize(
      object.plafondSource,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EtatDisponibilite object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EtatDisponibiliteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'capacites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CapaciteCoursier)]),
          ) as BuiltList<CapaciteCoursier>;
          result.capacites.replace(valueDes);
          break;
        case r'dans_le_pool':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.dansLePool = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'en_ligne':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enLigne = valueDes;
          break;
        case r'jour':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.jour = valueDes;
          break;
        case r'note_centiemes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.noteCentiemes = valueDes;
          break;
        case r'palier_note_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.palierNoteCle = valueDes;
          break;
        case r'periode_position_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.periodePositionS = valueDes;
          break;
        case r'plafond_declare_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.plafondDeclareUnites = valueDes;
          break;
        case r'plafond_retenu_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.plafondRetenuUnites = valueDes;
          break;
        case r'plafond_source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.plafondSource = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EtatDisponibilite deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EtatDisponibiliteBuilder();
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


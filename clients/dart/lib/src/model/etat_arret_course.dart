//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'etat_arret_course.g.dart';

/// État de l'arrêt et de sa course après la transition.
///
/// Properties:
/// * [arretId] - Arrêt concerné.
/// * [collectesFaites] - Arrêts effectivement COLLECTÉS (la remise n'en est pas une).
/// * [collectesResolues] - Arrêts RÉSOLUS — collectés **ou** indisponibles. C'est ce compteur qui dit au coursier ce qui lui reste à faire : un étal fermé est fini, même s'il n'y a rien pris.
/// * [collectesTotal] - Nombre total de COLLECTES de la course.
/// * [commandeId] - Commande ancre.
/// * [enLivraison] - Vrai si la course vient de basculer EN_LIVRAISON.
/// * [livraisonEtat] - État de la livraison : `assignee` | `en_collecte` | `en_livraison`.
/// * [livraisonId] - Livraison porteuse.
/// * [rejeu] - Vrai si l'appel était un rejeu du même `uuid_client` : rien n'a été réécrit, aucun événement n'a été ré-émis.
/// * [statut] - Statut de l'arrêt : `en_route` | `arrive` | `indisponible`.
@BuiltValue()
abstract class EtatArretCourse implements Built<EtatArretCourse, EtatArretCourseBuilder> {
  /// Arrêt concerné.
  @BuiltValueField(wireName: r'arret_id')
  String get arretId;

  /// Arrêts effectivement COLLECTÉS (la remise n'en est pas une).
  @BuiltValueField(wireName: r'collectes_faites')
  int get collectesFaites;

  /// Arrêts RÉSOLUS — collectés **ou** indisponibles. C'est ce compteur qui dit au coursier ce qui lui reste à faire : un étal fermé est fini, même s'il n'y a rien pris.
  @BuiltValueField(wireName: r'collectes_resolues')
  int get collectesResolues;

  /// Nombre total de COLLECTES de la course.
  @BuiltValueField(wireName: r'collectes_total')
  int get collectesTotal;

  /// Commande ancre.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Vrai si la course vient de basculer EN_LIVRAISON.
  @BuiltValueField(wireName: r'en_livraison')
  bool get enLivraison;

  /// État de la livraison : `assignee` | `en_collecte` | `en_livraison`.
  @BuiltValueField(wireName: r'livraison_etat')
  String get livraisonEtat;

  /// Livraison porteuse.
  @BuiltValueField(wireName: r'livraison_id')
  String get livraisonId;

  /// Vrai si l'appel était un rejeu du même `uuid_client` : rien n'a été réécrit, aucun événement n'a été ré-émis.
  @BuiltValueField(wireName: r'rejeu')
  bool get rejeu;

  /// Statut de l'arrêt : `en_route` | `arrive` | `indisponible`.
  @BuiltValueField(wireName: r'statut')
  String get statut;

  EtatArretCourse._();

  factory EtatArretCourse([void updates(EtatArretCourseBuilder b)]) = _$EtatArretCourse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EtatArretCourseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EtatArretCourse> get serializer => _$EtatArretCourseSerializer();
}

class _$EtatArretCourseSerializer implements PrimitiveSerializer<EtatArretCourse> {
  @override
  final Iterable<Type> types = const [EtatArretCourse, _$EtatArretCourse];

  @override
  final String wireName = r'EtatArretCourse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EtatArretCourse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arret_id';
    yield serializers.serialize(
      object.arretId,
      specifiedType: const FullType(String),
    );
    yield r'collectes_faites';
    yield serializers.serialize(
      object.collectesFaites,
      specifiedType: const FullType(int),
    );
    yield r'collectes_resolues';
    yield serializers.serialize(
      object.collectesResolues,
      specifiedType: const FullType(int),
    );
    yield r'collectes_total';
    yield serializers.serialize(
      object.collectesTotal,
      specifiedType: const FullType(int),
    );
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'en_livraison';
    yield serializers.serialize(
      object.enLivraison,
      specifiedType: const FullType(bool),
    );
    yield r'livraison_etat';
    yield serializers.serialize(
      object.livraisonEtat,
      specifiedType: const FullType(String),
    );
    yield r'livraison_id';
    yield serializers.serialize(
      object.livraisonId,
      specifiedType: const FullType(String),
    );
    yield r'rejeu';
    yield serializers.serialize(
      object.rejeu,
      specifiedType: const FullType(bool),
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
    EtatArretCourse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EtatArretCourseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.arretId = valueDes;
          break;
        case r'collectes_faites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.collectesFaites = valueDes;
          break;
        case r'collectes_resolues':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.collectesResolues = valueDes;
          break;
        case r'collectes_total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.collectesTotal = valueDes;
          break;
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'en_livraison':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enLivraison = valueDes;
          break;
        case r'livraison_etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.livraisonEtat = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.livraisonId = valueDes;
          break;
        case r'rejeu':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.rejeu = valueDes;
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
  EtatArretCourse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EtatArretCourseBuilder();
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


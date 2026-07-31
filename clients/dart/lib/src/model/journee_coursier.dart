//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'journee_coursier.g.dart';

/// Ce que Yao a gagné aujourd'hui, et ce qu'il peut encore engager (K1-1a).
///
/// Properties:
/// * [avancesEnCoursUnites] - Argent encore dehors, à l'origine de l'amputation ci-dessus.
/// * [coursesLivrees] - Courses dont la remise est validée dans le jour civil **de la zone**.
/// * [devise] - Devise ISO 4217.
/// * [gainsUnites] - Somme des parts coursier de ces courses (devis FIGÉ du cycle 007).
/// * [noteCentiemes] - **Toujours `null`** tant qu'AVI n'est pas construit (FR-094) : l'absence vaut mieux qu'un chiffre inventé.
/// * [plafondRetenuUnites] - Plafond d'avance qui s'applique — `min(déclaré, palier de la grille)`.
/// * [resteDisponibleUnites] - Ce qu'il reste engageable : plafond retenu **moins** avances en cours (FR-095). Jamais négatif — un « reste » négatif ne veut rien dire à l'écran ; l'écart, lui, est signalé par la caisse (FR-078).
/// * [tauxAcceptationPourcent] - Taux d'acceptation tenu par le dispatch, ou `null` si aucune offre décidable n'a été émise sur la fenêtre (FR-093).
@BuiltValue()
abstract class JourneeCoursier implements Built<JourneeCoursier, JourneeCoursierBuilder> {
  /// Argent encore dehors, à l'origine de l'amputation ci-dessus.
  @BuiltValueField(wireName: r'avances_en_cours_unites')
  int get avancesEnCoursUnites;

  /// Courses dont la remise est validée dans le jour civil **de la zone**.
  @BuiltValueField(wireName: r'courses_livrees')
  int get coursesLivrees;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Somme des parts coursier de ces courses (devis FIGÉ du cycle 007).
  @BuiltValueField(wireName: r'gains_unites')
  int get gainsUnites;

  /// **Toujours `null`** tant qu'AVI n'est pas construit (FR-094) : l'absence vaut mieux qu'un chiffre inventé.
  @BuiltValueField(wireName: r'note_centiemes')
  int? get noteCentiemes;

  /// Plafond d'avance qui s'applique — `min(déclaré, palier de la grille)`.
  @BuiltValueField(wireName: r'plafond_retenu_unites')
  int get plafondRetenuUnites;

  /// Ce qu'il reste engageable : plafond retenu **moins** avances en cours (FR-095). Jamais négatif — un « reste » négatif ne veut rien dire à l'écran ; l'écart, lui, est signalé par la caisse (FR-078).
  @BuiltValueField(wireName: r'reste_disponible_unites')
  int get resteDisponibleUnites;

  /// Taux d'acceptation tenu par le dispatch, ou `null` si aucune offre décidable n'a été émise sur la fenêtre (FR-093).
  @BuiltValueField(wireName: r'taux_acceptation_pourcent')
  int? get tauxAcceptationPourcent;

  JourneeCoursier._();

  factory JourneeCoursier([void updates(JourneeCoursierBuilder b)]) = _$JourneeCoursier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JourneeCoursierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JourneeCoursier> get serializer => _$JourneeCoursierSerializer();
}

class _$JourneeCoursierSerializer implements PrimitiveSerializer<JourneeCoursier> {
  @override
  final Iterable<Type> types = const [JourneeCoursier, _$JourneeCoursier];

  @override
  final String wireName = r'JourneeCoursier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JourneeCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'avances_en_cours_unites';
    yield serializers.serialize(
      object.avancesEnCoursUnites,
      specifiedType: const FullType(int),
    );
    yield r'courses_livrees';
    yield serializers.serialize(
      object.coursesLivrees,
      specifiedType: const FullType(int),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'gains_unites';
    yield serializers.serialize(
      object.gainsUnites,
      specifiedType: const FullType(int),
    );
    if (object.noteCentiemes != null) {
      yield r'note_centiemes';
      yield serializers.serialize(
        object.noteCentiemes,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'plafond_retenu_unites';
    yield serializers.serialize(
      object.plafondRetenuUnites,
      specifiedType: const FullType(int),
    );
    yield r'reste_disponible_unites';
    yield serializers.serialize(
      object.resteDisponibleUnites,
      specifiedType: const FullType(int),
    );
    if (object.tauxAcceptationPourcent != null) {
      yield r'taux_acceptation_pourcent';
      yield serializers.serialize(
        object.tauxAcceptationPourcent,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JourneeCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JourneeCoursierBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'avances_en_cours_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.avancesEnCoursUnites = valueDes;
          break;
        case r'courses_livrees':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.coursesLivrees = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'gains_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.gainsUnites = valueDes;
          break;
        case r'note_centiemes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.noteCentiemes = valueDes;
          break;
        case r'plafond_retenu_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.plafondRetenuUnites = valueDes;
          break;
        case r'reste_disponible_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.resteDisponibleUnites = valueDes;
          break;
        case r'taux_acceptation_pourcent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.tauxAcceptationPourcent = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JourneeCoursier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JourneeCoursierBuilder();
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


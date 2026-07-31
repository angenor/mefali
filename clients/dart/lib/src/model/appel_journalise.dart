//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'appel_journalise.g.dart';

/// Un appel journalisé, tel que l'exploitation le lit.
///
/// Properties:
/// * [id] - Appel.
/// * [issue] - Issue DÉCLARÉE par le coursier — affichée, jamais un critère (R19).
/// * [motif] - `suivi` | `substitution` | `client_absent`.
/// * [passeLe] - Horodatage **serveur** — celui qui fonde l'espacement.
/// * [passeLeLocal] - Horodatage de l'appareil — observation seulement.
/// * [prestataireId] - Prestataire appelé (si `vers = vendeur`).
/// * [vers] - `client` | `vendeur`. **Aucun numéro** — le serveur n'en a jamais vu.
@BuiltValue()
abstract class AppelJournalise implements Built<AppelJournalise, AppelJournaliseBuilder> {
  /// Appel.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Issue DÉCLARÉE par le coursier — affichée, jamais un critère (R19).
  @BuiltValueField(wireName: r'issue')
  String get issue;

  /// `suivi` | `substitution` | `client_absent`.
  @BuiltValueField(wireName: r'motif')
  String get motif;

  /// Horodatage **serveur** — celui qui fonde l'espacement.
  @BuiltValueField(wireName: r'passe_le')
  DateTime get passeLe;

  /// Horodatage de l'appareil — observation seulement.
  @BuiltValueField(wireName: r'passe_le_local')
  DateTime get passeLeLocal;

  /// Prestataire appelé (si `vers = vendeur`).
  @BuiltValueField(wireName: r'prestataire_id')
  String? get prestataireId;

  /// `client` | `vendeur`. **Aucun numéro** — le serveur n'en a jamais vu.
  @BuiltValueField(wireName: r'vers')
  String get vers;

  AppelJournalise._();

  factory AppelJournalise([void updates(AppelJournaliseBuilder b)]) = _$AppelJournalise;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AppelJournaliseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AppelJournalise> get serializer => _$AppelJournaliseSerializer();
}

class _$AppelJournaliseSerializer implements PrimitiveSerializer<AppelJournalise> {
  @override
  final Iterable<Type> types = const [AppelJournalise, _$AppelJournalise];

  @override
  final String wireName = r'AppelJournalise';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AppelJournalise object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'issue';
    yield serializers.serialize(
      object.issue,
      specifiedType: const FullType(String),
    );
    yield r'motif';
    yield serializers.serialize(
      object.motif,
      specifiedType: const FullType(String),
    );
    yield r'passe_le';
    yield serializers.serialize(
      object.passeLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'passe_le_local';
    yield serializers.serialize(
      object.passeLeLocal,
      specifiedType: const FullType(DateTime),
    );
    if (object.prestataireId != null) {
      yield r'prestataire_id';
      yield serializers.serialize(
        object.prestataireId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'vers';
    yield serializers.serialize(
      object.vers,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AppelJournalise object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AppelJournaliseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.issue = valueDes;
          break;
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motif = valueDes;
          break;
        case r'passe_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.passeLe = valueDes;
          break;
        case r'passe_le_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.passeLeLocal = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.prestataireId = valueDes;
          break;
        case r'vers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vers = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AppelJournalise deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AppelJournaliseBuilder();
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


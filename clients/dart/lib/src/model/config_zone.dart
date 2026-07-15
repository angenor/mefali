//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/devise_dto.dart';
import 'package:mefali_api_client/src/model/categorie_dto.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'config_zone.g.dart';

/// Document `/config` (contrat) — sous-ensemble public de la config effective.
///
/// Properties:
/// * [categories] - Catégories actives dans la zone.
/// * [devise] - Devise résolue.
/// * [drapeaux] - Drapeaux (clés `drapeau.*` sans préfixe).
/// * [noteVocaleDureeMaxS] - Durée maximale d'une note vocale, en secondes — borne l'enregistreur des apps (FR-019). `null` si la zone ne la résout pas.
/// * [parametres] - Paramètres client (clés `client.*` sans préfixe).
/// * [textes] - Textes (clés `texte.*` sans préfixe) — clés i18n fr.
/// * [transportsActifs] - Slugs des types de transport actifs.
/// * [version] - Empreinte SHA-256 hex du document canonique (= ETag).
/// * [zone] - Zone servie.
@BuiltValue()
abstract class ConfigZone implements Built<ConfigZone, ConfigZoneBuilder> {
  /// Catégories actives dans la zone.
  @BuiltValueField(wireName: r'categories')
  BuiltList<CategorieDto> get categories;

  /// Devise résolue.
  @BuiltValueField(wireName: r'devise')
  DeviseDto get devise;

  /// Drapeaux (clés `drapeau.*` sans préfixe).
  @BuiltValueField(wireName: r'drapeaux')
  BuiltMap<String, bool> get drapeaux;

  /// Durée maximale d'une note vocale, en secondes — borne l'enregistreur des apps (FR-019). `null` si la zone ne la résout pas.
  @BuiltValueField(wireName: r'note_vocale_duree_max_s')
  int? get noteVocaleDureeMaxS;

  /// Paramètres client (clés `client.*` sans préfixe).
  @BuiltValueField(wireName: r'parametres')
  JsonObject get parametres;

  /// Textes (clés `texte.*` sans préfixe) — clés i18n fr.
  @BuiltValueField(wireName: r'textes')
  BuiltMap<String, String> get textes;

  /// Slugs des types de transport actifs.
  @BuiltValueField(wireName: r'transports_actifs')
  BuiltList<String> get transportsActifs;

  /// Empreinte SHA-256 hex du document canonique (= ETag).
  @BuiltValueField(wireName: r'version')
  String get version;

  /// Zone servie.
  @BuiltValueField(wireName: r'zone')
  String get zone;

  ConfigZone._();

  factory ConfigZone([void updates(ConfigZoneBuilder b)]) = _$ConfigZone;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConfigZoneBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConfigZone> get serializer => _$ConfigZoneSerializer();
}

class _$ConfigZoneSerializer implements PrimitiveSerializer<ConfigZone> {
  @override
  final Iterable<Type> types = const [ConfigZone, _$ConfigZone];

  @override
  final String wireName = r'ConfigZone';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConfigZone object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categories';
    yield serializers.serialize(
      object.categories,
      specifiedType: const FullType(BuiltList, [FullType(CategorieDto)]),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(DeviseDto),
    );
    yield r'drapeaux';
    yield serializers.serialize(
      object.drapeaux,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(bool)]),
    );
    if (object.noteVocaleDureeMaxS != null) {
      yield r'note_vocale_duree_max_s';
      yield serializers.serialize(
        object.noteVocaleDureeMaxS,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'parametres';
    yield serializers.serialize(
      object.parametres,
      specifiedType: const FullType(JsonObject),
    );
    yield r'textes';
    yield serializers.serialize(
      object.textes,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(String)]),
    );
    yield r'transports_actifs';
    yield serializers.serialize(
      object.transportsActifs,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(String),
    );
    yield r'zone';
    yield serializers.serialize(
      object.zone,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConfigZone object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConfigZoneBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CategorieDto)]),
          ) as BuiltList<CategorieDto>;
          result.categories.replace(valueDes);
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeviseDto),
          ) as DeviseDto;
          result.devise.replace(valueDes);
          break;
        case r'drapeaux':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(bool)]),
          ) as BuiltMap<String, bool>;
          result.drapeaux.replace(valueDes);
          break;
        case r'note_vocale_duree_max_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.noteVocaleDureeMaxS = valueDes;
          break;
        case r'parametres':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.parametres = valueDes;
          break;
        case r'textes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(String)]),
          ) as BuiltMap<String, String>;
          result.textes.replace(valueDes);
          break;
        case r'transports_actifs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.transportsActifs.replace(valueDes);
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.version = valueDes;
          break;
        case r'zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConfigZone deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConfigZoneBuilder();
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


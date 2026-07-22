//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/horaires_semaine_dto.dart';
import 'package:mefali_api_client/src/model/statut_boutique.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'site_admin_dto.g.dart';

/// Corps de `PUT /admin/prestataires/{id}/site` — upsert du site UNIQUE (FR-019 : aucune sélection de site n'existe nulle part).
///
/// Properties:
/// * [horaires] - Horaires hebdomadaires (remplacement complet).
/// * [positionLat] - Latitude relevée sur place.
/// * [positionLng] - Longitude.
/// * [statutInitial] - Statut initial — à la CRÉATION seulement (`ouvert` par défaut ; `en_pause`/`ferme_journee` refusés).
@BuiltValue()
abstract class SiteAdminDto implements Built<SiteAdminDto, SiteAdminDtoBuilder> {
  /// Horaires hebdomadaires (remplacement complet).
  @BuiltValueField(wireName: r'horaires')
  HorairesSemaineDto get horaires;

  /// Latitude relevée sur place.
  @BuiltValueField(wireName: r'position_lat')
  double get positionLat;

  /// Longitude.
  @BuiltValueField(wireName: r'position_lng')
  double get positionLng;

  /// Statut initial — à la CRÉATION seulement (`ouvert` par défaut ; `en_pause`/`ferme_journee` refusés).
  @BuiltValueField(wireName: r'statut_initial')
  StatutBoutique? get statutInitial;
  // enum statutInitialEnum {  ouvert,  ferme,  ferme_journee,  en_pause,  };

  SiteAdminDto._();

  factory SiteAdminDto([void updates(SiteAdminDtoBuilder b)]) = _$SiteAdminDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SiteAdminDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SiteAdminDto> get serializer => _$SiteAdminDtoSerializer();
}

class _$SiteAdminDtoSerializer implements PrimitiveSerializer<SiteAdminDto> {
  @override
  final Iterable<Type> types = const [SiteAdminDto, _$SiteAdminDto];

  @override
  final String wireName = r'SiteAdminDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SiteAdminDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'horaires';
    yield serializers.serialize(
      object.horaires,
      specifiedType: const FullType(HorairesSemaineDto),
    );
    yield r'position_lat';
    yield serializers.serialize(
      object.positionLat,
      specifiedType: const FullType(double),
    );
    yield r'position_lng';
    yield serializers.serialize(
      object.positionLng,
      specifiedType: const FullType(double),
    );
    if (object.statutInitial != null) {
      yield r'statut_initial';
      yield serializers.serialize(
        object.statutInitial,
        specifiedType: const FullType.nullable(StatutBoutique),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SiteAdminDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SiteAdminDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'horaires':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HorairesSemaineDto),
          ) as HorairesSemaineDto;
          result.horaires.replace(valueDes);
          break;
        case r'position_lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.positionLat = valueDes;
          break;
        case r'position_lng':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.positionLng = valueDes;
          break;
        case r'statut_initial':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(StatutBoutique),
          ) as StatutBoutique?;
          if (valueDes == null) continue;
          result.statutInitial = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SiteAdminDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SiteAdminDtoBuilder();
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


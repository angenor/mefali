//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/horaires_semaine_dto.dart';
import 'package:mefali_api_client/src/model/statut_boutique.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'site_admin_vue_dto.g.dart';

/// LE site unique, vue admin (GPS compris — jamais servi en public).
///
/// Properties:
/// * [horaires] - Horaires hebdomadaires.
/// * [pauseFin] - Échéance de pause, le cas échéant.
/// * [positionLat] - Latitude relevée sur place.
/// * [positionLng] - Longitude.
/// * [statutBoutique] - Statut DÉCLARÉ de la boutique.
@BuiltValue()
abstract class SiteAdminVueDto implements Built<SiteAdminVueDto, SiteAdminVueDtoBuilder> {
  /// Horaires hebdomadaires.
  @BuiltValueField(wireName: r'horaires')
  HorairesSemaineDto get horaires;

  /// Échéance de pause, le cas échéant.
  @BuiltValueField(wireName: r'pause_fin')
  DateTime? get pauseFin;

  /// Latitude relevée sur place.
  @BuiltValueField(wireName: r'position_lat')
  double get positionLat;

  /// Longitude.
  @BuiltValueField(wireName: r'position_lng')
  double get positionLng;

  /// Statut DÉCLARÉ de la boutique.
  @BuiltValueField(wireName: r'statut_boutique')
  StatutBoutique get statutBoutique;
  // enum statutBoutiqueEnum {  ouvert,  ferme,  ferme_journee,  en_pause,  };

  SiteAdminVueDto._();

  factory SiteAdminVueDto([void updates(SiteAdminVueDtoBuilder b)]) = _$SiteAdminVueDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SiteAdminVueDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SiteAdminVueDto> get serializer => _$SiteAdminVueDtoSerializer();
}

class _$SiteAdminVueDtoSerializer implements PrimitiveSerializer<SiteAdminVueDto> {
  @override
  final Iterable<Type> types = const [SiteAdminVueDto, _$SiteAdminVueDto];

  @override
  final String wireName = r'SiteAdminVueDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SiteAdminVueDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'horaires';
    yield serializers.serialize(
      object.horaires,
      specifiedType: const FullType(HorairesSemaineDto),
    );
    if (object.pauseFin != null) {
      yield r'pause_fin';
      yield serializers.serialize(
        object.pauseFin,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
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
    yield r'statut_boutique';
    yield serializers.serialize(
      object.statutBoutique,
      specifiedType: const FullType(StatutBoutique),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SiteAdminVueDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SiteAdminVueDtoBuilder result,
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
        case r'pause_fin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.pauseFin = valueDes;
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
        case r'statut_boutique':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatutBoutique),
          ) as StatutBoutique;
          result.statutBoutique = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SiteAdminVueDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SiteAdminVueDtoBuilder();
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


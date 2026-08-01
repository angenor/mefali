//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'preuve_appels.g.dart';

/// Preuve « appels » — nombre ET espacement (FR-056).
///
/// Properties:
/// * [espacementOk] - Faux dès qu'un appel a été écarté pour cause d'espacement.
/// * [faits] - Appels `client_absent` **retenus** (espacement respecté).
/// * [horodatages] - Horodatages **serveur** des appels retenus (affichage K4-1e).
/// * [issues] - Issues DÉCLARÉES par le coursier — affichées, jamais un critère (R19).
/// * [motifCle] - Pourquoi elle ne l'est pas — clé i18n.
/// * [ok] - Preuve réunie.
/// * [requis] - Appels exigés par la zone.
@BuiltValue()
abstract class PreuveAppels implements Built<PreuveAppels, PreuveAppelsBuilder> {
  /// Faux dès qu'un appel a été écarté pour cause d'espacement.
  @BuiltValueField(wireName: r'espacement_ok')
  bool get espacementOk;

  /// Appels `client_absent` **retenus** (espacement respecté).
  @BuiltValueField(wireName: r'faits')
  int get faits;

  /// Horodatages **serveur** des appels retenus (affichage K4-1e).
  @BuiltValueField(wireName: r'horodatages')
  BuiltList<DateTime> get horodatages;

  /// Issues DÉCLARÉES par le coursier — affichées, jamais un critère (R19).
  @BuiltValueField(wireName: r'issues')
  BuiltList<String> get issues;

  /// Pourquoi elle ne l'est pas — clé i18n.
  @BuiltValueField(wireName: r'motif_cle')
  String? get motifCle;

  /// Preuve réunie.
  @BuiltValueField(wireName: r'ok')
  bool get ok;

  /// Appels exigés par la zone.
  @BuiltValueField(wireName: r'requis')
  int get requis;

  PreuveAppels._();

  factory PreuveAppels([void updates(PreuveAppelsBuilder b)]) = _$PreuveAppels;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PreuveAppelsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PreuveAppels> get serializer => _$PreuveAppelsSerializer();
}

class _$PreuveAppelsSerializer implements PrimitiveSerializer<PreuveAppels> {
  @override
  final Iterable<Type> types = const [PreuveAppels, _$PreuveAppels];

  @override
  final String wireName = r'PreuveAppels';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PreuveAppels object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'espacement_ok';
    yield serializers.serialize(
      object.espacementOk,
      specifiedType: const FullType(bool),
    );
    yield r'faits';
    yield serializers.serialize(
      object.faits,
      specifiedType: const FullType(int),
    );
    yield r'horodatages';
    yield serializers.serialize(
      object.horodatages,
      specifiedType: const FullType(BuiltList, [FullType(DateTime)]),
    );
    yield r'issues';
    yield serializers.serialize(
      object.issues,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    if (object.motifCle != null) {
      yield r'motif_cle';
      yield serializers.serialize(
        object.motifCle,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'ok';
    yield serializers.serialize(
      object.ok,
      specifiedType: const FullType(bool),
    );
    yield r'requis';
    yield serializers.serialize(
      object.requis,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PreuveAppels object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PreuveAppelsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'espacement_ok':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.espacementOk = valueDes;
          break;
        case r'faits':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.faits = valueDes;
          break;
        case r'horodatages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DateTime)]),
          ) as BuiltList<DateTime>;
          result.horodatages.replace(valueDes);
          break;
        case r'issues':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.issues.replace(valueDes);
          break;
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motifCle = valueDes;
          break;
        case r'ok':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ok = valueDes;
          break;
        case r'requis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.requis = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PreuveAppels deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PreuveAppelsBuilder();
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


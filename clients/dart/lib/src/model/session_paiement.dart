//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_paiement.g.dart';

/// État d'une session de prépaiement, tel que l'app cliente le lit.
///
/// Properties:
/// * [accesPaiement] - Page de paiement à ouvrir dans le **navigateur système**.  `null` dès que l'état quitte `ouverte` : la colonne est effacée à l'issue, et un accès d'encaissement survivant à son paiement est une surface d'attaque sans usage (FR-006).
/// * [devise] - Devise ISO 4217.
/// * [etat] - État : `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`.
/// * [expireLe] - Échéance **persistée**, calculée depuis `paiement.session_duree_s`.
/// * [montantUnites] - Montant **figé** à l'ouverture (unités mineures).
/// * [moyen] - Moyen effectivement employé, tel que le fournisseur l'a dit. `inconnu` tant qu'il ne l'a pas dit — jamais deviné (FR-012).
/// * [restantS] - Secondes restantes, **calculées côté serveur** (FR-017).  L'horloge de l'app ne décide de rien : elle affiche un compte à rebours qu'elle recale sur cette valeur à chaque lecture. Vaut `0` sur une session échue, jamais un nombre négatif.
/// * [transactionId] - Transaction de paiement.
@BuiltValue()
abstract class SessionPaiement implements Built<SessionPaiement, SessionPaiementBuilder> {
  /// Page de paiement à ouvrir dans le **navigateur système**.  `null` dès que l'état quitte `ouverte` : la colonne est effacée à l'issue, et un accès d'encaissement survivant à son paiement est une surface d'attaque sans usage (FR-006).
  @BuiltValueField(wireName: r'acces_paiement')
  String? get accesPaiement;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// État : `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Échéance **persistée**, calculée depuis `paiement.session_duree_s`.
  @BuiltValueField(wireName: r'expire_le')
  DateTime get expireLe;

  /// Montant **figé** à l'ouverture (unités mineures).
  @BuiltValueField(wireName: r'montant_unites')
  int get montantUnites;

  /// Moyen effectivement employé, tel que le fournisseur l'a dit. `inconnu` tant qu'il ne l'a pas dit — jamais deviné (FR-012).
  @BuiltValueField(wireName: r'moyen')
  String get moyen;

  /// Secondes restantes, **calculées côté serveur** (FR-017).  L'horloge de l'app ne décide de rien : elle affiche un compte à rebours qu'elle recale sur cette valeur à chaque lecture. Vaut `0` sur une session échue, jamais un nombre négatif.
  @BuiltValueField(wireName: r'restant_s')
  int get restantS;

  /// Transaction de paiement.
  @BuiltValueField(wireName: r'transaction_id')
  String get transactionId;

  SessionPaiement._();

  factory SessionPaiement([void updates(SessionPaiementBuilder b)]) = _$SessionPaiement;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionPaiementBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionPaiement> get serializer => _$SessionPaiementSerializer();
}

class _$SessionPaiementSerializer implements PrimitiveSerializer<SessionPaiement> {
  @override
  final Iterable<Type> types = const [SessionPaiement, _$SessionPaiement];

  @override
  final String wireName = r'SessionPaiement';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionPaiement object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.accesPaiement != null) {
      yield r'acces_paiement';
      yield serializers.serialize(
        object.accesPaiement,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'expire_le';
    yield serializers.serialize(
      object.expireLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'montant_unites';
    yield serializers.serialize(
      object.montantUnites,
      specifiedType: const FullType(int),
    );
    yield r'moyen';
    yield serializers.serialize(
      object.moyen,
      specifiedType: const FullType(String),
    );
    yield r'restant_s';
    yield serializers.serialize(
      object.restantS,
      specifiedType: const FullType(int),
    );
    yield r'transaction_id';
    yield serializers.serialize(
      object.transactionId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionPaiement object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionPaiementBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'acces_paiement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.accesPaiement = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'expire_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.expireLe = valueDes;
          break;
        case r'montant_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantUnites = valueDes;
          break;
        case r'moyen':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.moyen = valueDes;
          break;
        case r'restant_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.restantS = valueDes;
          break;
        case r'transaction_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.transactionId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SessionPaiement deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionPaiementBuilder();
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


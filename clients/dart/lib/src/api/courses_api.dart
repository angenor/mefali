//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:mefali_api_client/src/api_util.dart';
import 'package:mefali_api_client/src/model/action_arret.dart';
import 'package:mefali_api_client/src/model/demande_echec.dart';
import 'package:mefali_api_client/src/model/demande_remise.dart';
import 'package:mefali_api_client/src/model/demande_rupture.dart';
import 'package:mefali_api_client/src/model/erreur_api.dart';
import 'package:mefali_api_client/src/model/etat_arret_course.dart';
import 'package:mefali_api_client/src/model/issue_echec.dart';
import 'package:mefali_api_client/src/model/issue_rupture.dart';
import 'package:mefali_api_client/src/model/resultat_remise.dart';

class CoursesApi {

  final Dio _dio;

  final Serializers _serializers;

  const CoursesApi(this._dio, this._serializers);

  /// CMD-04 — le coursier déclare son ARRIVÉE sur un arrêt.
  /// &#x60;arrive_le&#x60; est posé par le serveur : c&#39;est la borne de départ de l&#39;attente facturable (prime TRF-06). C&#39;est pour cela que &#x60;en_route → collecte&#x60; n&#39;existe pas — on ne saute pas une déclaration qui vaut de l&#39;argent.
  ///
  /// Parameters:
  /// * [livraisonId] - Course assignée à l'appelant.
  /// * [arretId] - Arrêt de cette course, déjà EN ROUTE.
  /// * [actionArret] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [EtatArretCourse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<EtatArretCourse>> arretArrive({ 
    required String livraisonId,
    required String arretId,
    required ActionArret actionArret,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/arrets/{arret_id}/arrive'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString()).replaceAll('{' r'arret_id' '}', encodeQueryParameter(_serializers, arretId, const FullType(String)).toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(ActionArret);
      _bodyData = _serializers.serialize(actionArret, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    EtatArretCourse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(EtatArretCourse),
      ) as EtatArretCourse;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<EtatArretCourse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// CMD-04 — le coursier déclare partir vers un arrêt.
  /// Le PREMIER départ d&#39;une course la fait passer EN_COLLECTE (data-model §3.2).
  ///
  /// Parameters:
  /// * [livraisonId] - Course assignée à l'appelant.
  /// * [arretId] - Arrêt de cette course.
  /// * [actionArret] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [EtatArretCourse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<EtatArretCourse>> arretEnRoute({ 
    required String livraisonId,
    required String arretId,
    required ActionArret actionArret,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/arrets/{arret_id}/en-route'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString()).replaceAll('{' r'arret_id' '}', encodeQueryParameter(_serializers, arretId, const FullType(String)).toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(ActionArret);
      _bodyData = _serializers.serialize(actionArret, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    EtatArretCourse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(EtatArretCourse),
      ) as EtatArretCourse;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<EtatArretCourse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// CMD-04/CMD-06 — arrêt entièrement indisponible (FR-051).
  /// Vendeur fermé, ou plus une seule ligne à collecter. L&#39;arrêt est compté **résolu** (la course continue), son montant avancé retombe à zéro, et ses lignes sont retirées de la commande — les frais de livraison, eux, ne bougent pas (FR-050).
  ///
  /// Parameters:
  /// * [livraisonId] - Course assignée à l'appelant.
  /// * [arretId] - Arrêt de cette course.
  /// * [actionArret] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [EtatArretCourse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<EtatArretCourse>> arretIndisponible({ 
    required String livraisonId,
    required String arretId,
    required ActionArret actionArret,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/arrets/{arret_id}/indisponible'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString()).replaceAll('{' r'arret_id' '}', encodeQueryParameter(_serializers, arretId, const FullType(String)).toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(ActionArret);
      _bodyData = _serializers.serialize(actionArret, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    EtatArretCourse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(EtatArretCourse),
      ) as EtatArretCourse;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<EtatArretCourse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// CMD-08 — le coursier déclare l&#39;échec ; le serveur déroule l&#39;arbre §7.5.
  /// **Refusé sans preuves** (&#x60;409 preuves_incompletes&#x60;, FR-056) : « le coursier ne perd jamais » suppose une trace — appels via l&#39;app espacés, présence géolocalisée, photo sur place. Sans elle, la promesse deviendrait une invitation.
  ///
  /// Parameters:
  /// * [livraisonId] - Course assignée à l'appelant.
  /// * [demandeEchec] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [IssueEchec] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<IssueEchec>> declarerEchec({ 
    required String livraisonId,
    required DemandeEchec demandeEchec,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/echec'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(DemandeEchec);
      _bodyData = _serializers.serialize(demandeEchec, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    IssueEchec? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(IssueEchec),
      ) as IssueEchec;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<IssueEchec>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// CMD-06 — le coursier déclare un article indisponible et applique la préférence du client (FR-044/045).
  /// Trois chemins, deux invariants : le **devis de livraison ne bouge jamais** (FR-050) et le total reste payé **en une fois** (FR-049). La proposition de remplacement est refusée si l&#39;article vient d&#39;un **autre vendeur** (FR-048) ou si l&#39;écart de prix dépasse le plafond de zone (FR-047).
  ///
  /// Parameters:
  /// * [livraisonId] - Course assignée à l'appelant.
  /// * [demande] - Partie JSON `demande`.
  /// * [photo] - Photo du remplacement (obligatoire pour `remplacer` — FR-045).
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [IssueRupture] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<IssueRupture>> declarerRupture({ 
    required String livraisonId,
    required DemandeRupture demande,
    MultipartFile? photo,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/substitutions'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'multipart/form-data',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = FormData.fromMap(<String, dynamic>{
        r'demande': encodeFormParameter(_serializers, demande, const FullType(DemandeRupture)),
        r'photo': photo,
      });

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    IssueRupture? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(IssueRupture),
      ) as IssueRupture;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<IssueRupture>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// CMD-08 — remise au client : QR, code de secours, ou dépôt convenu.
  /// ⚠ Le coursier ne reçoit **JAMAIS** le code (research R6) : il en a l&#39;empreinte, et c&#39;est le client qui le lui dicte. La comparaison a lieu côté serveur, sur la valeur stockée.  Trois codes faux et la **saisie par code** est verrouillée (&#x60;423&#x60;) jusqu&#39;à intervention admin : quatre chiffres se devinent en quelques minutes sans plafond. Le **scan QR reste ouvert** (FR-043, K4-1d) — le jeton est un aléa long, il ne se devine pas.  **Multipart** depuis CRS 010 (R18) : la partie &#x60;photo&#x60; voyage AVEC la demande, donc dans la file hors-ligne. Référencer un objet « déjà déposé » faisait de la voie dépôt la seule des trois à exiger du réseau.
  ///
  /// Parameters:
  /// * [livraisonId] - Course assignée à l'appelant.
  /// * [demande] - Partie JSON `demande`.
  /// * [photo] - Photo du dépôt sur place (mode `depot` — FR-048).
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [ResultatRemise] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ResultatRemise>> remise({ 
    required String livraisonId,
    required DemandeRemise demande,
    MultipartFile? photo,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/remise'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'multipart/form-data',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = FormData.fromMap(<String, dynamic>{
        r'demande': encodeFormParameter(_serializers, demande, const FullType(DemandeRemise)),
        r'photo': photo,
      });

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    ResultatRemise? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(ResultatRemise),
      ) as ResultatRemise;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<ResultatRemise>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}

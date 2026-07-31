//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:mefali_api_client/src/api_util.dart';
import 'package:mefali_api_client/src/model/decision_depot.dart';
import 'package:mefali_api_client/src/model/demande_deblocage.dart';
import 'package:mefali_api_client/src/model/demande_depot.dart';
import 'package:mefali_api_client/src/model/erreur_api.dart';
import 'package:mefali_api_client/src/model/preuves_exploitation.dart';
import 'package:mefali_api_client/src/model/remises_bloquees.dart';

class CoursierAdminApi {

  final Dio _dio;

  final Serializers _serializers;

  const CoursierAdminApi(this._dio, this._serializers);

  /// **FR-116** — ouvre (ou referme) la voie « dépôt convenu » sur une commande.
  /// Le cadrage §7.4-5 dit « mode dépôt autorisé **par le client** ». Tant qu&#39;aucune surface cliente ne le porte, c&#39;est l&#39;exploitation qui l&#39;ouvre à sa demande, au téléphone, avec un motif tracé — le contrat ne changera pas quand l&#39;app cliente reprendra la main.  **Fermé par défaut** : un défaut ouvert aurait rendu le dépôt possible partout sans que personne ne l&#39;ait décidé.
  ///
  /// Parameters:
  /// * [commandeId] - Commande concernée.
  /// * [demandeDepot] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [DecisionDepot] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<DecisionDepot>> autoriserDepot({ 
    required String commandeId,
    required DemandeDepot demandeDepot,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/admin/commandes/{commande_id}/depot'.replaceAll('{' r'commande_id' '}', encodeQueryParameter(_serializers, commandeId, const FullType(String)).toString());
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
      const _type = FullType(DemandeDepot);
      _bodyData = _serializers.serialize(demandeDepot, specifiedType: _type);

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

    DecisionDepot? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(DecisionDepot),
      ) as DecisionDepot;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<DecisionDepot>(
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

  /// **FR-055** — l&#39;exploitation lève le blocage du code, avec motif tracé.
  /// Le compteur d&#39;essais retombe à zéro : une levée qui laisserait le compteur au plafond serait inopérante — le premier essai suivant rebloquerait la commande, et l&#39;exploitation croirait avoir agi.
  ///
  /// Parameters:
  /// * [commandeId] - Commande dont le code est bloqué.
  /// * [demandeDeblocage] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> debloquerCode({ 
    required String commandeId,
    required DemandeDeblocage demandeDeblocage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/admin/commandes/{commande_id}/code/debloquer'.replaceAll('{' r'commande_id' '}', encodeQueryParameter(_serializers, commandeId, const FullType(String)).toString());
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
      const _type = FullType(DemandeDeblocage);
      _bodyData = _serializers.serialize(demandeDeblocage, specifiedType: _type);

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

    return _response;
  }

  /// CRS-05 (exploitation) — le dossier de preuves d&#39;une livraison (FR-063).
  /// C&#39;est ce qui rend les preuves **lisibles**. Sans cet endpoint, elles existeraient en base sans que personne ne puisse répondre à un client qui conteste un échec — et une preuve que personne ne lit ne protège personne.  ⚠ Aucun numéro de téléphone n&#39;en sort : le serveur n&#39;en a jamais journalisé.
  ///
  /// Parameters:
  /// * [livraisonId] - Livraison dont on lit les preuves.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PreuvesExploitation] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PreuvesExploitation>> preuvesDeLivraison({ 
    required String livraisonId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/admin/livraisons/{livraison_id}/preuves'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
    final _options = Options(
      method: r'GET',
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
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PreuvesExploitation? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(PreuvesExploitation),
      ) as PreuvesExploitation;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PreuvesExploitation>(
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

  /// **FR-044** — les remises dont le code est épuisé et le blocage non levé.
  /// Le verrou du code protège un secret à quatre chiffres, mais il laisse une commande à la porte du client. Sans cette lecture, l&#39;alerte &#x60;remise.code_epuise&#x60; partirait dans l&#39;outbox sans que personne ne puisse répondre — et un humain ne s&#39;abonne pas à un journal.
  ///
  /// Parameters:
  /// * [zoneId] - Zone dont on veut les blocages. Absente = toutes les zones.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [RemisesBloquees] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<RemisesBloquees>> remisesBloquees({ 
    String? zoneId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/admin/remises/bloquees';
    final _options = Options(
      method: r'GET',
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
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'zone_id': encodeQueryParameter(_serializers, zoneId, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    RemisesBloquees? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(RemisesBloquees),
      ) as RemisesBloquees;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<RemisesBloquees>(
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

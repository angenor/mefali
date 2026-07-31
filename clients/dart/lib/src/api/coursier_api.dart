//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:mefali_api_client/src/api_util.dart';
import 'package:mefali_api_client/src/model/appel_enregistre.dart';
import 'package:mefali_api_client/src/model/course_active_complete.dart';
import 'package:mefali_api_client/src/model/demande_appel.dart';
import 'package:mefali_api_client/src/model/demande_photo_preuve.dart';
import 'package:mefali_api_client/src/model/erreur_api.dart';
import 'package:mefali_api_client/src/model/etat_preuves.dart';
import 'package:mefali_api_client/src/model/issue_appel_declaree.dart';
import 'package:mefali_api_client/src/model/journee_coursier.dart';
import 'package:mefali_api_client/src/model/lot_de_presence.dart';
import 'package:mefali_api_client/src/model/photo_preuve_deposee.dart';
import 'package:mefali_api_client/src/model/presence_enregistree.dart';
import 'package:mefali_api_client/src/model/signalement_recu_dto.dart';
import 'package:mefali_api_client/src/model/signaler_rupture_dto.dart';
import 'package:mefali_api_client/src/model/vue_caisse.dart';

class CoursierApi {

  final Dio _dio;

  final Serializers _serializers;

  const CoursierApi(this._dio, this._serializers);

  /// CRS-03 — course active du coursier, **complète** et pré-provisionnée.
  /// Cet endpoint a déménagé de &#x60;qr_http&#x60; : son contenu n&#39;a plus rien à faire dans un domaine dont l&#39;objet est la plaque. Le chemin ne bouge pas, et les champs du cycle 006 restent là — l&#39;app livrée continue de fonctionner pendant la transition.  &#x60;204&#x60; sans course : ce n&#39;est pas une erreur, c&#39;est une journée qui commence.
  ///
  /// Parameters:
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [CourseActiveComplete] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<CourseActiveComplete>> courseActive({ 
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/active';
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

    CourseActiveComplete? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(CourseActiveComplete),
      ) as CourseActiveComplete;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<CourseActiveComplete>(
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

  /// CRS-03 — déclare (ou corrige) l&#39;issue d&#39;un appel (FR-036, R19).
  /// Le serveur ne peut pas l&#39;observer : l&#39;appel part du téléphone. Cette issue sert l&#39;affichage de K4-1e et **n&#39;est jamais un critère de preuve** — un coursier qui déclarerait « sans réponse » à tort ne gagne rien.
  ///
  /// Parameters:
  /// * [livraisonId] - Livraison de la course active du coursier.
  /// * [issueAppelDeclaree] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AppelEnregistre] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AppelEnregistre>> declarerIssueAppel({ 
    required String livraisonId,
    required IssueAppelDeclaree issueAppelDeclaree,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/appels'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
    final _options = Options(
      method: r'PATCH',
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
      const _type = FullType(IssueAppelDeclaree);
      _bodyData = _serializers.serialize(issueAppelDeclaree, specifiedType: _type);

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

    AppelEnregistre? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(AppelEnregistre),
      ) as AppelEnregistre;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AppelEnregistre>(
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

  /// CRS-05 — dépose une photo de preuve d&#39;échec (FR-056, FR-064).
  /// **Multipart** pour la même raison que la remise (R18) : la photo voyage AVEC la demande, donc dans la file hors-ligne. Une preuve qui exigerait du réseau au moment de la prise serait une preuve qu&#39;on ne peut pas réunir là où elle sert — devant une porte close, dans un quartier sans couverture.  Idempotent par &#x60;uuid_client&#x60; : le rejeu ne redépose rien et ne compte pas une seconde photo.
  ///
  /// Parameters:
  /// * [livraisonId] - Livraison de la course active du coursier.
  /// * [demande] - Partie JSON `demande`.
  /// * [photo] - Photo de la porte close.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PhotoPreuveDeposee] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PhotoPreuveDeposee>> deposerPhotoPreuve({ 
    required String livraisonId,
    required DemandePhotoPreuve demande,
    required MultipartFile photo,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/preuves/photo'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
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
        r'demande': encodeFormParameter(_serializers, demande, const FullType(DemandePhotoPreuve)),
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

    PhotoPreuveDeposee? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(PhotoPreuveDeposee),
      ) as PhotoPreuveDeposee;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PhotoPreuveDeposee>(
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

  /// CRS-05 — enregistre un lot de relevés de présence (FR-061, FR-064).
  /// L&#39;app envoie des **échantillons**, jamais une durée : c&#39;est le serveur qui compte, en ignorant tout intervalle supérieur au « trou » de la zone. Sans cette règle, deux relevés espacés de dix minutes vaudraient dix minutes de présence, et un aller-retour vaudrait une attente (R8).  Idempotent par &#x60;uuid_client&#x60; : un lot rejoué par la file rend le même corps.
  ///
  /// Parameters:
  /// * [livraisonId] - Livraison de la course active du coursier.
  /// * [lotDePresence] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PresenceEnregistree] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PresenceEnregistree>> enregistrerPresence({ 
    required String livraisonId,
    required LotDePresence lotDePresence,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/presence'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
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
      const _type = FullType(LotDePresence);
      _bodyData = _serializers.serialize(lotDePresence, specifiedType: _type);

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

    PresenceEnregistree? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(PresenceEnregistree),
      ) as PresenceEnregistree;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PresenceEnregistree>(
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

  /// CRS-05 — état des trois preuves et **ce qui manque** (FR-058, FR-062).
  /// C&#39;est la **même fonction** que celle qui garde &#x60;POST /courses/{id}/echec&#x60; : l&#39;écran et le serveur ne peuvent pas diverger (FR-059, FR-060). Un bouton actif dont la déclaration serait refusée serait pire qu&#39;un bouton inactif.
  ///
  /// Parameters:
  /// * [livraisonId] - Livraison de la course active du coursier.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [EtatPreuves] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<EtatPreuves>> etatPreuves({ 
    required String livraisonId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/preuves'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
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

    EtatPreuves? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(EtatPreuves),
      ) as EtatPreuves;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<EtatPreuves>(
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

  /// CRS-03 — journalise un appel passé **via l&#39;app** (FR-030, FR-031, FR-033).
  /// ⚠ **Aucun numéro** n&#39;est transmis ni journalisé : le serveur ne voit pas l&#39;appel, il part du téléphone. Il en garde l&#39;intention, la direction, le motif et l&#39;issue déclarée.  Idempotent par &#x60;uuid_client&#x60; : le rejeu rend &#x60;200&#x60; et le même corps, sans seconde ligne ni second événement.
  ///
  /// Parameters:
  /// * [livraisonId] - Livraison de la course active du coursier.
  /// * [demandeAppel] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AppelEnregistre] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AppelEnregistre>> journaliserAppel({ 
    required String livraisonId,
    required DemandeAppel demandeAppel,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/courses/{livraison_id}/appels'.replaceAll('{' r'livraison_id' '}', encodeQueryParameter(_serializers, livraisonId, const FullType(String)).toString());
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
      const _type = FullType(DemandeAppel);
      _bodyData = _serializers.serialize(demandeAppel, specifiedType: _type);

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

    AppelEnregistre? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(AppelEnregistre),
      ) as AppelEnregistre;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AppelEnregistre>(
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

  /// CRS-06 — la caisse du coursier (FR-067 → FR-077).
  /// Yao sort de l&#39;argent de sa poche à chaque arrêt et le récupère chez le client. Entre les deux, il porte le risque : cet endpoint est la seule façon qu&#39;il a de vérifier que « le coursier ne perd jamais » est vrai.  ⚠ Une avance sur commande **prépayée** ne sera jamais soldée en espèces (PAY, tranche T3) : elle reste comptée et **annoncée comme telle** plutôt que masquée — la masquer la ferait disparaître de l&#39;écran dont c&#39;est la seule raison d&#39;être (R10, FR-117).
  ///
  /// Parameters:
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [VueCaisse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<VueCaisse>> maCaisse({ 
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/moi/caisse';
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

    VueCaisse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(VueCaisse),
      ) as VueCaisse;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<VueCaisse>(
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

  /// CRS-01 — la journée du coursier (FR-091 → FR-095).
  /// ⚠ **Composé DANS CE HANDLER**, et c&#39;est le seul du cycle : les gains et les avances viennent de &#x60;coursier&#x60;, le plafond retenu et le taux d&#39;acceptation de &#x60;dispatch&#x60;. Faire dépendre l&#39;un de l&#39;autre pour deux nombres créerait une arête permanente entre deux domaines qui n&#39;ont rien à se dire (&#x60;contracts/ports-coursier.md&#x60; §2). &#x60;api&#x60; détient déjà les deux dépôts.  La **note reste absente** : le module d&#39;avis n&#39;existe pas, et K1 afficherait un « 4,8 / 5 » que rien ne peut alimenter. Le cycle 009 avait déjà tranché.
  ///
  /// Parameters:
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [JourneeCoursier] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<JourneeCoursier>> maJournee({ 
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/moi/journee';
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

    JourneeCoursier? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(JourneeCoursier),
      ) as JourneeCoursier;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<JourneeCoursier>(
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

  /// Signale un article introuvable — REFUSÉ (et compté nulle part) sans commande active comportant un arrêt chez ce prestataire (FR-038).
  /// 
  ///
  /// Parameters:
  /// * [idempotencyKey] - UUID généré CÔTÉ CLIENT — devient l'identifiant du signalement, rejeu réseau idempotent (FR-039).
  /// * [signalerRuptureDto] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [SignalementRecuDto] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<SignalementRecuDto>> signalerRupture({ 
    required String idempotencyKey,
    required SignalerRuptureDto signalerRuptureDto,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/coursier/signalements-rupture';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'Idempotency-Key': idempotencyKey,
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
      const _type = FullType(SignalerRuptureDto);
      _bodyData = _serializers.serialize(signalerRuptureDto, specifiedType: _type);

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

    SignalementRecuDto? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(SignalementRecuDto),
      ) as SignalementRecuDto;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<SignalementRecuDto>(
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

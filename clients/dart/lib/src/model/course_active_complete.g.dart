// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_active_complete.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CourseActiveComplete extends CourseActiveComplete {
  @override
  final BuiltList<ArretCourse> arrets;
  @override
  final ClientCourse client;
  @override
  final String commandeId;
  @override
  final String devise;
  @override
  final String etat;
  @override
  final String livraisonId;
  @override
  final RemisePreprovisionnee remise;

  factory _$CourseActiveComplete(
          [void Function(CourseActiveCompleteBuilder)? updates]) =>
      (CourseActiveCompleteBuilder()..update(updates))._build();

  _$CourseActiveComplete._(
      {required this.arrets,
      required this.client,
      required this.commandeId,
      required this.devise,
      required this.etat,
      required this.livraisonId,
      required this.remise})
      : super._();
  @override
  CourseActiveComplete rebuild(
          void Function(CourseActiveCompleteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CourseActiveCompleteBuilder toBuilder() =>
      CourseActiveCompleteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CourseActiveComplete &&
        arrets == other.arrets &&
        client == other.client &&
        commandeId == other.commandeId &&
        devise == other.devise &&
        etat == other.etat &&
        livraisonId == other.livraisonId &&
        remise == other.remise;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arrets.hashCode);
    _$hash = $jc(_$hash, client.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, remise.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CourseActiveComplete')
          ..add('arrets', arrets)
          ..add('client', client)
          ..add('commandeId', commandeId)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('livraisonId', livraisonId)
          ..add('remise', remise))
        .toString();
  }
}

class CourseActiveCompleteBuilder
    implements Builder<CourseActiveComplete, CourseActiveCompleteBuilder> {
  _$CourseActiveComplete? _$v;

  ListBuilder<ArretCourse>? _arrets;
  ListBuilder<ArretCourse> get arrets =>
      _$this._arrets ??= ListBuilder<ArretCourse>();
  set arrets(ListBuilder<ArretCourse>? arrets) => _$this._arrets = arrets;

  ClientCourseBuilder? _client;
  ClientCourseBuilder get client => _$this._client ??= ClientCourseBuilder();
  set client(ClientCourseBuilder? client) => _$this._client = client;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  RemisePreprovisionneeBuilder? _remise;
  RemisePreprovisionneeBuilder get remise =>
      _$this._remise ??= RemisePreprovisionneeBuilder();
  set remise(RemisePreprovisionneeBuilder? remise) => _$this._remise = remise;

  CourseActiveCompleteBuilder() {
    CourseActiveComplete._defaults(this);
  }

  CourseActiveCompleteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arrets = $v.arrets.toBuilder();
      _client = $v.client.toBuilder();
      _commandeId = $v.commandeId;
      _devise = $v.devise;
      _etat = $v.etat;
      _livraisonId = $v.livraisonId;
      _remise = $v.remise.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CourseActiveComplete other) {
    _$v = other as _$CourseActiveComplete;
  }

  @override
  void update(void Function(CourseActiveCompleteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CourseActiveComplete build() => _build();

  _$CourseActiveComplete _build() {
    _$CourseActiveComplete _$result;
    try {
      _$result = _$v ??
          _$CourseActiveComplete._(
            arrets: arrets.build(),
            client: client.build(),
            commandeId: BuiltValueNullFieldError.checkNotNull(
                commandeId, r'CourseActiveComplete', 'commandeId'),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'CourseActiveComplete', 'devise'),
            etat: BuiltValueNullFieldError.checkNotNull(
                etat, r'CourseActiveComplete', 'etat'),
            livraisonId: BuiltValueNullFieldError.checkNotNull(
                livraisonId, r'CourseActiveComplete', 'livraisonId'),
            remise: remise.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'arrets';
        arrets.build();
        _$failedField = 'client';
        client.build();

        _$failedField = 'remise';
        remise.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CourseActiveComplete', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

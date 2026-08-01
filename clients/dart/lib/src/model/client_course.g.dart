// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_course.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ClientCourse extends ClientCourse {
  @override
  final bool depotAutorise;
  @override
  final double? lieuLat;
  @override
  final double? lieuLon;
  @override
  final String? nomUsage;
  @override
  final String? repereTexte;
  @override
  final int? repereVocalDureeS;
  @override
  final String? repereVocalUrl;
  @override
  final String? telephone;

  factory _$ClientCourse([void Function(ClientCourseBuilder)? updates]) =>
      (ClientCourseBuilder()..update(updates))._build();

  _$ClientCourse._(
      {required this.depotAutorise,
      this.lieuLat,
      this.lieuLon,
      this.nomUsage,
      this.repereTexte,
      this.repereVocalDureeS,
      this.repereVocalUrl,
      this.telephone})
      : super._();
  @override
  ClientCourse rebuild(void Function(ClientCourseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ClientCourseBuilder toBuilder() => ClientCourseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ClientCourse &&
        depotAutorise == other.depotAutorise &&
        lieuLat == other.lieuLat &&
        lieuLon == other.lieuLon &&
        nomUsage == other.nomUsage &&
        repereTexte == other.repereTexte &&
        repereVocalDureeS == other.repereVocalDureeS &&
        repereVocalUrl == other.repereVocalUrl &&
        telephone == other.telephone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, depotAutorise.hashCode);
    _$hash = $jc(_$hash, lieuLat.hashCode);
    _$hash = $jc(_$hash, lieuLon.hashCode);
    _$hash = $jc(_$hash, nomUsage.hashCode);
    _$hash = $jc(_$hash, repereTexte.hashCode);
    _$hash = $jc(_$hash, repereVocalDureeS.hashCode);
    _$hash = $jc(_$hash, repereVocalUrl.hashCode);
    _$hash = $jc(_$hash, telephone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ClientCourse')
          ..add('depotAutorise', depotAutorise)
          ..add('lieuLat', lieuLat)
          ..add('lieuLon', lieuLon)
          ..add('nomUsage', nomUsage)
          ..add('repereTexte', repereTexte)
          ..add('repereVocalDureeS', repereVocalDureeS)
          ..add('repereVocalUrl', repereVocalUrl)
          ..add('telephone', telephone))
        .toString();
  }
}

class ClientCourseBuilder
    implements Builder<ClientCourse, ClientCourseBuilder> {
  _$ClientCourse? _$v;

  bool? _depotAutorise;
  bool? get depotAutorise => _$this._depotAutorise;
  set depotAutorise(bool? depotAutorise) =>
      _$this._depotAutorise = depotAutorise;

  double? _lieuLat;
  double? get lieuLat => _$this._lieuLat;
  set lieuLat(double? lieuLat) => _$this._lieuLat = lieuLat;

  double? _lieuLon;
  double? get lieuLon => _$this._lieuLon;
  set lieuLon(double? lieuLon) => _$this._lieuLon = lieuLon;

  String? _nomUsage;
  String? get nomUsage => _$this._nomUsage;
  set nomUsage(String? nomUsage) => _$this._nomUsage = nomUsage;

  String? _repereTexte;
  String? get repereTexte => _$this._repereTexte;
  set repereTexte(String? repereTexte) => _$this._repereTexte = repereTexte;

  int? _repereVocalDureeS;
  int? get repereVocalDureeS => _$this._repereVocalDureeS;
  set repereVocalDureeS(int? repereVocalDureeS) =>
      _$this._repereVocalDureeS = repereVocalDureeS;

  String? _repereVocalUrl;
  String? get repereVocalUrl => _$this._repereVocalUrl;
  set repereVocalUrl(String? repereVocalUrl) =>
      _$this._repereVocalUrl = repereVocalUrl;

  String? _telephone;
  String? get telephone => _$this._telephone;
  set telephone(String? telephone) => _$this._telephone = telephone;

  ClientCourseBuilder() {
    ClientCourse._defaults(this);
  }

  ClientCourseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _depotAutorise = $v.depotAutorise;
      _lieuLat = $v.lieuLat;
      _lieuLon = $v.lieuLon;
      _nomUsage = $v.nomUsage;
      _repereTexte = $v.repereTexte;
      _repereVocalDureeS = $v.repereVocalDureeS;
      _repereVocalUrl = $v.repereVocalUrl;
      _telephone = $v.telephone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ClientCourse other) {
    _$v = other as _$ClientCourse;
  }

  @override
  void update(void Function(ClientCourseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ClientCourse build() => _build();

  _$ClientCourse _build() {
    final _$result = _$v ??
        _$ClientCourse._(
          depotAutorise: BuiltValueNullFieldError.checkNotNull(
              depotAutorise, r'ClientCourse', 'depotAutorise'),
          lieuLat: lieuLat,
          lieuLon: lieuLon,
          nomUsage: nomUsage,
          repereTexte: repereTexte,
          repereVocalDureeS: repereVocalDureeS,
          repereVocalUrl: repereVocalUrl,
          telephone: telephone,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

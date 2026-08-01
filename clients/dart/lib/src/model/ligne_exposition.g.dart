// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ligne_exposition.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LigneExposition extends LigneExposition {
  @override
  final int avanceUnites;
  @override
  final int courses;
  @override
  final String coursierId;
  @override
  final String nom;

  factory _$LigneExposition([void Function(LigneExpositionBuilder)? updates]) =>
      (LigneExpositionBuilder()..update(updates))._build();

  _$LigneExposition._(
      {required this.avanceUnites,
      required this.courses,
      required this.coursierId,
      required this.nom})
      : super._();
  @override
  LigneExposition rebuild(void Function(LigneExpositionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LigneExpositionBuilder toBuilder() => LigneExpositionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LigneExposition &&
        avanceUnites == other.avanceUnites &&
        courses == other.courses &&
        coursierId == other.coursierId &&
        nom == other.nom;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, avanceUnites.hashCode);
    _$hash = $jc(_$hash, courses.hashCode);
    _$hash = $jc(_$hash, coursierId.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LigneExposition')
          ..add('avanceUnites', avanceUnites)
          ..add('courses', courses)
          ..add('coursierId', coursierId)
          ..add('nom', nom))
        .toString();
  }
}

class LigneExpositionBuilder
    implements Builder<LigneExposition, LigneExpositionBuilder> {
  _$LigneExposition? _$v;

  int? _avanceUnites;
  int? get avanceUnites => _$this._avanceUnites;
  set avanceUnites(int? avanceUnites) => _$this._avanceUnites = avanceUnites;

  int? _courses;
  int? get courses => _$this._courses;
  set courses(int? courses) => _$this._courses = courses;

  String? _coursierId;
  String? get coursierId => _$this._coursierId;
  set coursierId(String? coursierId) => _$this._coursierId = coursierId;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  LigneExpositionBuilder() {
    LigneExposition._defaults(this);
  }

  LigneExpositionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _avanceUnites = $v.avanceUnites;
      _courses = $v.courses;
      _coursierId = $v.coursierId;
      _nom = $v.nom;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LigneExposition other) {
    _$v = other as _$LigneExposition;
  }

  @override
  void update(void Function(LigneExpositionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LigneExposition build() => _build();

  _$LigneExposition _build() {
    final _$result = _$v ??
        _$LigneExposition._(
          avanceUnites: BuiltValueNullFieldError.checkNotNull(
              avanceUnites, r'LigneExposition', 'avanceUnites'),
          courses: BuiltValueNullFieldError.checkNotNull(
              courses, r'LigneExposition', 'courses'),
          coursierId: BuiltValueNullFieldError.checkNotNull(
              coursierId, r'LigneExposition', 'coursierId'),
          nom: BuiltValueNullFieldError.checkNotNull(
              nom, r'LigneExposition', 'nom'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journee_coursier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JourneeCoursier extends JourneeCoursier {
  @override
  final int avancesEnCoursUnites;
  @override
  final int coursesLivrees;
  @override
  final String devise;
  @override
  final int gainsUnites;
  @override
  final int? noteCentiemes;
  @override
  final int plafondRetenuUnites;
  @override
  final int resteDisponibleUnites;
  @override
  final int? tauxAcceptationPourcent;

  factory _$JourneeCoursier([void Function(JourneeCoursierBuilder)? updates]) =>
      (JourneeCoursierBuilder()..update(updates))._build();

  _$JourneeCoursier._(
      {required this.avancesEnCoursUnites,
      required this.coursesLivrees,
      required this.devise,
      required this.gainsUnites,
      this.noteCentiemes,
      required this.plafondRetenuUnites,
      required this.resteDisponibleUnites,
      this.tauxAcceptationPourcent})
      : super._();
  @override
  JourneeCoursier rebuild(void Function(JourneeCoursierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JourneeCoursierBuilder toBuilder() => JourneeCoursierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JourneeCoursier &&
        avancesEnCoursUnites == other.avancesEnCoursUnites &&
        coursesLivrees == other.coursesLivrees &&
        devise == other.devise &&
        gainsUnites == other.gainsUnites &&
        noteCentiemes == other.noteCentiemes &&
        plafondRetenuUnites == other.plafondRetenuUnites &&
        resteDisponibleUnites == other.resteDisponibleUnites &&
        tauxAcceptationPourcent == other.tauxAcceptationPourcent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, avancesEnCoursUnites.hashCode);
    _$hash = $jc(_$hash, coursesLivrees.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, gainsUnites.hashCode);
    _$hash = $jc(_$hash, noteCentiemes.hashCode);
    _$hash = $jc(_$hash, plafondRetenuUnites.hashCode);
    _$hash = $jc(_$hash, resteDisponibleUnites.hashCode);
    _$hash = $jc(_$hash, tauxAcceptationPourcent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JourneeCoursier')
          ..add('avancesEnCoursUnites', avancesEnCoursUnites)
          ..add('coursesLivrees', coursesLivrees)
          ..add('devise', devise)
          ..add('gainsUnites', gainsUnites)
          ..add('noteCentiemes', noteCentiemes)
          ..add('plafondRetenuUnites', plafondRetenuUnites)
          ..add('resteDisponibleUnites', resteDisponibleUnites)
          ..add('tauxAcceptationPourcent', tauxAcceptationPourcent))
        .toString();
  }
}

class JourneeCoursierBuilder
    implements Builder<JourneeCoursier, JourneeCoursierBuilder> {
  _$JourneeCoursier? _$v;

  int? _avancesEnCoursUnites;
  int? get avancesEnCoursUnites => _$this._avancesEnCoursUnites;
  set avancesEnCoursUnites(int? avancesEnCoursUnites) =>
      _$this._avancesEnCoursUnites = avancesEnCoursUnites;

  int? _coursesLivrees;
  int? get coursesLivrees => _$this._coursesLivrees;
  set coursesLivrees(int? coursesLivrees) =>
      _$this._coursesLivrees = coursesLivrees;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _gainsUnites;
  int? get gainsUnites => _$this._gainsUnites;
  set gainsUnites(int? gainsUnites) => _$this._gainsUnites = gainsUnites;

  int? _noteCentiemes;
  int? get noteCentiemes => _$this._noteCentiemes;
  set noteCentiemes(int? noteCentiemes) =>
      _$this._noteCentiemes = noteCentiemes;

  int? _plafondRetenuUnites;
  int? get plafondRetenuUnites => _$this._plafondRetenuUnites;
  set plafondRetenuUnites(int? plafondRetenuUnites) =>
      _$this._plafondRetenuUnites = plafondRetenuUnites;

  int? _resteDisponibleUnites;
  int? get resteDisponibleUnites => _$this._resteDisponibleUnites;
  set resteDisponibleUnites(int? resteDisponibleUnites) =>
      _$this._resteDisponibleUnites = resteDisponibleUnites;

  int? _tauxAcceptationPourcent;
  int? get tauxAcceptationPourcent => _$this._tauxAcceptationPourcent;
  set tauxAcceptationPourcent(int? tauxAcceptationPourcent) =>
      _$this._tauxAcceptationPourcent = tauxAcceptationPourcent;

  JourneeCoursierBuilder() {
    JourneeCoursier._defaults(this);
  }

  JourneeCoursierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _avancesEnCoursUnites = $v.avancesEnCoursUnites;
      _coursesLivrees = $v.coursesLivrees;
      _devise = $v.devise;
      _gainsUnites = $v.gainsUnites;
      _noteCentiemes = $v.noteCentiemes;
      _plafondRetenuUnites = $v.plafondRetenuUnites;
      _resteDisponibleUnites = $v.resteDisponibleUnites;
      _tauxAcceptationPourcent = $v.tauxAcceptationPourcent;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JourneeCoursier other) {
    _$v = other as _$JourneeCoursier;
  }

  @override
  void update(void Function(JourneeCoursierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JourneeCoursier build() => _build();

  _$JourneeCoursier _build() {
    final _$result = _$v ??
        _$JourneeCoursier._(
          avancesEnCoursUnites: BuiltValueNullFieldError.checkNotNull(
              avancesEnCoursUnites, r'JourneeCoursier', 'avancesEnCoursUnites'),
          coursesLivrees: BuiltValueNullFieldError.checkNotNull(
              coursesLivrees, r'JourneeCoursier', 'coursesLivrees'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'JourneeCoursier', 'devise'),
          gainsUnites: BuiltValueNullFieldError.checkNotNull(
              gainsUnites, r'JourneeCoursier', 'gainsUnites'),
          noteCentiemes: noteCentiemes,
          plafondRetenuUnites: BuiltValueNullFieldError.checkNotNull(
              plafondRetenuUnites, r'JourneeCoursier', 'plafondRetenuUnites'),
          resteDisponibleUnites: BuiltValueNullFieldError.checkNotNull(
              resteDisponibleUnites,
              r'JourneeCoursier',
              'resteDisponibleUnites'),
          tauxAcceptationPourcent: tauxAcceptationPourcent,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

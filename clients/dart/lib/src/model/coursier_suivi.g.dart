// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coursier_suivi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CoursierSuivi extends CoursierSuivi {
  @override
  final bool appelPossible;
  @override
  final String id;
  @override
  final double? note;
  @override
  final String? prenom;

  factory _$CoursierSuivi([void Function(CoursierSuiviBuilder)? updates]) =>
      (CoursierSuiviBuilder()..update(updates))._build();

  _$CoursierSuivi._(
      {required this.appelPossible, required this.id, this.note, this.prenom})
      : super._();
  @override
  CoursierSuivi rebuild(void Function(CoursierSuiviBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CoursierSuiviBuilder toBuilder() => CoursierSuiviBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CoursierSuivi &&
        appelPossible == other.appelPossible &&
        id == other.id &&
        note == other.note &&
        prenom == other.prenom;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appelPossible.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, prenom.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CoursierSuivi')
          ..add('appelPossible', appelPossible)
          ..add('id', id)
          ..add('note', note)
          ..add('prenom', prenom))
        .toString();
  }
}

class CoursierSuiviBuilder
    implements Builder<CoursierSuivi, CoursierSuiviBuilder> {
  _$CoursierSuivi? _$v;

  bool? _appelPossible;
  bool? get appelPossible => _$this._appelPossible;
  set appelPossible(bool? appelPossible) =>
      _$this._appelPossible = appelPossible;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  double? _note;
  double? get note => _$this._note;
  set note(double? note) => _$this._note = note;

  String? _prenom;
  String? get prenom => _$this._prenom;
  set prenom(String? prenom) => _$this._prenom = prenom;

  CoursierSuiviBuilder() {
    CoursierSuivi._defaults(this);
  }

  CoursierSuiviBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appelPossible = $v.appelPossible;
      _id = $v.id;
      _note = $v.note;
      _prenom = $v.prenom;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CoursierSuivi other) {
    _$v = other as _$CoursierSuivi;
  }

  @override
  void update(void Function(CoursierSuiviBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CoursierSuivi build() => _build();

  _$CoursierSuivi _build() {
    final _$result = _$v ??
        _$CoursierSuivi._(
          appelPossible: BuiltValueNullFieldError.checkNotNull(
              appelPossible, r'CoursierSuivi', 'appelPossible'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'CoursierSuivi', 'id'),
          note: note,
          prenom: prenom,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

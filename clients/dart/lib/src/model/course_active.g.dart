// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_active.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CourseActive extends CourseActive {
  @override
  final BuiltList<ArretPreProvisionne> arrets;
  @override
  final String? livraisonId;

  factory _$CourseActive([void Function(CourseActiveBuilder)? updates]) =>
      (CourseActiveBuilder()..update(updates))._build();

  _$CourseActive._({required this.arrets, this.livraisonId}) : super._();
  @override
  CourseActive rebuild(void Function(CourseActiveBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CourseActiveBuilder toBuilder() => CourseActiveBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CourseActive &&
        arrets == other.arrets &&
        livraisonId == other.livraisonId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arrets.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CourseActive')
          ..add('arrets', arrets)
          ..add('livraisonId', livraisonId))
        .toString();
  }
}

class CourseActiveBuilder
    implements Builder<CourseActive, CourseActiveBuilder> {
  _$CourseActive? _$v;

  ListBuilder<ArretPreProvisionne>? _arrets;
  ListBuilder<ArretPreProvisionne> get arrets =>
      _$this._arrets ??= ListBuilder<ArretPreProvisionne>();
  set arrets(ListBuilder<ArretPreProvisionne>? arrets) =>
      _$this._arrets = arrets;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  CourseActiveBuilder() {
    CourseActive._defaults(this);
  }

  CourseActiveBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arrets = $v.arrets.toBuilder();
      _livraisonId = $v.livraisonId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CourseActive other) {
    _$v = other as _$CourseActive;
  }

  @override
  void update(void Function(CourseActiveBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CourseActive build() => _build();

  _$CourseActive _build() {
    _$CourseActive _$result;
    try {
      _$result = _$v ??
          _$CourseActive._(
            arrets: arrets.build(),
            livraisonId: livraisonId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'arrets';
        arrets.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CourseActive', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

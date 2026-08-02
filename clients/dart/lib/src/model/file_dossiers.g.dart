// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_dossiers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FileDossiers extends FileDossiers {
  @override
  final BuiltList<DossierPaiement> dossiers;

  factory _$FileDossiers([void Function(FileDossiersBuilder)? updates]) =>
      (FileDossiersBuilder()..update(updates))._build();

  _$FileDossiers._({required this.dossiers}) : super._();
  @override
  FileDossiers rebuild(void Function(FileDossiersBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FileDossiersBuilder toBuilder() => FileDossiersBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FileDossiers && dossiers == other.dossiers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, dossiers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FileDossiers')
          ..add('dossiers', dossiers))
        .toString();
  }
}

class FileDossiersBuilder
    implements Builder<FileDossiers, FileDossiersBuilder> {
  _$FileDossiers? _$v;

  ListBuilder<DossierPaiement>? _dossiers;
  ListBuilder<DossierPaiement> get dossiers =>
      _$this._dossiers ??= ListBuilder<DossierPaiement>();
  set dossiers(ListBuilder<DossierPaiement>? dossiers) =>
      _$this._dossiers = dossiers;

  FileDossiersBuilder() {
    FileDossiers._defaults(this);
  }

  FileDossiersBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dossiers = $v.dossiers.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FileDossiers other) {
    _$v = other as _$FileDossiers;
  }

  @override
  void update(void Function(FileDossiersBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FileDossiers build() => _build();

  _$FileDossiers _build() {
    _$FileDossiers _$result;
    try {
      _$result = _$v ??
          _$FileDossiers._(
            dossiers: dossiers.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'dossiers';
        dossiers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FileDossiers', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

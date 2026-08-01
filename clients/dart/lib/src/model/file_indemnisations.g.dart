// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_indemnisations.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FileIndemnisations extends FileIndemnisations {
  @override
  final BuiltList<IndemnisationVue> indemnisations;

  factory _$FileIndemnisations(
          [void Function(FileIndemnisationsBuilder)? updates]) =>
      (FileIndemnisationsBuilder()..update(updates))._build();

  _$FileIndemnisations._({required this.indemnisations}) : super._();
  @override
  FileIndemnisations rebuild(
          void Function(FileIndemnisationsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FileIndemnisationsBuilder toBuilder() =>
      FileIndemnisationsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FileIndemnisations &&
        indemnisations == other.indemnisations;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, indemnisations.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FileIndemnisations')
          ..add('indemnisations', indemnisations))
        .toString();
  }
}

class FileIndemnisationsBuilder
    implements Builder<FileIndemnisations, FileIndemnisationsBuilder> {
  _$FileIndemnisations? _$v;

  ListBuilder<IndemnisationVue>? _indemnisations;
  ListBuilder<IndemnisationVue> get indemnisations =>
      _$this._indemnisations ??= ListBuilder<IndemnisationVue>();
  set indemnisations(ListBuilder<IndemnisationVue>? indemnisations) =>
      _$this._indemnisations = indemnisations;

  FileIndemnisationsBuilder() {
    FileIndemnisations._defaults(this);
  }

  FileIndemnisationsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _indemnisations = $v.indemnisations.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FileIndemnisations other) {
    _$v = other as _$FileIndemnisations;
  }

  @override
  void update(void Function(FileIndemnisationsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FileIndemnisations build() => _build();

  _$FileIndemnisations _build() {
    _$FileIndemnisations _$result;
    try {
      _$result = _$v ??
          _$FileIndemnisations._(
            indemnisations: indemnisations.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'indemnisations';
        indemnisations.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FileIndemnisations', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

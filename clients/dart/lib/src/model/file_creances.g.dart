// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_creances.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FileCreances extends FileCreances {
  @override
  final BuiltList<Creance> creances;
  @override
  final int totalDuUnites;

  factory _$FileCreances([void Function(FileCreancesBuilder)? updates]) =>
      (FileCreancesBuilder()..update(updates))._build();

  _$FileCreances._({required this.creances, required this.totalDuUnites})
      : super._();
  @override
  FileCreances rebuild(void Function(FileCreancesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FileCreancesBuilder toBuilder() => FileCreancesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FileCreances &&
        creances == other.creances &&
        totalDuUnites == other.totalDuUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, creances.hashCode);
    _$hash = $jc(_$hash, totalDuUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FileCreances')
          ..add('creances', creances)
          ..add('totalDuUnites', totalDuUnites))
        .toString();
  }
}

class FileCreancesBuilder
    implements Builder<FileCreances, FileCreancesBuilder> {
  _$FileCreances? _$v;

  ListBuilder<Creance>? _creances;
  ListBuilder<Creance> get creances =>
      _$this._creances ??= ListBuilder<Creance>();
  set creances(ListBuilder<Creance>? creances) => _$this._creances = creances;

  int? _totalDuUnites;
  int? get totalDuUnites => _$this._totalDuUnites;
  set totalDuUnites(int? totalDuUnites) =>
      _$this._totalDuUnites = totalDuUnites;

  FileCreancesBuilder() {
    FileCreances._defaults(this);
  }

  FileCreancesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _creances = $v.creances.toBuilder();
      _totalDuUnites = $v.totalDuUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FileCreances other) {
    _$v = other as _$FileCreances;
  }

  @override
  void update(void Function(FileCreancesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FileCreances build() => _build();

  _$FileCreances _build() {
    _$FileCreances _$result;
    try {
      _$result = _$v ??
          _$FileCreances._(
            creances: creances.build(),
            totalDuUnites: BuiltValueNullFieldError.checkNotNull(
                totalDuUnites, r'FileCreances', 'totalDuUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'creances';
        creances.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FileCreances', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

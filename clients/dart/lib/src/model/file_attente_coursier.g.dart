// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_attente_coursier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FileAttenteCoursier extends FileAttenteCoursier {
  @override
  final BuiltList<CommandeEnAttente> commandes;

  factory _$FileAttenteCoursier(
          [void Function(FileAttenteCoursierBuilder)? updates]) =>
      (FileAttenteCoursierBuilder()..update(updates))._build();

  _$FileAttenteCoursier._({required this.commandes}) : super._();
  @override
  FileAttenteCoursier rebuild(
          void Function(FileAttenteCoursierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FileAttenteCoursierBuilder toBuilder() =>
      FileAttenteCoursierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FileAttenteCoursier && commandes == other.commandes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FileAttenteCoursier')
          ..add('commandes', commandes))
        .toString();
  }
}

class FileAttenteCoursierBuilder
    implements Builder<FileAttenteCoursier, FileAttenteCoursierBuilder> {
  _$FileAttenteCoursier? _$v;

  ListBuilder<CommandeEnAttente>? _commandes;
  ListBuilder<CommandeEnAttente> get commandes =>
      _$this._commandes ??= ListBuilder<CommandeEnAttente>();
  set commandes(ListBuilder<CommandeEnAttente>? commandes) =>
      _$this._commandes = commandes;

  FileAttenteCoursierBuilder() {
    FileAttenteCoursier._defaults(this);
  }

  FileAttenteCoursierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandes = $v.commandes.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FileAttenteCoursier other) {
    _$v = other as _$FileAttenteCoursier;
  }

  @override
  void update(void Function(FileAttenteCoursierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FileAttenteCoursier build() => _build();

  _$FileAttenteCoursier _build() {
    _$FileAttenteCoursier _$result;
    try {
      _$result = _$v ??
          _$FileAttenteCoursier._(
            commandes: commandes.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'commandes';
        commandes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FileAttenteCoursier', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

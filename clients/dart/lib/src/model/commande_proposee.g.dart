// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commande_proposee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CommandeProposee extends CommandeProposee {
  @override
  final BuiltList<String> articles;
  @override
  final String libelleCle;
  @override
  final int totalArticlesUnites;

  factory _$CommandeProposee(
          [void Function(CommandeProposeeBuilder)? updates]) =>
      (CommandeProposeeBuilder()..update(updates))._build();

  _$CommandeProposee._(
      {required this.articles,
      required this.libelleCle,
      required this.totalArticlesUnites})
      : super._();
  @override
  CommandeProposee rebuild(void Function(CommandeProposeeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandeProposeeBuilder toBuilder() =>
      CommandeProposeeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandeProposee &&
        articles == other.articles &&
        libelleCle == other.libelleCle &&
        totalArticlesUnites == other.totalArticlesUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, articles.hashCode);
    _$hash = $jc(_$hash, libelleCle.hashCode);
    _$hash = $jc(_$hash, totalArticlesUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CommandeProposee')
          ..add('articles', articles)
          ..add('libelleCle', libelleCle)
          ..add('totalArticlesUnites', totalArticlesUnites))
        .toString();
  }
}

class CommandeProposeeBuilder
    implements Builder<CommandeProposee, CommandeProposeeBuilder> {
  _$CommandeProposee? _$v;

  ListBuilder<String>? _articles;
  ListBuilder<String> get articles =>
      _$this._articles ??= ListBuilder<String>();
  set articles(ListBuilder<String>? articles) => _$this._articles = articles;

  String? _libelleCle;
  String? get libelleCle => _$this._libelleCle;
  set libelleCle(String? libelleCle) => _$this._libelleCle = libelleCle;

  int? _totalArticlesUnites;
  int? get totalArticlesUnites => _$this._totalArticlesUnites;
  set totalArticlesUnites(int? totalArticlesUnites) =>
      _$this._totalArticlesUnites = totalArticlesUnites;

  CommandeProposeeBuilder() {
    CommandeProposee._defaults(this);
  }

  CommandeProposeeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _articles = $v.articles.toBuilder();
      _libelleCle = $v.libelleCle;
      _totalArticlesUnites = $v.totalArticlesUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandeProposee other) {
    _$v = other as _$CommandeProposee;
  }

  @override
  void update(void Function(CommandeProposeeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CommandeProposee build() => _build();

  _$CommandeProposee _build() {
    _$CommandeProposee _$result;
    try {
      _$result = _$v ??
          _$CommandeProposee._(
            articles: articles.build(),
            libelleCle: BuiltValueNullFieldError.checkNotNull(
                libelleCle, r'CommandeProposee', 'libelleCle'),
            totalArticlesUnites: BuiltValueNullFieldError.checkNotNull(
                totalArticlesUnites,
                r'CommandeProposee',
                'totalArticlesUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'articles';
        articles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CommandeProposee', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

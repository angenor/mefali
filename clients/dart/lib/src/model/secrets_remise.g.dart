// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secrets_remise.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SecretsRemise extends SecretsRemise {
  @override
  final String codeLivraison;
  @override
  final String jetonReception;

  factory _$SecretsRemise([void Function(SecretsRemiseBuilder)? updates]) =>
      (SecretsRemiseBuilder()..update(updates))._build();

  _$SecretsRemise._({required this.codeLivraison, required this.jetonReception})
      : super._();
  @override
  SecretsRemise rebuild(void Function(SecretsRemiseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SecretsRemiseBuilder toBuilder() => SecretsRemiseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SecretsRemise &&
        codeLivraison == other.codeLivraison &&
        jetonReception == other.jetonReception;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, codeLivraison.hashCode);
    _$hash = $jc(_$hash, jetonReception.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SecretsRemise')
          ..add('codeLivraison', codeLivraison)
          ..add('jetonReception', jetonReception))
        .toString();
  }
}

class SecretsRemiseBuilder
    implements Builder<SecretsRemise, SecretsRemiseBuilder> {
  _$SecretsRemise? _$v;

  String? _codeLivraison;
  String? get codeLivraison => _$this._codeLivraison;
  set codeLivraison(String? codeLivraison) =>
      _$this._codeLivraison = codeLivraison;

  String? _jetonReception;
  String? get jetonReception => _$this._jetonReception;
  set jetonReception(String? jetonReception) =>
      _$this._jetonReception = jetonReception;

  SecretsRemiseBuilder() {
    SecretsRemise._defaults(this);
  }

  SecretsRemiseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _codeLivraison = $v.codeLivraison;
      _jetonReception = $v.jetonReception;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SecretsRemise other) {
    _$v = other as _$SecretsRemise;
  }

  @override
  void update(void Function(SecretsRemiseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SecretsRemise build() => _build();

  _$SecretsRemise _build() {
    final _$result = _$v ??
        _$SecretsRemise._(
          codeLivraison: BuiltValueNullFieldError.checkNotNull(
              codeLivraison, r'SecretsRemise', 'codeLivraison'),
          jetonReception: BuiltValueNullFieldError.checkNotNull(
              jetonReception, r'SecretsRemise', 'jetonReception'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

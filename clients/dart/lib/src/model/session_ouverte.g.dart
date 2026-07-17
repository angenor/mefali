// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_ouverte.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionOuverte extends SessionOuverte {
  @override
  final CompteMoi compte;
  @override
  final JetonsDto jetons;
  @override
  final DiscriminantSession resultat;

  factory _$SessionOuverte([void Function(SessionOuverteBuilder)? updates]) =>
      (SessionOuverteBuilder()..update(updates))._build();

  _$SessionOuverte._(
      {required this.compte, required this.jetons, required this.resultat})
      : super._();
  @override
  SessionOuverte rebuild(void Function(SessionOuverteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionOuverteBuilder toBuilder() => SessionOuverteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionOuverte &&
        compte == other.compte &&
        jetons == other.jetons &&
        resultat == other.resultat;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, compte.hashCode);
    _$hash = $jc(_$hash, jetons.hashCode);
    _$hash = $jc(_$hash, resultat.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionOuverte')
          ..add('compte', compte)
          ..add('jetons', jetons)
          ..add('resultat', resultat))
        .toString();
  }
}

class SessionOuverteBuilder
    implements Builder<SessionOuverte, SessionOuverteBuilder> {
  _$SessionOuverte? _$v;

  CompteMoiBuilder? _compte;
  CompteMoiBuilder get compte => _$this._compte ??= CompteMoiBuilder();
  set compte(CompteMoiBuilder? compte) => _$this._compte = compte;

  JetonsDtoBuilder? _jetons;
  JetonsDtoBuilder get jetons => _$this._jetons ??= JetonsDtoBuilder();
  set jetons(JetonsDtoBuilder? jetons) => _$this._jetons = jetons;

  DiscriminantSession? _resultat;
  DiscriminantSession? get resultat => _$this._resultat;
  set resultat(DiscriminantSession? resultat) => _$this._resultat = resultat;

  SessionOuverteBuilder() {
    SessionOuverte._defaults(this);
  }

  SessionOuverteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _compte = $v.compte.toBuilder();
      _jetons = $v.jetons.toBuilder();
      _resultat = $v.resultat;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionOuverte other) {
    _$v = other as _$SessionOuverte;
  }

  @override
  void update(void Function(SessionOuverteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionOuverte build() => _build();

  _$SessionOuverte _build() {
    _$SessionOuverte _$result;
    try {
      _$result = _$v ??
          _$SessionOuverte._(
            compte: compte.build(),
            jetons: jetons.build(),
            resultat: BuiltValueNullFieldError.checkNotNull(
                resultat, r'SessionOuverte', 'resultat'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'compte';
        compte.build();
        _$failedField = 'jetons';
        jetons.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SessionOuverte', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

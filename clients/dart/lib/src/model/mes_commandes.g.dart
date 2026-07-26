// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mes_commandes.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MesCommandes extends MesCommandes {
  @override
  final BuiltList<CommandeResumee> commandes;

  factory _$MesCommandes([void Function(MesCommandesBuilder)? updates]) =>
      (MesCommandesBuilder()..update(updates))._build();

  _$MesCommandes._({required this.commandes}) : super._();
  @override
  MesCommandes rebuild(void Function(MesCommandesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MesCommandesBuilder toBuilder() => MesCommandesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MesCommandes && commandes == other.commandes;
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
    return (newBuiltValueToStringHelper(r'MesCommandes')
          ..add('commandes', commandes))
        .toString();
  }
}

class MesCommandesBuilder
    implements Builder<MesCommandes, MesCommandesBuilder> {
  _$MesCommandes? _$v;

  ListBuilder<CommandeResumee>? _commandes;
  ListBuilder<CommandeResumee> get commandes =>
      _$this._commandes ??= ListBuilder<CommandeResumee>();
  set commandes(ListBuilder<CommandeResumee>? commandes) =>
      _$this._commandes = commandes;

  MesCommandesBuilder() {
    MesCommandes._defaults(this);
  }

  MesCommandesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandes = $v.commandes.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MesCommandes other) {
    _$v = other as _$MesCommandes;
  }

  @override
  void update(void Function(MesCommandesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MesCommandes build() => _build();

  _$MesCommandes _build() {
    _$MesCommandes _$result;
    try {
      _$result = _$v ??
          _$MesCommandes._(
            commandes: commandes.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'commandes';
        commandes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MesCommandes', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

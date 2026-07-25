// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scission_proposee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ScissionProposee extends ScissionProposee {
  @override
  final String cause;
  @override
  final BuiltList<CommandeProposee> commandesProposees;
  @override
  final String messageCle;

  factory _$ScissionProposee(
          [void Function(ScissionProposeeBuilder)? updates]) =>
      (ScissionProposeeBuilder()..update(updates))._build();

  _$ScissionProposee._(
      {required this.cause,
      required this.commandesProposees,
      required this.messageCle})
      : super._();
  @override
  ScissionProposee rebuild(void Function(ScissionProposeeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ScissionProposeeBuilder toBuilder() =>
      ScissionProposeeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScissionProposee &&
        cause == other.cause &&
        commandesProposees == other.commandesProposees &&
        messageCle == other.messageCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cause.hashCode);
    _$hash = $jc(_$hash, commandesProposees.hashCode);
    _$hash = $jc(_$hash, messageCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ScissionProposee')
          ..add('cause', cause)
          ..add('commandesProposees', commandesProposees)
          ..add('messageCle', messageCle))
        .toString();
  }
}

class ScissionProposeeBuilder
    implements Builder<ScissionProposee, ScissionProposeeBuilder> {
  _$ScissionProposee? _$v;

  String? _cause;
  String? get cause => _$this._cause;
  set cause(String? cause) => _$this._cause = cause;

  ListBuilder<CommandeProposee>? _commandesProposees;
  ListBuilder<CommandeProposee> get commandesProposees =>
      _$this._commandesProposees ??= ListBuilder<CommandeProposee>();
  set commandesProposees(ListBuilder<CommandeProposee>? commandesProposees) =>
      _$this._commandesProposees = commandesProposees;

  String? _messageCle;
  String? get messageCle => _$this._messageCle;
  set messageCle(String? messageCle) => _$this._messageCle = messageCle;

  ScissionProposeeBuilder() {
    ScissionProposee._defaults(this);
  }

  ScissionProposeeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cause = $v.cause;
      _commandesProposees = $v.commandesProposees.toBuilder();
      _messageCle = $v.messageCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ScissionProposee other) {
    _$v = other as _$ScissionProposee;
  }

  @override
  void update(void Function(ScissionProposeeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ScissionProposee build() => _build();

  _$ScissionProposee _build() {
    _$ScissionProposee _$result;
    try {
      _$result = _$v ??
          _$ScissionProposee._(
            cause: BuiltValueNullFieldError.checkNotNull(
                cause, r'ScissionProposee', 'cause'),
            commandesProposees: commandesProposees.build(),
            messageCle: BuiltValueNullFieldError.checkNotNull(
                messageCle, r'ScissionProposee', 'messageCle'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'commandesProposees';
        commandesProposees.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ScissionProposee', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

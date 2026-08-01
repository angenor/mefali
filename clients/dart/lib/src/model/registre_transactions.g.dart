// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registre_transactions.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegistreTransactions extends RegistreTransactions {
  @override
  final int totalRegleUnites;
  @override
  final BuiltList<LigneRegistre> transactions;

  factory _$RegistreTransactions(
          [void Function(RegistreTransactionsBuilder)? updates]) =>
      (RegistreTransactionsBuilder()..update(updates))._build();

  _$RegistreTransactions._(
      {required this.totalRegleUnites, required this.transactions})
      : super._();
  @override
  RegistreTransactions rebuild(
          void Function(RegistreTransactionsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegistreTransactionsBuilder toBuilder() =>
      RegistreTransactionsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegistreTransactions &&
        totalRegleUnites == other.totalRegleUnites &&
        transactions == other.transactions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, totalRegleUnites.hashCode);
    _$hash = $jc(_$hash, transactions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegistreTransactions')
          ..add('totalRegleUnites', totalRegleUnites)
          ..add('transactions', transactions))
        .toString();
  }
}

class RegistreTransactionsBuilder
    implements Builder<RegistreTransactions, RegistreTransactionsBuilder> {
  _$RegistreTransactions? _$v;

  int? _totalRegleUnites;
  int? get totalRegleUnites => _$this._totalRegleUnites;
  set totalRegleUnites(int? totalRegleUnites) =>
      _$this._totalRegleUnites = totalRegleUnites;

  ListBuilder<LigneRegistre>? _transactions;
  ListBuilder<LigneRegistre> get transactions =>
      _$this._transactions ??= ListBuilder<LigneRegistre>();
  set transactions(ListBuilder<LigneRegistre>? transactions) =>
      _$this._transactions = transactions;

  RegistreTransactionsBuilder() {
    RegistreTransactions._defaults(this);
  }

  RegistreTransactionsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _totalRegleUnites = $v.totalRegleUnites;
      _transactions = $v.transactions.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegistreTransactions other) {
    _$v = other as _$RegistreTransactions;
  }

  @override
  void update(void Function(RegistreTransactionsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegistreTransactions build() => _build();

  _$RegistreTransactions _build() {
    _$RegistreTransactions _$result;
    try {
      _$result = _$v ??
          _$RegistreTransactions._(
            totalRegleUnites: BuiltValueNullFieldError.checkNotNull(
                totalRegleUnites, r'RegistreTransactions', 'totalRegleUnites'),
            transactions: transactions.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'transactions';
        transactions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RegistreTransactions', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attente.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Attente extends Attente {
  @override
  final DateTime arrivee;
  @override
  final DateTime scan;

  factory _$Attente([void Function(AttenteBuilder)? updates]) =>
      (AttenteBuilder()..update(updates))._build();

  _$Attente._({required this.arrivee, required this.scan}) : super._();
  @override
  Attente rebuild(void Function(AttenteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AttenteBuilder toBuilder() => AttenteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Attente && arrivee == other.arrivee && scan == other.scan;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arrivee.hashCode);
    _$hash = $jc(_$hash, scan.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Attente')
          ..add('arrivee', arrivee)
          ..add('scan', scan))
        .toString();
  }
}

class AttenteBuilder implements Builder<Attente, AttenteBuilder> {
  _$Attente? _$v;

  DateTime? _arrivee;
  DateTime? get arrivee => _$this._arrivee;
  set arrivee(DateTime? arrivee) => _$this._arrivee = arrivee;

  DateTime? _scan;
  DateTime? get scan => _$this._scan;
  set scan(DateTime? scan) => _$this._scan = scan;

  AttenteBuilder() {
    Attente._defaults(this);
  }

  AttenteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arrivee = $v.arrivee;
      _scan = $v.scan;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Attente other) {
    _$v = other as _$Attente;
  }

  @override
  void update(void Function(AttenteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Attente build() => _build();

  _$Attente _build() {
    final _$result = _$v ??
        _$Attente._(
          arrivee: BuiltValueNullFieldError.checkNotNull(
              arrivee, r'Attente', 'arrivee'),
          scan: BuiltValueNullFieldError.checkNotNull(scan, r'Attente', 'scan'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

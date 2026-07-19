// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signalement_recu_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SignalementRecuDto extends SignalementRecuDto {
  @override
  final bool masquageAutomatique;
  @override
  final bool recu;

  factory _$SignalementRecuDto(
          [void Function(SignalementRecuDtoBuilder)? updates]) =>
      (SignalementRecuDtoBuilder()..update(updates))._build();

  _$SignalementRecuDto._(
      {required this.masquageAutomatique, required this.recu})
      : super._();
  @override
  SignalementRecuDto rebuild(
          void Function(SignalementRecuDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SignalementRecuDtoBuilder toBuilder() =>
      SignalementRecuDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SignalementRecuDto &&
        masquageAutomatique == other.masquageAutomatique &&
        recu == other.recu;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, masquageAutomatique.hashCode);
    _$hash = $jc(_$hash, recu.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SignalementRecuDto')
          ..add('masquageAutomatique', masquageAutomatique)
          ..add('recu', recu))
        .toString();
  }
}

class SignalementRecuDtoBuilder
    implements Builder<SignalementRecuDto, SignalementRecuDtoBuilder> {
  _$SignalementRecuDto? _$v;

  bool? _masquageAutomatique;
  bool? get masquageAutomatique => _$this._masquageAutomatique;
  set masquageAutomatique(bool? masquageAutomatique) =>
      _$this._masquageAutomatique = masquageAutomatique;

  bool? _recu;
  bool? get recu => _$this._recu;
  set recu(bool? recu) => _$this._recu = recu;

  SignalementRecuDtoBuilder() {
    SignalementRecuDto._defaults(this);
  }

  SignalementRecuDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _masquageAutomatique = $v.masquageAutomatique;
      _recu = $v.recu;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SignalementRecuDto other) {
    _$v = other as _$SignalementRecuDto;
  }

  @override
  void update(void Function(SignalementRecuDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SignalementRecuDto build() => _build();

  _$SignalementRecuDto _build() {
    final _$result = _$v ??
        _$SignalementRecuDto._(
          masquageAutomatique: BuiltValueNullFieldError.checkNotNull(
              masquageAutomatique,
              r'SignalementRecuDto',
              'masquageAutomatique'),
          recu: BuiltValueNullFieldError.checkNotNull(
              recu, r'SignalementRecuDto', 'recu'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alertes_dispatch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AlertesDispatch extends AlertesDispatch {
  @override
  final BuiltList<CourseBloquee> coursesBloquees;
  @override
  final BuiltList<EscaladeDispatch> escalades;

  factory _$AlertesDispatch([void Function(AlertesDispatchBuilder)? updates]) =>
      (AlertesDispatchBuilder()..update(updates))._build();

  _$AlertesDispatch._({required this.coursesBloquees, required this.escalades})
      : super._();
  @override
  AlertesDispatch rebuild(void Function(AlertesDispatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AlertesDispatchBuilder toBuilder() => AlertesDispatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AlertesDispatch &&
        coursesBloquees == other.coursesBloquees &&
        escalades == other.escalades;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, coursesBloquees.hashCode);
    _$hash = $jc(_$hash, escalades.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AlertesDispatch')
          ..add('coursesBloquees', coursesBloquees)
          ..add('escalades', escalades))
        .toString();
  }
}

class AlertesDispatchBuilder
    implements Builder<AlertesDispatch, AlertesDispatchBuilder> {
  _$AlertesDispatch? _$v;

  ListBuilder<CourseBloquee>? _coursesBloquees;
  ListBuilder<CourseBloquee> get coursesBloquees =>
      _$this._coursesBloquees ??= ListBuilder<CourseBloquee>();
  set coursesBloquees(ListBuilder<CourseBloquee>? coursesBloquees) =>
      _$this._coursesBloquees = coursesBloquees;

  ListBuilder<EscaladeDispatch>? _escalades;
  ListBuilder<EscaladeDispatch> get escalades =>
      _$this._escalades ??= ListBuilder<EscaladeDispatch>();
  set escalades(ListBuilder<EscaladeDispatch>? escalades) =>
      _$this._escalades = escalades;

  AlertesDispatchBuilder() {
    AlertesDispatch._defaults(this);
  }

  AlertesDispatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _coursesBloquees = $v.coursesBloquees.toBuilder();
      _escalades = $v.escalades.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AlertesDispatch other) {
    _$v = other as _$AlertesDispatch;
  }

  @override
  void update(void Function(AlertesDispatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AlertesDispatch build() => _build();

  _$AlertesDispatch _build() {
    _$AlertesDispatch _$result;
    try {
      _$result = _$v ??
          _$AlertesDispatch._(
            coursesBloquees: coursesBloquees.build(),
            escalades: escalades.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'coursesBloquees';
        coursesBloquees.build();
        _$failedField = 'escalades';
        escalades.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AlertesDispatch', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

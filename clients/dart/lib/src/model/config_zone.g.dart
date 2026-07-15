// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_zone.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConfigZone extends ConfigZone {
  @override
  final BuiltList<CategorieDto> categories;
  @override
  final String? consentementArtciVersion;
  @override
  final DeviseDto devise;
  @override
  final BuiltMap<String, bool> drapeaux;
  @override
  final int? noteVocaleDureeMaxS;
  @override
  final JsonObject parametres;
  @override
  final BuiltMap<String, String> textes;
  @override
  final BuiltList<String> transportsActifs;
  @override
  final String version;
  @override
  final String zone;

  factory _$ConfigZone([void Function(ConfigZoneBuilder)? updates]) =>
      (ConfigZoneBuilder()..update(updates))._build();

  _$ConfigZone._(
      {required this.categories,
      this.consentementArtciVersion,
      required this.devise,
      required this.drapeaux,
      this.noteVocaleDureeMaxS,
      required this.parametres,
      required this.textes,
      required this.transportsActifs,
      required this.version,
      required this.zone})
      : super._();
  @override
  ConfigZone rebuild(void Function(ConfigZoneBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConfigZoneBuilder toBuilder() => ConfigZoneBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConfigZone &&
        categories == other.categories &&
        consentementArtciVersion == other.consentementArtciVersion &&
        devise == other.devise &&
        drapeaux == other.drapeaux &&
        noteVocaleDureeMaxS == other.noteVocaleDureeMaxS &&
        parametres == other.parametres &&
        textes == other.textes &&
        transportsActifs == other.transportsActifs &&
        version == other.version &&
        zone == other.zone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categories.hashCode);
    _$hash = $jc(_$hash, consentementArtciVersion.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, drapeaux.hashCode);
    _$hash = $jc(_$hash, noteVocaleDureeMaxS.hashCode);
    _$hash = $jc(_$hash, parametres.hashCode);
    _$hash = $jc(_$hash, textes.hashCode);
    _$hash = $jc(_$hash, transportsActifs.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, zone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConfigZone')
          ..add('categories', categories)
          ..add('consentementArtciVersion', consentementArtciVersion)
          ..add('devise', devise)
          ..add('drapeaux', drapeaux)
          ..add('noteVocaleDureeMaxS', noteVocaleDureeMaxS)
          ..add('parametres', parametres)
          ..add('textes', textes)
          ..add('transportsActifs', transportsActifs)
          ..add('version', version)
          ..add('zone', zone))
        .toString();
  }
}

class ConfigZoneBuilder implements Builder<ConfigZone, ConfigZoneBuilder> {
  _$ConfigZone? _$v;

  ListBuilder<CategorieDto>? _categories;
  ListBuilder<CategorieDto> get categories =>
      _$this._categories ??= ListBuilder<CategorieDto>();
  set categories(ListBuilder<CategorieDto>? categories) =>
      _$this._categories = categories;

  String? _consentementArtciVersion;
  String? get consentementArtciVersion => _$this._consentementArtciVersion;
  set consentementArtciVersion(String? consentementArtciVersion) =>
      _$this._consentementArtciVersion = consentementArtciVersion;

  DeviseDtoBuilder? _devise;
  DeviseDtoBuilder get devise => _$this._devise ??= DeviseDtoBuilder();
  set devise(DeviseDtoBuilder? devise) => _$this._devise = devise;

  MapBuilder<String, bool>? _drapeaux;
  MapBuilder<String, bool> get drapeaux =>
      _$this._drapeaux ??= MapBuilder<String, bool>();
  set drapeaux(MapBuilder<String, bool>? drapeaux) =>
      _$this._drapeaux = drapeaux;

  int? _noteVocaleDureeMaxS;
  int? get noteVocaleDureeMaxS => _$this._noteVocaleDureeMaxS;
  set noteVocaleDureeMaxS(int? noteVocaleDureeMaxS) =>
      _$this._noteVocaleDureeMaxS = noteVocaleDureeMaxS;

  JsonObject? _parametres;
  JsonObject? get parametres => _$this._parametres;
  set parametres(JsonObject? parametres) => _$this._parametres = parametres;

  MapBuilder<String, String>? _textes;
  MapBuilder<String, String> get textes =>
      _$this._textes ??= MapBuilder<String, String>();
  set textes(MapBuilder<String, String>? textes) => _$this._textes = textes;

  ListBuilder<String>? _transportsActifs;
  ListBuilder<String> get transportsActifs =>
      _$this._transportsActifs ??= ListBuilder<String>();
  set transportsActifs(ListBuilder<String>? transportsActifs) =>
      _$this._transportsActifs = transportsActifs;

  String? _version;
  String? get version => _$this._version;
  set version(String? version) => _$this._version = version;

  String? _zone;
  String? get zone => _$this._zone;
  set zone(String? zone) => _$this._zone = zone;

  ConfigZoneBuilder() {
    ConfigZone._defaults(this);
  }

  ConfigZoneBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categories = $v.categories.toBuilder();
      _consentementArtciVersion = $v.consentementArtciVersion;
      _devise = $v.devise.toBuilder();
      _drapeaux = $v.drapeaux.toBuilder();
      _noteVocaleDureeMaxS = $v.noteVocaleDureeMaxS;
      _parametres = $v.parametres;
      _textes = $v.textes.toBuilder();
      _transportsActifs = $v.transportsActifs.toBuilder();
      _version = $v.version;
      _zone = $v.zone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConfigZone other) {
    _$v = other as _$ConfigZone;
  }

  @override
  void update(void Function(ConfigZoneBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConfigZone build() => _build();

  _$ConfigZone _build() {
    _$ConfigZone _$result;
    try {
      _$result = _$v ??
          _$ConfigZone._(
            categories: categories.build(),
            consentementArtciVersion: consentementArtciVersion,
            devise: devise.build(),
            drapeaux: drapeaux.build(),
            noteVocaleDureeMaxS: noteVocaleDureeMaxS,
            parametres: BuiltValueNullFieldError.checkNotNull(
                parametres, r'ConfigZone', 'parametres'),
            textes: textes.build(),
            transportsActifs: transportsActifs.build(),
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'ConfigZone', 'version'),
            zone: BuiltValueNullFieldError.checkNotNull(
                zone, r'ConfigZone', 'zone'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'categories';
        categories.build();

        _$failedField = 'devise';
        devise.build();
        _$failedField = 'drapeaux';
        drapeaux.build();

        _$failedField = 'textes';
        textes.build();
        _$failedField = 'transportsActifs';
        transportsActifs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ConfigZone', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

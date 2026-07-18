// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prestataire_admin_detail.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PrestataireAdminDetail extends PrestataireAdminDetail {
  @override
  final String categorie;
  @override
  final bool commandable;
  @override
  final String contactTelephone;
  @override
  final int delaiPreparationMin;
  @override
  final String id;
  @override
  final String nom;
  @override
  final StatutPrestataire statut;
  @override
  final String villeId;
  @override
  final BuiltList<CharteAdminDto> chartes;
  @override
  final String? codeSecours;
  @override
  final String? jetonPlaque;
  @override
  final BuiltList<PhotoAdminDto> photos;
  @override
  final BuiltList<RattachementDto> rattachements;
  @override
  final SiteAdminVueDto? site;
  @override
  final DateTime? statutDecideLe;
  @override
  final String? statutDecidePar;
  @override
  final String? statutMotif;

  factory _$PrestataireAdminDetail(
          [void Function(PrestataireAdminDetailBuilder)? updates]) =>
      (PrestataireAdminDetailBuilder()..update(updates))._build();

  _$PrestataireAdminDetail._(
      {required this.categorie,
      required this.commandable,
      required this.contactTelephone,
      required this.delaiPreparationMin,
      required this.id,
      required this.nom,
      required this.statut,
      required this.villeId,
      required this.chartes,
      this.codeSecours,
      this.jetonPlaque,
      required this.photos,
      required this.rattachements,
      this.site,
      this.statutDecideLe,
      this.statutDecidePar,
      this.statutMotif})
      : super._();
  @override
  PrestataireAdminDetail rebuild(
          void Function(PrestataireAdminDetailBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrestataireAdminDetailBuilder toBuilder() =>
      PrestataireAdminDetailBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrestataireAdminDetail &&
        categorie == other.categorie &&
        commandable == other.commandable &&
        contactTelephone == other.contactTelephone &&
        delaiPreparationMin == other.delaiPreparationMin &&
        id == other.id &&
        nom == other.nom &&
        statut == other.statut &&
        villeId == other.villeId &&
        chartes == other.chartes &&
        codeSecours == other.codeSecours &&
        jetonPlaque == other.jetonPlaque &&
        photos == other.photos &&
        rattachements == other.rattachements &&
        site == other.site &&
        statutDecideLe == other.statutDecideLe &&
        statutDecidePar == other.statutDecidePar &&
        statutMotif == other.statutMotif;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categorie.hashCode);
    _$hash = $jc(_$hash, commandable.hashCode);
    _$hash = $jc(_$hash, contactTelephone.hashCode);
    _$hash = $jc(_$hash, delaiPreparationMin.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jc(_$hash, villeId.hashCode);
    _$hash = $jc(_$hash, chartes.hashCode);
    _$hash = $jc(_$hash, codeSecours.hashCode);
    _$hash = $jc(_$hash, jetonPlaque.hashCode);
    _$hash = $jc(_$hash, photos.hashCode);
    _$hash = $jc(_$hash, rattachements.hashCode);
    _$hash = $jc(_$hash, site.hashCode);
    _$hash = $jc(_$hash, statutDecideLe.hashCode);
    _$hash = $jc(_$hash, statutDecidePar.hashCode);
    _$hash = $jc(_$hash, statutMotif.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrestataireAdminDetail')
          ..add('categorie', categorie)
          ..add('commandable', commandable)
          ..add('contactTelephone', contactTelephone)
          ..add('delaiPreparationMin', delaiPreparationMin)
          ..add('id', id)
          ..add('nom', nom)
          ..add('statut', statut)
          ..add('villeId', villeId)
          ..add('chartes', chartes)
          ..add('codeSecours', codeSecours)
          ..add('jetonPlaque', jetonPlaque)
          ..add('photos', photos)
          ..add('rattachements', rattachements)
          ..add('site', site)
          ..add('statutDecideLe', statutDecideLe)
          ..add('statutDecidePar', statutDecidePar)
          ..add('statutMotif', statutMotif))
        .toString();
  }
}

class PrestataireAdminDetailBuilder
    implements Builder<PrestataireAdminDetail, PrestataireAdminDetailBuilder> {
  _$PrestataireAdminDetail? _$v;

  String? _categorie;
  String? get categorie => _$this._categorie;
  set categorie(String? categorie) => _$this._categorie = categorie;

  bool? _commandable;
  bool? get commandable => _$this._commandable;
  set commandable(bool? commandable) => _$this._commandable = commandable;

  String? _contactTelephone;
  String? get contactTelephone => _$this._contactTelephone;
  set contactTelephone(String? contactTelephone) =>
      _$this._contactTelephone = contactTelephone;

  int? _delaiPreparationMin;
  int? get delaiPreparationMin => _$this._delaiPreparationMin;
  set delaiPreparationMin(int? delaiPreparationMin) =>
      _$this._delaiPreparationMin = delaiPreparationMin;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  StatutPrestataire? _statut;
  StatutPrestataire? get statut => _$this._statut;
  set statut(StatutPrestataire? statut) => _$this._statut = statut;

  String? _villeId;
  String? get villeId => _$this._villeId;
  set villeId(String? villeId) => _$this._villeId = villeId;

  ListBuilder<CharteAdminDto>? _chartes;
  ListBuilder<CharteAdminDto> get chartes =>
      _$this._chartes ??= ListBuilder<CharteAdminDto>();
  set chartes(ListBuilder<CharteAdminDto>? chartes) =>
      _$this._chartes = chartes;

  String? _codeSecours;
  String? get codeSecours => _$this._codeSecours;
  set codeSecours(String? codeSecours) => _$this._codeSecours = codeSecours;

  String? _jetonPlaque;
  String? get jetonPlaque => _$this._jetonPlaque;
  set jetonPlaque(String? jetonPlaque) => _$this._jetonPlaque = jetonPlaque;

  ListBuilder<PhotoAdminDto>? _photos;
  ListBuilder<PhotoAdminDto> get photos =>
      _$this._photos ??= ListBuilder<PhotoAdminDto>();
  set photos(ListBuilder<PhotoAdminDto>? photos) => _$this._photos = photos;

  ListBuilder<RattachementDto>? _rattachements;
  ListBuilder<RattachementDto> get rattachements =>
      _$this._rattachements ??= ListBuilder<RattachementDto>();
  set rattachements(ListBuilder<RattachementDto>? rattachements) =>
      _$this._rattachements = rattachements;

  SiteAdminVueDtoBuilder? _site;
  SiteAdminVueDtoBuilder get site => _$this._site ??= SiteAdminVueDtoBuilder();
  set site(SiteAdminVueDtoBuilder? site) => _$this._site = site;

  DateTime? _statutDecideLe;
  DateTime? get statutDecideLe => _$this._statutDecideLe;
  set statutDecideLe(DateTime? statutDecideLe) =>
      _$this._statutDecideLe = statutDecideLe;

  String? _statutDecidePar;
  String? get statutDecidePar => _$this._statutDecidePar;
  set statutDecidePar(String? statutDecidePar) =>
      _$this._statutDecidePar = statutDecidePar;

  String? _statutMotif;
  String? get statutMotif => _$this._statutMotif;
  set statutMotif(String? statutMotif) => _$this._statutMotif = statutMotif;

  PrestataireAdminDetailBuilder() {
    PrestataireAdminDetail._defaults(this);
  }

  PrestataireAdminDetailBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categorie = $v.categorie;
      _commandable = $v.commandable;
      _contactTelephone = $v.contactTelephone;
      _delaiPreparationMin = $v.delaiPreparationMin;
      _id = $v.id;
      _nom = $v.nom;
      _statut = $v.statut;
      _villeId = $v.villeId;
      _chartes = $v.chartes.toBuilder();
      _codeSecours = $v.codeSecours;
      _jetonPlaque = $v.jetonPlaque;
      _photos = $v.photos.toBuilder();
      _rattachements = $v.rattachements.toBuilder();
      _site = $v.site?.toBuilder();
      _statutDecideLe = $v.statutDecideLe;
      _statutDecidePar = $v.statutDecidePar;
      _statutMotif = $v.statutMotif;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrestataireAdminDetail other) {
    _$v = other as _$PrestataireAdminDetail;
  }

  @override
  void update(void Function(PrestataireAdminDetailBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrestataireAdminDetail build() => _build();

  _$PrestataireAdminDetail _build() {
    _$PrestataireAdminDetail _$result;
    try {
      _$result = _$v ??
          _$PrestataireAdminDetail._(
            categorie: BuiltValueNullFieldError.checkNotNull(
                categorie, r'PrestataireAdminDetail', 'categorie'),
            commandable: BuiltValueNullFieldError.checkNotNull(
                commandable, r'PrestataireAdminDetail', 'commandable'),
            contactTelephone: BuiltValueNullFieldError.checkNotNull(
                contactTelephone,
                r'PrestataireAdminDetail',
                'contactTelephone'),
            delaiPreparationMin: BuiltValueNullFieldError.checkNotNull(
                delaiPreparationMin,
                r'PrestataireAdminDetail',
                'delaiPreparationMin'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PrestataireAdminDetail', 'id'),
            nom: BuiltValueNullFieldError.checkNotNull(
                nom, r'PrestataireAdminDetail', 'nom'),
            statut: BuiltValueNullFieldError.checkNotNull(
                statut, r'PrestataireAdminDetail', 'statut'),
            villeId: BuiltValueNullFieldError.checkNotNull(
                villeId, r'PrestataireAdminDetail', 'villeId'),
            chartes: chartes.build(),
            codeSecours: codeSecours,
            jetonPlaque: jetonPlaque,
            photos: photos.build(),
            rattachements: rattachements.build(),
            site: _site?.build(),
            statutDecideLe: statutDecideLe,
            statutDecidePar: statutDecidePar,
            statutMotif: statutMotif,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'chartes';
        chartes.build();

        _$failedField = 'photos';
        photos.build();
        _$failedField = 'rattachements';
        rattachements.build();
        _$failedField = 'site';
        _site?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PrestataireAdminDetail', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

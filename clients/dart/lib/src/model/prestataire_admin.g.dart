// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prestataire_admin.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PrestataireAdmin extends PrestataireAdmin {
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

  factory _$PrestataireAdmin(
          [void Function(PrestataireAdminBuilder)? updates]) =>
      (PrestataireAdminBuilder()..update(updates))._build();

  _$PrestataireAdmin._(
      {required this.categorie,
      required this.commandable,
      required this.contactTelephone,
      required this.delaiPreparationMin,
      required this.id,
      required this.nom,
      required this.statut,
      required this.villeId})
      : super._();
  @override
  PrestataireAdmin rebuild(void Function(PrestataireAdminBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrestataireAdminBuilder toBuilder() =>
      PrestataireAdminBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrestataireAdmin &&
        categorie == other.categorie &&
        commandable == other.commandable &&
        contactTelephone == other.contactTelephone &&
        delaiPreparationMin == other.delaiPreparationMin &&
        id == other.id &&
        nom == other.nom &&
        statut == other.statut &&
        villeId == other.villeId;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrestataireAdmin')
          ..add('categorie', categorie)
          ..add('commandable', commandable)
          ..add('contactTelephone', contactTelephone)
          ..add('delaiPreparationMin', delaiPreparationMin)
          ..add('id', id)
          ..add('nom', nom)
          ..add('statut', statut)
          ..add('villeId', villeId))
        .toString();
  }
}

class PrestataireAdminBuilder
    implements Builder<PrestataireAdmin, PrestataireAdminBuilder> {
  _$PrestataireAdmin? _$v;

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

  PrestataireAdminBuilder() {
    PrestataireAdmin._defaults(this);
  }

  PrestataireAdminBuilder get _$this {
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
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrestataireAdmin other) {
    _$v = other as _$PrestataireAdmin;
  }

  @override
  void update(void Function(PrestataireAdminBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrestataireAdmin build() => _build();

  _$PrestataireAdmin _build() {
    final _$result = _$v ??
        _$PrestataireAdmin._(
          categorie: BuiltValueNullFieldError.checkNotNull(
              categorie, r'PrestataireAdmin', 'categorie'),
          commandable: BuiltValueNullFieldError.checkNotNull(
              commandable, r'PrestataireAdmin', 'commandable'),
          contactTelephone: BuiltValueNullFieldError.checkNotNull(
              contactTelephone, r'PrestataireAdmin', 'contactTelephone'),
          delaiPreparationMin: BuiltValueNullFieldError.checkNotNull(
              delaiPreparationMin, r'PrestataireAdmin', 'delaiPreparationMin'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PrestataireAdmin', 'id'),
          nom: BuiltValueNullFieldError.checkNotNull(
              nom, r'PrestataireAdmin', 'nom'),
          statut: BuiltValueNullFieldError.checkNotNull(
              statut, r'PrestataireAdmin', 'statut'),
          villeId: BuiltValueNullFieldError.checkNotNull(
              villeId, r'PrestataireAdmin', 'villeId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

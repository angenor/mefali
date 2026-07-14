import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';

/// Source configurable : renvoie les réponses en séquence (ConfigDistante) ou
/// lève l'exception fournie (hors-ligne). La dernière réponse est répétée.
class _SourceFake implements SourceConfig {
  _SourceFake(this._reponses);

  final List<Object> _reponses;
  int appels = 0;

  @override
  Future<ConfigDistante> recuperer(String zone) async {
    final index = appels < _reponses.length ? appels : _reponses.length - 1;
    appels++;
    final reponse = _reponses[index];
    if (reponse is ConfigDistante) return reponse;
    throw reponse;
  }
}

/// Cache en mémoire.
class _CacheFake implements CacheConfig {
  _CacheFake([this._stocke]);

  ConfigDistante? _stocke;

  @override
  Future<ConfigDistante?> lire(String zone) async => _stocke;

  @override
  Future<void> ecrire(ConfigDistante config) async => _stocke = config;
}

ConfigDistante _config(String version) => ConfigDistante(
      zone: zoneBootstrapTiassale,
      version: version,
      donnees: {
        'zone': zoneBootstrapTiassale,
        'version': version,
        'drapeaux': <String, dynamic>{},
      },
    );

void main() {
  test('zone de bootstrap = Tiassalé (UUID fixe du seed)', () {
    expect(zoneBootstrapTiassale, '01900000-0000-7000-8000-000000000002');
    final service = ServiceConfig(source: _SourceFake([]), cache: _CacheFake());
    expect(service.zone, '01900000-0000-7000-8000-000000000002');
  });

  test('hors-ligne au démarrage → sert le cache sans erreur (SC-007)', () {
    fakeAsync((async) {
      final cache = _CacheFake(_config('v-cache'));
      final source = _SourceFake([Exception('pas de réseau')]);
      final service = ServiceConfig(source: source, cache: cache);

      service.demarrer();
      async.flushMicrotasks();

      expect(service.courante?.version, 'v-cache', reason: 'dernière config connue');
      service.arreter();
    });
  });

  test('rafraîchit au démarrage puis toutes les heures (FR-020)', () {
    fakeAsync((async) {
      final source = _SourceFake([_config('v1'), _config('v1'), _config('v2')]);
      final service = ServiceConfig(source: source, cache: _CacheFake());

      service.demarrer();
      async.flushMicrotasks();
      expect(source.appels, 1, reason: 'rafraîchi au démarrage');
      expect(service.courante?.version, 'v1');

      async.elapse(const Duration(hours: 1));
      async.flushMicrotasks();
      expect(source.appels, 2, reason: 'rafraîchi après 1 h');

      async.elapse(const Duration(hours: 1));
      async.flushMicrotasks();
      expect(source.appels, 3);
      expect(service.courante?.version, 'v2', reason: 'nouvelle version adoptée');

      service.arreter();
    });
  });

  test('une nouvelle version remplace la valeur et le cache (FR-019)', () {
    fakeAsync((async) {
      final cache = _CacheFake(_config('v1'));
      final source = _SourceFake([_config('v2')]);
      final service = ServiceConfig(source: source, cache: cache);

      service.demarrer();
      async.flushMicrotasks();
      expect(service.courante?.version, 'v2');

      ConfigDistante? enCache;
      cache.lire(zoneBootstrapTiassale).then((c) => enCache = c);
      async.flushMicrotasks();
      expect(enCache?.version, 'v2', reason: 'cache mis à jour');

      service.arreter();
    });
  });

  test('version inchangée → ne réécrit pas le cache', () {
    fakeAsync((async) {
      var ecritures = 0;
      final cache = _CacheCompteur(_config('v1'), () => ecritures++);
      final source = _SourceFake([_config('v1')]);
      final service = ServiceConfig(source: source, cache: cache);

      service.demarrer();
      async.flushMicrotasks();
      expect(service.courante?.version, 'v1');
      expect(ecritures, 0, reason: 'même version → aucune écriture');

      service.arreter();
    });
  });
}

/// Cache qui compte les écritures.
class _CacheCompteur implements CacheConfig {
  _CacheCompteur(this._stocke, this._onEcrire);

  ConfigDistante? _stocke;
  final void Function() _onEcrire;

  @override
  Future<ConfigDistante?> lire(String zone) async => _stocke;

  @override
  Future<void> ecrire(ConfigDistante config) async {
    _onEcrire();
    _stocke = config;
  }
}

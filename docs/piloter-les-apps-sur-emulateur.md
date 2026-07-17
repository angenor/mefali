# Piloter les apps sur émulateur / appareil

Comment dérouler un parcours à la main sur `mefali_client` ou `mefali_pro`, et
comment ces parcours ont été joués au cycle plateformes (PLT). Un `flutter test`
ne voit pas les permissions natives, les piles réseau ni le comportement réel de
la caméra : ce document décrit le seul moyen de les observer.

## L'outil : `adb`, et rien d'autre

`adb` (Android Debug Bridge) est livré avec le SDK Android :
`~/Library/Android/sdk/platform-tools/adb`.

Pas d'Appium, pas de Flutter Driver, pas d'`integration_test` — voir
« [Limites](#limites-et-quand-passer-à-integration_test) » pour savoir quand ce
choix cesse d'être le bon.

## Préparer l'environnement

Sur un appareil ou un émulateur, `localhost` désigne **l'appareil lui-même**.
Il faut l'ip LAN du poste, routable des deux côtés (voir `CLAUDE.md`) :

```bash
IP=$(ipconfig getifaddr en0)

# Backend : S3_ENDPOINT doit porter la MÊME ip — c'est elle qui est SIGNÉE dans
# les URLs présignées. Un « localhost » ici et les repères vocaux ne se lisent
# pas, alors que tout le reste de l'app fonctionne.
export S3_ENDPOINT="http://$IP:3900"
export APP_ENV=dev SMS_MODE=traces
cargo run -p api --bin api

# Redis sature vite : 10 demandes d'OTP par heure et par IP, et tout part de la
# même. Un parcours long doit repartir d'un Redis vide, sinon les 202 restent
# neutres SANS SMS et les codes lus sont périmés.
docker exec mefali-dev-redis-1 redis-cli FLUSHALL
```

Puis l'app, avec l'affordance dev qui affiche le code OTP sur l'écran de saisie :

```bash
flutter emulators --launch Medium_Phone_API_36.1

# Attendre le boot réel plutôt qu'un sleep au jugé
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done

flutter run -d emulator-5554 \
  --dart-define=MEFALI_API_URL=http://$IP:8080 \
  --dart-define=MEFALI_DEV_OTP=true
```

## La boucle de pilotage

Trois temps, répétés à chaque écran :

```bash
# 1. photographier l'écran
adb exec-out screencap -p > /tmp/ecran.png

# 2. REGARDER l'image et y repérer la cible (c'est l'étape humaine)

# 3. taper aux coordonnées, puis recapturer pour vérifier
adb shell input tap 868 904
```

On ne voit pas l'app en direct : on prend une capture, on en déduit des
coordonnées en pixels, et on envoie un tap aveugle. La vérification vient de la
capture suivante.

### Commandes utiles

| Commande | Usage |
|---|---|
| `adb shell input tap X Y` | toucher l'écran |
| `adb shell input text "0712345678"` | saisir du texte (`%s` = espace) |
| `adb shell input keyevent 4` | Retour (ferme aussi le clavier) |
| `adb shell input keyevent 67` | Effacer (avant le curseur) |
| `adb shell input keyevent 112` | Suppr (après le curseur) |
| `adb exec-out screencap -p > f.png` | capture d'écran |
| `adb shell dumpsys window \| grep mCurrentFocus` | quelle app est au premier plan |
| `adb devices -l` | appareils connectés |
| `adb uninstall ci.mefali.mefali_pro` | libérer de la place |
| `adb shell df /data` | espace restant |
| `adb emu kill` | arrêter l'émulateur |
| `aapt2 dump permissions <apk>` | permissions RÉELLES de l'apk (build-tools) |
| `aapt2 dump badging <apk> \| grep application-label` | nom sous l'icône |

## Les pièges, tous rencontrés au cycle PLT

**Les coordonnées sont à l'échelle.** L'écran fait 1080 × 2400 mais les captures
peuvent être redimensionnées (900 × 2000 dans notre cas) : il faut multiplier
chaque coordonnée lue sur l'image par le facteur (**× 1,2** ici) avant de
l'envoyer à `adb`. Un bouton vu à `y=753` se tape à `y=904`.

**Le clavier fait scroller la page.** Une position calculée sur une capture
prise AVANT l'ouverture du clavier ne vaut plus rien après. C'est ce qui a fait
atterrir le téléphone du référent dans le champ « Nom » : les deux saisies se
sont concaténées. Recapturer après chaque ouverture de clavier, ou le fermer
(`keyevent 4`) avant de viser.

**Un champ peut être simplement masqué.** « Téléphone du référent » semblait
absent du formulaire ; il était sous le clavier.

**L'espace disque de l'émulateur part vite.** Un APK debug pèse ~180 Mo :
`INSTALL_FAILED_INSUFFICIENT_STORAGE` arrive au deuxième. Désinstaller l'app
qu'on ne teste plus.

**Un appareil physique branché peut disparaître** en cours de session
(`adb devices` vide) — basculer sur l'émulateur plutôt que d'attendre.

**Lire les logs autant que l'écran.** Le bug le plus important du cycle
(`CleartextNotPermittedException` sur la note vocale) n'était pas visible à
l'écran : le bouton tournait, sans plus. Il n'existait que dans la sortie de
`flutter run`. Filtrer large :

```bash
grep -iE "Exception|error|Cleartext|SecurityException|denied" run.log \
  | grep -viE "InteractionJank"
```

## Limites, et quand passer à `integration_test`

Cette méthode est faite pour **explorer et découvrir** : elle a trouvé le
cleartext d'ExoPlayer, confirmé que déclarer `CAMERA` aurait cassé la caméra, et
permis de jouer SC-006 sur un vrai runtime. Mais elle est fragile et non
rejouable — coordonnées en dur, aucune attente sur les frames, rien qui échoue
proprement.

Pour transformer un parcours en test qui tient dans le temps, l'outil est
`integration_test` : il vise les widgets par `Key`, tourne sur le vrai appareil
et sait attendre. À faire le jour où l'un de ces parcours doit devenir un
garde-fou de CI plutôt qu'une observation ponctuelle.

⚠ `testWidgets` ne remplace PAS ce document : son horloge est SIMULÉE, y
attendre un appel dio suspend le test pour toujours (piège connu du cycle CPT).
Il ne voit ni les permissions natives, ni les deux piles réseau, ni la caméra.

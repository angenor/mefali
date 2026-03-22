# Test API après déploiement

Liens rapides pour vérifier que `api.mefali.com` fonctionne après un déploiement.
Aucun token nécessaire — à ouvrir directement dans le navigateur ou avec `curl`.

## Health check

```
https://api.mefali.com/api/v1/health
```

Réponse attendue :

```json
{"data":{"service":"mefali-api","status":"ok","version":"0.1.0"}}
```

## Validation des erreurs (400/401)

Ces URLs doivent retourner des erreurs formatées, pas un timeout ou une 502 :

| Test | URL / commande | Code attendu |
|------|---------------|--------------|
| Route protégée sans token | `https://api.mefali.com/api/v1/users/me` | 401 |
| Body manquant | `curl -X POST https://api.mefali.com/api/v1/auth/request-otp -H "Content-Type: application/json" -d '{}'` | 400 |
| Route inexistante | `https://api.mefali.com/api/v1/nimportequoi` | 404 |

## Page de partage (HTML)

```
https://api.mefali.com/share/r/00000000-0000-0000-0000-000000000000
```

Retourne une page HTML avec les balises Open Graph (même si le merchant n'existe pas, le serveur doit répondre sans 502).

## Script de vérification rapide

```bash
echo "=== Health ==="
curl -s https://api.mefali.com/api/v1/health | python3 -m json.tool

echo -e "\n=== Auth (401) ==="
curl -s -o /dev/null -w "HTTP %{http_code}" https://api.mefali.com/api/v1/users/me

echo -e "\n=== Validation (400) ==="
curl -s -o /dev/null -w "HTTP %{http_code}" -X POST https://api.mefali.com/api/v1/auth/request-otp -H "Content-Type: application/json" -d '{}'

echo -e "\n=== Route inconnue (404) ==="
curl -s -o /dev/null -w "HTTP %{http_code}" https://api.mefali.com/api/v1/nimportequoi

echo ""
```

Résultat attendu :

```
=== Health ===
{ "data": { "service": "mefali-api", "status": "ok", "version": "0.1.0" } }
=== Auth (401) ===
HTTP 401
=== Validation (400) ===
HTTP 400
=== Route inconnue (404) ===
HTTP 404
```

Si le health retourne une 502 ou un timeout, vérifier que le conteneur `mefali-api` tourne :

```bash
ssh root@161.97.92.63 "docker ps | grep mefali"
```

#!/usr/bin/env bash
set -e

# -------------------------------------------------------
# LexiDrill - Apple Distribution Certificate Setup
# Spusť v Git Bash: bash setup-cert.sh
# -------------------------------------------------------

WORKDIR="$HOME/lexidrill-cert"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo ""
echo "=== LexiDrill Certificate Setup ==="
echo "Výstup bude uložen do: $WORKDIR"
echo ""

# --- Vstupní údaje ---

read -p "Tvůj Apple email: " APPLE_EMAIL
read -p "Team Name (jméno nebo firma): " TEAM_NAME
read -s -p "Heslo pro P12 certifikát (vymysli si): " CERT_PASSWORD
echo ""
echo ""

# --- Krok 1: Vygeneruj klíč + CSR ---

echo "[1/4] Generuji privátní klíč a CSR..."

openssl genrsa -out distribution.key 2048

openssl req -new \
  -key distribution.key \
  -out CertificateSigningRequest.certSigningRequest \
  -subj "/emailAddress=${APPLE_EMAIL}/CN=${TEAM_NAME}/C=CZ"

echo ""
echo "✓ Hotovo. Soubory vytvořeny:"
echo "   $WORKDIR/distribution.key"
echo "   $WORKDIR/CertificateSigningRequest.certSigningRequest"
echo ""

# --- Krok 2: Uživatel nahraje CSR na Apple ---

echo "-------------------------------------------------------------"
echo "[2/4] Nahraj CSR na Apple Developer Portal:"
echo ""
echo "  1. Otevři: https://developer.apple.com/account/resources/certificates/add"
echo "  2. Vyber: Apple Distribution → Continue"
echo "  3. Nahraj soubor:"
echo "     $WORKDIR/CertificateSigningRequest.certSigningRequest"
echo "  4. Klikni Generate → Download"
echo "  5. Stažený soubor (distribution.cer) přesuň do:"
echo "     $WORKDIR/"
echo "-------------------------------------------------------------"
echo ""
read -p "Stiskni Enter až budeš mít distribution.cer ve složce $WORKDIR ..."

if [ ! -f "distribution.cer" ]; then
  echo ""
  echo "CHYBA: Soubor distribution.cer nebyl nalezen v $WORKDIR"
  echo "Přesuň ho tam a spusť skript znovu."
  exit 1
fi

# --- Krok 3: Vytvoř P12 ---

echo ""
echo "[3/4] Vytvářím P12 certifikát..."

openssl x509 -in distribution.cer -inform DER -out distribution.pem

openssl pkcs12 -export \
  -out distribution.p12 \
  -inkey distribution.key \
  -in distribution.pem \
  -passout "pass:${CERT_PASSWORD}"

echo "✓ distribution.p12 vytvořen"

# --- Krok 4: Base64 kódování ---

echo ""
echo "[4/4] Kóduji do base64..."

CERT_B64=$(base64 -w 0 distribution.p12)

echo ""
echo "============================================================"
echo "  GITHUB SECRETS - zkopíruj tyto hodnoty do GitHub:"
echo "  (github.com/tvůj-repo → Settings → Secrets → Actions)"
echo "============================================================"
echo ""
echo "Secret name:  DISTRIBUTION_CERTIFICATE_BASE64"
echo "Secret value:"
echo "$CERT_B64"
echo ""
echo "------------------------------------------------------------"
echo ""
echo "Secret name:  DISTRIBUTION_CERTIFICATE_PASSWORD"
echo "Secret value: ${CERT_PASSWORD}"
echo ""
echo "Secret name:  KEYCHAIN_PASSWORD"
echo "Secret value: ${CERT_PASSWORD}CI"
echo "  (nebo libovolné jiné heslo - jen pro dočasný CI keychain)"
echo "============================================================"
echo ""
echo "Co zbývá:"
echo "  1. Stáhni provisioning profil z developer.apple.com"
echo "     a spusť:  base64 -w 0 LexiDrill_AppStore.mobileprovision"
echo "  2. Stáhni API klíč z appstoreconnect.apple.com"
echo "     a spusť:  base64 -w 0 AuthKey_XXXXXXXX.p8"
echo ""
echo "Soubory jsou uloženy v: $WORKDIR"
echo "!! Smaž složku až skončíš - obsahuje privátní klíč !!"
echo ""

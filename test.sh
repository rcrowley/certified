set -e -x

export PATH="$(cd "$(dirname "$0")" && pwd)/bin:$PATH"

TMP="$(mktemp -d "$PWD/certified-XXXXXX")"
cd "$TMP"
trap "rm -rf \"$TMP\"" EXIT INT QUIT TERM

# Convert the decimal serial number from x509(1) to hex for crl(1).
serial() {
    printf "%02X" "$(
        openssl x509 -in "$1" -noout -text |
        awk '/Serial Number:/ {print $3}'
    )"
}

# Test that you don't need a CA to generate a CSR.
certified-csr C="US" ST="CA" L="San Francisco" O="Certified" CN="No CA"
openssl req -in "etc/ssl/no-ca.csr" -noout -text |
grep -q "Subject: C=US, ST=CA, L=San Francisco, O=Certified, CN=No CA"
test ! -f "etc/ssl/certs/no-ca.crt"

# Test that you don't need a CA to self-sign a certificate.
certified-crt --self-signed CN="No CA"
openssl x509 -in "etc/ssl/certs/no-ca.crt" -noout -text |
grep -q "Issuer: CN=No CA, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/no-ca.crt" -noout -text |
grep -q "Subject: CN=No CA, C=US, L=San Francisco, O=Certified, ST=CA"

# Test that we can generate a CA even after self-signing a certificate.
certified-ca --crl-url="http://example.com/ca.crl" --ocsp-url="http://ocsp.example.com" --password="password" C="US" ST="CA" L="San Francisco" O="Certified" CN="Certified CA"
openssl x509 -in "etc/ssl/certs/ca.crt" -noout -text |
grep -q "Issuer: C=US, ST=CA, L=San Francisco, O=Certified, CN=Certified CA"
openssl x509 -in "etc/ssl/certs/ca.crt" -noout -text |
grep -q "Subject: CN=Certified CA, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/ca.crt" -noout -text |
grep -A"3" "X509v3 CRL Distribution Points" |
grep -q "http://example.com/ca.crl"
openssl x509 -in "etc/ssl/certs/ca.crt" -noout -text |
grep -q "OCSP - URI:http://ocsp.example.com"

# Test that we can't generate another CA.
certified-ca C="US" ST="CA" L="San Francisco" O="Certified" CN="New CA" &&
false
openssl x509 -in "etc/ssl/certs/ca.crt" -noout -text |
grep -q "Subject: CN=Certified CA, C=US, L=San Francisco, O=Certified, ST=CA"

# Test that we can still self-sign a certificate.
certified --self-signed CN="Self-Signed Certificate"
openssl x509 -in "etc/ssl/certs/self-signed-certificate.crt" -noout -text |
grep -q "Issuer: CN=Self-Signed Certificate"
openssl x509 -in "etc/ssl/certs/self-signed-certificate.crt" -noout -text |
grep -q "Subject: CN=Self-Signed Certificate"

# Test that we can sign a certificate with our CA and that it has the correct
# version and bit width.
certified --password="password" CN="Certificate"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Version: 3"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Issuer: CN=Certified CA, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Subject: CN=Certificate, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Public-Key: (2048 bit)"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -A"3" "X509v3 CRL Distribution Points" |
grep -q "http://example.com/ca.crl"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "OCSP - URI:http://ocsp.example.com"
openssl verify "etc/ssl/certs/certificate.crt" |
grep -q "error 20"
cat "etc/ssl/certs/ca.crt" "etc/ssl/certs/root-ca.crt" >"etc/ssl/certs/ca.chain.crt"
openssl verify -CAfile "etc/ssl/certs/ca.chain.crt" "etc/ssl/certs/certificate.crt" |
grep -q "OK"

# Test that we can't reissue a certificate without revoking it first.
certified CN="Certificate" && false

# Test that we can revoke and reissue a certificate.
SERIAL="$(serial "etc/ssl/certs/certificate.crt")"
certified --password="password" --revoke CN="Certificate"
openssl crl -in "etc/ssl/crl/ca.crl" -noout -text |
grep -q "Serial Number: $SERIAL"
certified --password="password" CN="Certificate"
openssl x509 -in "etc/ssl/certs/certificate.crt" -noout -text |
grep -q "Subject: CN=Certificate, C=US, L=San Francisco, O=Certified, ST=CA"

# Test that we can generate 4096-bit certificates.
certified --bits="4096" --password="password" CN="4096"
openssl x509 -in "etc/ssl/certs/4096.crt" -noout -text |
grep -q "Public-Key: (4096 bit)"

# Test that we can generate certificates only valid until tomorrow.
certified --days="1" --password="password" CN="Tomorrow"
openssl x509 -in "etc/ssl/certs/tomorrow.crt" -noout -text |
grep -E -q "Not After : $(date -d"tomorrow" +"%b %e %H:%M:[0-6][0-9] %Y")"

# Test that we can change the name of the certificate file.
certified --name="filename" --password="password" CN="certname"
openssl x509 -in "etc/ssl/certs/filename.crt" -noout -text |
grep -q "Subject: CN=certname"

# Test that we can add subject alternative names to a certificate.
certified --password="password" CN="SAN" +"127.0.0.1" +"example.com"
openssl x509 -in "etc/ssl/certs/san.crt" -noout -text |
grep -q "DNS:example.com"
openssl x509 -in "etc/ssl/certs/san.crt" -noout -text |
grep -q "IP Address:127.0.0.1"

# Test that a valid DNS name as CN is added as a subject alternative name.
certified --password="password" CN="example.com"
openssl x509 -in "etc/ssl/certs/example.com.crt" -noout -text |
grep -q "DNS:example.com"

# Test that we can add DNS wildcards to a certificate.
certified --password="password" CN="Wildcard" +"*.example.com"
openssl x509 -in "etc/ssl/certs/wildcard.crt" -noout -text |
grep -F -q "DNS:*.example.com"

# Test that we can't add double DNS wildcards to a certificate.
certified CN="Double Wildcard" +"*.*.example.com" && false

# Test that we can delegate signing to an alternative CA.
certified --ca --password="password" CN="Sub CA"
openssl x509 -in "etc/ssl/certs/sub-ca.crt" -noout -text |
grep -q "Issuer: CN=Certified CA, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/sub-ca.crt" -noout -text |
grep -q "Subject: CN=Sub CA"
cat "etc/ssl/certs/ca.crt" "etc/ssl/certs/root-ca.crt" >"etc/ssl/certs/ca.chain.crt"
openssl verify -CAfile "etc/ssl/certs/ca.chain.crt" "etc/ssl/certs/sub-ca.crt" |
grep -q "OK"
certified --issuer="Sub CA" CN="Sub Certificate"
openssl x509 -in "etc/ssl/certs/sub-certificate.crt" -noout -text |
grep -q "Issuer: CN=Sub CA, C=US, L=San Francisco, O=Certified, ST=CA"
openssl x509 -in "etc/ssl/certs/sub-certificate.crt" -noout -text |
grep -q "Subject: CN=Sub Certificate"
openssl verify -CAfile "etc/ssl/certs/ca.crt" "etc/ssl/certs/sub-certificate.crt" |
grep -q "error 20"
cat "etc/ssl/certs/sub-ca.crt" "etc/ssl/certs/ca.crt" "etc/ssl/certs/root-ca.crt" >"etc/ssl/certs/sub-ca.chain.crt"
openssl verify -CAfile "etc/ssl/certs/sub-ca.chain.crt" "etc/ssl/certs/sub-certificate.crt" |
grep -q "OK"

# Test that we can revoke a certificate signed by an alternative CA.
SERIAL="$(serial "etc/ssl/certs/sub-certificate.crt")"
certified --issuer="Sub CA" --revoke CN="Sub Certificate"
openssl crl -in "etc/ssl/crl/sub-ca.crl" -noout -text |
grep -q "Serial Number: $SERIAL"

set +x
echo >&2
echo "PASS" >&2

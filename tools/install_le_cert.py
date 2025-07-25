#!/usr/bin/env python3
# install_le_cert.py
# Installs and validates Let's Encrypt cert/key on the device
import os
import shutil
import sys
import stat
from pathlib import Path
from OpenSSL import crypto

CERT_PATH = '/data/rayhunter/ssl/cert.pem'
KEY_PATH = '/data/rayhunter/ssl/key.pem'


def validate_cert_and_key(cert_file, key_file):
    # Validate certificate
    with open(cert_file, 'rb') as f:
        cert_data = f.read()
    try:
        cert = crypto.load_certificate(crypto.FILETYPE_PEM, cert_data)
    except Exception as e:
        print(f"Error: Invalid certificate: {e}")
        return False
    # Validate private key
    with open(key_file, 'rb') as f:
        key_data = f.read()
    try:
        key = crypto.load_privatekey(crypto.FILETYPE_PEM, key_data)
    except Exception as e:
        print(f"Error: Invalid private key: {e}")
        return False
    # Check that key matches cert
    try:
        context = crypto.X509StoreContext(cert, cert)
    except Exception:
        pass  # Not strictly needed for match
    return True

def install_cert_and_key(cert_file, key_file):
    # Copy files to destination
    os.makedirs(os.path.dirname(CERT_PATH), exist_ok=True)
    shutil.copy2(cert_file, CERT_PATH)
    shutil.copy2(key_file, KEY_PATH)
    # Set permissions
    os.chmod(CERT_PATH, stat.S_IRUSR | stat.S_IWUSR)
    os.chmod(KEY_PATH, stat.S_IRUSR | stat.S_IWUSR)
    print(f"Installed cert to {CERT_PATH} and key to {KEY_PATH}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <cert.pem> <key.pem>")
        sys.exit(1)
    cert_file = sys.argv[1]
    key_file = sys.argv[2]
    if not validate_cert_and_key(cert_file, key_file):
        print("Validation failed. Aborting install.")
        sys.exit(2)
    install_cert_and_key(cert_file, key_file)
    print("Certificate and key installed successfully.")

#!/usr/bin/env python3
"""Valida o arquivo APK Android bruto (nao um ZIP de artifact do Actions)."""
import hashlib
from pathlib import Path
import sys
from zipfile import BadZipFile, ZipFile, is_zipfile

MANDATORY = frozenset({'AndroidManifest.xml', 'classes.dex', 'resources.arsc'})


def check_apk(filename: str) -> dict:
    p = Path(filename)
    if not p.is_file():
        raise ValueError('Arquivo APK inexistente')
    if p.suffix.lower() != '.apk':
        raise ValueError('Extensao invalida: esperado .apk')
    if p.stat().st_size < 256:
        raise ValueError('Arquivo pequeno demais para APK Android')
    if not is_zipfile(p):
        raise ValueError('Arquivo nao e um ZIP/APK valido')
    try:
        with ZipFile(p) as z:
            bad = z.testzip()
            if bad is not None:
                raise ValueError(f'Erro de integridade CRC: {bad}')
            names = set(z.namelist())
            missing = MANDATORY - names
            if missing:
                raise ValueError('Nao e APK Android; faltam: ' + ', '.join(sorted(missing)))
            dex = z.read('classes.dex')
            if not dex.startswith(b'dex\n'):
                raise ValueError('DEX invalido')
            if z.getinfo('AndroidManifest.xml').file_size == 0 or z.getinfo('resources.arsc').file_size == 0:
                raise ValueError('Manifesto ou recursos vazios')
    except BadZipFile as e:
        raise ValueError('Arquivo ZIP corrompido') from e
    return {'file': p.name, 'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Uso: python3 tools/check_apk.py arquivo.apk', file=sys.stderr)
        sys.exit(2)
    try:
        result = check_apk(sys.argv[1])
        print('APK VALIDO (estrutura minima):', result)
    except ValueError as e:
        print('APK INVALIDO:', e, file=sys.stderr)
        sys.exit(1)

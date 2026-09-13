#!/usr/bin/env python3
"""Verificación estática ligera del código Dart (sin SDK de Flutter).

No reemplaza a `flutter analyze`; detecta a tiempo los errores más comunes
cuando se trabaja sin el SDK:
  * llaves, paréntesis y corchetes desbalanceados;
  * imports relativos que no existen o paquetes no declarados;
  * clases del proyecto usadas sin importar el archivo que las declara;
  * imports del proyecto que no se usan.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALLOWED_PACKAGES = {"flutter", "flutter_riverpod", "shared_preferences", "flutter_test", "inferencia_estadistica"}
problems = []


def strip_code(src):
    """Quita comentarios y literales de texto, conservando interpolaciones ${...}."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if c in "'\"":
            raw = i > 0 and src[i - 1] == "r"
            triple = src.startswith(c * 3, i)
            q = c * 3 if triple else c
            i += len(q)
            out.append(" ")
            while i < n and not src.startswith(q, i):
                if src[i] == "\\" and not raw:
                    i += 2
                    continue
                if not raw and src.startswith("${", i):
                    depth, j = 1, i + 2
                    while j < n and depth:
                        if src[j] == "{":
                            depth += 1
                        elif src[j] == "}":
                            depth -= 1
                        j += 1
                    out.append(" " + src[i + 2:j - 1] + " ")
                    i = j
                    continue
                if not triple and src[i] == "\n":
                    problems.append("cadena sin cerrar")
                    break
                i += 1
            i += len(q)
            out.append(" ")
            continue
        out.append(c)
        i += 1
    return "".join(out)


dart_files = []
for base in ("lib", "test"):
    for dp, _, fs in os.walk(os.path.join(ROOT, base)):
        dart_files += [os.path.join(dp, f) for f in fs if f.endswith(".dart")]

decl_re = re.compile(r"\b(?:class|enum|mixin|extension|typedef)\s+([A-Z]\w*)")
top_fn_re = re.compile(r"^(?:[A-Z]\w*(?:<[^>]*>)?\??|void|int|double|bool|String|Future<[^>]*>|IconData|Widget)\s+([a-z]\w*)\s*[(<]", re.M)
top_var_re = re.compile(r"^final\s+(\w+)\s*=", re.M)
decls, code_of, raw_of = {}, {}, {}
for f in dart_files:
    raw = open(f, encoding="utf-8").read()
    raw_of[f] = raw
    code = strip_code(raw)
    code_of[f] = code
    names = set(decl_re.findall(code))
    names |= set(top_fn_re.findall(code))
    names |= set(top_var_re.findall(code))
    decls[f] = names

owner = {}
for f, names in decls.items():
    for nme in names:
        owner.setdefault(nme, set()).add(f)

import_re = re.compile(r"^import\s+'([^']+)'(?:\s+(?:as\s+\w+|show\s+[\w\s,]+|hide\s+[\w\s,]+))*\s*;", re.M)
for f in dart_files:
    rel = os.path.relpath(f, ROOT)
    code, raw = code_of[f], raw_of[f]
    # 1. balance
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack = []
    for ch in code:
        if ch in pairs:
            stack.append(ch)
        elif ch in pairs.values():
            if not stack or pairs[stack.pop()] != ch:
                problems.append(f"{rel}: '{ch}' sin pareja")
                break
    if stack:
        problems.append(f"{rel}: {len(stack)} delimitadores sin cerrar")
    # 2. imports
    imported_files = []
    for imp in import_re.findall(raw):
        if imp.startswith("dart:"):
            continue
        if imp.startswith("package:"):
            pkg = imp[8:].split("/")[0]
            if pkg not in ALLOWED_PACKAGES:
                problems.append(f"{rel}: paquete no declarado {pkg}")
            if pkg == "inferencia_estadistica":
                target = os.path.join(ROOT, "lib", imp.split("/", 1)[1])
                if not os.path.exists(target):
                    problems.append(f"{rel}: import inexistente {imp}")
                else:
                    imported_files.append(os.path.normpath(target))
            continue
        target = os.path.normpath(os.path.join(os.path.dirname(f), imp))
        if not os.path.exists(target):
            problems.append(f"{rel}: import inexistente {imp}")
        else:
            imported_files.append(target)
    tokens = set(re.findall(r"\b([A-Za-z_]\w*)\b", code))
    # 3. clases del proyecto usadas sin importar
    visible = set(decls[f])
    for t in imported_files:
        visible |= decls.get(t, set())
    for tok in tokens:
        if tok in owner and tok not in visible and tok[0].isupper():
            problems.append(f"{rel}: usa {tok} sin importar {', '.join(os.path.relpath(o, ROOT) for o in owner[tok])}")
    # 3b. bibliotecas de Dart
    uses_math = re.search(r"\bmath\.", code) is not None
    has_math = "import 'dart:math' as math;" in raw
    if uses_math and not has_math:
        problems.append(f"{rel}: usa math. sin importar dart:math")
    if has_math and not uses_math:
        problems.append(f"{rel}: import sin uso dart:math")
    uses_json = re.search(r"\b(json(De|En)code|utf8|base64)\b", code) is not None
    has_convert = "import 'dart:convert';" in raw
    if uses_json != has_convert:
        problems.append(f"{rel}: dart:convert {'falta' if uses_json else 'sin uso'}")
    for pkg, pat in [("flutter_riverpod", r"\b(ConsumerWidget|ConsumerStatefulWidget|ConsumerState|WidgetRef|Notifier|NotifierProvider|Provider|FutureProvider|ProviderScope|ProviderContainer)\b"),
                     ("shared_preferences", r"\bSharedPreferences\b")]:
        uses = re.search(pat, code) is not None
        has = f"package:{pkg}/" in raw
        if uses and not has:
            problems.append(f"{rel}: usa {pkg} sin importarlo")
        if has and not uses:
            problems.append(f"{rel}: import sin uso {pkg}")
    # 4. imports del proyecto sin uso
    for t in imported_files:
        names = decls.get(t, set())
        if names and not (names & tokens):
            problems.append(f"{rel}: import sin uso {os.path.relpath(t, ROOT)}")

dups = {k: v for k, v in owner.items() if len(v) > 1 and k[0].isupper()}
for k, v in dups.items():
    problems.append(f"clase {k} declarada en varios archivos: {[os.path.relpath(x, ROOT) for x in v]}")

print(f"Archivos Dart: {len(dart_files)} · líneas: {sum(r.count(chr(10)) for r in raw_of.values())}")
if problems:
    print(f"{len(problems)} problema(s):")
    for p in sorted(set(problems)):
        print("  ✗", p)
    sys.exit(1)
print("✓ Sin problemas estáticos detectados")

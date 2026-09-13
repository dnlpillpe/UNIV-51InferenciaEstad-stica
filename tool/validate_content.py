#!/usr/bin/env python3
"""Valida el contenido de la app sin necesidad de Flutter.

1. Integridad: ids únicos, referencias existentes, cada ejercicio con su
   respuesta correcta, cada confusión catalogada producida por algún
   distractor, remedios que apuntan a lecciones y experimentos reales.
2. Cifras: cada `verify` del JSON se recalcula con inference_core.py.

Uso:  python3 tool/validate_content.py        (sale con código 1 si falla)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from inference_core import evaluate  # noqa: E402

ROOT = os.path.dirname(HERE)
CONTENT = os.path.join(ROOT, "assets", "content")
errors = []


def load(name):
    with open(os.path.join(CONTENT, name), encoding="utf-8") as f:
        return json.load(f)


def err(msg):
    errors.append(msg)


modules_doc = load("modules.json")
modules = modules_doc["modules"]
exercises = load("exercises.json")["exercises"]
cases = load("cases.json")["cases"]
labs = load("labs.json")["labs"]
miscs = load("misconceptions.json")["misconceptions"]
glossary = load("glossary.json")["glossary"]

module_ids = {m["id"] for m in modules}
lesson_ids = {l["id"] for m in modules for l in m["lessons"]}
lab_ids = {l["id"] for l in labs}
exp_ids = {e["id"] for l in labs for e in l["experiments"]}
misc_ids = {m["id"] for m in miscs}

# ------------------------------------------------------------- unicidad
all_ids = [m["id"] for m in modules] + list(lesson_ids) + [e["id"] for e in exercises] + \
    [c["id"] for c in cases] + list(lab_ids) + list(exp_ids) + list(misc_ids)
dups = {i for i in all_ids if all_ids.count(i) > 1}
if dups:
    err(f"ids duplicados: {sorted(dups)}")

# ------------------------------------------------------------- módulos
for m in modules:
    if m["labId"] not in lab_ids:
        err(f"{m['id']}: labId {m['labId']} no existe")
    ra = m.get("recommendedAfter")
    if ra and ra not in module_ids:
        err(f"{m['id']}: recommendedAfter {ra} no existe")
    for l in m["lessons"]:
        if len(l["cards"]) < 3:
            err(f"{l['id']}: menos de 3 tarjetas")
        for c in l["cards"]:
            if c["type"] == "check":
                if not (0 <= c.get("answer", -1) < len(c.get("options", []))):
                    err(f"{l['id']}: tarjeta check sin respuesta válida")
            if c.get("tag") and c["tag"] not in misc_ids:
                err(f"{l['id']}: tag {c['tag']} no catalogado")

# ------------------------------------------------------------- ejercicios
used_tags = set()


def check_options(where, options, need_correct=True, exactly_one=True):
    n_ok = sum(1 for o in options if o.get("correct"))
    if need_correct and (n_ok != 1 if exactly_one else n_ok < 1):
        err(f"{where}: {n_ok} opciones correctas")
    for o in options:
        t = o.get("tag")
        if t:
            if t not in misc_ids:
                err(f"{where}: tag {t} no catalogado")
            if o.get("correct"):
                err(f"{where}: una opción correcta no debe llevar tag")
            used_tags.add(t)
        if not o.get("correct") and not o.get("feedback"):
            err(f"{where}: distractor sin retroalimentación: {o['text'][:40]}")


for e in exercises:
    w = e["id"]
    if e["module"] not in module_ids:
        err(f"{w}: módulo inexistente")
    if e.get("lessonRef") and e["lessonRef"] not in lesson_ids:
        err(f"{w}: lessonRef inexistente")
    if not e.get("explanation"):
        err(f"{w}: sin explicación")
    t = e["type"]
    if t == "choice":
        check_options(w, e["options"])
    elif t == "decision":
        check_options(w + "/decisión", e["options"])
        check_options(w + "/justificación", e["justifications"])
    elif t == "numeric":
        for tr in e.get("traps", []):
            if abs(tr["value"] - e["answer"]) <= max(tr.get("tol", 0.01), e.get("tol", 0.01)):
                err(f"{w}: una trampa se superpone con la respuesta correcta")
            if tr.get("tag"):
                if tr["tag"] not in misc_ids:
                    err(f"{w}: tag {tr['tag']} no catalogado")
                used_tags.add(tr["tag"])
    elif t == "conclusion":
        for s in e["slots"]:
            check_options(f"{w}/{s['label']}", s["options"])
    elif t == "classify":
        cats = e["categories"]
        used = set()
        for it in e["items"]:
            if not (0 <= it["category"] < len(cats)):
                err(f"{w}: categoría fuera de rango")
            used.add(it["category"])
            if it.get("tag"):
                if it["tag"] not in misc_ids:
                    err(f"{w}: tag {it['tag']} no catalogado")
                used_tags.add(it["tag"])
        if used != set(range(len(cats))):
            err(f"{w}: hay categorías sin ítems")
    else:
        err(f"{w}: tipo desconocido {t}")

# ------------------------------------------------------------- casos
for c in cases:
    w = c["id"]
    for m in c.get("modules", []):
        if m not in module_ids:
            err(f"{w}: módulo {m} inexistente")
    has_compute = False
    for s in c["steps"]:
        if s["type"] == "choice":
            check_options(f"{w}/{s['title']}", s["options"])
        elif s["type"] == "compute":
            has_compute = True
    if has_compute and not c.get("analysis"):
        err(f"{w}: paso de cálculo sin análisis")
    a = c.get("analysis")
    if a and "expectedReject" in c:
        r = evaluate(a["fn"], a["args"])
        rej = r["p"] <= a.get("alpha", 0.05)
        if rej != c["expectedReject"]:
            err(f"{w}: expectedReject={c['expectedReject']} pero p={r['p']:.4f}")

# ------------------------------------------------------------- laboratorios
for l in labs:
    if l["module"] not in module_ids:
        err(f"{l['id']}: módulo inexistente")
    for x in l["experiments"]:
        check_options(f"{x['id']}/predicción", x["predictions"])
        if x.get("tag") and x["tag"] not in misc_ids:
            err(f"{x['id']}: tag no catalogado")

# ------------------------------------------------------------- confusiones
for m in miscs:
    if m["module"] not in module_ids:
        err(f"{m['id']}: módulo inexistente")
    if m.get("remedyLesson") and m["remedyLesson"] not in lesson_ids:
        err(f"{m['id']}: remedyLesson inexistente")
    if m.get("remedyExperiment") and m["remedyExperiment"] not in exp_ids:
        err(f"{m['id']}: remedyExperiment inexistente")
orphans = misc_ids - used_tags
if orphans:
    err(f"confusiones que ningún distractor produce: {sorted(orphans)}")

for g in glossary:
    if g["module"] not in module_ids:
        err(f"glosario {g['term']}: módulo inexistente")

# ------------------------------------------------------------- cifras
claims = 0
for src in exercises + cases:
    for v in src.get("verify", []):
        claims += 1
        try:
            r = evaluate(v["fn"], v["args"])
        except Exception as ex:  # noqa: BLE001
            err(f"{src['id']}: {v['fn']} falló: {ex}")
            continue
        got = r.get(v["field"])
        if got is None:
            err(f"{src['id']}: campo {v['field']} no existe en {v['fn']}")
        elif abs(got - v["value"]) > v.get("tol", 0.001):
            err(f"{src['id']}: {v['fn']}.{v['field']} = {got:.5f}, el contenido dice {v['value']}")
for e in exercises:
    if e["type"] == "numeric":
        # Convención: el primer `verify` de un ejercicio numérico es su respuesta.
        for v in e.get("verify", [])[:1]:
            got = evaluate(v["fn"], v["args"]).get(v["field"])
            if got is not None and abs(got - e["answer"]) > e.get("tol", 0.01):
                err(f"{e['id']}: la respuesta {e['answer']} no coincide con el motor ({got:.5f})")

# ------------------------------------------------------------- reporte
n_cards = sum(len(l["cards"]) for m in modules for l in m["lessons"])
print(f"Módulos {len(modules)} · lecciones {len(lesson_ids)} · tarjetas {n_cards}")
print(f"Ejercicios {len(exercises)} · casos {len(cases)} · experimentos {len(exp_ids)}")
print(f"Confusiones {len(misc_ids)} (usadas {len(used_tags & misc_ids)}) · glosario {len(glossary)}")
print(f"Cifras verificadas: {claims}")
if errors:
    print(f"\n{len(errors)} ERROR(ES):")
    for e in errors:
        print("  ✗", e)
    sys.exit(1)
print("\n✓ Contenido válido")

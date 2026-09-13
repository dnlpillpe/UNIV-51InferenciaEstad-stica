# Guía de contenido

Todo el contenido educativo vive en `assets/content/` y es declarativo: **añadir material no
requiere tocar código Dart**. El validador (`python3 tool/validate_content.py`) y las pruebas de
contenido rechazan cualquier archivo incoherente.

## Archivos

| Archivo | Contiene |
|---|---|
| `modules.json` | Carreras del selector, módulos, lecciones y tarjetas |
| `exercises.json` | Los 50 ejercicios |
| `cases.json` | Los casos profesionales |
| `labs.json` | Laboratorios y experimentos (pregunta, predicciones, conclusión) |
| `misconceptions.json` | Las 30 confusiones con su corrección y su remedio |
| `glossary.json` | Términos del glosario |

## Añadir un ejercicio

```jsonc
{
  "id": "ex_m4_11",              // único; el sufijo se muestra en la cuadrícula del módulo
  "module": "m4",
  "type": "choice",              // choice | decision | numeric | conclusion | classify
  "difficulty": 2,               // 1 a 3
  "lessonRef": "m4_l3",          // lección relacionada (opcional)
  "context": "Enunciado largo opcional, en recuadro aparte.",
  "prompt": "La pregunta.",
  "options": [
    {"text": "La correcta", "correct": true, "feedback": "Por qué lo es."},
    {"text": "Un error típico", "tag": "p_azar", "feedback": "Por qué atrae y por qué falla."}
  ],
  "explanation": "Explicación completa que se muestra siempre tras corregir."
}
```

Reglas que el validador exige:

- exactamente **una** opción correcta; la correcta **no** lleva `tag`;
- todo distractor tiene `feedback` no vacío;
- todo `tag` existe en `misconceptions.json`;
- `classify` usa todas sus categorías;
- en `numeric`, ninguna trampa puede caer dentro de la tolerancia de la respuesta.

### Tipos especiales

**`numeric`** — respuesta con tolerancia y errores típicos declarados:

```jsonc
{
  "type": "numeric", "answer": 3, "tol": 0.01, "decimals": 2, "unit": "puntos",
  "hint": "Pista opcional",
  "traps": [{"value": 15, "tol": 0.01, "tag": "de_vs_error_estandar", "feedback": "..."}],
  "verify": [{"fn": "se_mean", "args": {"sd": 15, "n": 25}, "field": "se", "value": 3, "tol": 0.0001}]
}
```

**`conclusion`** — el estudiante arma la frase: cada `slot` tiene una opción correcta y
fragmentos que son lecturas incorrectas clásicas. `model` es la conclusión completa que se
muestra al final.

**`classify`** — `categories` y `items` con su `category` (índice).

## Cifras verificadas (`verify`)

Cualquier número afirmado en un enunciado debe declararse para que CI lo recalcule:

```jsonc
"verify": [
  {"fn": "test_mean_t",
   "args": {"mean": 0.86, "sd": 0.11, "n": 18, "mu0": 0.80, "tail": "greater"},
   "field": "p", "value": 0.017, "tol": 0.0005}
]
```

Funciones disponibles (`InferenceRegistry.functions`): `z_crit`, `t_crit`, `ci_mean_z`,
`ci_mean_t`, `ci_prop`, `ci_diff_means`, `ci_diff_props`, `test_mean_z`, `test_mean_t`,
`test_prop`, `test_diff_means`, `test_diff_props`, `n_mean`, `n_prop`, `se_mean`, `se_prop`,
`binom_upper`, `cohen_d`, `prob_mean_above`, `prob_mean_between`, `fwer`, `power_mean_z`.

Campos devueltos: `estimate`, `se`, `critical`, `margin`, `lower`, `upper`, `df` (intervalos);
`statistic`, `p`, `df`, `pooled` (pruebas); `n`, `d`, `power` según la función.

**Convención:** en un ejercicio numérico, el primer `verify` es la respuesta.

## Añadir un caso profesional

```jsonc
{
  "id": "case_nuevo", "career": "Ingeniería de Minas", "icon": "terrain",
  "difficulty": 2, "modules": ["m4", "m5"],
  "title": "...", "role": "Eres...", "brief": "Contexto...", "question": "¿...?",
  "data": [{"label": "Muestras (n)", "value": "18"}],
  "analysis": {"fn": "test_mean_t", "alpha": 0.05,
               "args": {"mean": 0.86, "sd": 0.11, "n": 18, "mu0": 0.8, "tail": "greater"},
               "companion": {"fn": "ci_mean_t", "args": {"mean": 0.86, "sd": 0.11, "n": 18, "conf": 0.95}}},
  "expectedReject": true,
  "verify": [ /* las cifras citadas en los pasos */ ],
  "steps": [
    {"type": "choice", "title": "Parámetro", "prompt": "...", "options": [ /* ... */ ]},
    {"type": "compute", "title": "Cálculo", "prompt": "...", "note": "Fórmula sustituida"}
  ],
  "debrief": "Cierre profesional del caso."
}
```

El paso `compute` no necesita nada más: la app ejecuta `analysis`, dibuja la distribución con el
p-valor sombreado y el intervalo, y redacta la interpretación. `expectedReject` se compara en CI
con el resultado real: si alguien edita los datos y la decisión cambia, la prueba falla.

Un caso puede **no** tener `analysis` (como el de Humanidades): entonces no lleva paso de
cálculo, y la enseñanza es precisamente que no corresponde inferir.

## Añadir un experimento a un laboratorio

En `labs.json`, dentro del laboratorio correspondiente:

```jsonc
{
  "id": "e3_4", "minRuns": 200, "tag": "z_en_lugar_de_t",
  "title": "Título corto",
  "question": "La predicción que se pide antes de simular",
  "predictions": [
    {"text": "Intuición equivocada frecuente", "feedback": "Qué muestra la simulación"},
    {"text": "La correcta", "correct": true, "feedback": "Confirmación"}
  ],
  "instructions": "Qué controles mover y cuánto simular.",
  "reveal": "El hallazgo, redactado en el lenguaje del curso."
}
```

Los **preajustes de parámetros** de cada experimento sí viven en código
(`lib/presentation/labs/lab_view_models.dart`, método `preset`): un experimento nuevo que use
una configuración distinta necesita una línea allí.

## Añadir una lección

Tarjetas de tipo `concept`, `formula`, `example`, `warning` (lleva `tag`) y `check` (pregunta con
`options`, `answer` y `explanation`). El campo `visual` acepta una de las ilustraciones
disponibles: `population_sample`, `bias_variance`, `three_distributions`, `se_sqrt_n`,
`clt_shapes`, `normal_95`, `ci_rain_mini`, `t_vs_z`, `p_value_tail`, `errors_matrix`,
`power_curves`, `decision_tree`, `two_groups`, `effect_vs_n`.

## Añadir una confusión

```jsonc
{
  "id": "mi_confusion", "module": "m4",
  "name": "Nombre corto que verá el estudiante",
  "description": "En qué consiste el error.",
  "correction": "La idea correcta, en una frase.",
  "remedyLesson": "m4_l3", "remedyExperiment": "e4_1"
}
```

Debe **usarse** en al menos un distractor: el validador falla si queda huérfana.

## Antes de dar por buena una edición

```bash
python3 tool/validate_content.py   # integridad y cifras
flutter test                       # incluye las suites de contenido
```

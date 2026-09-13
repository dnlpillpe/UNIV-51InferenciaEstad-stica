# Pruebas y calidad

## Estrategia

La app se construyó **sin SDK de Flutter en el entorno** (la red del entorno de construcción no
alcanza pub.dev ni los artefactos de Flutter), así que la verificación se organizó en tres
anillos, del más barato al más caro:

1. **Python, sin Flutter** — corre en cualquier máquina y es el primer paso de CI.
2. **Dart puro** — motor, simulación, contenido y motores de decisión: la mayoría de las pruebas.
3. **Widgets** — flujos completos de la interfaz.

## Anillo 1 · Python

| Script | Qué protege |
|---|---|
| `tool/inference_core.py` | Réplica del motor estadístico, validada contra SciPy (errores < 1e-10) |
| `tool/validate_content.py` | Ids únicos, referencias existentes, una sola opción correcta por ítem, distractores con retroalimentación, etiquetas catalogadas, cada confusión producida por algún distractor, remedios válidos y **50 cifras recalculadas** |
| `tool/static_check.py` | Balance de delimitadores, imports relativos existentes, clases del proyecto importadas donde se usan, imports sin uso, uso coherente de `dart:math`, `dart:convert`, Riverpod y `shared_preferences` en los 88 archivos Dart |

## Anillo 2 · Dart puro

| Suite | Contenido |
|---|---|
| `test/domain/distributions_test.dart` | Normal, t (incluidos grados de libertad no enteros), binomial y `logGamma` frente a valores de tabla y de SciPy; CDF y cuantil como inversas |
| `test/domain/inference_test.dart` | Intervalos y pruebas con los datos reales de las lecciones y los casos; **dualidad IC 95 % ↔ prueba bilateral al 5 %**; tamaño de muestra y potencia; el registro completo de funciones; la calculadora con sus validaciones y advertencias |
| `test/domain/simulation_test.dart` | Propiedades que las lecciones afirman: σ/√n observado, TLC, captura del 95 % con t y del 88 % con el atajo z, sesgo de conveniencia, ventaja del estratificado, tasa de error tipo I ≈ α, potencia ≈ 25 %, 64 % de falsos hallazgos con 20 pruebas, p por permutación ≈ 0,013. Todos los márgenes son de al menos cuatro errores estándar |
| `test/domain/engines_test.dart` | Corrección de los cinco tipos de ejercicio, regla 60/40 y acierto ciego, cálculo de dominio, diagnóstico con decaimiento, recomendación y serialización del progreso |
| `test/content/content_integrity_test.dart` | La misma integridad del validador Python, ahora sobre los modelos de dominio: volumen mínimo, ilustraciones existentes, casos con análisis, 10 carreras, confusiones sin huérfanas |
| `test/content/content_figures_test.dart` | Cada `verify` del contenido contra el motor Dart; la respuesta de cada ejercicio numérico; la decisión esperada de cada caso |
| `test/presentation/lab_view_models_test.dart` | Los cinco ViewModels: preajustes por experimento, reinicio al cambiar parámetros, historial, potencia teórica y barajado que conserva los datos |
| `test/presentation/formatters_test.dart` | Formato español, lectura de lo que escribe el estudiante, marcas de eje |

## Anillo 3 · Widgets

`test/widget/app_flow_test.dart` recorre la app como lo haría un estudiante, en tamaño de
teléfono:

1. Onboarding completo (incluida la elección de carrera) → Inicio → Calculadora, con cálculo y
   lectura de la interpretación.
2. Las cinco pestañas, comprobando que cada una llega a su pantalla sin excepciones.
3. Una lección: el botón «Terminar» permanece desactivado hasta responder la tarjeta de
   comprobación.
4. Un experimento completo: predicción → 100 simulaciones → conclusión revelada con la
   predicción confirmada.

## Doble verificación de las cifras

Las afirmaciones numéricas del contenido se comprueban **dos veces con motores
independientes**: en Python (`validate_content.py`, réplica validada contra SciPy) y en Dart
(`content_figures_test.dart`, el motor real de la app). Si ambos coinciden con el texto, el
enunciado es correcto y la app mostrará exactamente ese número.

Convención: en un ejercicio numérico, el **primer** `verify` es la respuesta esperada; los demás
verifican cifras citadas en la explicación.

## Lo que la verificación no cubre

- **Compilación y ejecución reales**: no había SDK de Flutter en el entorno de construcción. La
  primera compilación ocurre en CI (`ci.yml`), que es la puerta de entrada del proyecto.
- **Aspecto visual en dispositivo**: los pintores se probaron por lógica, no por captura de
  pantalla. Una revisión visual en un teléfono real es el siguiente paso natural.
- **Rendimiento en gama baja**: las simulaciones están acotadas por lotes, pero conviene medir
  la lluvia de 100 intervalos y la máquina de muestras con 1 000 extracciones en un equipo modesto.

## Comprobación local completa

```bash
python3 tool/validate_content.py
python3 tool/static_check.py
flutter analyze --no-fatal-infos
flutter test
```

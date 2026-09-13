# Arquitectura técnica

## Stack y dependencias

| Elemento | Elección | Justificación |
|---|---|---|
| Framework | Flutter (Dart 3.5+) | Un código, Android e iOS; `CustomPainter` da el control fino que exigen los laboratorios |
| Estado | `flutter_riverpod` ^2.6 (`Notifier`) | Providers componibles y sobreescribibles en pruebas; sin generación de código |
| Persistencia | `shared_preferences` ^2.3 | El progreso es un único JSON pequeño; no hace falta una base de datos |
| Arquitectura | MVVM + Repository, con dominio en Dart puro | El motor y las reglas se prueban sin arrancar Flutter |
| Gráficos | `CustomPainter` propio | Ningún paquete permite sombrear exactamente una cola, mover el origen del eje o dibujar cien intervalos con marca de fallo |
| Contenido | JSON en `assets/` | Editable sin tocar código y verificable en CI |

**Dependencias de producción: dos.** Sin backend, sin login, sin `build_runner`, sin router
declarativo, sin librería de gráficos, sin analítica.

## Capas

```
presentation  (widgets, providers, pintores)      ── depende de ──▶ domain
      │                                                              ▲
      └── data (JSON de assets, preferencias) ── implementa ─────────┘ (interfaces)
```

`lib/domain` no importa Flutter en ninguno de sus archivos. Eso permite que la mayor parte de
las pruebas corra sin interfaz.

```
lib/
├── core/
│   ├── theme/          AppColors (semántica de color), AppTheme (claro y oscuro), ChartPalette
│   ├── utils/          formato español (coma decimal, p-valores, marcas de eje), iconos
│   ├── widgets/        tarjetas, anillos, píldoras, fondo con curvas
│   └── branding/       AppLogoPainter (misma figura que el icono)
├── domain/
│   ├── stats/          Distributions · Inference · InferenceRegistry · RandomSource · Descriptive
│   ├── simulation/     Population · SamplingSimulator · IntervalSimulator ·
│   │                   HypothesisSimulator · PermutationTest · CitySurvey
│   ├── models/         contenido (módulos, ejercicios sellados, casos, laboratorios) y progreso
│   ├── engine/         GradingEngine · MasteryEngine · DiagnosisEngine ·
│   │                   RecommendationEngine · ProcedureRunner + Interpretation
│   └── repositories/   interfaces ContentRepository y ProgressRepository
├── data/               ContentParser · AssetContentRepository · PrefsProgressRepository
└── presentation/
    ├── providers/      providers de la app y ProgressNotifier (única puerta de escritura)
    ├── charts/         chart_kit + 7 pintores + ilustraciones de lecciones
    ├── labs/           ViewModels de laboratorio (Dart puro) + marco de experimento
    ├── screens/        14 pantallas
    └── widgets/        opciones, ejercicios, resultados, confusiones
```

## El motor estadístico

Todo implementado desde cero, sin dependencias:

| Función | Algoritmo | Precisión verificada |
|---|---|---|
| CDF normal | Hart 5666 (West, 2005) | ~1e-14 frente a SciPy |
| Cuantil normal | Acklam + un paso de Halley | ~1e-10 |
| CDF t | Beta incompleta regularizada, fracción continua de Lentz | ~1e-13 |
| Cuantil t | Bisección sobre la CDF, con caché | ~1e-11 |
| Binomial | Vía `logGamma` (Lanczos) | ~1e-12 |

`tool/inference_core.py` es la **réplica exacta en Python** de este motor: se validó contra
SciPy y permite verificar las cifras del contenido en CI sin instalar Flutter.

Procedimientos: IC y prueba para una media (z/t), una proporción, diferencia de medias (Welch,
con grados de libertad no enteros), diferencia de proporciones (combinada en la prueba, no
combinada en el intervalo), tamaño de muestra, d de Cohen, potencia y error por comparaciones
múltiples.

### Registro de funciones con nombre

`InferenceRegistry` expone el motor bajo nombres (`test_mean_t`, `ci_prop`, …). Gracias a eso:

- un **caso** declara su análisis en JSON (`{"fn": "...", "args": {...}, "alpha": 0.05}`) y la
  app lo ejecuta sin código específico;
- cualquier **cifra afirmada** en un enunciado se declara como `verify` y el test la recalcula;
- la **réplica Python** tiene el mismo registro, así que la validación de contenido en CI no
  necesita el SDK de Flutter.

## Simulación

`RandomSource` envuelve `math.Random` con semilla y añade normal (polar de Marsaglia),
exponencial y barajado. Todas las simulaciones la reciben por parámetro: los tests reproducen
cualquier experimento.

- `Population`: población **finita y concreta** (5 000 valores) en cuatro formas. μ y σ son
  exactos, no teóricos: el estudiante ve el mundo que la muestra intenta adivinar.
- `CitySurvey`: 600 residentes en cuadrícula con cuatro distritos de tasas muy distintas
  (90 %, 60 %, 30 %, 10 %); cinco métodos, incluidos conveniencia (muestreo ponderado por
  cercanía al campus y por uso del transporte) y respuesta voluntaria (probabilidad de responder
  dependiente de la opinión).
- `IntervalSimulator`, `HypothesisSimulator`, `PermutationTest`: el resto de los laboratorios.

Rendimiento: 1 000 muestras de n = 200 son 200 000 extracciones, imperceptible en el hilo de UI;
los laboratorios trabajan por lotes (×1, ×10, ×100, ×1 000) en vez de animar cada repetición.

## Estado y persistencia

`ProgressState` es inmutable (`copyWith`) y contiene lecciones, ejercicios (mejor puntaje,
intentos), casos, experimentos, predicciones, historial de etiquetas, contadores de decisión y
ajustes. Se serializa a un único JSON con claves cortas y se guarda en cada cambio.
`ProgressNotifier` es la única puerta de escritura.

Los **ViewModels de laboratorio** (`presentation/labs/lab_view_models.dart`) son Dart puro y de
vida corta: cada pantalla crea el suyo. Una simulación nunca contamina otra y se prueban sin
interfaz.

## Decisión sobre inteligencia artificial

**No hay IA en el MVP, y es una decisión, no una omisión.**

Lo que un tutor generativo aportaría aquí es redacción; lo que hace falta es **diagnóstico de
contenido**: saber que *este* estudiante confunde α con p. Eso lo produce el historial de
etiquetas con mucha más fiabilidad y sin costo, conexión ni riesgo.

Riesgos concretos de un modelo de lenguaje en este dominio: inventar una fórmula, afirmar
causalidad a partir de una asociación —justo lo que el módulo 5 corrige— o dar un número
distinto al del motor de la app, que sería el peor error posible en una app de estadística.

**Dónde sí aportaría, en una versión futura**: evaluar conclusiones escritas libremente (con el
motor como fuente de verdad de las cifras y el modelo solo como evaluador de redacción) y generar
variantes de casos para práctica adicional. La arquitectura lo permite sin reescribir nada:
bastaría una implementación alternativa de un `ConclusionEvaluator` inyectado por provider, con
la regla de que el modelo nunca calcula ni modifica el puntaje.

## Riesgos técnicos conocidos

| Riesgo | Mitigación |
|---|---|
| Primera compilación sin SDK local | CI compila y prueba; validación previa en Python y verificación estática de los 88 archivos |
| Cambios de API entre versiones de Flutter | Se evitan las clases de tema en transición (`AppBarTheme`, `InputDecorationTheme`); solo dos dependencias externas |
| Simulaciones pesadas en equipos modestos | Lotes acotados; el histograma reemplaza a los puntos apilados cuando hay más de 300 medias |
| Crecimiento del contenido | JSON declarativo + validador que exige retroalimentación, etiquetas catalogadas y cifras verificadas |

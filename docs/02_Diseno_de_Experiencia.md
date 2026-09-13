# Diseño de la experiencia de aprendizaje

## El ciclo de cada módulo

```
Lecciones (tarjetas)  →  Laboratorio (Predice · Simula · Explica)  →  Práctica  →  Casos
      ↑                                                                  │
      └──────────────── diagnóstico de confusiones ──────────────────────┘
```

Ninguna etapa está bloqueada: el estudiante que llega el día antes del examen puede ir directo a
la práctica. Lo que sí ocurre es que el **dominio** solo sube si pasa por todas, y que la
recomendación de Inicio lo lleva a la siguiente actividad pendiente del primer módulo no
competente.

## Predice → Simula → Explica

Cada experimento tiene tres fases y una regla estricta:

1. **Predice.** Se muestra la pregunta y tres alternativas. Los controles del laboratorio están
   desactivados hasta registrar la predicción. No resta puntos: su función es comprometer una
   intuición, porque una intuición explícita que falla se corrige; una implícita, no.
2. **Simula.** Se habilitan los controles y una barra indica cuántas repeticiones faltan
   (`minRuns`, entre 5 y 1 000 según el experimento).
3. **Explica.** Recién con el mínimo alcanzado aparece «Ver la conclusión», que compara la
   predicción con el resultado, muestra **lo que el estudiante midió en su propia simulación** y
   revela el hallazgo redactado.

Quien ya completó un experimento entra en modo exploración: controles libres y conclusión
disponible.

## Los cinco laboratorios

| Lab | Módulo | Qué se manipula | Qué se descubre |
|---|---|---|---|
| **Encuesta en Villa Muestra** | 1 | Método (5 diseños) y n en dos filas comparables | El sesgo no baja con n; el estratificado reduce la dispersión |
| **Máquina de muestras** | 2 | Forma de la población, n, número de muestras | TLC, ley de √n, muestra ≠ distribución muestral |
| **Lluvia de intervalos** | 3 | Nivel de confianza, n, método (z σ, t s, z s) | La confianza es una tasa de acierto del método; el atajo z con s falla |
| **El mundo de H0** | 4 | Aciertos observados; efecto real, n | De dónde sale el p-valor; α como tasa de falsas alarmas; potencia |
| **Sala de decisiones** | 5 | Barajado de etiquetas; nº de analistas; n por grupo | Inferencia sin fórmulas; comparaciones múltiples; significativo ≠ importante |

Cada laboratorio mantiene un **historial de configuraciones** (el lab 3 guarda las tasas de
captura anteriores; el 2, el error estándar observado por cada n) para que la comparación no
dependa de la memoria del estudiante.

## Los cinco tipos de ejercicio

| Tipo | Qué evalúa | Detalle |
|---|---|---|
| **Elige** | Concepto o lectura correcta | Cada alternativa incorrecta tiene su propia retroalimentación y su etiqueta de confusión |
| **Decide y justifica** | Decisión + razón | Regla 60/40; detecta el «acierto ciego» |
| **Calcula** | Aplicación con interpretación | Las respuestas erróneas típicas son *trampas* declaradas: usar σ en vez de σ/√n, z en vez de t, una sola cola |
| **Redacta la conclusión** | Comunicación | El estudiante arma la frase eligiendo un fragmento por casilla; los fragmentos equivocados son las lecturas incorrectas clásicas |
| **Clasifica** | Discriminación | Parámetro/estadístico, probabilístico/no probabilístico, error I/II, elección de procedimiento |

La corrección nunca dice solo «incorrecto»: muestra la retroalimentación del distractor elegido,
la etiqueta de la confusión (tocable, con su remedio) y la explicación completa.

## Casos profesionales

Flujo de 4 a 6 pasos: parámetro → hipótesis o procedimiento → condiciones → **cálculo ejecutado
por la app** → decisión → conclusión o riesgo. El paso de cálculo dibuja la distribución de
referencia con el p-valor sombreado y el intervalo asociado; el estudiante no calcula, interpreta.

El puntaje cuenta el **primer intento** de cada paso, pero el caso permite reintentar hasta
acertar: en la vida profesional el informe se entrega con la decisión correcta.

Dos casos rompen el patrón a propósito: el ambiental termina en «no concluyente, amplíe el
muestreo» y el de Humanidades en «no se puede inferir», porque saber cuándo **no** hacer
inferencia es parte de la competencia.

## Identidad visual

La paleta sale del propio curso y se mantiene en toda la app:

| Color | Significado | Uso |
|---|---|---|
| Índigo `#22306B` | El mundo desconocido: la población, μ, p | Marca, líneas de parámetro |
| Ámbar `#F2A541` | Confianza | Bandas e intervalos que capturan, estimaciones |
| Coral `#E5484D` | Rechazo y error | Colas del p-valor, intervalos que fallan, confusiones |
| Verde azulado `#1F9E89` | Acierto | Correcciones, decisiones correctas |
| Violeta `#6C4AB6` | Distribución muestral | Histogramas de medias, predicciones |

Cada módulo tiene su color (azul, violeta, ámbar, coral, verde azulado) y lo lleva a sus
lecciones, ejercicios y laboratorio. Los intervalos que fallan se marcan además con un punto
lateral, para no depender solo del color.

El fondo de cabecera dibuja curvas normales tenues y puntos muestrales: el motivo de la app es
la campana con su franja de confianza, el mismo dibujo del icono (`AppLogoPainter` y
`tool/generate_icon.py` producen la misma figura).

**Gráficos propios.** Siete pintores (`CustomPainter`) sin librerías: histograma con curva
teórica superpuesta, puntos apilados, lluvia de intervalos, densidad con regiones sombreadas,
mapa de la ciudad, barras discretas y curva de potencia. Razón: los laboratorios necesitan
geometría expuesta (mover el eje, sombrear una cola exacta, marcar μ) que una librería genérica
no ofrece. Las ilustraciones de las lecciones se generan con el mismo motor de simulación: no
hay imágenes estáticas que puedan contradecir al contenido.

## Accesibilidad y forma

- Todo funciona en vertical, con áreas táctiles de al menos 48 dp.
- Tema claro y oscuro, con paletas de gráfico separadas.
- Las casillas de estadísticas escalan el valor en vez de desbordar si el texto crece.
- Español rioplatense-neutro con notación local: coma decimal, espacio fino para los miles.

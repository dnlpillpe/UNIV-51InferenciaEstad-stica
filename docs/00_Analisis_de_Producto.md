# Análisis de producto — Inferencia Estadística

Marco de 13 dimensiones de *Educational App Factory*. Este análisis se hizo **antes** de
construir y explica por qué la app tiene la forma que tiene.

---

## 1. Problema educativo que resuelve

El enunciado de partida —«enseñar inferencia estadística mediante simulaciones»— es correcto
pero no dice dónde falla el aprendizaje. Al descomponerlo aparecen cinco fallos concretos,
todos documentados en la investigación sobre enseñanza de la estadística:

1. **El experimento imaginario nunca se ve.** Toda la inferencia se apoya en «si repitiera el
   muestreo muchas veces». El estudiante nunca lo repite: recibe el resultado ya empaquetado
   en una fórmula.
2. **Se confunden tres distribuciones**: la de la población, la de una muestra y la del
   estadístico a lo largo de muchas muestras. Sin separarlas, el error estándar es un símbolo
   sin significado y el TLC se recuerda como «los datos se vuelven normales».
3. **El intervalo se lee como probabilidad**: «hay 95 % de probabilidad de que μ esté aquí».
   La confianza es una propiedad del procedimiento, no del intervalo ya calculado.
4. **El p-valor se lee al revés**: como probabilidad de que H0 sea cierta, o de que «el
   resultado se deba al azar»; y «no rechazar» se convierte en «queda demostrado que no hay
   efecto».
5. **La decisión se separa del contexto**: el curso termina en «rechazo H0» y no en «qué hago,
   qué comunico y qué riesgo asumo», que es lo que pide el trabajo profesional.

Un sexto fallo atraviesa a todos: **acertar sin entender**. En inferencia el repertorio de
respuestas es pequeño (rechazar / no rechazar, t / z) y se puede acertar por eliminación.

## 2. Usuario objetivo

Estudiantes universitarios que cursan Estadística Inferencial, Estadística II, Bioestadística,
Métodos cuantitativos o Control estadístico de la calidad. Es transversal: aparece en las nueve
carreras del proyecto, y se suma a Biología y Estadística. También sirve a quien prepara tesis y
necesita justificar un análisis.

## 3. Nivel académico

Ciclos intermedios (3.º a 5.º). **Conocimientos previos que asume**: estadística descriptiva
(media, desviación, distribución de frecuencias) y lectura básica de gráficos —justo lo que
cubren *Estadística Fundamental* y *Data Visualization Lab* de este mismo catálogo—. No asume
cálculo ni probabilidad formal: las distribuciones se presentan como herramientas de trabajo.

## 4. Competencia que desarrolla

**Tomar y comunicar decisiones bajo incertidumbre a partir de datos muestrales.** En concreto:
elegir el procedimiento, verificar condiciones, interpretar el resultado en el lenguaje del
problema, declarar la incertidumbre y nombrar el riesgo de equivocarse (tipo I o II).

## 5. Metodología educativa

Cuatro enfoques combinados, cada uno donde es más eficaz:

- **Aprendizaje experiencial con simulación** (laboratorios): la inferencia se *observa* antes
  de formalizarse.
- **Ciclo Predice → Simula → Explica** (POE): la predicción previa hace visible la intuición
  equivocada, que es lo que hay que corregir.
- **Práctica deliberada con retroalimentación diagnóstica**: cada error devuelve la confusión
  conceptual que lo explica, no solo la corrección.
- **Aprendizaje basado en problemas**: los casos ponen al estudiante en el rol profesional, con
  datos, costos y consecuencias.

Microlearning en las lecciones (tarjetas de 4–6 minutos) como soporte, nunca como núcleo.

## 6. Experiencia de aprendizaje

El estudiante **predice** qué pasará, **mueve controles** (tamaño de muestra, nivel de
confianza, método, efecto real), **acumula cientos de repeticiones** y ve aparecer la forma de
la distribución muestral, la lluvia de intervalos o la tasa de falsas alarmas. Luego **decide**:
elige el procedimiento, justifica, arma la conclusión con fragmentos y asume el riesgo. La app
le devuelve no un puntaje, sino un diagnóstico: «estás mezclando α con p».

## 7. Evaluación del aprendizaje

- **Puntaje por ejercicio** con regla 60/40 en las decisiones (elección 0,6 / justificación 0,4).
- **Dominio por módulo** = 15 % lecciones + 15 % experimentos + 70 % práctica; «competente»
  exige 0,70 en el total **y** 0,70 en la práctica, precisamente para que el acierto ciego no
  alcance.
- **Historial de confusiones** con decaimiento: un error suma, un acierto posterior en un ítem
  capaz de detectar esa confusión resta.
- **Indicadores propios**: *acierto ciego* (decisión correcta con justificación incorrecta) e
  *intuición inicial* (predicciones acertadas antes de simular).
- **Casos**: fracción de pasos acertados al primer intento, con reintento permitido para que el
  caso siempre termine con la decisión correcta.

## 8. Funcionalidades principales

1. Cinco laboratorios de simulación con 14 experimentos (muestreo sesgado, máquina de muestras,
   lluvia de intervalos, mundo de H0, sala de decisiones).
2. Cincuenta ejercicios en cinco formatos, incluido «arma la conclusión» y «clasifica».
3. Once casos profesionales paso a paso con cálculo ejecutado por la app.
4. Calculadora inferencial (8 procedimientos) con interpretación redactada y advertencias de
   condiciones.
5. Diagnóstico de confusiones con remedio enlazado.
6. Veinte lecciones en tarjetas con ilustraciones generadas por el mismo motor de simulación.
7. Glosario de 43 términos y progreso detallado. Todo sin conexión.

## 9. Tipo de aplicación

**Laboratorio virtual + entrenador de decisiones.** No es un banco de preguntas ni un libro
digital: su núcleo es un motor de simulación con el que el estudiante experimenta, y un motor de
diagnóstico que interpreta sus errores.

## 10. Viabilidad técnica

Alta. No requiere servicios externos: toda la estadística (normal, t, binomial, beta incompleta)
y toda la simulación están implementadas en Dart puro, con generador aleatorio con semilla. Sin
backend, sin login, sin librería de gráficos (siete pintores propios). **MVP construido**: los 5
módulos, 14 experimentos, 50 ejercicios, 11 casos, calculadora, diagnóstico y progreso local.

## 11. Escalabilidad

- El **motor estadístico y de simulación** sirve para cualquier curso de inferencia.
- El **sistema de confusiones etiquetadas** y el diagnóstico son independientes del dominio.
- El **contenido es 100 % declarativo en JSON**: añadir un caso de otra carrera no toca código.
- El **registro de funciones con nombre** (`fn` + `args`) permite que un caso nuevo declare su
  análisis y que el test de cifras lo verifique automáticamente.
- Crecimiento natural: ANOVA y chi-cuadrado, regresión, bootstrap, panel docente.

## 12. Diferenciación frente a métodos tradicionales

Una clase magistral puede *describir* la distribución muestral; un libro puede *dibujarla*. Solo
una simulación interactiva permite que el estudiante la **construya** y descubra que su
intuición fallaba. Frente a una app genérica de preguntas, aquí el error no es un fallo: es un
dato que activa un diagnóstico y un experimento que corrige justo esa idea. Y frente a un
software estadístico profesional (SPSS, R), la app no busca calcular más rápido, sino explicar
por qué el cálculo significa lo que significa.

## 13. Evaluación del potencial

**Fortalezas.** Cubre el curso más reprobado de la línea cuantitativa en muchas carreras; el
contenido es transversal, así que una institución lo usa en todas sus facultades; el diagnóstico
de confusiones produce información útil para el docente sin necesidad de conectar nada.

**Riesgos y mitigaciones.**

| Riesgo | Mitigación aplicada |
|---|---|
| Una app «para todos» puede no ser de nadie | 11 casos anclados en carreras concretas y selector de carrera al inicio. |
| La simulación puede quedarse en juego visual | Cada experimento exige predicción previa y termina en una conclusión escrita que nombra el concepto. |
| El estudiante puede adivinar respuestas | Regla 60/40, indicador de acierto ciego y umbral de competencia en la práctica. |
| Sin panel docente no hay adopción institucional | La arquitectura aísla el progreso en un repositorio: un backend opcional es un cambio local (ver docs/04). |
| Contenido numérico que envejece mal | 50 cifras verificadas en CI contra el motor; ninguna afirmación se escribe a mano sin comprobar. |

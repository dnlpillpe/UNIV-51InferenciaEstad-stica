# Especificación funcional del MVP

## Alcance construido

| # | Funcionalidad | Criterio de aceptación | Estado |
|---|---|---|---|
| F1 | Onboarding con selección de carrera | Tres pantallas; la carrera ordena los casos y se puede cambiar en Ajustes | ✔ |
| F2 | Ruta de 5 módulos con dominio | Cada módulo muestra su dominio y su nivel; ninguno bloqueado | ✔ |
| F3 | 20 lecciones en tarjetas | Tarjeta de comprobación obligatoria antes de avanzar; ilustraciones generadas | ✔ |
| F4 | 5 laboratorios, 14 experimentos | Ciclo Predice → Simula → Explica con mínimo de repeticiones | ✔ |
| F5 | 50 ejercicios en 5 formatos | Retroalimentación por alternativa y etiqueta de confusión | ✔ |
| F6 | 11 casos profesionales | Cálculo ejecutado por la app; puntaje por primer intento; cierre con debrief | ✔ |
| F7 | Calculadora inferencial | 8 procedimientos, interpretación redactada, advertencias de condiciones | ✔ |
| F8 | Diagnóstico de confusiones | Historial con decaimiento; remedio enlazado; visible en Inicio y Progreso | ✔ |
| F9 | Progreso | Dominio por módulo, acierto ciego, intuición inicial, días activos, reinicio | ✔ |
| F10 | Glosario | 43 términos con búsqueda sin acentos | ✔ |
| F11 | Sin conexión y sin cuentas | Todo el contenido empaquetado; progreso en almacenamiento local | ✔ |
| F12 | Tema claro/oscuro | Preferencia persistida; gráficos con paleta propia por tema | ✔ |

## Reglas de negocio

- **Puntaje de decisión:** 0,6 elección + 0,4 justificación. `blindHit` cuando la elección es
  correcta y la justificación no.
- **Dominio de módulo:** `0,15·lecciones + 0,15·experimentos + 0,70·práctica`. La práctica
  promedia el mejor puntaje de cada ejercicio y de cada caso vinculado, contando 0 lo no
  intentado. **Competente** exige ≥ 0,70 en total y ≥ 0,70 en práctica; **dominio**, ≥ 0,90 y
  ≥ 0,85.
- **Confusiones:** cada distractor con etiqueta suma 1; cada acierto en un ítem capaz de
  detectar esa etiqueta resta 0,5. Los eventos pierden 3 % de peso por cada evento posterior; se
  consideran activas desde 0,6. Se guardan los últimos 400 eventos.
- **Recomendación:** confusión fuerte (≥ 1,5) → su remedio; si no, primer módulo no competente
  → lección pendiente → experimento pendiente → práctica; si todo está competente → casos, con
  los de la carrera primero.
- **Casos:** el puntaje cuenta el primer intento de cada paso de elección; se guarda el mejor
  resultado.

## Fuera del MVP (y por qué)

| Descartado | Razón | Cuándo tendría sentido |
|---|---|---|
| Tutor con modelo de lenguaje | Riesgo alto en este dominio: inventar una fórmula, afirmar causalidad o dar un número distinto al del motor. El diagnóstico que importa es de contenido (qué confusión), y eso lo produce el historial de etiquetas | Cuando exista proxy institucional y evaluación de respuestas abiertas (ver docs/04) |
| Panel docente y sincronización | Exige backend, cuentas y protección de datos de estudiantes | Piloto institucional |
| ANOVA, chi-cuadrado, regresión | Alcance controlado: el MVP cubre la lógica inferencial completa con una y dos muestras | v1.1 |
| Bootstrap e intervalos por simulación | El lab 5 ya introduce la lógica de remuestreo con la prueba por permutación | v1.1 |
| Importar datos del estudiante | Complejidad de formatos y validación; la calculadora acepta resúmenes | v1.2 |
| Ejercicios de respuesta abierta | Evaluar texto libre sin LLM produce falsos negativos; «arma la conclusión» captura casi lo mismo | Con evaluación asistida |

## Ruta de evolución

1. **v1.1** — pruebas pareadas y chi-cuadrado; bootstrap en el lab 5; 10 casos nuevos.
2. **v1.2** — exportar informe del estudiante (PDF) y modo docente sin backend (código de aula
   con resumen local compartible).
3. **v2.0** — backend opcional (progreso sincronizado, panel de aula) y evaluación de
   conclusiones abiertas.

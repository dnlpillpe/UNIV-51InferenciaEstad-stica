# Validación académica

## Cursos donde encaja

| Carrera | Curso típico | Uso principal |
|---|---|---|
| Todas | Estadística II / Inferencial | Curso completo |
| Ing. de Minas | Muestreo de minerales, Control de calidad | Módulos 3–5 y caso de leyes |
| Ing. Ambiental | Monitoreo y cumplimiento de límites | Módulo 4 y caso de vertimientos |
| Ing. de Sistemas | Experimentación A/B, métricas de producto | Módulo 5 y caso A/B |
| Ing. Electrónica | Control estadístico de procesos | Módulos 3–4 y caso de resistencias |
| Administración / Economía | Métodos cuantitativos, investigación de mercados | Módulos 1, 3 y 5 |
| Contabilidad | Auditoría y muestreo | Módulo 4 y caso de auditoría |
| Psicología | Estadística aplicada, diseño de investigación | Módulos 4–5 y caso de intervención |
| Biología | Bioestadística | Módulo 4 y caso de germinación |
| Humanidades | Métodos de investigación social | Módulos 1 y 3 |

## Temas fundamentales y dónde están

| Tema | Módulo | Lección | Laboratorio |
|---|---|---|---|
| Parámetro vs. estadístico | 1 | m1_l1 | — |
| Diseños de muestreo probabilístico | 1 | m1_l2 | e1_2 |
| Sesgo de selección, cobertura y no respuesta | 1 | m1_l3 | e1_1 |
| Variabilidad muestral | 1 | m1_l4 | e1_1 |
| Las tres distribuciones | 2 | m2_l1 | e2_3 |
| Error estándar y ley de la raíz | 2 | m2_l2 | e2_2 |
| Teorema del Límite Central | 2 | m2_l3 | e2_1 |
| Probabilidad de una media; condiciones para p̂ | 2 | m2_l4 | — |
| Construcción del intervalo | 3 | m3_l1 | e3_1 |
| Interpretación del nivel de confianza | 3 | m3_l2 | e3_1, e3_2 |
| t de Student y grados de libertad | 3 | m3_l3 | e3_3 |
| IC para proporción y tamaño de muestra | 3 | m3_l4 | — |
| Lógica de la prueba; H0 como presunción | 4 | m4_l1 | e4_1 |
| Planteamiento de hipótesis y dirección | 4 | m4_l2 | — |
| p-valor | 4 | m4_l3 | e4_1, e4_2 |
| Errores tipo I y II, potencia, dualidad IC–prueba | 4 | m4_l4 | e4_2, e4_3 |
| Elección del procedimiento; pareados | 5 | m5_l1 | — |
| Comparación de dos grupos | 5 | m5_l2 | e5_1 |
| Significancia vs. relevancia; tamaño del efecto | 5 | m5_l3 | e5_3 |
| Comparaciones múltiples y reporte honesto | 5 | m5_l4 | e5_2 |

**Dos módulos añadidos al encargo.** El pedido mencionaba cuatro temas (muestras, población,
intervalos, pruebas). El análisis incorporó el módulo 2, *Distribución muestral*, porque sin él
los intervalos y las pruebas se aprenden como rituales; y el módulo 5, *Decisiones*, porque la
competencia pedida —«analiza escenarios y toma decisiones estadísticas»— no se evalúa con
ejercicios de cálculo.

## Dificultades frecuentes que el contenido ataca

Las 30 confusiones catalogadas (`assets/content/misconceptions.json`) corresponden a los errores
más documentados en la enseñanza de la inferencia. Cada una:

1. aparece como **distractor** en al menos un ejercicio o caso (verificado en CI);
2. tiene una **corrección** redactada en una frase;
3. enlaza a la **lección** y, cuando existe, al **experimento** que la desmonta.

Ejemplos de las más resistentes:

- `ic_probabilidad_parametro` — «95 % de probabilidad de que μ esté en el intervalo». Se ataca
  con la lluvia de intervalos: cien investigadores, cada uno con un solo intervalo y sin ver μ.
- `p_prob_h0` y `p_azar` — el p-valor como probabilidad de la hipótesis o del azar. Se ataca
  simulando el mundo de H0 y contando frecuencias.
- `no_rechazar_es_aceptar` y `baja_potencia` — el no rechazo leído como prueba de ausencia. Se
  ataca con el experimento de potencia: con efecto real de 0,3σ y n = 20, tres de cada cuatro
  estudios «no encuentran nada».
- `muestra_grande_corrige_sesgo` — el tamaño como remedio del sesgo. Se ataca con 200 encuestas
  de conveniencia que caen lejos del valor real y 25 aleatorias que caen alrededor.

## Aplicación profesional

Cada caso reproduce un encargo real con su decisión y su costo: aprobar una inversión minera,
sancionar un vertimiento, implementar un cambio de producto, recalibrar una línea, lanzar una
suscripción, informar un cambio de gasto, ampliar una auditoría, recomendar un programa
psicológico, reclamar a un proveedor, frenar una cifra mal obtenida y redactar una campaña sin
prometer causalidad.

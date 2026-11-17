# Pre-entrega · Feature Engineering con SQL Analítico (RFM + Trend para Churn)

**Curso:** Data Science II — Coderhouse

Preparación de *features* por usuario **directamente desde la base de datos** con SQL,
pensadas para alimentar un modelo de **predicción de abandono (Churn)**. Se calculan las
tres métricas clásicas de comportamiento (**RFM**) más una variable de **tendencia**,
usando funciones de ventana.

## Archivos

| Archivo | Contenido |
|---------|-----------|
| `features_churn.sql` | **Consulta principal**: genera las features por usuario. |
| `datos_ejemplo.sql`  | Crea y puebla tablas de ejemplo (`users`, `orders`) para probar la consulta. |

## Cómo ejecutar

Dialecto: **DuckDB** (embebido, sin servidor).

```bash
pip install duckdb

# con la CLI de DuckDB:
duckdb < datos_ejemplo.sql
duckdb < features_churn.sql

# o en una sola sesión de Python:
python -c "import duckdb; c=duckdb.connect(); \
c.execute(open('datos_ejemplo.sql').read()); \
print(c.execute(open('features_churn.sql').read()).df())"
```

> En PostgreSQL funciona igual cambiando `date_diff('day', a, b)` por `(b - a)`.

## Lógica de cada feature

El modelo de churn busca distinguir usuarios que están por abandonar de los que siguen
activos. Cada feature aporta una señal distinta de ese comportamiento:

- **Recency (`recency_dias`)** — días desde la última compra, calculado como
  `fecha_referencia - MAX(order_date)`. Es el predictor de churn más fuerte: cuanto más
  tiempo sin comprar, mayor probabilidad de abandono. Un usuario sin pedidos recibe un
  valor alto (9999) que lo marca como inactivo.

- **Frequency (`frequency_pedidos`)** — cantidad de pedidos únicos
  (`COUNT(DISTINCT order_id)`). Mide el hábito de compra: los clientes frecuentes tienen
  una relación más sólida y menor propensión a irse.

- **Monetary (`monetary_total`)** — gasto total acumulado (`SUM(amount)`). Cuantifica el
  valor del cliente; perder clientes de alto gasto es más costoso, y el nivel de gasto
  suele correlacionar con la retención.

- **Trend (`trend_delta_gasto`)** — diferencia entre el **gasto del último mes** y el
  **promedio mensual histórico** del usuario. Captura la *dirección* del comportamiento,
  no solo su nivel: un delta **negativo** indica que el usuario está gastando menos de lo
  habitual (señal temprana de desenganche), mientras que uno positivo indica crecimiento.
  Esta variable es la que mejor anticipa el churn antes de que la recency se dispare.

## Decisiones técnicas

- **Fecha de referencia:** se usa `MAX(order_date)` del dataset como "hoy", en lugar de
  `CURRENT_DATE`. Sobre datos históricos, `CURRENT_DATE` inflaría artificialmente la
  recency de todos los usuarios por igual.

- **Funciones de ventana (dos):**
  - `AVG(gasto_mes) OVER (PARTITION BY user_id)` → promedio mensual histórico por usuario.
  - `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY mes DESC)` → identifica el mes más
    reciente de cada usuario para obtener su gasto del último mes.

- **Manejo de nulos:** la consulta parte de la tabla `users` con `LEFT JOIN` a las
  transacciones, de modo que **todos** los usuarios aparecen (incluidos los que nunca
  compraron). Las agregaciones se envuelven en `COALESCE(..., 0)` para que un usuario sin
  actividad tenga `0` en Frequency, Monetary y Trend, en lugar de `NULL` —necesario para
  que el modelo no reciba valores faltantes.

- **Ventanas temporales:** la tendencia se calcula sobre meses calendario
  (`date_trunc('month', order_date)`), evitando mezclar períodos parciales que sesgarían
  el promedio.

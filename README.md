# Pre-entrega · Feature Engineering con SQL Analítico

**Curso:** Data Science II — Coderhouse

Preparación de *features* por usuario directamente desde la base de datos con SQL,
pensadas para alimentar un modelo de predicción de abandono (Churn). Se calculan las
tres métricas clásicas de comportamiento (RFM) más una variable de tendencia,
usando funciones de ventana.

## Archivos

| Archivo | Contenido |
|---------|-----------|
| `features_churn.sql` | Consulta principal: genera las features por usuario. |
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

- **Trend (`trend_delta_gasto`)** — diferencia entre el gasto del último mes y el
  promedio mensual histórico del usuario. Captura la *dirección* del comportamiento,
  no solo su nivel: un delta negativo indica que el usuario está gastando menos de lo
  habitual (señal temprana de desenganche), mientras que uno positivo indica crecimiento.
  Esta variable es la que mejor anticipa el churn antes de que la recency se dispare.

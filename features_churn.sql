-- ============================================================================
-- features_churn.sql
-- Consulta principal: preparación de features por usuario para un modelo de
-- predicción de abandono (Churn), directamente desde la base de datos.
--
-- Features generadas (una fila por usuario):
--   - recency_dias        : días desde la última compra
--   - frequency_pedidos   : cantidad de pedidos únicos
--   - monetary_total      : gasto total acumulado
--   - trend_delta_gasto   : gasto del último mes - promedio mensual histórico
--
-- Dialecto: DuckDB (date_diff, date_trunc). En PostgreSQL, reemplazar
-- date_diff('day', a, b) por (b - a) y date_trunc se mantiene igual.
-- Requiere las tablas creadas por datos_ejemplo.sql.
-- ============================================================================

WITH parametros AS (
    -- Fecha de referencia ("hoy"): la última fecha con actividad en el dataset.
    -- Evita usar CURRENT_DATE, que sobre datos históricos distorsiona la recency.
    SELECT MAX(order_date) AS fecha_ref
    FROM orders
),

gasto_mensual AS (
    -- Gasto por usuario y mes calendario (base para las métricas de tendencia).
    SELECT
        user_id,
        date_trunc('month', order_date) AS mes,
        SUM(amount)                     AS gasto_mes
    FROM orders
    GROUP BY user_id, date_trunc('month', order_date)
),

mensual_ventana AS (
    -- Funciones de ventana sobre la serie mensual de cada usuario:
    --   (1) promedio mensual histórico  -> AVG() OVER (PARTITION BY ...)
    --   (2) ranking del mes más reciente -> ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)
    SELECT
        user_id,
        mes,
        gasto_mes,
        AVG(gasto_mes)  OVER (PARTITION BY user_id)                    AS gasto_mensual_prom_hist,
        ROW_NUMBER()    OVER (PARTITION BY user_id ORDER BY mes DESC)  AS orden_mes_desc
    FROM gasto_mensual
),

ultimo_mes AS (
    -- Se queda con el mes más reciente de cada usuario (orden_mes_desc = 1).
    SELECT
        user_id,
        gasto_mes                 AS gasto_ultimo_mes,
        gasto_mensual_prom_hist
    FROM mensual_ventana
    WHERE orden_mes_desc = 1
),

rfm AS (
    -- Métricas clásicas RFM por usuario.
    SELECT
        o.user_id,
        date_diff('day', MAX(o.order_date), (SELECT fecha_ref FROM parametros)) AS recency_dias,
        COUNT(DISTINCT o.order_id)                                              AS frequency_pedidos,
        SUM(o.amount)                                                           AS monetary_total
    FROM orders o
    GROUP BY o.user_id
)

SELECT
    u.user_id,
    u.nombre,
    -- Nulos: usuarios sin pedidos quedan con recency alta (señal de inactividad)
    -- y 0 en las agregaciones, en lugar de NULL.
    COALESCE(r.recency_dias, 9999)                                   AS recency_dias,
    COALESCE(r.frequency_pedidos, 0)                                 AS frequency_pedidos,
    COALESCE(r.monetary_total, 0)                                    AS monetary_total,
    ROUND(
        COALESCE(um.gasto_ultimo_mes, 0) - COALESCE(um.gasto_mensual_prom_hist, 0)
    , 2)                                                             AS trend_delta_gasto
FROM users u
LEFT JOIN rfm         r  ON u.user_id = r.user_id
LEFT JOIN ultimo_mes  um ON u.user_id = um.user_id
ORDER BY recency_dias DESC, monetary_total DESC;

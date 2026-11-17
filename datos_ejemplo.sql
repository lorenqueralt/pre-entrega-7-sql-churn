-- datos_ejemplo.sql
-- Crea y puebla tablas de ejemplo para probar la consulta de features.
-- Dos tablas: users (maestro) y orders (transacciones).
-- Incluye a propósito un usuario sin pedidos (7) para probar el manejo de nulos.

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id   INTEGER PRIMARY KEY,
    nombre    VARCHAR,
    alta      DATE
);

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    user_id     INTEGER,
    order_date  DATE,
    amount      DECIMAL(10,2)
);

INSERT INTO users VALUES
    (1, 'Ana',    '2023-11-01'),
    (2, 'Bruno',  '2023-12-15'),
    (3, 'Carla',  '2024-01-05'),
    (4, 'Diego',  '2024-02-20'),
    (5, 'Elena',  '2023-10-10'),
    (6, 'Franco', '2023-09-01'),
    (7, 'Gaby',   '2024-05-01');   -- usuario SIN pedidos (inactivo)

INSERT INTO orders VALUES
    -- Ana: compradora frecuente y reciente
    (101, 1, '2024-04-10', 120.00),
    (102, 1, '2024-05-08',  90.00),
    (103, 1, '2024-06-02', 150.00),
    (104, 1, '2024-06-20', 110.00),
    -- Bruno: dejó de comprar en febrero (churn probable)
    (105, 2, '2024-01-12', 200.00),
    (106, 2, '2024-02-05', 180.00),
    -- Carla: compradora estable todos los meses
    (107, 3, '2024-03-03',  60.00),
    (108, 3, '2024-04-14',  75.00),
    (109, 3, '2024-05-19',  80.00),
    (110, 3, '2024-06-10',  70.00),
    -- Diego: un único pedido grande reciente
    (111, 4, '2024-06-25', 500.00),
    -- Elena: gastaba mucho al principio, cae al final (tendencia negativa)
    (112, 5, '2024-03-01', 300.00),
    (113, 5, '2024-03-22', 280.00),
    (114, 5, '2024-04-05', 150.00),
    (115, 5, '2024-06-15',  40.00),
    -- Franco: solo pedidos viejos (enero), alta recency
    (116, 6, '2024-01-08',  95.00),
    (117, 6, '2024-01-28', 100.00);

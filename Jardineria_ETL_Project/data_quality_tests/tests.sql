-- VERIFICAR VALORES NULOS
-- Dimension_Cliente
SELECT 'Dimension_Cliente' AS table_name, COUNT(*) AS null_count
FROM Dimension_Cliente
WHERE nombre IS NULL OR telefono IS NULL OR ciudad IS NULL OR pais IS NULL OR limite_credito IS NULL;

-- Dimension_Producto
SELECT 'Dimension_Producto' AS table_name, COUNT(*) AS null_count
FROM Dimension_Producto
WHERE codigo_producto IS NULL OR nombre IS NULL OR categoria IS NULL OR precio IS NULL;

-- Dimension_Vendedor
SELECT 'Dimension_Vendedor' AS table_name, COUNT(*) AS null_count
FROM Dimension_Vendedor
WHERE nombre_vendedor IS NULL OR apellido_vendedor IS NULL OR id_oficina IS NULL;

-- Dimension_Tiempo
SELECT 'Dimension_Tiempo' AS table_name, COUNT(*) AS null_count
FROM Dimension_Tiempo
WHERE dia IS NULL OR mes IS NULL OR año IS NULL OR semestre IS NULL OR numero_semana IS NULL OR bimestre IS NULL OR dia_semana IS NULL;

-- Hechos_Ventas
SELECT 'Hechos_Ventas' AS table_name, COUNT(*) AS null_count
FROM Hechos_Ventas
WHERE id_cliente IS NULL OR id_tiempo IS NULL OR id_producto IS NULL OR id_vendedor IS NULL OR cantidad IS NULL OR total IS NULL OR precio_unitario IS NULL;


-- CONSISTENCIA
-- Dimension_Producto (campos numericos)
SELECT 'Dimension_Producto' AS table_name, COUNT(*) AS inconsistent_count
FROM Dimension_Producto
WHERE NOT (precio ~ '^[0-9]+(\.[0-9]{1,2})?$');

-- Dimension_Tiempo (campos enteros)
SELECT 'Dimension_Tiempo' AS table_name, COUNT(*) AS inconsistent_count
FROM Dimension_Tiempo
WHERE NOT (dia ~ '^\d+$') OR NOT (mes ~ '^\d+$') OR NOT (año ~ '^\d+$') OR NOT (semestre ~ '^\d+$') OR NOT (numero_semana ~ '^\d+$') OR NOT (bimestre ~ '^\d+$');


-- COMPLETITUD
-- Dimension_Cliente
SELECT 'Dimension_Cliente' AS table_name, COUNT(*) AS total_count
FROM Dimension_Cliente;

-- Dimension_Producto
SELECT 'Dimension_Producto' AS table_name, COUNT(*) AS total_count
FROM Dimension_Producto;

-- Dimension_Vendedor
SELECT 'Dimension_Vendedor' AS table_name, COUNT(*) AS total_count
FROM Dimension_Vendedor;

-- Dimension_Tiempo
SELECT 'Dimension_Tiempo' AS table_name, COUNT(*) AS total_count
FROM Dimension_Tiempo;

-- Hechos_Ventas
SELECT 'Hechos_Ventas' AS table_name, COUNT(*) AS total_count
FROM Hechos_Ventas;
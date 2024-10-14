-- EXTRACT
-- CREACION DE BASE DE DATOS
-- DROP DATABASE IF EXISTS staging;
CREATE DATABASE staging
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Latin America.1252'
    LC_CTYPE = 'Spanish_Latin America.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- CREAR TABLAS DE DATOS CRUDOS EN STAGING
CREATE TABLE staging_cliente (
    id_cliente SERIAL PRIMARY KEY,
    nombre_cliente VARCHAR(255),
    telefono VARCHAR(20),
    ciudad VARCHAR(100),
    pais VARCHAR(100),
    limite_credito NUMERIC
);

CREATE TABLE staging_producto (
    id_producto SERIAL PRIMARY KEY,
    codigo_producto VARCHAR(50),
    nombre VARCHAR(255),
    categoria INT,
    precio NUMERIC
);

CREATE TABLE staging_categoria_producto (
    id_categoria SERIAL PRIMARY KEY,
    descripcion VARCHAR(100)
);

CREATE TABLE staging_pedido (
    id_pedido SERIAL PRIMARY KEY,
    fecha_pedido DATE,
    id_cliente INT,
    id_empleado_rep_ventas INT
);

CREATE TABLE staging_detalle_pedido (
    id_detalle SERIAL PRIMARY KEY,
    id_pedido INT,
    id_producto INT,
    cantidad INT,
    precio_unidad NUMERIC
);

CREATE TABLE staging_empleado (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(255),
    apellido1 VARCHAR(255),
    id_oficina INT
);

CREATE TABLE staging_pago (
    id_pago SERIAL PRIMARY KEY,
    fecha_pago DATE,
    id_pedido INT
);

-- EXTENSIÓN DBLINK
CREATE EXTENSION IF NOT EXISTS dblink;

-- EXTRAER DATOS CRUDOS DE JARDINERIA A STAGING
-- Cliente
INSERT INTO staging_cliente (nombre_cliente, telefono, ciudad, pais, limite_credito)
SELECT nombre_cliente, telefono, ciudad, pais, limite_credito
FROM dblink('dbname=jardineria user=postgres password=yourpassword', 'SELECT nombre_cliente, telefono, ciudad, pais, limite_credito FROM cliente')
AS source(nombre_cliente TEXT, telefono TEXT, ciudad TEXT, pais TEXT, limite_credito NUMERIC);

-- Producto
INSERT INTO staging_producto (codigo_producto, nombre, precio, categoria)
SELECT codigoproducto, nombre, precio_venta, categoria
FROM dblink('dbname=jardineria user=postgres password=yourpassword', 'SELECT codigoproducto, nombre, precio_venta, categoria FROM producto')
AS source(codigoproducto TEXT, nombre TEXT, precio NUMERIC, categoria INT);

-- Categoria_Producto
INSERT INTO staging_categoria_producto (id_categoria, descripcion)
SELECT id_categoria, descripcion_texto
FROM dblink('dbname=jardineria user=postgres password=yourpassword', 'SELECT id_categoria, descripcion_texto FROM categoria_producto')
AS source(id_categoria INT, descripcion_texto TEXT);

-- Pedido
INSERT INTO staging_pedido (fecha_pedido, id_cliente, id_empleado_rep_ventas)
SELECT fecha_pedido, id_cliente, id_empleado_rep_ventas
FROM dblink('dbname=jardineria user=postgres password=yourpassword', 'SELECT fecha_pedido, id_cliente, id_empleado_rep_ventas FROM pedido')
AS source(fecha_pedido DATE, id_cliente INT, id_empleado_rep_ventas INT);

-- Detalle_Pedido
INSERT INTO staging_detalle_pedido (id_pedido, id_producto, cantidad, precio_unidad)
SELECT id_pedido, id_producto, cantidad, precio_unidad
FROM dblink('dbname=jardineria user=postgres password=yourpassword', 'SELECT id_pedido, id_producto, cantidad, precio_unidad FROM detalle_pedido')
AS source(id_pedido INT, id_producto INT, cantidad INT, precio_unidad NUMERIC);

-- Empleado
INSERT INTO staging_empleado (nombre, apellido1, id_oficina)
SELECT nombre, apellido1, id_oficina
FROM dblink('dbname=jardineria user=postgres password=yourpassword', 'SELECT nombre, apellido1, id_oficina FROM empleado')
AS source(nombre TEXT, apellido1 TEXT, id_oficina INT);

-- Pago
INSERT INTO staging_pago (fecha_pago, id_pedido)
SELECT fecha_pago, id_pedido
FROM dblink('dbname=jardineria user=postgres password=yourpassword', 'SELECT fecha_pago, id_pedido FROM pago')
AS source(fecha_pago DATE, id_pedido INT);

-- TRANSFORM
-- Dimension Cliente
INSERT INTO Dimension_Cliente (nombre, telefono, ciudad, pais, limite_credito)
SELECT nombre_cliente, telefono, ciudad, pais, limite_credito
FROM staging_cliente;

-- Dimension Producto
INSERT INTO Dimension_Producto (codigo_producto, nombre, precio, categoria)
SELECT p.codigo_producto, p.nombre, p.precio, c.descripcion
FROM staging_producto p
JOIN staging_categoria_producto c ON p.categoria = c.id_categoria;

-- Dimension Vendedor
INSERT INTO Dimension_Vendedor (nombre_vendedor, apellido_vendedor, id_oficina)
SELECT nombre, apellido1, id_oficina
FROM staging_empleado;

-- Dimension Tiempo
INSERT INTO Dimension_Tiempo (dia, mes, año, semestre, numero_semana, bimestre, dia_semana)
SELECT 
    EXTRACT(DAY FROM fecha_pago) AS dia,
    EXTRACT(MONTH FROM fecha_pago) AS mes,
    EXTRACT(YEAR FROM fecha_pago) AS año,
    CASE WHEN EXTRACT(MONTH FROM fecha_pago) IN (1, 2, 3, 4, 5, 6) THEN 1 ELSE 2 END AS semestre,
    EXTRACT(WEEK FROM fecha_pago) AS numero_semana,
    CASE WHEN EXTRACT(MONTH FROM fecha_pago) IN (1, 2) THEN 1
         WHEN EXTRACT(MONTH FROM fecha_pago) IN (3, 4) THEN 2
         WHEN EXTRACT(MONTH FROM fecha_pago) IN (5, 6) THEN 3
         WHEN EXTRACT(MONTH FROM fecha_pago) IN (7, 8) THEN 4
         WHEN EXTRACT(MONTH FROM fecha_pago) IN (9, 10) THEN 5
         ELSE 6 END AS bimestre,
    TO_CHAR(fecha_pago, 'Day') AS dia_semana
FROM staging_pago;

-- Hechos Ventas
INSERT INTO Hechos_Ventas (id_cliente, id_tiempo, id_producto, id_vendedor, cantidad, total, precio_unitario)
SELECT 
    p.id_cliente, 
    t.id_tiempo, 
    d.id_producto, 
    e.id_empleado,
    d.cantidad,
    d.cantidad * d.precio_unidad AS total,
    d.precio_unidad
FROM staging_pedido p
JOIN staging_detalle_pedido d ON p.id_pedido = d.id_pedido
JOIN staging_pago pg ON p.id_pedido = pg.id_pedido
JOIN Dimension_Tiempo t ON t.dia = EXTRACT(DAY FROM pg.fecha_pago) AND t.mes = EXTRACT(MONTH FROM pg.fecha_pago) AND t.año = EXTRACT(YEAR FROM pg.fecha_pago)
JOIN staging_empleado e ON p.id_empleado_rep_ventas = e.id_empleado;

-- LOAD
-- Verificar datos en la tabla de Hechos
SELECT * FROM Hechos_Ventas;

-- Verificar datos en las dimensiones
SELECT * FROM Dimension_Cliente;
SELECT * FROM Dimension_Producto;
SELECT * FROM Dimension_Vendedor;
SELECT * FROM Dimension_Tiempo;
USE [CO2_Insight_Engine]

/*CONSULTA N° 1 - Vista de Eficiencia Ecológica y Costo por Kilómetro Recorrido*/

CREATE VIEW V_Rendimiento_Ecologico_Financiero AS
SELECT 
    v.ID_vehiculo,
    v.Placa,
    m.Nombre_modelo AS Modelo,
    tc.Nombre AS Tipo_Combustible,
    SUM(cc.KM_recorridos) AS Total_KM_Recorridos,
    SUM(cc.Litros_consumidos) AS Total_Litros_Consumidos,
    SUM(cc.Litros_consumidos * tc.Precio_unitario) AS Costo_Total_Combustible,
    SUM(e.Kg_Co2) AS Total_Kg_CO2,
    CAST(SUM(cc.Litros_consumidos * tc.Precio_unitario) / SUM(cc.KM_recorridos) AS DECIMAL(10,2)) AS Costo_Por_KM,
    CAST(SUM(e.Kg_Co2) / SUM(cc.KM_recorridos) AS DECIMAL(10,4)) AS Kg_CO2_Por_KM
FROM Vehiculo v
INNER JOIN Modelo m ON v.ID_modelo = m.ID_modelo
INNER JOIN Tipo_combustible tc ON v.ID_Tipo_combustible = tc.ID_Tipo_combustible
INNER JOIN Consumo_combustible cc ON v.ID_vehiculo = cc.ID_vehiculo
INNER JOIN Emision_Co2 e ON cc.ID_consumo = e.ID_consumo
GROUP BY v.ID_vehiculo, v.Placa, m.Nombre_modelo, tc.Nombre

-- Consulta para explotación de la vista
SELECT * FROM V_Rendimiento_Ecologico_Financiero
ORDER BY Kg_CO2_Por_KM DESC

/*CONSULTA N°2 - Conductores con Alertas Críticas Recurrentes*/

SELECT 
    c.ID_Conductor,
    CONCAT(c.Nombre, ' ', c.Apellidos) AS Conductor,
    ta.Nombre AS Tipo_Alerta,
    COUNT(a.ID_alerta) AS Total_Alertas,
    MAX(a.Fecha_alerta) AS Ultima_Alerta
FROM Conductor c
INNER JOIN Asignacion asig ON c.ID_Conductor = asig.ID_Conductor
INNER JOIN Alerta a ON asig.ID_vehiculo = a.ID_vehiculo
INNER JOIN Tipo_Alerta ta ON a.ID_Tipo_alerta = ta.ID_Tipo_alerta
WHERE c.ID_estado = 1 AND ta.Nombre IN ('Exceso Velocidad', 'Frenado Brusco', 'Desvio de Ruta')
GROUP BY c.ID_Conductor, c.Nombre, c.Apellidos, ta.Nombre
HAVING COUNT(a.ID_alerta) >= 1
ORDER BY Total_Alertas DESC

/*CONSULTA N°3 - Análisis de Desviación de Costos de Mantenimiento por Tipo de Flota*/

SELECT 
    ma.Nombre_marca AS Marca,
    mo.Nombre_modelo AS Modelo,
    tm.Nombre AS Tipo_Mantenimiento,
    COUNT(m.ID_mantenimiento) AS Cantidad_Mantenimientos,
    SUM(m.Costo) AS Gasto_Total,
    AVG(m.Costo) AS Costo_Promedio
FROM Mantenimiento m
INNER JOIN Tipo_mantenimiento tm ON m.ID_Tipo_mantenimiento = tm.ID_Tipo_mantenimiento
INNER JOIN Vehiculo v ON m.ID_vehiculo = v.ID_vehiculo
INNER JOIN Modelo mo ON v.ID_modelo = mo.ID_modelo
INNER JOIN Marca ma ON mo.ID_marca = ma.ID_marca
GROUP BY ma.Nombre_marca, mo.Nombre_modelo, tm.Nombre
HAVING AVG(m.Costo) > (SELECT AVG(Costo) FROM Mantenimiento)
ORDER BY Gasto_Total DESC

/*CONSULTA N°4 - Subconsulta Correlacionada para Identificar Consumos Anómalos*/

SELECT 
    cc1.ID_consumo,
    cc1.ID_vehiculo,
    v.Placa,
    cc1.Fecha_registro,
    cc1.Litros_consumidos,
    (SELECT AVG(cc2.Litros_consumidos) 
     FROM Consumo_combustible cc2 
     WHERE cc2.ID_vehiculo = cc1.ID_vehiculo) AS Promedio_Historico_Vehiculo,
    (cc1.Litros_consumidos - (SELECT AVG(cc2.Litros_consumidos) 
                              FROM Consumo_combustible cc2 
                              WHERE cc2.ID_vehiculo = cc1.ID_vehiculo)) AS Desviacion_Litros
FROM Consumo_combustible cc1
INNER JOIN Vehiculo v ON cc1.ID_vehiculo = v.ID_vehiculo
WHERE cc1.Litros_consumidos > (
    SELECT AVG(cc2.Litros_consumidos)
    FROM Consumo_combustible cc2
    WHERE cc2.ID_vehiculo = cc1.ID_vehiculo
)
ORDER BY Desviacion_Litros DESC

/*CONSULTA N°5 - Vehículos Estratégicos sin Alertas Críticas (Subconsulta No Correlacionada con NOT IN)*/

SELECT 
    v.ID_vehiculo,
    v.Placa,
    m.Nombre_modelo,
    v.Capacidad_de_carga
FROM Vehiculo v
INNER JOIN Modelo m ON v.ID_modelo = m.ID_modelo
WHERE v.Capacidad_de_carga >= 5000
  AND v.ID_vehiculo NOT IN (
      SELECT DISTINCT a.ID_vehiculo
      FROM Alerta a
      INNER JOIN Tipo_Alerta ta ON a.ID_Tipo_alerta = ta.ID_Tipo_alerta
      WHERE ta.Nombre IN ('Mant. Vencido', 'Fallo de Sensor')
  )
ORDER BY v.Capacidad_de_carga DESC

/*CONSULTA N°6 - Administradores con Gestión Excepcional de Auditoría (Uso de EXISTS)*/

SELECT 
    adm.ID_administrador,
    CONCAT(adm.Nombre_admin, ' ', adm.Apellidos) AS Administrador,
    adm.Num_documento
FROM Administrador adm
WHERE EXISTS (
    SELECT 1 
    FROM Modificacion_vehiculo mv
    WHERE mv.ID_administrador = adm.ID_administrador
      AND (mv.Campo_modificado LIKE '%Motor%' OR mv.Campo_modificado LIKE '%Frenos%')
)
ORDER BY Administrador ASC

/*CONSULTA N°7 - UDF Escalar para Calcular Factor de Emisión Dinámico Real*/

CREATE FUNCTION dbo.UFN_Calcular_Co2_Por_KM (@ID_consumo INT)
RETURNS DECIMAL(10,4)
AS
BEGIN
    DECLARE @Resultado DECIMAL(10,4)
    DECLARE @Kg_Co2 DECIMAL(10,2)
    DECLARE @KM_recorridos DECIMAL(10,2)

    SELECT @Kg_Co2 = Kg_Co2 FROM Emision_Co2 WHERE ID_consumo = @ID_consumo
    SELECT @KM_recorridos = KM_recorridos FROM Consumo_combustible WHERE ID_consumo = @ID_consumo

    SET @Resultado = CAST(@Kg_Co2 / @KM_recorridos AS DECIMAL(10,4))

    RETURN @Resultado;
END

-- Aplicación de la UDF en un reporte analítico de emisiones
SELECT 
    cc.ID_consumo,
    v.Placa,
    cc.KM_recorridos,
    e.Kg_Co2,
    dbo.UFN_Calcular_Co2_Por_KM(cc.ID_consumo) AS Kg_CO2_por_Kilometro
FROM Consumo_combustible cc
INNER JOIN Emision_Co2 e ON cc.ID_consumo = e.ID_consumo
INNER JOIN Vehiculo v ON cc.ID_vehiculo = v.ID_vehiculo

/*CONSULTA N°8 - UDF de Tabla en Línea para Historial Operativo de Rutas por Vehículo*/

CREATE FUNCTION dbo.UFN_Historial_Rutas_Vehiculo (@Placa VARCHAR(7))
RETURNS TABLE
AS
RETURN (
    SELECT 
        v.Placa,
        m.Nombre_modelo AS Modelo,
        r.Origen,
        r.Destino,
        r.Distancia_KM,
        r.Fecha_registro AS Fecha_Viaje
    FROM Vehiculo v
    INNER JOIN Modelo m ON v.ID_modelo = m.ID_modelo
    INNER JOIN Ruta r ON v.ID_vehiculo = r.ID_vehiculo
    WHERE v.Placa = @Placa
)

-- Invocación de la función inline
SELECT * FROM dbo.UFN_Historial_Rutas_Vehiculo('ABC123')

/*CONSULTA N°9 - UDF de Tabla Multi-sentencia para Alertas y Contactos de Emergencia*/

CREATE FUNCTION dbo.UFN_Reporte_Contingencia_Alertas()
RETURNS @TablaContingencia TABLE (
    ID_alerta INT,
    Placa VARCHAR(7),
    Alerta NVARCHAR(80),
    Administrador NVARCHAR(150),
    Telf_Admin CHAR(9),
    Conductor NVARCHAR(150),
    Telf_Conductor CHAR(9)
)
AS
BEGIN
    INSERT INTO @TablaContingencia
    SELECT 
        a.ID_alerta,
        v.Placa,
        a.Mensaje,
        CONCAT(adm.Nombre_admin, ' ', adm.Apellidos),
        ISNULL(ta.Numero_administrador, 'SIN TELF'),
        CONCAT(c.Nombre, ' ', c.Apellidos),
        ISNULL(tc.Numero_conductor, 'SIN TELF')
    FROM Alerta a
    INNER JOIN Vehiculo v ON a.ID_vehiculo = v.ID_vehiculo
    INNER JOIN Administrador adm ON a.ID_administrador = adm.ID_administrador
    LEFT JOIN Telefono_administrador ta ON adm.ID_administrador = ta.ID_administrador
    LEFT JOIN Asignacion asig ON v.ID_vehiculo = asig.ID_vehiculo AND asig.ID_estado = 1
    LEFT JOIN Conductor c ON asig.ID_Conductor = c.ID_Conductor
    LEFT JOIN Telefono_conductor tc ON c.ID_Conductor = tc.ID_Conductor
    WHERE a.ID_estado = 1

    RETURN
END

-- Consumo del objeto programable complejo
SELECT * FROM dbo.UFN_Reporte_Contingencia_Alertas()

/*CONSULTA N°10 - Vehículos que superan el Costo Promedio de Mantenimiento de su propia Marca (Subconsulta Correlacionada)*/

SELECT 
    v.ID_vehiculo,
    v.Placa,
    ma.Nombre_marca AS Marca,
    mo.Nombre_modelo AS Modelo,
    SUM(m.Costo) AS Gasto_Total_Vehiculo
FROM Vehiculo v
INNER JOIN Modelo mo ON v.ID_modelo = mo.ID_modelo
INNER JOIN Marca ma ON mo.ID_marca = ma.ID_marca
INNER JOIN Mantenimiento m ON v.ID_vehiculo = m.ID_vehiculo
GROUP BY v.ID_vehiculo, v.Placa, ma.Nombre_marca, mo.Nombre_modelo, mo.ID_marca
HAVING SUM(m.Costo) > (
    SELECT AVG(Gasto_Por_Unidad)
    FROM (
        SELECT v2.ID_vehiculo, SUM(m2.Costo) AS Gasto_Por_Unidad
        FROM Vehiculo v2
        INNER JOIN Mantenimiento m2 ON v2.ID_vehiculo = m2.ID_vehiculo
        INNER JOIN Modelo mo2 ON v2.ID_modelo = mo2.ID_modelo
        WHERE mo2.ID_marca = mo.ID_marca
        GROUP BY v2.ID_vehiculo
    ) AS Sub_Gastos_Marca
)
ORDER BY Gasto_Total_Vehiculo DESC

/*CONSULTA N°11 - Conductores que nunca han registrado Alertas de Conducción Ineficiente (Subconsulta con NOT EXISTS)*/

SELECT 
    c.ID_Conductor,
    CONCAT(c.Nombre, ' ', c.Apellidos) AS Conductor,
    c.Num_documento AS DNI
FROM Conductor c
WHERE c.ID_estado = 1
  AND NOT EXISTS (
      SELECT 1 
      FROM Asignacion asig
      INNER JOIN Alerta a ON asig.ID_vehiculo = a.ID_vehiculo
      INNER JOIN Tipo_Alerta ta ON a.ID_Tipo_alerta = ta.ID_Tipo_alerta
      WHERE asig.ID_Conductor = c.ID_Conductor
        AND ta.Nombre IN ('Exceso Velocidad', 'Frenado Brusco', 'Desvio de Ruta')
  )
ORDER BY Conductor ASC

/*CONSULTA N°12 - Rutas Críticas que representan más del 15% de la Huella de Carbono Total de la Empresa (Subconsulta en Expresión de Proporción)*/

SELECT 
    r.ID_ruta,
    r.Origen,
    r.Destino,
    SUM(e.Kg_Co2) AS CO2_Ruta_KG,
    CAST((SUM(e.Kg_Co2) / (SELECT SUM(Kg_Co2) FROM Emision_Co2)) * 100 AS DECIMAL(5,2)) AS Porcentaje_Del_Total_Empresa
FROM Ruta r
INNER JOIN Vehiculo v ON r.ID_vehiculo = v.ID_vehiculo
INNER JOIN Consumo_combustible cc ON v.ID_vehiculo = cc.ID_vehiculo
INNER JOIN Emision_Co2 e ON cc.ID_consumo = e.ID_consumo
GROUP BY r.ID_ruta, r.Origen, r.Destino
HAVING SUM(e.Kg_Co2) > (SELECT SUM(Kg_Co2) FROM Emision_Co2) * 0.15
ORDER BY CO2_Ruta_KG DESC

/*CONSULTA N°13 - Última Modificación de Auditoría por Administrador con Detalle Completo (Subconsulta de Tabla Derivada con Filas Máximas)*/

SELECT 
    CONCAT(adm.Nombre_admin, ' ', adm.Apellidos) AS Administrador,
    mv.Fecha_modificacion AS Fecha_Ultimo_Cambio,
    mv.Campo_modificado,
    mv.Valor_anterior,
    mv.Valor_nuevo,
    v.Placa AS Vehiculo_Modificado
FROM Modificacion_vehiculo mv
INNER JOIN Administrador adm ON mv.ID_administrador = adm.ID_administrador
INNER JOIN Vehiculo v ON mv.ID_vehiculo = v.ID_vehiculo
WHERE mv.Fecha_modificacion = (
    SELECT MAX(mv2.Fecha_modificacion)
    FROM Modificacion_vehiculo mv2
    WHERE mv2.ID_administrador = mv.ID_administrador
)
ORDER BY Fecha_Ultimo_Cambio DESC

/*CONSULTA N°14 - Estadísticas de Emisiones Acumuladas por Tipo de Vehículo y Carga (Reporte Avanzado de Auditoría Ambiental)*/

SELECT 
    Flota_Agrupada.Capacidad_de_carga,
    COUNT(DISTINCT Flota_Agrupada.ID_vehiculo) AS Unidades_Activas,
    SUM(Flota_Agrupada.Total_Litros) AS Litros_Totales,
    SUM(Flota_Agrupada.Total_Kg_CO2) AS CO2_Total_Generado,
    AVG(Flota_Agrupada.Total_Kg_CO2) AS CO2_Promedio_Por_Categoria
FROM (
    SELECT 
        v.ID_vehiculo,
        v.Capacidad_de_carga,
        SUM(cc.Litros_consumidos) AS Total_Litros,
        SUM(e.Kg_Co2) AS Total_Kg_CO2
    FROM Vehiculo v
    INNER JOIN Consumo_combustible cc ON v.ID_vehiculo = cc.ID_vehiculo
    INNER JOIN Emision_Co2 e ON cc.ID_consumo = e.ID_consumo
    GROUP BY v.ID_vehiculo, v.Capacidad_de_carga
) AS Flota_Agrupada
GROUP BY Flota_Agrupada.Capacidad_de_carga
ORDER BY Capacidad_de_carga ASC

/*CONSULTA N°15 - Stored Procedure de Consulta Avanzada para Simulación de Presupuesto por Incremento de Combustible*/

CREATE PROCEDURE dbo.USP_Simulador_Impacto_Precios
    @PorcentajeIncremento DECIMAL(5,2)
AS
BEGIN
    DECLARE @Multiplicador DECIMAL(5,2) = 1 + (@PorcentajeIncremento / 100)

    SELECT 
        tc.Nombre AS Combustible,
        tc.Precio_unitario AS Precio_Actual,
        CAST(tc.Precio_unitario * @Multiplicador AS MONEY) AS Precio_Proyectado,
        SUM(cc.Litros_consumidos) AS Litros_Consumidos_Historicos,
        SUM(cc.Litros_consumidos * tc.Precio_unitario) AS Gasto_Historico,
        CAST(SUM(cc.Litros_consumidos * tc.Precio_unitario) * @Multiplicador AS MONEY) AS Gasto_Proyectado,
        CAST((SUM(cc.Litros_consumidos * tc.Precio_unitario) * @Multiplicador) - SUM(cc.Litros_consumidos * tc.Precio_unitario) AS MONEY) AS Impacto_Financiero_Neto
    FROM Consumo_combustible cc
    INNER JOIN Vehiculo v ON cc.ID_vehiculo = v.ID_vehiculo
    INNER JOIN Tipo_combustible tc ON v.ID_Tipo_combustible = tc.ID_Tipo_combustible
    GROUP BY tc.Nombre, tc.Precio_unitario
END

-- Simulación de un incremento drástico del 12.5% en los combustibles del mercado peruano
EXEC dbo.USP_Simulador_Impacto_Precios @PorcentajeIncremento = 12.50

/*CONSULTA N°16 - Vehículos activos sin mantenimiento reciente*/

SELECT 
    V.Placa,
    Mo.Nombre_modelo
FROM Vehiculo V
INNER JOIN Modelo Mo ON V.ID_modelo = Mo.ID_modelo
WHERE EXISTS (
        SELECT 1 
        FROM Asignacion A 
        WHERE A.ID_vehiculo = V.ID_vehiculo 
          AND A.ID_estado = 1
      )
  AND NOT EXISTS (
        SELECT 1
        FROM Mantenimiento M
        WHERE M.ID_vehiculo = V.ID_vehiculo
          AND M.Fecha_mantenimiento >= DATEADD(DAY, -60, GETDATE())
      )
ORDER BY V.Placa

/*CONSULTA N°17 - Trigger: cálculo automático de emisiones de CO2*/

CREATE TRIGGER trg_CalcularEmisionCO2
ON Consumo_combustible
AFTER INSERT
AS
BEGIN
 
    INSERT INTO Emision_Co2 (Fecha_registro, Kg_Co2, Factor_aplicado, ID_consumo)
    SELECT 
        I.Fecha_registro,
        I.Litros_consumidos * TC.Factor_emision_Co2_L,
        TC.Factor_emision_Co2_L,
        I.ID_consumo
    FROM inserted I
    INNER JOIN Vehiculo V ON I.ID_vehiculo = V.ID_vehiculo
    INNER JOIN Tipo_combustible TC ON V.ID_Tipo_combustible = TC.ID_Tipo_combustible;
END

--Ejemplo de uso
INSERT INTO Consumo_combustible (Fecha_registro, Litros_consumidos, KM_recorridos, ID_vehiculo)
VALUES ('2026-07-07 10:00:00', 50.00, 450.00, 3)

/*CONSULTA N°18 - Función de tabla: historial de mantenimiento por rango de fechas*/

CREATE FUNCTION fn_HistorialMantenimiento
(
    @ID_vehiculo INT,
    @FechaInicio DATETIME,
    @FechaFin DATETIME
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        M.ID_mantenimiento,
        M.Fecha_mantenimiento,
        M.Descripcion,
        M.Costo,
        TM.Nombre AS Tipo_mantenimiento,
        A.Nombre_admin + ' ' + A.Apellidos AS Responsable
    FROM Mantenimiento M
    INNER JOIN Tipo_mantenimiento TM ON M.ID_Tipo_mantenimiento = TM.ID_Tipo_mantenimiento
    INNER JOIN Administrador A ON M.ID_administrador = A.ID_administrador
    WHERE M.ID_vehiculo = @ID_vehiculo
      AND M.Fecha_mantenimiento BETWEEN @FechaInicio AND @FechaFin
)

--Ejemplo de uso
SELECT * FROM dbo.fn_HistorialMantenimiento(1, '2026-01-01', '2026-03-31')


/* ============================================================
   Proyecto: Carbontix
   ============================================================ */

-- Creación de la base de datos
CREATE DATABASE CO2_Insight_Engine;
GO

USE CO2_Insight_Engine;
GO

-- =========================================================
-- TABLAS DE CATÁLOGO / MAESTRAS
-- =========================================================

CREATE TABLE Estado (
    ID_estado       INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_estado   NVARCHAR(30) NOT NULL UNIQUE
);
GO

CREATE TABLE Tipo_documento (
    Cod_Tip_Doc     INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion     NVARCHAR(40) NOT NULL UNIQUE
);
GO

CREATE TABLE Tipo_combustible (
    ID_Tipo_combustible    INT IDENTITY(1,1) PRIMARY KEY,
    Nombre                 NVARCHAR(40) NOT NULL UNIQUE,
    Factor_emision_Co2_L   DECIMAL(10,2) NOT NULL CHECK (Factor_emision_Co2_L >= 0),
    Precio_unitario        MONEY NOT NULL CHECK (Precio_unitario >= 0)
);
GO

CREATE TABLE Marca (
    ID_marca        INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_marca    NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE Tipo_mantenimiento (
    ID_Tipo_mantenimiento  INT IDENTITY(1,1) PRIMARY KEY,
    Nombre                 NVARCHAR(40) NOT NULL,
    Descripcion            NVARCHAR(50)
);
GO

CREATE TABLE Tipo_Alerta (
    ID_Tipo_alerta  INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(40) NOT NULL,
    Descripcion     NVARCHAR(55)
);
GO

CREATE TABLE Modelo (
    ID_modelo       INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_modelo   NVARCHAR(50) NOT NULL,
    ID_marca        INT NOT NULL,
    CONSTRAINT FK_Modelo_Marca FOREIGN KEY (ID_marca) REFERENCES Marca(ID_marca)
);
GO

-- =========================================================
-- PERSONAS
-- =========================================================

CREATE TABLE Administrador (
    ID_administrador    INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_admin        NVARCHAR(70) NOT NULL,
    Apellidos           NVARCHAR(70) NOT NULL,
    Cod_Tip_Doc         INT NOT NULL,
    Num_documento       CHAR(15) NOT NULL UNIQUE,
    Fecha_registro      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Administrador_TipoDoc FOREIGN KEY (Cod_Tip_Doc) REFERENCES Tipo_documento(Cod_Tip_Doc)
);
GO

CREATE TABLE Conductor (
    ID_Conductor        INT IDENTITY(1,1) PRIMARY KEY,
    Nombre              NVARCHAR(70) NOT NULL,
    Apellidos           NVARCHAR(70) NOT NULL,
    Cod_Tip_Doc         INT NOT NULL,
    Num_documento       CHAR(15) NOT NULL UNIQUE,
    Fecha_registro      DATETIME NOT NULL DEFAULT GETDATE(),
    ID_estado           INT NOT NULL,
    CONSTRAINT FK_Conductor_TipoDoc FOREIGN KEY (Cod_Tip_Doc) REFERENCES Tipo_documento(Cod_Tip_Doc),
    CONSTRAINT FK_Conductor_Estado FOREIGN KEY (ID_estado) REFERENCES Estado(ID_estado)
);
GO

-- =========================================================
-- FLOTA
-- =========================================================

CREATE TABLE Vehiculo (
    ID_vehiculo              INT IDENTITY(1,1) PRIMARY KEY,
    Placa                    VARCHAR(7) NOT NULL UNIQUE,
    ID_modelo                INT NOT NULL,
    ID_Tipo_combustible      INT NOT NULL,
    Capacidad_de_carga       INT NOT NULL CHECK (Capacidad_de_carga >= 0),
    CONSTRAINT FK_Vehiculo_Modelo FOREIGN KEY (ID_modelo) REFERENCES Modelo(ID_modelo),
    CONSTRAINT FK_Vehiculo_TipoCombustible FOREIGN KEY (ID_Tipo_combustible) REFERENCES Tipo_combustible(ID_Tipo_combustible)
);
GO

CREATE TABLE Ruta (
    ID_ruta          INT IDENTITY(1,1) PRIMARY KEY,
    Origen           NVARCHAR(60) NOT NULL,
    Destino          NVARCHAR(60) NOT NULL,
    Distancia_KM     FLOAT NOT NULL CHECK (Distancia_KM > 0),
    Fecha_registro   DATETIME NOT NULL DEFAULT GETDATE(),
    ID_vehiculo      INT NOT NULL,
    CONSTRAINT FK_Ruta_Vehiculo FOREIGN KEY (ID_vehiculo) REFERENCES Vehiculo(ID_vehiculo),
);
GO

CREATE TABLE Asignacion (
    ID_asignacion    INT IDENTITY(1,1) PRIMARY KEY,
    ID_vehiculo      INT NOT NULL,
    ID_Conductor     INT NOT NULL,
    Fecha_inicio     DATETIME NOT NULL,
    Fecha_fin        DATETIME NOT NULL,
    ID_estado        INT NOT NULL,
    CONSTRAINT FK_Asignacion_Vehiculo FOREIGN KEY (ID_vehiculo) REFERENCES Vehiculo(ID_vehiculo),
    CONSTRAINT FK_Asignacion_Conductor FOREIGN KEY (ID_Conductor) REFERENCES Conductor(ID_Conductor),
    CONSTRAINT FK_Asignacion_Estado FOREIGN KEY (ID_estado) REFERENCES Estado(ID_estado),
	CONSTRAINT CK_FechaInicio_FechaFin  CHECK(Fecha_inicio < Fecha_fin),
);
GO

-- =========================================================
-- CONSUMO Y EMISIONES
-- =========================================================

CREATE TABLE Consumo_combustible (
    ID_consumo          INT IDENTITY(1,1) PRIMARY KEY,
    Fecha_registro      DATETIME NOT NULL DEFAULT GETDATE(),
    Litros_consumidos   DECIMAL(10,2) NOT NULL CHECK (Litros_consumidos > 0),
    KM_recorridos       DECIMAL(10,2) NOT NULL CHECK(KM_recorridos > 0),
    ID_vehiculo         INT NOT NULL,
    CONSTRAINT FK_Consumo_Vehiculo FOREIGN KEY (ID_vehiculo) REFERENCES Vehiculo(ID_vehiculo),
);
GO

CREATE TABLE Emision_Co2 (
    ID_emision        INT IDENTITY(1,1) PRIMARY KEY,
    Fecha_registro    DATETIME NOT NULL DEFAULT GETDATE(),
    Kg_Co2            DECIMAL(10,2) NOT NULL CHECK (Kg_Co2 >= 0),
    Factor_aplicado   DECIMAL(10,2) NOT NULL CHECK (Factor_aplicado >= 0),
    ID_consumo        INT NOT NULL UNIQUE,
    CONSTRAINT FK_Emision_Consumo FOREIGN KEY (ID_consumo) REFERENCES Consumo_combustible(ID_consumo)
);
GO

-- =========================================================
-- MANTENIMIENTO Y ALERTAS
-- =========================================================

CREATE TABLE Mantenimiento (
    ID_mantenimiento      INT IDENTITY(1,1) PRIMARY KEY,
    Fecha_mantenimiento   DATETIME NOT NULL DEFAULT GETDATE(),
    Descripcion           NVARCHAR(100) NOT NULL,
    Costo                 MONEY NOT NULL CHECK (Costo >= 0),
    ID_administrador      INT NOT NULL,
    ID_vehiculo           INT NOT NULL,
    ID_Tipo_mantenimiento INT NOT NULL,
    CONSTRAINT FK_Mantenimiento_Admin FOREIGN KEY (ID_administrador) REFERENCES Administrador(ID_administrador),
    CONSTRAINT FK_Mantenimiento_Vehiculo FOREIGN KEY (ID_vehiculo) REFERENCES Vehiculo(ID_vehiculo),
    CONSTRAINT FK_Mantenimiento_Tipo FOREIGN KEY (ID_Tipo_mantenimiento) REFERENCES Tipo_mantenimiento(ID_Tipo_mantenimiento)
);
GO

CREATE TABLE Alerta (
    ID_alerta        INT IDENTITY(1,1) PRIMARY KEY,
    Mensaje          NVARCHAR(80) NOT NULL,
    Fecha_alerta     DATETIME NOT NULL DEFAULT GETDATE(),
    ID_Tipo_alerta   INT NOT NULL,
    ID_administrador INT NOT NULL,
    ID_vehiculo      INT NOT NULL,
    ID_estado        INT NOT NULL,
    CONSTRAINT FK_Alerta_Tipo FOREIGN KEY (ID_Tipo_alerta) REFERENCES Tipo_Alerta(ID_Tipo_alerta),
    CONSTRAINT FK_Alerta_Admin FOREIGN KEY (ID_administrador) REFERENCES Administrador(ID_administrador),
    CONSTRAINT FK_Alerta_Vehiculo FOREIGN KEY (ID_vehiculo) REFERENCES Vehiculo(ID_vehiculo),
    CONSTRAINT FK_Alerta_Estado FOREIGN KEY (ID_estado) REFERENCES Estado(ID_estado)
);
GO

-- =========================================================
-- CONTACTOS
-- =========================================================

CREATE TABLE Telefono_conductor (
    ID_telefono_conductor  INT IDENTITY(1,1) PRIMARY KEY,
    Numero_conductor       CHAR(9) NOT NULL,
    ID_Conductor           INT NOT NULL,
    CONSTRAINT FK_TelefonoConductor_Conductor FOREIGN KEY (ID_Conductor) REFERENCES Conductor(ID_Conductor)
);
GO

CREATE TABLE Telefono_administrador (
    ID_telefono_administrador  INT IDENTITY(1,1) PRIMARY KEY,
    Numero_administrador       CHAR(9) NOT NULL,
    ID_administrador           INT NOT NULL,
    CONSTRAINT FK_TelefonoAdmin_Admin FOREIGN KEY (ID_administrador) REFERENCES Administrador(ID_administrador)
);
GO

-- =========================================================
-- AUDITORÍA
-- =========================================================

CREATE TABLE Modificacion_vehiculo (
    ID_modificacion     INT IDENTITY(1,1) PRIMARY KEY,
    Fecha_modificacion  DATETIME NOT NULL DEFAULT GETDATE(),
    Campo_modificado    NVARCHAR(80) NOT NULL,
    Valor_anterior      NVARCHAR(80) NOT NULL,
    Valor_nuevo         NVARCHAR(80) NOT NULL,
    ID_vehiculo         INT NOT NULL,
    ID_administrador    INT NOT NULL,
    CONSTRAINT FK_ModVehiculo_Vehiculo FOREIGN KEY (ID_vehiculo) REFERENCES Vehiculo(ID_vehiculo),
    CONSTRAINT FK_ModVehiculo_Admin FOREIGN KEY (ID_administrador) REFERENCES Administrador(ID_administrador)
);
GO

-- =====================================================================
-- Inserción de datos - Carbontix
-- =====================================================================
-- =====================================================================
-- 1. Estado
-- =====================================================================
INSERT INTO Estado (Nombre_estado) VALUES
('Activo'),
('Inactivo'),
('En mantenimiento');
GO

-- =====================================================================
-- 2. Tipo_documento
-- =====================================================================
INSERT INTO Tipo_documento (Descripcion) VALUES
('DNI'),
('Carnet de Extranjeria'),
('Pasaporte'),
('RUC');
GO

-- =====================================================================
-- 3. Tipo_combustible
-- =====================================================================
INSERT INTO Tipo_combustible (Nombre, Factor_emision_Co2_L, Precio_unitario) VALUES
('Gasolina 90',   2.31, 16.50),
('Diesel B5',     2.68, 14.20),
('GLP',           1.51, 9.80),
('GNV',           1.96, 8.50),
('Gasolina 84',   2.10, 15.20),
('Gasolina 95',   2.35, 17.80),
('Gasolina 97',   2.40, 18.90),
('Electrico',     0.00, 1.80),
('Hibrido',       1.20, 15.00);
GO

-- =====================================================================
-- 4. Marca 
-- =====================================================================
INSERT INTO Marca (Nombre_marca) VALUES
('Toyota'), 
('Hyundai'),      
('Volvo'),         
('Scania'),     
('Mercedes-Benz'),
('Isuzu'),      
('Ford'),  
('Nissan'),  
('Kia');
GO

-- =====================================================================
-- 5. Tipo_mantenimiento
-- =====================================================================
INSERT INTO Tipo_mantenimiento (Nombre, Descripcion) VALUES
('Preventivo',          'Cambio de aceite y filtros'),
('Correctivo',          'Reparacion de averias'),
('Predictivo',          'Analisis de sensores'),
('Revision Tecnica',    'Inspeccion anual obligatoria'),
('Cambio Neumaticos',   'Reemplazo de llantas desgastadas'),
('Alineamiento',        'Alineacion y balanceo de ruedas'),
('Cambio de Frenos',    'Reemplazo de pastillas y discos'),
('Revision Electrica',  'Diagnostico del sistema electrico'),
('Cambio de Bateria',   'Reemplazo de bateria vehicular'),
('Lavado y Engrase',    'Limpieza y lubricacion general'),
('Calibracion Sensor',  'Ajuste de sensores de emision'),
('Mant. Emisiones',     'Revision del sistema de escape');
GO

-- =====================================================================
-- 6. Tipo_Alerta
-- =====================================================================
INSERT INTO Tipo_Alerta (Nombre, Descripcion) VALUES
('Exceso Velocidad', 'Vehiculo supero el limite permitido'),
('Mant. Vencido',    'Mantenimiento programado vencido'),
('Doc. Vencido',     'Documentos del conductor vencidos'),
('Consumo Anomalo',  'Consumo de fuera de rango'),
('Desvio de Ruta',   'Vehiculo fuera de ruta asignada'),
('Frenado Brusco',   'Frenada peligrosa detectada'),
('Exceso de Carga',  'Carga supera capacidad permitida'),
('Fuera de Horario', 'Operacion fuera de horario'),
('Bateria Baja',     'Nivel bajo de bateria del GPS'),
('Fallo de Sensor',  'Sensor reporta error'),
('Zona Restringida', 'Ingreso a zona no autorizada'),
('Parada Prolongada','Detencion mayor al limite permitido');
GO

-- =====================================================================
-- 7. Modelo
-- =====================================================================
INSERT INTO Modelo (Nombre_modelo, ID_marca) VALUES
('Hilux',    1),
('Tucson',   2),
('FH16',     3),
('R450',     4),
('Actros',   5),
('NPR',      6),
('Corolla',  1),
('H1',       2),
('Explorer', 7),
('Ranger',   7), 
('Frontier', 8), 
('Sportage', 9);
GO

-- =====================================================================
-- 8. Administrador
-- =====================================================================
INSERT INTO Administrador (Nombre_admin, Apellidos, Cod_Tip_Doc, Num_documento, Fecha_registro) VALUES
('Carlos',    'Ramirez Soto',    1, '74582136',   '2025-01-10'),
('Maria',     'Fernandez Lopez', 1, '71234567',   '2025-02-15'),
('Jorge',     'Quispe Mamani',   1, '45678912',   '2025-03-20'), 
('Ana',       'Torres Diaz',     2, 'CE12345678', '2025-04-05'),
('Luis',      'Vargas Chura',    1, '80123456',   '2025-05-12'),
('Patricia',  'Mendoza Rios',    1, '76543210',   '2025-06-01'),
('Diego',     'Castillo Vega',   1, '77654321',   '2025-06-15'),
('Sofia',     'Aguilar Paz',     1, '78765432',   '2025-07-01'),
('Raul',      'Espinoza Cruz',   3, 'PA1234567',  '2025-07-20'),
('Carmen',    'Rojas Leon',      1, '79876543',   '2025-08-05'),
('Victor',    'Huaman Salas',    1, '80987654',   '2025-08-25'),
('Elena',     'Paredes Nina',    1, '81098765',   '2025-09-10');
GO

-- =====================================================================
-- 9. Conductor
-- =====================================================================
INSERT INTO Conductor (Nombre, Apellidos, Cod_Tip_Doc, Num_documento, Fecha_registro, ID_estado) VALUES
('Pedro',    'Gomez Rios',     1, '41234567',   '2025-01-15', 1),
('Juan',     'Perez Castro',   1, '42345678',   '2025-01-20', 1),
('Miguel',   'Rojas Vega',     1, '43456789',   '2025-02-01', 2),
('Roberto',  'Silva Cruz',     1, '44567890',   '2025-02-10', 1),
('Fernando', 'Diaz Leon',      1, '45678901',   '2025-02-18', 1), 
('Manuel',   'Flores Paz',     2, 'CE87654321', '2025-03-01', 2),
('Jose',     'Herrera Nunez',  1, '46789012',   '2025-03-10', 1),
('Ricardo',  'Chavez Mora',    1, '47890123',   '2025-03-22', 2),
('Andres',   'Salazar Rios',   1, '48901234',   '2025-04-02', 1),
('Cesar',    'Medina Torres',  1, '49012345',   '2025-04-15', 1),
('Oscar',    'Vidal Campos',   1, '50123456',   '2025-04-28', 2),
('Luisa',    'Camacho Flores', 1, '51234567',   '2025-05-10', 1); 
GO

-- =====================================================================
-- 10. Vehiculo
-- =====================================================================
INSERT INTO Vehiculo (Placa, ID_modelo, ID_Tipo_combustible, Capacidad_de_carga) VALUES
('ABC123', 1,  1, 1000),
('DEF456', 2,  2, 1500),
('GHI789', 3,  2, 8000),
('JKL012', 4,  2, 12000),
('MNO345', 5,  2, 10000),
('PQR678', 6,  1, 3000),
('STU901', 7,  1, 500), 
('VWX234', 8,  3, 700),
('YZA567', 1,  4, 900),
('BCD890', 2,  1, 1600), 
('CDE123', 9,  5, 1100), 
('FGH456', 10, 8, 1300);
GO

-- =====================================================================
-- 11. Ruta
-- =====================================================================
INSERT INTO Ruta (Origen, Destino, Distancia_KM, Fecha_registro, ID_vehiculo) VALUES
('Lima', 'Arequipa',  1009.5, '2026-01-05', 1),
('Lima', 'Trujillo',  561.3,  '2026-01-08', 2),
('Lima', 'Chiclayo',  770.2,  '2026-01-11', 3),
('Lima', 'Piura',     973.8,  '2026-01-14', 4),
('Lima', 'Cusco',     1105.6, '2026-01-17', 5),
('Lima', 'Ica',       306.4,  '2026-01-20', 6),
('Lima', 'Huancayo',  298.7,  '2026-01-23', 7),
('Lima', 'Tacna',     1292.1, '2026-01-26', 8),
('Lima', 'Chimbote',  420.9,  '2026-01-29', 9),
('Arequipa', 'Lima',  1009.5, '2026-02-01', 1);
GO

-- =====================================================================
-- 12. Asignacion
-- =====================================================================
INSERT INTO Asignacion (ID_vehiculo, ID_Conductor, Fecha_inicio, Fecha_fin, ID_estado) VALUES
(1, 1, '2026-01-05', '2026-05-30', 1),
(2, 2, '2026-01-06', '2026-03-30', 1),
(3, 3, '2026-01-07', '2026-04-30', 2),
(4, 4, '2026-01-08', '2026-05-30', 1),
(5, 5, '2026-01-09', '2026-06-30', 1),
(6, 6, '2026-01-10', '2026-07-30', 2),
(7, 7, '2026-01-11', '2026-04-30', 1),
(8, 8, '2026-01-12', '2026-03-30', 2),
(9, 9, '2026-01-13', '2026-02-28', 1),
(10, 10, '2026-01-14', '2026-03-30', 1),
(11, 11, '2026-01-15', '2026-07-30', 1),
(12, 12, '2026-01-16', '2026-06-30', 1);
GO

-- =====================================================================
-- 13. Consumo_combustible (12 registros)
-- =====================================================================
INSERT INTO Consumo_combustible (Fecha_registro, Litros_consumidos, KM_recorridos, ID_vehiculo) VALUES
('2026-01-05', 85.5,  850, 1),
('2026-01-10', 45.2,  480, 2),
('2026-01-15', 320.8, 680, 3),
('2026-01-20', 410.5, 820, 4),
('2026-01-25', 380.0, 950, 3),
('2026-02-01', 95.6,  260, 1), 
('2026-02-05', 22.4,  250, 1),
('2026-02-10', 60.3,  360, 8), 
('2026-02-15', 30.8,  360, 9), 
('2026-02-20', 55.0,  420, 10),
('2026-02-25', 40.2,  380, 11),
('2026-03-01', 75.6,  510, 11);
GO

-- =====================================================================
-- 14. Emision_Co2
-- =====================================================================
INSERT INTO Emision_Co2 (Fecha_registro, Kg_Co2, Factor_aplicado, ID_consumo) VALUES
('2026-01-05', 197.51,  2.31, 1),
('2026-01-10', 121.14,  2.68, 2),
('2026-01-15', 859.74,  2.68, 3),
('2026-01-20', 1100.14, 2.68, 4),
('2026-01-25', 1018.40, 2.68, 5),
('2026-02-01', 220.84,  2.31, 6),
('2026-02-05', 51.74,   2.31, 7),
('2026-02-10', 91.05,   1.51, 8),
('2026-02-15', 60.37,   1.96, 9),
('2026-02-20', 127.05,  2.31, 10),
('2026-02-25', 84.42,   2.10, 11),
('2026-03-01', 192.78,  2.55, 12);
GO

-- =====================================================================
-- 15. Mantenimiento
-- =====================================================================
INSERT INTO Mantenimiento (Fecha_mantenimiento, Descripcion, Costo, ID_administrador, ID_vehiculo, ID_Tipo_mantenimiento) VALUES
('2026-01-08', 'Cambio de aceite y filtros', 250.00,  1, 1, 1),
('2026-01-12', 'Revision de frenos',         180.50,  2, 2, 2),
('2026-01-18', 'Cambio de llantas',          1200.00, 3, 3, 1),
('2026-01-22', 'Reparacion de motor',        3500.00, 1, 4, 2),
('2026-02-02', 'Revision tecnica anual',     150.00,  4, 5, 4),
('2026-02-08', 'Cambio de bateria',          320.00,  2, 6, 1),
('2026-02-12', 'Analisis de sensores',       400.00,  5, 7, 3),
('2026-02-18', 'Reparacion de suspension',   980.00,  3, 8, 2),
('2026-02-22', 'Cambio de neumaticos',       1450.00, 4, 9, 5),
('2026-02-25', 'Alineamiento y balanceo',    220.00,  5, 10, 6),
('2026-03-01', 'Cambio de bateria',          310.00,  1, 11, 9),
('2026-03-05', 'Revision electrica',         275.00,  2, 12, 8);
GO

-- =====================================================================
-- 16. Alerta
-- =====================================================================
INSERT INTO Alerta (Mensaje, Fecha_alerta, ID_Tipo_alerta, ID_administrador, ID_vehiculo, ID_estado) VALUES
('Exceso de velocidad detectado',   '2026-01-06', 1, 1, 1, 1),
('Mantenimiento proximo a vencer',  '2026-01-11', 2, 2, 2, 1),
('Documento de conductor vencido',  '2026-01-16', 3, 3, 3, 2),
('Consumo fuera de rango normal',   '2026-01-21', 4, 1, 4, 1),
('Exceso de velocidad en ruta',     '2026-01-26', 1, 4, 5, 1),
('Mantenimiento vencido urgente',   '2026-02-03', 2, 5, 6, 3),
('Consumo anomalo reportado',       '2026-02-09', 4, 2, 7, 1),
('Desvio de ruta detectado',        '2026-02-14', 5, 3, 9, 1),
('Frenado brusco registrado',       '2026-02-19', 6, 4, 10, 1),
('Exceso de carga en vehiculo',     '2026-02-24', 7, 5, 11, 2),
('Operacion fuera de horario',      '2026-03-01', 8, 1, 12, 1),
('Bateria de GPS baja',             '2026-03-04', 9, 2, 3, 1);
GO

-- =====================================================================
-- 17. Telefono_conductor (12 registros, uno por conductor)
-- =====================================================================
INSERT INTO Telefono_conductor (Numero_conductor, ID_Conductor) VALUES
('987654321', 1),
('976543210', 2),
('965432109', 3),
('954321098', 4),
('943210987', 5),
('932109876', 1),
('921098765', 7),
('910987654', 8),
('998877665', 9),
('987001122', 10),
('987002233', 11),
('987003344', 12);
GO
 
-- =====================================================================
-- 18. Telefono_administrador (12 registros)
-- =====================================================================
INSERT INTO Telefono_administrador (Numero_administrador, ID_administrador) VALUES
('987111222', 1),
('987222333', 2),
('987333444', 3),
('987444555', 4),
('987555666', 5),
('987666777', 6),
('987777888', 7),
('987888999', 4),
('987999000', 9),
('988000111', 10),
('988111222', 11),
('988222333', 12);
GO
 
-- =====================================================================
-- 19. Modificacion_vehiculo
-- =====================================================================
INSERT INTO Modificacion_vehiculo (Fecha_modificacion, Campo_modificado, Valor_anterior, Valor_nuevo, ID_vehiculo, ID_administrador) VALUES
('2026-01-10', 'Capacidad_de_carga', '900.00 kg',  '1000.00 kg', 1, 1),
('2026-01-15', 'Sistema_de_frenos',  'Tambor trasero', 'Disco ventilado',2, 2),
('2026-01-20', 'Motor_Serie',        'D13K460',      'D16K540',       3, 3),
('2026-01-25', 'Sistema_Suspension', 'Mecánica',     'Neumática',     4, 1),
('2026-02-01', 'Tipo_Combustible',   'Diesel B5',    'GNV (Gas)',     5, 4),
('2026-02-05', 'Color_Pintura',      'Blanco',       'Azul Empresa',  6, 2),
('2026-02-10', 'Capacidad_de_carga', '600.00 kg',    '700.00 kg',     8, 5),
('2026-02-15', 'Motor_Potencia',     '170 HP',       '200 HP',        10, 3),
('2026-02-20', 'Sistema_de_frenos',  'ABS Estándar', 'ABS + EBD',     11, 4),
('2026-02-25', 'Color_Pintura',      'Rojo',         'Blanco Perlado',12, 5),
('2026-03-01', 'Motor_Serie',        'D16K540',      'D16K600',       3, 1),
('2026-03-05', 'Tipo_Combustible',   'Gasolina Regular','GLP',         6, 2);
GO
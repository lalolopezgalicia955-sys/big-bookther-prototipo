-- =====================================================================
-- BIG BOOKTHER - Hito 1: Modelado físico (MySQL 8.0.16+)
-- Basado en 3.3 Modelo relacional (3FN): 14 tablas
--   8 principales: Estudiante, Libro, Ejemplar, Prestamo, Sancion,
--                  Equipo, Venta, DetalleVenta
--   6 complementarias: Rol, Usuario, Seccion, UsoEquipo,
--                      ParametroSistema, Bitacora
-- NOTA: los tipos de dato son una propuesta, ajustalos al diccionario
-- de datos (2.3.2) si difieren.
-- =====================================================================

DROP DATABASE IF EXISTS big_bookther;
CREATE DATABASE big_bookther
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE big_bookther;

-- ---------------------------------------------------------------------
-- 1. Tablas complementarias sin dependencias
-- ---------------------------------------------------------------------

CREATE TABLE Rol (
  idRol  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(30)  NOT NULL,
  CONSTRAINT pk_rol PRIMARY KEY (idRol),
  CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE Seccion (
  idSeccion INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre    VARCHAR(60)  NOT NULL,
  CONSTRAINT pk_seccion PRIMARY KEY (idSeccion),
  CONSTRAINT uq_seccion_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE ParametroSistema (
  clave       VARCHAR(30)  NOT NULL,  -- tasaIVA, diasPrestamo, maxLibros
  valor       VARCHAR(30)  NOT NULL,
  descripcion VARCHAR(150) NULL,
  CONSTRAINT pk_parametro PRIMARY KEY (clave)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. Usuario (personal) depende de Rol
-- ---------------------------------------------------------------------

CREATE TABLE Usuario (
  idUsuario      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(100) NOT NULL,
  correo         VARCHAR(100) NOT NULL,
  contrasenaHash VARCHAR(255) NOT NULL,           -- bcrypt (R-UBI-01)
  activo         BOOLEAN      NOT NULL DEFAULT TRUE,
  idRol          INT UNSIGNED NOT NULL,
  CONSTRAINT pk_usuario PRIMARY KEY (idUsuario),
  CONSTRAINT uq_usuario_correo UNIQUE (correo),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (idRol)
    REFERENCES Rol (idRol)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. Estudiante (titular de préstamos, sanciones, usos y compras)
-- ---------------------------------------------------------------------

CREATE TABLE Estudiante (
  matricula      VARCHAR(20)  NOT NULL,
  nombre         VARCHAR(100) NOT NULL,
  correo         VARCHAR(100) NOT NULL,
  contrasenaHash VARCHAR(255) NOT NULL,
  activo         BOOLEAN      NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_estudiante PRIMARY KEY (matricula),
  CONSTRAINT uq_estudiante_correo UNIQUE (correo)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. Catálogo: Libro y Ejemplar
-- ---------------------------------------------------------------------

CREATE TABLE Libro (
  idLibro   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  titulo    VARCHAR(200)  NOT NULL,
  autor     VARCHAR(150)  NOT NULL,
  precio    DECIMAL(10,2) NOT NULL,
  idSeccion INT UNSIGNED  NOT NULL,
  CONSTRAINT pk_libro PRIMARY KEY (idLibro),
  CONSTRAINT ck_libro_precio CHECK (precio >= 0),
  CONSTRAINT fk_libro_seccion FOREIGN KEY (idSeccion)
    REFERENCES Seccion (idSeccion)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Ejemplar (
  codigo    VARCHAR(30)  NOT NULL,
  tipoStock ENUM('consulta','venta') NOT NULL,
  estatus   ENUM('disponible','prestado','vendido','en_revision','baja')
            NOT NULL DEFAULT 'disponible',
  idLibro   INT UNSIGNED NOT NULL,
  CONSTRAINT pk_ejemplar PRIMARY KEY (codigo),
  CONSTRAINT fk_ejemplar_libro FOREIGN KEY (idLibro)
    REFERENCES Libro (idLibro)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. Préstamos y sanciones
-- ---------------------------------------------------------------------

CREATE TABLE Prestamo (
  folio            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fechaPrestamo    DATE         NOT NULL,
  fechaLimite      DATE         NOT NULL,      -- fechaPrestamo + diasPrestamo (3)
  fechaDevolucion  DATE         NULL,          -- NULL mientras siga activo
  estatus          ENUM('activo','devuelto','vencido')
                   NOT NULL DEFAULT 'activo',
  matricula        VARCHAR(20)  NOT NULL,
  codigoEjemplar   VARCHAR(30)  NOT NULL,
  idUsuario        INT UNSIGNED NOT NULL,      -- bibliotecario que autoriza
  CONSTRAINT pk_prestamo PRIMARY KEY (folio),
  CONSTRAINT ck_prestamo_fechas CHECK (fechaLimite >= fechaPrestamo),
  CONSTRAINT fk_prestamo_estudiante FOREIGN KEY (matricula)
    REFERENCES Estudiante (matricula)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_prestamo_ejemplar FOREIGN KEY (codigoEjemplar)
    REFERENCES Ejemplar (codigo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_prestamo_usuario FOREIGN KEY (idUsuario)
    REFERENCES Usuario (idUsuario)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Sancion (
  idSancion     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  monto         DECIMAL(10,2) NOT NULL,
  motivo        VARCHAR(255)  NOT NULL,
  estatus       ENUM('pendiente','pagada','condonada')
                NOT NULL DEFAULT 'pendiente',
  matricula     VARCHAR(20)   NOT NULL,
  folioPrestamo INT UNSIGNED  NULL,            -- NULL en sanciones manuales (daño/pérdida)
  CONSTRAINT pk_sancion PRIMARY KEY (idSancion),
  CONSTRAINT uq_sancion_prestamo UNIQUE (folioPrestamo),   -- Prestamo 1 : Sancion 0..1
  CONSTRAINT ck_sancion_monto CHECK (monto >= 0),
  CONSTRAINT fk_sancion_estudiante FOREIGN KEY (matricula)
    REFERENCES Estudiante (matricula)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_sancion_prestamo FOREIGN KEY (folioPrestamo)
    REFERENCES Prestamo (folio)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. Equipos de cómputo y su historial de uso
-- ---------------------------------------------------------------------

CREATE TABLE Equipo (
  idEquipo INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre   VARCHAR(50)  NOT NULL,
  estatus  ENUM('Libre','En uso','Sin servicio') NOT NULL DEFAULT 'Libre',
  CONSTRAINT pk_equipo PRIMARY KEY (idEquipo),
  CONSTRAINT uq_equipo_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE UsoEquipo (
  idUso      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  horaInicio DATETIME     NOT NULL,
  horaFin    DATETIME     NULL,                -- NULL mientras el equipo esté en uso
  idEquipo   INT UNSIGNED NOT NULL,
  matricula  VARCHAR(20)  NOT NULL,
  CONSTRAINT pk_usoequipo PRIMARY KEY (idUso),
  CONSTRAINT ck_uso_horas CHECK (horaFin IS NULL OR horaFin >= horaInicio),
  CONSTRAINT fk_uso_equipo FOREIGN KEY (idEquipo)
    REFERENCES Equipo (idEquipo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_uso_estudiante FOREIGN KEY (matricula)
    REFERENCES Estudiante (matricula)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. Ventas y su detalle
-- ---------------------------------------------------------------------

CREATE TABLE Venta (
  folioTicket INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  fecha       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subtotal    DECIMAL(10,2) NOT NULL,
  iva         DECIMAL(10,2) NOT NULL,
  total       DECIMAL(10,2) NOT NULL,
  matricula   VARCHAR(20)   NULL,              -- NULL si compra alguien sin matrícula
  idUsuario   INT UNSIGNED  NOT NULL,          -- cajero
  CONSTRAINT pk_venta PRIMARY KEY (folioTicket),
  CONSTRAINT ck_venta_montos CHECK (subtotal >= 0 AND iva >= 0 AND total >= 0),
  CONSTRAINT fk_venta_estudiante FOREIGN KEY (matricula)
    REFERENCES Estudiante (matricula)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_venta_usuario FOREIGN KEY (idUsuario)
    REFERENCES Usuario (idUsuario)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE DetalleVenta (
  folioTicket    INT UNSIGNED  NOT NULL,
  codigoEjemplar VARCHAR(30)   NOT NULL,
  cantidad       INT UNSIGNED  NOT NULL DEFAULT 1,
  precioUnitario DECIMAL(10,2) NOT NULL,       -- precio vigente al momento de la venta
  CONSTRAINT pk_detalleventa PRIMARY KEY (folioTicket, codigoEjemplar),
  CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_detalle_precio CHECK (precioUnitario >= 0),
  CONSTRAINT fk_detalle_venta FOREIGN KEY (folioTicket)
    REFERENCES Venta (folioTicket)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_detalle_ejemplar FOREIGN KEY (codigoEjemplar)
    REFERENCES Ejemplar (codigo)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. Bitácora
-- ---------------------------------------------------------------------

CREATE TABLE Bitacora (
  idBitacora INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fechaHora  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  accion     VARCHAR(100) NOT NULL,            -- acceso, alta, respaldo...
  detalle    VARCHAR(255) NULL,
  idUsuario  INT UNSIGNED NULL,
  CONSTRAINT pk_bitacora PRIMARY KEY (idBitacora),
  CONSTRAINT fk_bitacora_usuario FOREIGN KEY (idUsuario)
    REFERENCES Usuario (idUsuario)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. Datos iniciales (roles y parámetros del sistema)
-- ---------------------------------------------------------------------

INSERT INTO Rol (nombre) VALUES
  ('Administrador'), ('Bibliotecario'), ('Cajero'), ('Usuario');

INSERT INTO ParametroSistema (clave, valor, descripcion) VALUES
  ('tasaIVA',      '0.16', 'Tasa de IVA aplicada a las ventas'),
  ('diasPrestamo', '3',    'Días de plazo de un préstamo'),
  ('maxLibros',    '2',    'Máximo de libros prestados por estudiante');

-- ---------------------------------------------------------------------
-- 10. Verificación (para la captura de evidencia)
-- ---------------------------------------------------------------------

SHOW TABLES;

SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'big_bookther'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;

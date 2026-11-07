-- =====================================================================
-- BIG BOOKTHER - Sistema Integral de Gestión de Biblioteca y Librería
-- Script de creación de la base de datos
-- Motor: MySQL 8.0 (MySQL Workbench 8.0 CE) - InnoDB (transacciones ACID)
-- Fuente: 2.3.2 Diccionario de datos y 3.3 Modelo relacional
-- =====================================================================

CREATE DATABASE IF NOT EXISTS bigbookther
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE bigbookther;

-- =====================================================================
-- TABLAS COMPLEMENTARIAS DE SEGURIDAD Y CATÁLOGO
-- (se crean primero porque las tablas principales hacen referencia a ellas)
-- =====================================================================

-- 1. Rol
CREATE TABLE Rol (
    idRol   INT         NOT NULL AUTO_INCREMENT,
    nombre  VARCHAR(30) NOT NULL,                       -- Administrador, Bibliotecario, Cajero, Usuario
    CONSTRAINT pk_rol PRIMARY KEY (idRol),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- 2. Usuario (personal del sistema)
CREATE TABLE Usuario (
    idUsuario       INT          NOT NULL AUTO_INCREMENT,
    nombreUsuario   VARCHAR(30)  NOT NULL,
    contrasenaHash  VARCHAR(255) NOT NULL,              -- bcrypt (R-UBI-01)
    idRol           INT          NOT NULL,
    activo          BOOLEAN      NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (idUsuario),
    CONSTRAINT uq_usuario_nombre UNIQUE (nombreUsuario),
    CONSTRAINT fk_usuario_rol FOREIGN KEY (idRol)
        REFERENCES Rol (idRol)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 3. Seccion
CREATE TABLE Seccion (
    idSeccion  INT         NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(50) NOT NULL,
    CONSTRAINT pk_seccion PRIMARY KEY (idSeccion),
    CONSTRAINT uq_seccion_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- =====================================================================
-- TABLAS PRINCIPALES (3.3.1)
-- =====================================================================

-- 4. Estudiante (padrón de alumnos)
CREATE TABLE Estudiante (
    matricula       VARCHAR(15)  NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    correo          VARCHAR(100) NULL,
    contrasenaHash  VARCHAR(255) NOT NULL,              -- bcrypt (R-UBI-01)
    activo          BOOLEAN      NOT NULL,              -- vigencia en el padrón
    CONSTRAINT pk_estudiante PRIMARY KEY (matricula),
    CONSTRAINT uq_estudiante_correo UNIQUE (correo)
) ENGINE = InnoDB;

-- 5. Libro (catálogo de títulos)
CREATE TABLE Libro (
    idLibro    INT           NOT NULL AUTO_INCREMENT,
    titulo     VARCHAR(150)  NOT NULL,
    autor      VARCHAR(100)  NOT NULL,
    idSeccion  INT           NOT NULL,
    precio     DECIMAL(10,2) NULL,                      -- nulo si no se vende; precio sin IVA
    CONSTRAINT pk_libro PRIMARY KEY (idLibro),
    CONSTRAINT fk_libro_seccion FOREIGN KEY (idSeccion)
        REFERENCES Seccion (idSeccion)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_libro_titulo (titulo),                    -- búsquedas por filtro en menos de 2 s (R-EVE-03)
    INDEX idx_libro_autor (autor)
) ENGINE = InnoDB;

-- 6. Ejemplar (copias físicas)
CREATE TABLE Ejemplar (
    codigo     VARCHAR(20) NOT NULL,
    idLibro    INT         NOT NULL,
    tipoStock  ENUM('consulta', 'venta') NOT NULL,      -- R-UBI-02
    estatus    ENUM('disponible', 'prestado', 'vendido', 'en_revision', 'baja') NOT NULL,
    CONSTRAINT pk_ejemplar PRIMARY KEY (codigo),
    CONSTRAINT fk_ejemplar_libro FOREIGN KEY (idLibro)
        REFERENCES Libro (idLibro)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 7. Prestamo
CREATE TABLE Prestamo (
    folio            VARCHAR(20) NOT NULL,              -- folio único (R-EVE-04)
    matricula        VARCHAR(15) NOT NULL,
    codigoEjemplar   VARCHAR(20) NOT NULL,
    idUsuario        INT         NOT NULL,              -- bibliotecario que autoriza
    fechaPrestamo    DATETIME    NOT NULL,
    fechaLimite      DATETIME    NOT NULL,              -- plazo de 3 días
    fechaDevolucion  DATETIME    NULL,                  -- fecha real de entrega
    estatus          ENUM('activo', 'devuelto', 'vencido') NOT NULL,
    CONSTRAINT pk_prestamo PRIMARY KEY (folio),
    CONSTRAINT fk_prestamo_estudiante FOREIGN KEY (matricula)
        REFERENCES Estudiante (matricula)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_prestamo_ejemplar FOREIGN KEY (codigoEjemplar)
        REFERENCES Ejemplar (codigo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_prestamo_usuario FOREIGN KEY (idUsuario)
        REFERENCES Usuario (idUsuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 8. Sancion
CREATE TABLE Sancion (
    idSancion      INT           NOT NULL AUTO_INCREMENT,
    matricula      VARCHAR(15)   NOT NULL,
    folioPrestamo  VARCHAR(20)   NULL,                  -- nulo en sanciones manuales (daño o pérdida)
    monto          DECIMAL(10,2) NOT NULL,
    motivo         VARCHAR(100)  NOT NULL,              -- retraso, daño o pérdida
    estatus        ENUM('pendiente', 'pagada', 'condonada') NOT NULL,
    CONSTRAINT pk_sancion PRIMARY KEY (idSancion),
    CONSTRAINT fk_sancion_estudiante FOREIGN KEY (matricula)
        REFERENCES Estudiante (matricula)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_sancion_prestamo FOREIGN KEY (folioPrestamo)
        REFERENCES Prestamo (folio)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 9. Equipo (computadoras de la sala)
CREATE TABLE Equipo (
    idEquipo  INT         NOT NULL AUTO_INCREMENT,
    nombre    VARCHAR(30) NOT NULL,
    estatus   ENUM('Libre', 'En uso', 'Sin servicio') NOT NULL,   -- R-EVE-05
    CONSTRAINT pk_equipo PRIMARY KEY (idEquipo),
    CONSTRAINT uq_equipo_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- 10. Venta (ticket)
CREATE TABLE Venta (
    folioTicket  VARCHAR(20)   NOT NULL,
    matricula    VARCHAR(15)   NULL,                    -- comprador; admite nulo
    idUsuario    INT           NOT NULL,                -- cajero
    fecha        DATETIME      NOT NULL,
    subtotal     DECIMAL(10,2) NOT NULL,                -- total sin IVA
    iva          DECIMAL(10,2) NOT NULL,                -- IVA desglosado
    total        DECIMAL(10,2) NOT NULL,                -- total cobrado
    CONSTRAINT pk_venta PRIMARY KEY (folioTicket),
    CONSTRAINT fk_venta_estudiante FOREIGN KEY (matricula)
        REFERENCES Estudiante (matricula)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_venta_usuario FOREIGN KEY (idUsuario)
        REFERENCES Usuario (idUsuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 11. DetalleVenta (líneas del ticket)
CREATE TABLE DetalleVenta (
    folioTicket     VARCHAR(20)   NOT NULL,
    codigoEjemplar  VARCHAR(20)   NOT NULL,
    cantidad        INT           NOT NULL,
    precioUnitario  DECIMAL(10,2) NOT NULL,             -- precio al momento de la venta
    CONSTRAINT pk_detalleventa PRIMARY KEY (folioTicket, codigoEjemplar),
    CONSTRAINT fk_detalleventa_venta FOREIGN KEY (folioTicket)
        REFERENCES Venta (folioTicket)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_detalleventa_ejemplar FOREIGN KEY (codigoEjemplar)
        REFERENCES Ejemplar (codigo)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- =====================================================================
-- TABLAS COMPLEMENTARIAS DE HISTORIAL Y CONTROL (3.3.5)
-- =====================================================================

-- 12. UsoEquipo (historial de uso de computadoras)
CREATE TABLE UsoEquipo (
    idUso       INT         NOT NULL AUTO_INCREMENT,
    idEquipo    INT         NOT NULL,
    matricula   VARCHAR(15) NOT NULL,
    horaInicio  DATETIME    NOT NULL,
    horaFin     DATETIME    NULL,
    CONSTRAINT pk_usoequipo PRIMARY KEY (idUso),
    CONSTRAINT fk_usoequipo_equipo FOREIGN KEY (idEquipo)
        REFERENCES Equipo (idEquipo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_usoequipo_estudiante FOREIGN KEY (matricula)
        REFERENCES Estudiante (matricula)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 13. ParametroSistema (reglas de negocio ajustables)
CREATE TABLE ParametroSistema (
    clave  VARCHAR(30) NOT NULL,
    valor  VARCHAR(30) NOT NULL,
    CONSTRAINT pk_parametrosistema PRIMARY KEY (clave)
) ENGINE = InnoDB;

-- 14. Bitacora
CREATE TABLE Bitacora (
    idRegistro  INT          NOT NULL AUTO_INCREMENT,
    idUsuario   INT          NULL,
    fechaHora   DATETIME     NOT NULL,
    accion      VARCHAR(150) NOT NULL,                  -- acceso, alta, respaldo, etc.
    CONSTRAINT pk_bitacora PRIMARY KEY (idRegistro),
    CONSTRAINT fk_bitacora_usuario FOREIGN KEY (idUsuario)
        REFERENCES Usuario (idUsuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- =====================================================================
-- DATOS INICIALES
-- =====================================================================

-- Roles definidos en el diccionario de datos
INSERT INTO Rol (nombre) VALUES
    ('Administrador'),
    ('Bibliotecario'),
    ('Cajero'),
    ('Usuario');

-- Reglas actuales de la biblioteca: IVA 16 %, 3 días de préstamo, máximo 2 libros
INSERT INTO ParametroSistema (clave, valor) VALUES
    ('tasaIVA', '16'),
    ('diasPrestamo', '3'),
    ('maxLibros', '2');

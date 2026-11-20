-- Datos de demostración para probar el Happy Path y tomar capturas.
-- Ejecutar DESPUÉS de big_bookther_schema.sql:  mysql -u root -p big_bookther < database/datos_demo.sql
-- Los "hash" son texto de relleno, NO contraseñas reales (el módulo de autenticación con bcrypt va aparte).

USE big_bookther;

INSERT INTO Seccion (idSeccion, nombre) VALUES (1, 'Ciencias'), (2, 'Literatura');

INSERT INTO Libro (idLibro, titulo, autor, precio, idSeccion) VALUES
  (1, 'Fundamentos de Bases de Datos', 'Silberschatz', 450.00, 1),
  (2, 'Cien años de soledad', 'Gabriel García Márquez', 199.50, 2);

INSERT INTO Ejemplar (codigo, tipoStock, estatus, idLibro) VALUES
  ('BD-001', 'consulta', 'disponible', 1),
  ('BD-002', 'consulta', 'disponible', 1),
  ('LIT-001', 'consulta', 'disponible', 2),
  ('LIT-002', 'venta',    'vendido',    2);

INSERT INTO Estudiante (matricula, nombre, correo, contrasenaHash, activo) VALUES
  ('A001', 'Ana López',   'ana@correo.com',  'hash-demo', TRUE),
  ('A002', 'Luis Pérez',  'luis@correo.com', 'hash-demo', FALSE);

INSERT INTO Usuario (idUsuario, nombre, correo, contrasenaHash, activo, idRol) VALUES
  (1, 'Bibliotecario Demo', 'biblio@correo.com', 'hash-demo', TRUE, 2);

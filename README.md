# BIG BOOKTHER

Sistema de biblioteca y venta de libros. Hito 2: núcleo (Happy Path) y pruebas unitarias.

**Equipo:** _(nombres de los integrantes)_

## Stack
Java 17 · JDBC con patrón DAO · MySQL 8 · Maven · JUnit 5 · Mockito · Testcontainers

## Estructura
```
database/            script SQL del modelo relacional (14 tablas) y datos de demostración
src/main/java/com/bookther/
  db/                ConexionFactory (configuración por variables de entorno)
  model/             Libro, Ejemplar, Estudiante, Prestamo
  dao/               interfaces DAO + implementaciones JDBC (con transacciones)
  service/           LibroService (CRUD) y PrestamoService (reglas de préstamo/devolución)
  Main.java          vista de consola del Happy Path
src/test/java/       pruebas unitarias (Mockito) y de integración (Testcontainers)
```

## Cómo ejecutarlo
1. Crear la base de datos y cargar datos de prueba:
   ```
   mysql -u root -p < database/big_bookther_schema.sql
   mysql -u root -p big_bookther < database/datos_demo.sql
   ```
2. Configurar la conexión (si no se define, usa `root` sin contraseña en localhost):
   ```
   export DB_URL="jdbc:mysql://localhost:3306/big_bookther?useSSL=false&allowPublicKeyRetrieval=true"
   export DB_USER=root
   export DB_PASSWORD=tu_contraseña
   ```
3. Ejecutar el menú de consola:
   ```
   mvn compile exec:java -Dexec.mainClass=com.bookther.Main
   ```

## Happy Path
Bibliotecario consulta el catálogo → registra un préstamo (`A001`, ejemplar `BD-001`, usuario `1`) → registra la devolución.
Además: CRUD completo de libros.

## Reglas de negocio implementadas
- R-STA-01: no se presta un ejemplar vendido.
- Un ejemplar solo se presta si está `disponible`.
- Límite de libros por estudiante (`maxLibros`) y plazo de préstamo (`diasPrestamo`), leídos de `ParametroSistema`.
- Préstamo y cambio de estatus del ejemplar ocurren en **una sola transacción** (también la devolución).

## Pruebas
```
mvn test
```
- `PrestamoServiceTest`, `LibroServiceTest`: JUnit 5 + Mockito, sin base de datos.
- `EsquemaMySqlTest`: Testcontainers levanta un MySQL real, ejecuta el script y valida tablas, llaves foráneas,
  restricciones y transacciones. **Requiere Docker**; sin Docker se omite.

## Flujo de ramas
Cada módulo en su rama `feature/...`, con Pull Request hacia `main` y revisión de al menos un compañero.

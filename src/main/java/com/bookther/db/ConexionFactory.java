package com.bookther.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Entrega conexiones JDBC. Es una interfaz para poder cambiarla en las pruebas
 * (por ejemplo, apuntar a un contenedor MySQL de Testcontainers).
 */
@FunctionalInterface
public interface ConexionFactory {

    Connection get() throws SQLException;

    /**
     * Lee la configuración de variables de entorno (no se suben contraseñas al repositorio):
     * DB_URL, DB_USER y DB_PASSWORD. Si no existen, usa valores locales por defecto.
     */
    static ConexionFactory desdeEntorno() {
        String url = valor("DB_URL",
                "jdbc:mysql://localhost:3306/big_bookther?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Mexico_City");
        String usuario = valor("DB_USER", "root");
        String clave = valor("DB_PASSWORD", "");
        return () -> DriverManager.getConnection(url, usuario, clave);
    }

    private static String valor(String nombre, String porDefecto) {
        String v = System.getenv(nombre);
        return (v == null || v.isBlank()) ? porDefecto : v;
    }
}

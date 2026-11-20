package com.bookther.model;

/**
 * Tabla Ejemplar.
 * tipoStock: consulta | venta.
 * estatus: disponible | prestado | vendido | en_revision | baja.
 */
public record Ejemplar(String codigo, String tipoStock, String estatus, int idLibro) {
}

package com.bookther.model;

import java.math.BigDecimal;

/** Tabla Libro. idLibro es null mientras el libro no se ha guardado. */
public record Libro(Integer idLibro, String titulo, String autor, BigDecimal precio, int idSeccion) {
}

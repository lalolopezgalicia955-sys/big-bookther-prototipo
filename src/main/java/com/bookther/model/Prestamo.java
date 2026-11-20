package com.bookther.model;

import java.time.LocalDate;

/**
 * Tabla Prestamo.
 * folio es null antes de guardarlo; fechaDevolucion es null mientras siga pendiente.
 * estatus: activo | devuelto | vencido.
 */
public record Prestamo(Integer folio, LocalDate fechaPrestamo, LocalDate fechaLimite,
                       LocalDate fechaDevolucion, String estatus,
                       String matricula, String codigoEjemplar, int idUsuario) {
}

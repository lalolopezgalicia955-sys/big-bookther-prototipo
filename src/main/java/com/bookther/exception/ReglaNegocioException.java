package com.bookther.exception;

/** Se lanza cuando una operación viola una regla del negocio (por ejemplo, R-STA-01). */
public class ReglaNegocioException extends RuntimeException {

    public ReglaNegocioException(String mensaje) {
        super(mensaje);
    }
}

package com.bookther.exception;

/** Envuelve los errores de JDBC para que las capas superiores no dependan de SQLException. */
public class DaoException extends RuntimeException {

    public DaoException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}

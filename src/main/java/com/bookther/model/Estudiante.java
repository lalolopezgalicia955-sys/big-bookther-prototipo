package com.bookther.model;

/** Tabla Estudiante (sin el hash de contraseña, que no debe circular por la aplicación). */
public record Estudiante(String matricula, String nombre, String correo, boolean activo) {
}

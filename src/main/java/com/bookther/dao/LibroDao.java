package com.bookther.dao;

import com.bookther.model.Libro;

import java.util.List;
import java.util.Optional;

/** CRUD de la tabla Libro. */
public interface LibroDao {

    /** Inserta el libro y devuelve el idLibro generado. */
    int insertar(Libro libro);

    Optional<Libro> buscarPorId(int idLibro);

    List<Libro> listar();

    /** Devuelve true si se actualizó una fila. */
    boolean actualizar(Libro libro);

    /** Devuelve true si se eliminó una fila. Falla si el libro tiene ejemplares (FK RESTRICT). */
    boolean eliminar(int idLibro);
}

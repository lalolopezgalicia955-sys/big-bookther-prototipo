package com.bookther.service;

import com.bookther.dao.LibroDao;
import com.bookther.exception.ReglaNegocioException;
import com.bookther.model.Libro;

import java.math.BigDecimal;
import java.util.List;

/** CRUD de libros con validación de datos antes de llegar a la base de datos. */
public class LibroService {

    private final LibroDao libroDao;

    public LibroService(LibroDao libroDao) {
        this.libroDao = libroDao;
    }

    public int crear(String titulo, String autor, BigDecimal precio, int idSeccion) {
        validar(titulo, autor, precio, idSeccion);
        return libroDao.insertar(new Libro(null, titulo.trim(), autor.trim(), precio, idSeccion));
    }

    public List<Libro> listar() {
        return libroDao.listar();
    }

    public Libro buscar(int idLibro) {
        return libroDao.buscarPorId(idLibro)
                .orElseThrow(() -> new ReglaNegocioException("El libro " + idLibro + " no existe"));
    }

    public void actualizar(int idLibro, String titulo, String autor, BigDecimal precio, int idSeccion) {
        validar(titulo, autor, precio, idSeccion);
        boolean actualizado = libroDao.actualizar(new Libro(idLibro, titulo.trim(), autor.trim(), precio, idSeccion));
        if (!actualizado) {
            throw new ReglaNegocioException("El libro " + idLibro + " no existe");
        }
    }

    public void eliminar(int idLibro) {
        if (!libroDao.eliminar(idLibro)) {
            throw new ReglaNegocioException("El libro " + idLibro + " no existe");
        }
    }

    private static void validar(String titulo, String autor, BigDecimal precio, int idSeccion) {
        if (titulo == null || titulo.isBlank()) {
            throw new ReglaNegocioException("El título es obligatorio");
        }
        if (titulo.trim().length() > 200) {
            throw new ReglaNegocioException("El título no puede pasar de 200 caracteres");
        }
        if (autor == null || autor.isBlank()) {
            throw new ReglaNegocioException("El autor es obligatorio");
        }
        if (autor.trim().length() > 150) {
            throw new ReglaNegocioException("El autor no puede pasar de 150 caracteres");
        }
        if (precio == null || precio.signum() < 0) {
            throw new ReglaNegocioException("El precio no puede ser negativo");
        }
        if (idSeccion <= 0) {
            throw new ReglaNegocioException("Debes indicar una sección válida");
        }
    }
}

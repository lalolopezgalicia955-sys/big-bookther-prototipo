package com.bookther.service;

import com.bookther.dao.LibroDao;
import com.bookther.exception.ReglaNegocioException;
import com.bookther.model.Libro;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Pruebas unitarias del CRUD de libros (la base de datos se simula con Mockito). */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class LibroServiceTest {

    @Mock private LibroDao libroDao;
    @InjectMocks private LibroService servicio;

    @Test
    @DisplayName("Crear: guarda el libro con el título sin espacios sobrantes y devuelve el id")
    void creaLibro() {
        when(libroDao.insertar(any(Libro.class))).thenReturn(15);

        int id = servicio.crear("  Cien años de soledad ", "García Márquez", new BigDecimal("199.50"), 2);

        assertEquals(15, id);
        ArgumentCaptor<Libro> captor = ArgumentCaptor.forClass(Libro.class);
        verify(libroDao).insertar(captor.capture());
        assertNull(captor.getValue().idLibro());
        assertEquals("Cien años de soledad", captor.getValue().titulo());
        assertEquals(new BigDecimal("199.50"), captor.getValue().precio());
    }

    @ParameterizedTest(name = "título inválido: [{0}]")
    @NullAndEmptySource
    @ValueSource(strings = {"   "})
    @DisplayName("Crear: rechaza título vacío o nulo")
    void rechazaTituloVacio(String titulo) {
        assertThrows(ReglaNegocioException.class,
                () -> servicio.crear(titulo, "Autor", BigDecimal.TEN, 1));
        verify(libroDao, never()).insertar(any());
    }

    @Test
    @DisplayName("Crear: rechaza precio negativo")
    void rechazaPrecioNegativo() {
        assertThrows(ReglaNegocioException.class,
                () -> servicio.crear("Libro", "Autor", new BigDecimal("-1"), 1));
        verify(libroDao, never()).insertar(any());
    }

    @Test
    @DisplayName("Crear: acepta precio cero")
    void aceptaPrecioCero() {
        when(libroDao.insertar(any(Libro.class))).thenReturn(1);

        assertEquals(1, servicio.crear("Libro", "Autor", BigDecimal.ZERO, 1));
    }

    @Test
    @DisplayName("Crear: rechaza sección inválida")
    void rechazaSeccionInvalida() {
        assertThrows(ReglaNegocioException.class,
                () -> servicio.crear("Libro", "Autor", BigDecimal.TEN, 0));
    }

    @Test
    @DisplayName("Buscar: lanza error si el libro no existe")
    void buscarInexistente() {
        when(libroDao.buscarPorId(99)).thenReturn(Optional.empty());

        assertThrows(ReglaNegocioException.class, () -> servicio.buscar(99));
    }

    @Test
    @DisplayName("Actualizar: lanza error si ninguna fila cambió")
    void actualizarInexistente() {
        when(libroDao.actualizar(any(Libro.class))).thenReturn(false);

        assertThrows(ReglaNegocioException.class,
                () -> servicio.actualizar(99, "Libro", "Autor", BigDecimal.TEN, 1));
    }

    @Test
    @DisplayName("Eliminar: lanza error si el libro no existe")
    void eliminarInexistente() {
        when(libroDao.eliminar(99)).thenReturn(false);

        assertThrows(ReglaNegocioException.class, () -> servicio.eliminar(99));
    }

    @Test
    @DisplayName("Eliminar: elimina un libro existente")
    void eliminaLibro() {
        when(libroDao.eliminar(5)).thenReturn(true);

        servicio.eliminar(5);

        verify(libroDao).eliminar(5);
    }
}

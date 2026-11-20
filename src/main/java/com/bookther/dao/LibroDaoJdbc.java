package com.bookther.dao;

import com.bookther.db.ConexionFactory;
import com.bookther.exception.DaoException;
import com.bookther.model.Libro;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class LibroDaoJdbc implements LibroDao {

    private final ConexionFactory conexiones;

    public LibroDaoJdbc(ConexionFactory conexiones) {
        this.conexiones = conexiones;
    }

    @Override
    public int insertar(Libro libro) {
        String sql = "INSERT INTO Libro (titulo, autor, precio, idSeccion) VALUES (?, ?, ?, ?)";
        try (Connection c = conexiones.get();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, libro.titulo());
            ps.setString(2, libro.autor());
            ps.setBigDecimal(3, libro.precio());
            ps.setInt(4, libro.idSeccion());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            throw new DaoException("No se pudo insertar el libro", e);
        }
    }

    @Override
    public Optional<Libro> buscarPorId(int idLibro) {
        String sql = "SELECT idLibro, titulo, autor, precio, idSeccion FROM Libro WHERE idLibro = ?";
        try (Connection c = conexiones.get();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, idLibro);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapear(rs)) : Optional.empty();
            }
        } catch (SQLException e) {
            throw new DaoException("No se pudo consultar el libro " + idLibro, e);
        }
    }

    @Override
    public List<Libro> listar() {
        String sql = "SELECT idLibro, titulo, autor, precio, idSeccion FROM Libro ORDER BY titulo";
        try (Connection c = conexiones.get();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<Libro> libros = new ArrayList<>();
            while (rs.next()) {
                libros.add(mapear(rs));
            }
            return libros;
        } catch (SQLException e) {
            throw new DaoException("No se pudo listar los libros", e);
        }
    }

    @Override
    public boolean actualizar(Libro libro) {
        String sql = "UPDATE Libro SET titulo = ?, autor = ?, precio = ?, idSeccion = ? WHERE idLibro = ?";
        try (Connection c = conexiones.get();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, libro.titulo());
            ps.setString(2, libro.autor());
            ps.setBigDecimal(3, libro.precio());
            ps.setInt(4, libro.idSeccion());
            ps.setInt(5, libro.idLibro());
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            throw new DaoException("No se pudo actualizar el libro", e);
        }
    }

    @Override
    public boolean eliminar(int idLibro) {
        String sql = "DELETE FROM Libro WHERE idLibro = ?";
        try (Connection c = conexiones.get();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, idLibro);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            throw new DaoException("No se pudo eliminar el libro (¿tiene ejemplares?)", e);
        }
    }

    private static Libro mapear(ResultSet rs) throws SQLException {
        return new Libro(rs.getInt("idLibro"), rs.getString("titulo"), rs.getString("autor"),
                rs.getBigDecimal("precio"), rs.getInt("idSeccion"));
    }
}

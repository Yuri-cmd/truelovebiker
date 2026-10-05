/// Ordena un par de coordenadas recibido en cualquier orden.
///
/// En Perú la latitud (-19..0) y la longitud (-82..-68) nunca se solapan, así
/// que el orden real se deduce por el valor. Así la navegación funciona tanto
/// con pedidos guardados correctamente como con los antiguos que quedaron con
/// latitud y longitud invertidas.
class CoordenadasHelper {
  CoordenadasHelper._();

  static bool _latEnPeru(double v) => v >= -19 && v <= 0;
  static bool _lonEnPeru(double v) => v >= -82 && v <= -68;

  /// Devuelve `{"lat": ..., "lon": ...}`. Si ningún orden cae en Perú, deja
  /// los valores como llegaron.
  static Map<String, double> normalizar(double lat, double lon) {
    if (_latEnPeru(lat) && _lonEnPeru(lon)) {
      return {"lat": lat, "lon": lon};
    }
    if (_latEnPeru(lon) && _lonEnPeru(lat)) {
      return {"lat": lon, "lon": lat};
    }
    return {"lat": lat, "lon": lon};
  }
}

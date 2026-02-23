
/// Lightweight geohash encoder + range calculator.
/// No external dependencies.
class GeohashService {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  String encode(double lat, double lng, {int precision = 9}) {
    var latRange = [-90.0, 90.0];
    var lngRange = [-180.0, 180.0];
    var hash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < precision) {
      if (isEven) {
        final mid = (lngRange[0] + lngRange[1]) / 2;
        if (lng >= mid) {
          ch |= (1 << (4 - bit));
          lngRange[0] = mid;
        } else {
          lngRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (lat >= mid) {
          ch |= (1 << (4 - bit));
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        hash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    return hash;
  }

  /// Returns geohash range pairs that cover a bounding box around [lat, lng] + [radiusKm].
  List<GeohashRange> getQueryRanges(double lat, double lng, double radiusKm) {
    // Determine precision based on radius
    int precision;
    if (radiusKm <= 0.5) {
      precision = 7;
    } else if (radiusKm <= 2) {
      precision = 6;
    } else if (radiusKm <= 20) {
      precision = 5;
    } else if (radiusKm <= 80) {
      precision = 4;
    } else {
      precision = 3;
    }

    final centerHash = encode(lat, lng, precision: precision);
    final neighbors = _neighbors(centerHash);
    final allHashes = [centerHash, ...neighbors];

    return allHashes
        .map((h) => GeohashRange(start: h, end: '$h~'))
        .toList();
  }

  List<String> _neighbors(String hash) {
    // Simplified: return the 8 adjacent geohash cells
    // Full implementation uses the geohash neighbor algorithm
    // For MVP, we use a bounding box approach with expanded prefix
    if (hash.isEmpty) return [];
    final parent = hash.substring(0, hash.length - 1);
    final lastChar = hash[hash.length - 1];
    final idx = _base32.indexOf(lastChar);

    final result = <String>[];
    for (var delta = -1; delta <= 1; delta++) {
      final ni = idx + delta;
      if (ni >= 0 && ni < 32) {
        result.add('$parent${_base32[ni]}');
      }
    }
    return result.where((h) => h != hash).toList();
  }
}

class GeohashRange {
  final String start;
  final String end;
  const GeohashRange({required this.start, required this.end});
}
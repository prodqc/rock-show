/// Lightweight geohash encoder + range calculator.
/// No external dependencies.
class GeohashService {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const Map<String, Map<String, String>> _neighborsByDirection = {
    'right': {
      'even': 'bc01fg45238967deuvhjyznpkmstqrwx',
      'odd': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
    },
    'left': {
      'even': '238967debc01fg45kmstqrwxuvhjyznp',
      'odd': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
    },
    'top': {
      'even': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      'odd': 'bc01fg45238967deuvhjyznpkmstqrwx',
    },
    'bottom': {
      'even': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      'odd': '238967debc01fg45kmstqrwxuvhjyznp',
    },
  };
  static const Map<String, Map<String, String>> _borderByDirection = {
    'right': {
      'even': 'bcfguvyz',
      'odd': 'prxz',
    },
    'left': {
      'even': '0145hjnp',
      'odd': '028b',
    },
    'top': {
      'even': 'prxz',
      'odd': 'bcfguvyz',
    },
    'bottom': {
      'even': '028b',
      'odd': '0145hjnp',
    },
  };

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
    if (radiusKm <= 0.3) {
      precision = 7;
    } else if (radiusKm <= 1.0) {
      precision = 6;
    } else if (radiusKm <= 5.0) {
      precision = 5;
    } else if (radiusKm <= 25.0) {
      precision = 4;
    } else if (radiusKm <= 120.0) {
      precision = 3;
    } else {
      precision = 2;
    }

    final centerHash = encode(lat, lng, precision: precision);
    final neighbors = _neighbors(centerHash);
    final allHashes = {centerHash, ...neighbors}.toList();

    return allHashes.map((h) => GeohashRange(start: h, end: '$h~')).toList();
  }

  List<String> _neighbors(String hash) {
    if (hash.isEmpty) return [];

    final north = _adjacent(hash, 'top');
    final south = _adjacent(hash, 'bottom');
    final east = _adjacent(hash, 'right');
    final west = _adjacent(hash, 'left');

    final result = <String>{
      north,
      south,
      east,
      west,
      _adjacent(north, 'right'),
      _adjacent(north, 'left'),
      _adjacent(south, 'right'),
      _adjacent(south, 'left'),
    };
    result.remove('');
    result.remove(hash);
    return result.toList();
  }

  String _adjacent(String hash, String direction) {
    if (hash.isEmpty) return '';
    final lower = hash.toLowerCase();
    final parity = lower.length.isEven ? 'even' : 'odd';
    final last = lower[lower.length - 1];
    final parent = lower.substring(0, lower.length - 1);

    var nextParent = parent;
    final border = _borderByDirection[direction]![parity]!;
    if (border.contains(last) && parent.isNotEmpty) {
      nextParent = _adjacent(parent, direction);
    }

    final neighbor = _neighborsByDirection[direction]![parity]!;
    final idx = neighbor.indexOf(last);
    if (idx < 0) {
      return '';
    }
    return '$nextParent${_base32[idx]}';
  }
}

class GeohashRange {
  final String start;
  final String end;
  const GeohashRange({required this.start, required this.end});
}

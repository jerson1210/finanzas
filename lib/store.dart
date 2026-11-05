import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils.dart';

class Tarifa {
  Tarifa({required this.id, required this.nombre, required this.valor});

  final String id;

  /// Ej. "Corto", "Al colegio". Puede ir vacío si la persona tiene una sola.
  String nombre;

  /// Lo que cobras por cada viaje con esta tarifa.
  int valor;

  String get etiqueta => nombre.isEmpty ? 'Viaje' : nombre;

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'valor': valor};

  factory Tarifa.fromJson(Map<String, dynamic> j) => Tarifa(
        id: j['id'] as String,
        nombre: j['nombre'] as String? ?? '',
        valor: (j['valor'] as num).toInt(),
      );
}

class Persona {
  Persona({required this.id, required this.nombre, required this.tarifas});

  final String id;
  String nombre;

  /// Siempre tiene al menos una.
  List<Tarifa> tarifas;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tarifas': tarifas.map((t) => t.toJson()).toList(),
      };

  factory Persona.fromJson(Map<String, dynamic> j) => Persona(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        tarifas: j['tarifas'] != null
            ? (j['tarifas'] as List)
                .map((e) => Tarifa.fromJson(e as Map<String, dynamic>))
                .toList()
            // Datos viejos: una sola tarifa.
            : [
                Tarifa(
                  id: 't0',
                  nombre: '',
                  valor: (j['tarifa'] as num).toInt(),
                ),
              ],
      );
}

/// Lo que debía una persona en una semana ya cerrada.
class LineaSemana {
  LineaSemana({
    required this.personaId,
    required this.nombre,
    required this.viajes,
    required this.monto,
    this.detalle = '',
  });

  final String personaId;
  final String nombre;
  final int viajes;
  final int monto;

  /// Ej. "2 × Corto, 1 × Largo". Vacío si solo había una tarifa.
  final String detalle;

  Map<String, dynamic> toJson() => {
        'personaId': personaId,
        'nombre': nombre,
        'viajes': viajes,
        'monto': monto,
        'detalle': detalle,
      };

  factory LineaSemana.fromJson(Map<String, dynamic> j) => LineaSemana(
        personaId: j['personaId'] as String,
        nombre: j['nombre'] as String,
        viajes: (j['viajes'] as num).toInt(),
        monto: (j['monto'] as num).toInt(),
        detalle: j['detalle'] as String? ?? '',
      );
}

class SemanaCerrada {
  SemanaCerrada({
    required this.inicio,
    required this.cerradaEl,
    required this.lineas,
  });

  /// Clave (yyyy-mm-dd) del lunes de la semana.
  final String inicio;
  final DateTime cerradaEl;
  final List<LineaSemana> lineas;

  int get total => lineas.fold(0, (s, l) => s + l.monto);

  Map<String, dynamic> toJson() => {
        'inicio': inicio,
        'cerradaEl': cerradaEl.toIso8601String(),
        'lineas': lineas.map((l) => l.toJson()).toList(),
      };

  factory SemanaCerrada.fromJson(Map<String, dynamic> j) => SemanaCerrada(
        inicio: j['inicio'] as String,
        cerradaEl: DateTime.parse(j['cerradaEl'] as String),
        lineas: (j['lineas'] as List)
            .map((e) => LineaSemana.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Pago {
  Pago({
    required this.id,
    required this.personaId,
    required this.monto,
    required this.fecha,
  });

  final String id;
  final String personaId;
  final int monto;
  final DateTime fecha;

  Map<String, dynamic> toJson() => {
        'id': id,
        'personaId': personaId,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
      };

  factory Pago.fromJson(Map<String, dynamic> j) => Pago(
        id: j['id'] as String,
        personaId: j['personaId'] as String,
        monto: (j['monto'] as num).toInt(),
        fecha: DateTime.parse(j['fecha'] as String),
      );
}

class AppStore extends ChangeNotifier {
  static const _clave = 'finanzas_datos_v1';

  final List<Persona> personas = [];

  /// fecha (yyyy-mm-dd) -> "personaId|tarifaId" -> cantidad de viajes
  final Map<String, Map<String, int>> viajes = {};
  final List<SemanaCerrada> semanasCerradas = [];
  final List<Pago> pagos = [];

  SharedPreferences? _prefs;

  Future<void> cargar() async {
    _prefs = await SharedPreferences.getInstance();
    final texto = _prefs!.getString(_clave);
    if (texto == null) return;
    final j = jsonDecode(texto) as Map<String, dynamic>;
    personas
      ..clear()
      ..addAll((j['personas'] as List? ?? [])
          .map((e) => Persona.fromJson(e as Map<String, dynamic>)));
    viajes.clear();
    (j['viajes'] as Map<String, dynamic>? ?? {}).forEach((fecha, mapa) {
      viajes[fecha] = (mapa as Map<String, dynamic>).map((k, v) {
        // Datos viejos: la clave era solo el id de la persona.
        if (!k.contains('|')) {
          k = _clave2(k, persona(k)?.tarifas.first.id ?? 't0');
        }
        return MapEntry(k, (v as num).toInt());
      });
    });
    semanasCerradas
      ..clear()
      ..addAll((j['semanasCerradas'] as List? ?? [])
          .map((e) => SemanaCerrada.fromJson(e as Map<String, dynamic>)));
    pagos
      ..clear()
      ..addAll((j['pagos'] as List? ?? [])
          .map((e) => Pago.fromJson(e as Map<String, dynamic>)));
    notifyListeners();
  }

  void _guardar() {
    notifyListeners();
    _prefs?.setString(
      _clave,
      jsonEncode({
        'personas': personas.map((p) => p.toJson()).toList(),
        'viajes': viajes,
        'semanasCerradas': semanasCerradas.map((s) => s.toJson()).toList(),
        'pagos': pagos.map((p) => p.toJson()).toList(),
      }),
    );
  }

  String _nuevoId() => DateTime.now().microsecondsSinceEpoch.toString();

  static String _clave2(String personaId, String tarifaId) =>
      '$personaId|$tarifaId';

  Persona? persona(String id) {
    for (final p in personas) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------- Personas ----------

  void agregarPersona(String nombre, List<Tarifa> tarifas) {
    personas.add(Persona(id: _nuevoId(), nombre: nombre, tarifas: tarifas));
    _guardar();
  }

  /// ¿Hay viajes guardados (en cualquier semana) con esa tarifa?
  bool tarifaUsada(String personaId, String tarifaId) {
    final k = _clave2(personaId, tarifaId);
    return viajes.values.any((dia) => (dia[k] ?? 0) > 0);
  }

  /// Devuelve un mensaje de error si no se pudo.
  String? editarPersona(Persona p, String nombre, List<Tarifa> tarifas) {
    final ids = tarifas.map((t) => t.id).toSet();
    for (final t in p.tarifas) {
      if (!ids.contains(t.id) && tarifaUsada(p.id, t.id)) {
        return 'La tarifa "${t.etiqueta}" ya tiene viajes. '
            'Puedes cambiarle el nombre o el valor, pero no borrarla.';
      }
    }
    p.nombre = nombre;
    p.tarifas = tarifas;
    _guardar();
    return null;
  }

  /// Solo se puede borrar si no te debe nada.
  bool borrarPersona(Persona p) {
    if (saldoDe(p.id) != 0) return false;
    personas.remove(p);
    for (final dia in viajes.values) {
      dia.removeWhere((k, _) => k.startsWith('${p.id}|'));
    }
    viajes.removeWhere((_, dia) => dia.isEmpty);
    _guardar();
    return true;
  }

  // ---------- Viajes ----------

  int viajesDe(DateTime dia, String personaId, String tarifaId) =>
      viajes[claveFecha(dia)]?[_clave2(personaId, tarifaId)] ?? 0;

  void cambiarViajes(
      DateTime dia, String personaId, String tarifaId, int delta) {
    final clave = claveFecha(dia);
    final k = _clave2(personaId, tarifaId);
    final mapa = viajes.putIfAbsent(clave, () => {});
    final nuevo = (mapa[k] ?? 0) + delta;
    if (nuevo <= 0) {
      mapa.remove(k);
      if (mapa.isEmpty) viajes.remove(clave);
    } else {
      mapa[k] = nuevo;
    }
    _guardar();
  }

  /// Viajes de [p] por tarifa (tarifaId -> cantidad) en la semana de [inicio].
  Map<String, int> conteoTarifas(DateTime inicio, Persona p) {
    final res = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final dia = viajes[claveFecha(sumarDias(inicio, i))];
      if (dia == null) continue;
      for (final t in p.tarifas) {
        final n = dia[_clave2(p.id, t.id)] ?? 0;
        if (n > 0) res[t.id] = (res[t.id] ?? 0) + n;
      }
    }
    return res;
  }

  /// Total de viajes de cada persona en la semana que empieza en [inicio].
  Map<String, int> conteoSemana(DateTime inicio) => {
        for (final p in personas)
          p.id: conteoTarifas(inicio, p).values.fold(0, (a, b) => a + b),
      };

  /// Lo que te debe [p] por la semana de [inicio].
  int montoSemana(DateTime inicio, Persona p) {
    final c = conteoTarifas(inicio, p);
    return p.tarifas.fold(0, (s, t) => s + (c[t.id] ?? 0) * t.valor);
  }

  // ---------- Semanas ----------

  SemanaCerrada? semanaCerrada(DateTime inicio) {
    final clave = claveFecha(inicio);
    for (final s in semanasCerradas) {
      if (s.inicio == clave) return s;
    }
    return null;
  }

  /// Pasa lo de la semana a la cuenta. Devuelve el total sumado.
  int cerrarSemana(DateTime inicio) {
    if (semanaCerrada(inicio) != null) return 0;
    final lineas = <LineaSemana>[];
    for (final p in personas) {
      final c = conteoTarifas(inicio, p);
      final n = c.values.fold(0, (a, b) => a + b);
      if (n == 0) continue;
      lineas.add(LineaSemana(
        personaId: p.id,
        nombre: p.nombre,
        viajes: n,
        monto: montoSemana(inicio, p),
        detalle: p.tarifas.length == 1
            ? ''
            : [
                for (final t in p.tarifas)
                  if ((c[t.id] ?? 0) > 0) '${c[t.id]} × ${t.etiqueta}',
              ].join(', '),
      ));
    }
    final s = SemanaCerrada(
      inicio: claveFecha(inicio),
      cerradaEl: DateTime.now(),
      lineas: lineas,
    );
    semanasCerradas.add(s);
    _guardar();
    return s.total;
  }

  void reabrirSemana(DateTime inicio) {
    final s = semanaCerrada(inicio);
    if (s == null) return;
    semanasCerradas.remove(s);
    _guardar();
  }

  // ---------- Cuenta ----------

  int saldoDe(String personaId) {
    var saldo = 0;
    for (final s in semanasCerradas) {
      for (final l in s.lineas) {
        if (l.personaId == personaId) saldo += l.monto;
      }
    }
    for (final p in pagos) {
      if (p.personaId == personaId) saldo -= p.monto;
    }
    return saldo;
  }

  int get saldoTotal => personas.fold(0, (s, p) => s + saldoDe(p.id));

  void registrarPago(String personaId, int monto) {
    pagos.add(Pago(
      id: _nuevoId(),
      personaId: personaId,
      monto: monto,
      fecha: DateTime.now(),
    ));
    _guardar();
  }

  void borrarPago(Pago p) {
    pagos.remove(p);
    _guardar();
  }
}

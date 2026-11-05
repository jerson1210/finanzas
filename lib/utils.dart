const diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lunes de la semana a la que pertenece [d].
DateTime inicioSemana(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

DateTime sumarDias(DateTime d, int dias) =>
    DateTime(d.year, d.month, d.day + dias);

String _dos(int n) => n.toString().padLeft(2, '0');

String claveFecha(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_dos(d.month)}-${_dos(d.day)}';

DateTime desdeClave(String clave) {
  final p = clave.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String fechaCorta(DateTime d) => '${d.day} ${meses[d.month - 1]}';

String rangoSemana(DateTime inicio) {
  final fin = sumarDias(inicio, 6);
  return '${fechaCorta(inicio)} – ${fechaCorta(fin)} ${fin.year}';
}

/// Formato de dinero: $ 12.500
String dinero(int valor) {
  final negativo = valor < 0;
  final s = valor.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${negativo ? '-' : ''}\$ $buf';
}

/// Convierte texto como "12.500" o "12500" a entero.
int? leerDinero(String texto) {
  final limpio = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (limpio.isEmpty) return null;
  return int.tryParse(limpio);
}

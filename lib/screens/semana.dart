import 'package:flutter/material.dart';

import '../store.dart';
import '../utils.dart';

class SemanaScreen extends StatefulWidget {
  const SemanaScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<SemanaScreen> createState() => _SemanaScreenState();
}

class _SemanaScreenState extends State<SemanaScreen> {
  DateTime _inicio = inicioSemana(DateTime.now());

  /// Persona elegida en la lista de arriba.
  String? _personaId;

  AppStore get store => widget.store;

  /// La persona elegida, o la primera si no hay ninguna elegida (o se borró).
  Persona get _persona =>
      store.persona(_personaId ?? '') ?? store.personas.first;

  void _moverSemana(int semanas) =>
      setState(() => _inicio = sumarDias(_inicio, 7 * semanas));

  @override
  Widget build(BuildContext context) {
    final esActual = _inicio == inicioSemana(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes de la semana'),
        actions: [
          if (!esActual)
            TextButton(
              onPressed: () =>
                  setState(() => _inicio = inicioSemana(DateTime.now())),
              child: const Text('Hoy'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Semana anterior',
                onPressed: () => _moverSemana(-1),
              ),
              Text(
                rangoSemana(_inicio),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Semana siguiente',
                onPressed: () => _moverSemana(1),
              ),
            ],
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => _contenido(context),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    if (store.personas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Primero agrega a alguien en la pestaña "Personas".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final cerrada = store.semanaCerrada(_inicio);
    final hoy = soloFecha(DateTime.now());
    final persona = _persona;
    final conteo = store.conteoSemana(_inicio);
    return Column(
      children: [
        _selectorPersonas(context, persona, conteo),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              if (cerrada != null) _avisoCerrada(context, cerrada),
              _encabezadoPersona(context, persona, conteo[persona.id] ?? 0),
              if (persona.tarifas.length > 1) _leyendaTarifas(context, persona),
              for (var i = 0; i < 7; i++)
                _filaDia(
                  context,
                  sumarDias(_inicio, i),
                  i,
                  persona,
                  esHoy: sumarDias(_inicio, i) == hoy,
                  bloqueada: cerrada != null,
                ),
              const SizedBox(height: 8),
              _resumen(context, cerrada),
            ],
          ),
        ),
      ],
    );
  }

  /// Lista deslizable con las personas; se toca una para ver sus viajes.
  Widget _selectorPersonas(
      BuildContext context, Persona elegida, Map<String, int> conteo) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: store.personas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = store.personas[i];
          final n = conteo[p.id] ?? 0;
          return ChoiceChip(
            avatar: CircleAvatar(
              child: Text(p.nombre.characters.first.toUpperCase()),
            ),
            label: Text(n > 0 ? '${p.nombre} ($n)' : p.nombre),
            selected: p.id == elegida.id,
            onSelected: (_) => setState(() => _personaId = p.id),
          );
        },
      ),
    );
  }

  Widget _encabezadoPersona(BuildContext context, Persona p, int viajes) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: tt.titleLarge),
                if (p.tarifas.length == 1)
                  Text('${dinero(p.tarifas.first.valor)} por viaje',
                      style: tt.bodyMedium?.copyWith(color: cs.outline)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$viajes ${viajes == 1 ? 'viaje' : 'viajes'}',
                  style: tt.bodyMedium?.copyWith(color: cs.outline)),
              Text(dinero(store.montoSemana(_inicio, p)),
                  style: tt.titleMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avisoCerrada(BuildContext context, SemanaCerrada s) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Semana cerrada'),
        subtitle: Text('Se pasaron ${dinero(s.total)} a la cuenta.'),
        trailing: TextButton(
          onPressed: () => _reabrir(context),
          child: const Text('Reabrir'),
        ),
      ),
    );
  }

  /// Las tarifas de la persona, cuántos viajes lleva de cada una.
  Widget _leyendaTarifas(BuildContext context, Persona p) {
    final c = store.conteoTarifas(_inicio, p);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final t in p.tarifas)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                  '${t.etiqueta} ${dinero(t.valor)} · ${c[t.id] ?? 0}'),
            ),
        ],
      ),
    );
  }

  Widget _filaDia(
    BuildContext context,
    DateTime dia,
    int indice,
    Persona p, {
    required bool esHoy,
    required bool bloqueada,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(diasSemana[indice], style: tt.titleMedium),
        Text(
          esHoy ? '${fechaCorta(dia)} · Hoy' : fechaCorta(dia),
          style: tt.bodySmall?.copyWith(color: esHoy ? cs.primary : cs.outline),
        ),
      ],
    );
    final unaSola = p.tarifas.length == 1;
    return Card(
      shape: esHoy
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, unaSola ? 4 : 10, 4, 4),
        child: unaSola
            ? Row(
                children: [
                  Expanded(child: titulo),
                  ..._contador(context, dia, p, p.tarifas.first, bloqueada),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titulo,
                  for (final t in p.tarifas)
                    Row(
                      children: [
                        Expanded(
                          child: Text('${t.etiqueta}  ·  ${dinero(t.valor)}'),
                        ),
                        ..._contador(context, dia, p, t, bloqueada),
                      ],
                    ),
                ],
              ),
      ),
    );
  }

  List<Widget> _contador(BuildContext context, DateTime dia, Persona p,
      Tarifa t, bool bloqueada) {
    final tt = Theme.of(context).textTheme;
    final n = store.viajesDe(dia, p.id, t.id);
    return [
      IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        tooltip: 'Quitar viaje',
        onPressed: bloqueada || n == 0
            ? null
            : () => store.cambiarViajes(dia, p.id, t.id, -1),
      ),
      SizedBox(
        width: 28,
        child: Text(
          '$n',
          textAlign: TextAlign.center,
          style: tt.titleMedium?.copyWith(
            fontWeight: n > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Agregar viaje',
        onPressed:
            bloqueada ? null : () => store.cambiarViajes(dia, p.id, t.id, 1),
      ),
    ];
  }

  Widget _resumen(BuildContext context, SemanaCerrada? cerrada) {
    final tt = Theme.of(context).textTheme;
    var total = 0;
    final filas = <Widget>[];
    for (final p in store.personas) {
      final c = store.conteoTarifas(_inicio, p);
      if (c.isEmpty) continue;
      final monto = store.montoSemana(_inicio, p);
      total += monto;
      final partes = [
        for (final t in p.tarifas)
          if ((c[t.id] ?? 0) > 0)
            p.tarifas.length == 1
                ? '${c[t.id]} × ${dinero(t.valor)}'
                : '${c[t.id]} × ${t.etiqueta}',
      ];
      filas.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre),
                  Text(partes.join(', '), style: tt.bodySmall),
                ],
              ),
            ),
            Text(dinero(monto),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumen de la semana (todos)', style: tt.titleMedium),
            const SizedBox(height: 8),
            if (filas.isEmpty)
              const Text('Todavía no hay viajes esta semana.')
            else
              ...filas,
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: Text('Te deben', style: tt.titleMedium)),
                Text(dinero(total), style: tt.titleLarge),
              ],
            ),
            if (cerrada == null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: total == 0 ? null : () => _cerrar(context, total),
                icon: const Icon(Icons.check),
                label: const Text('Cerrar semana y pasar a la cuenta'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cerrar(BuildContext context, int total) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar la semana?'),
        content: Text(
            'Se sumarán ${dinero(total)} a tu cuenta. Puedes reabrirla si te equivocas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar semana'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final sumado = store.cerrarSemana(_inicio);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Se sumaron ${dinero(sumado)} a tu cuenta.')),
    );
  }

  Future<void> _reabrir(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Reabrir la semana?'),
        content: const Text(
            'Lo que se había pasado a la cuenta por esta semana se quitará, '
            'y podrás corregir los viajes y volver a cerrarla.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );
    if (ok == true) store.reabrirSemana(_inicio);
  }
}

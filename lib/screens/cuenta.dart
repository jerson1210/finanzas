import 'package:flutter/material.dart';

import '../store.dart';
import '../utils.dart';

class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => _contenido(context),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final historial = _historial(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Te deben en total',
                    style: tt.titleMedium
                        ?.copyWith(color: cs.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text(
                  dinero(store.saldoTotal),
                  style: tt.displaySmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Por persona', style: tt.titleMedium),
        const SizedBox(height: 4),
        if (store.personas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aún no has agregado personas.'),
          ),
        for (final p in store.personas)
          Card(
            child: ListTile(
              title: Text(p.nombre),
              subtitle: Text('Debe ${dinero(store.saldoDe(p.id))}'),
              trailing: FilledButton.tonal(
                onPressed: store.saldoDe(p.id) <= 0
                    ? null
                    : () => _registrarPago(context, p),
                child: const Text('Pagó'),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Historial', style: tt.titleMedium),
        const SizedBox(height: 4),
        if (historial.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
                'Cuando cierres una semana o registres un pago, aparecerá aquí.'),
          ),
        ...historial,
      ],
    );
  }

  List<Widget> _historial(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <(DateTime, Widget)>[];

    for (final s in store.semanasCerradas) {
      items.add((
        s.cerradaEl,
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.calendar_month),
            title: Text('Semana ${rangoSemana(desdeClave(s.inicio))}'),
            subtitle: Text('+ ${dinero(s.total)}'),
            shape: const Border(),
            children: [
              for (final l in s.lineas)
                ListTile(
                  dense: true,
                  title: Text(l.nombre),
                  subtitle: Text(l.detalle.isNotEmpty
                      ? l.detalle
                      : '${l.viajes} ${l.viajes == 1 ? 'viaje' : 'viajes'}'),
                  trailing: Text(dinero(l.monto)),
                ),
            ],
          ),
        ),
      ));
    }

    for (final p in store.pagos) {
      final nombre = store.persona(p.personaId)?.nombre ?? 'Alguien';
      items.add((
        p.fecha,
        Card(
          child: ListTile(
            leading: Icon(Icons.payments_outlined, color: cs.tertiary),
            title: Text('Pago de $nombre'),
            subtitle: Text(fechaCorta(p.fecha)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('- ${dinero(p.monto)}'),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Borrar pago',
                  onPressed: () => _borrarPago(context, p, nombre),
                ),
              ],
            ),
          ),
        ),
      ));
    }

    items.sort((a, b) => b.$1.compareTo(a.$1));
    return items.map((e) => e.$2).toList();
  }

  Future<void> _registrarPago(BuildContext context, Persona p) async {
    final monto = await showDialog<int>(
      context: context,
      builder: (_) => _DialogoPago(persona: p, saldo: store.saldoDe(p.id)),
    );
    if (monto != null && monto > 0) store.registrarPago(p.id, monto);
  }

  Future<void> _borrarPago(BuildContext context, Pago p, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar este pago?'),
        content: Text(
            'El pago de $nombre por ${dinero(p.monto)} se quitará y volverá a la deuda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true) store.borrarPago(p);
  }
}

class _DialogoPago extends StatefulWidget {
  const _DialogoPago({required this.persona, required this.saldo});

  final Persona persona;
  final int saldo;

  @override
  State<_DialogoPago> createState() => _DialogoPagoState();
}

class _DialogoPagoState extends State<_DialogoPago> {
  late final _monto = TextEditingController(text: widget.saldo.toString());

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _guardar() => Navigator.pop(context, leerDinero(_monto.text));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pago de ${widget.persona.nombre}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Debe ${dinero(widget.saldo)}. ¿Cuánto te pagó?'),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '\$ '),
            onSubmitted: (_) => _guardar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Registrar')),
      ],
    );
  }
}

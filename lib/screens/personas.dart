import 'package:flutter/material.dart';

import '../store.dart';
import '../utils.dart';

class PersonasScreen extends StatelessWidget {
  const PersonasScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.personas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Agrega a las personas que llevas\n(por ejemplo, tu prima) '
                  'y cuánto cobras por viaje.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final p in store.personas)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(p.nombre.characters.first.toUpperCase()),
                  ),
                  title: Text(p.nombre),
                  subtitle: Text(_textoTarifas(p)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar',
                    onPressed: () => _borrar(context, p),
                  ),
                  onTap: () => _abrirFormulario(context, p),
                ),
            ],
          );
        },
      ),
    );
  }

  String _textoTarifas(Persona p) {
    if (p.tarifas.length == 1) {
      return '${dinero(p.tarifas.first.valor)} por viaje';
    }
    return p.tarifas.map((t) => '${t.etiqueta} ${dinero(t.valor)}').join(' · ');
  }

  Future<void> _abrirFormulario(BuildContext context, [Persona? p]) async {
    final res = await showDialog<(String, List<Tarifa>)>(
      context: context,
      builder: (_) => _FormPersona(persona: p),
    );
    if (res == null) return;
    if (p == null) {
      store.agregarPersona(res.$1, res.$2);
      return;
    }
    final error = store.editarPersona(p, res.$1, res.$2);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _borrar(BuildContext context, Persona p) async {
    final saldo = store.saldoDe(p.id);
    if (saldo != 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${p.nombre} todavía tiene ${dinero(saldo)} pendiente en la cuenta.'),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar a ${p.nombre}?'),
        content: const Text('También se borran sus viajes sin cerrar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) store.borrarPersona(p);
  }
}

/// Una fila del formulario: nombre y valor de una tarifa.
class _FilaTarifa {
  _FilaTarifa({required this.id, String nombre = '', String valor = ''})
      : nombre = TextEditingController(text: nombre),
        valor = TextEditingController(text: valor);

  final String id;
  final TextEditingController nombre;
  final TextEditingController valor;

  void dispose() {
    nombre.dispose();
    valor.dispose();
  }
}

class _FormPersona extends StatefulWidget {
  const _FormPersona({this.persona});

  final Persona? persona;

  @override
  State<_FormPersona> createState() => _FormPersonaState();
}

class _FormPersonaState extends State<_FormPersona> {
  late final _nombre = TextEditingController(text: widget.persona?.nombre);
  late final List<_FilaTarifa> _filas = widget.persona == null
      ? [_FilaTarifa(id: _nuevoId())]
      : [
          for (final t in widget.persona!.tarifas)
            _FilaTarifa(id: t.id, nombre: t.nombre, valor: t.valor.toString()),
        ];
  String? _error;
  int _contador = 0;

  String _nuevoId() =>
      't${DateTime.now().microsecondsSinceEpoch}_${_contador++}';

  @override
  void dispose() {
    _nombre.dispose();
    for (final f in _filas) {
      f.dispose();
    }
    super.dispose();
  }

  void _agregarTarifa() =>
      setState(() => _filas.add(_FilaTarifa(id: _nuevoId())));

  void _quitarTarifa(_FilaTarifa f) => setState(() {
        _filas.remove(f);
        f.dispose();
      });

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe un nombre');
      return;
    }
    final varias = _filas.length > 1;
    final tarifas = <Tarifa>[];
    for (var i = 0; i < _filas.length; i++) {
      final f = _filas[i];
      final valor = leerDinero(f.valor.text);
      if (valor == null) {
        setState(() => _error = varias
            ? 'Escribe cuánto cobras en la tarifa ${i + 1}'
            : 'Escribe cuánto cobras por viaje');
        return;
      }
      var etiqueta = f.nombre.text.trim();
      if (varias && etiqueta.isEmpty) etiqueta = 'Tarifa ${i + 1}';
      tarifas.add(Tarifa(id: f.id, nombre: etiqueta, valor: valor));
    }
    Navigator.pop(context, (nombre, tarifas));
  }

  @override
  Widget build(BuildContext context) {
    final varias = _filas.length > 1;
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.persona == null ? 'Nueva persona' : 'Editar persona'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nombre,
              autofocus: widget.persona == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 20),
            Text(varias ? 'Tarifas' : 'Cobro por viaje', style: tt.titleSmall),
            for (var i = 0; i < _filas.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (varias) ...[
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: _filas[i].nombre,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Tarifa ${i + 1}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _filas[i].valor,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                          prefixText: '\$ ',
                        ),
                      ),
                    ),
                    if (varias)
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Quitar tarifa',
                        onPressed: () => _quitarTarifa(_filas[i]),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _agregarTarifa,
                icon: const Icon(Icons.add),
                label: const Text('Agregar otra tarifa'),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finanzas/main.dart';
import 'package:finanzas/store.dart';
import 'package:finanzas/utils.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cerrar semana suma a la cuenta y los pagos restan', () async {
    final store = AppStore();
    await store.cargar();
    store.agregarPersona(
        'Prima', [Tarifa(id: 't1', nombre: '', valor: 5000)]);
    final prima = store.personas.first;
    final lunes = inicioSemana(DateTime(2026, 11, 4));

    store.cambiarViajes(lunes, prima.id, 't1', 1);
    store.cambiarViajes(sumarDias(lunes, 2), prima.id, 't1', 2);
    expect(store.conteoSemana(lunes)[prima.id], 3);

    expect(store.cerrarSemana(lunes), 15000);
    expect(store.saldoDe(prima.id), 15000);
    expect(store.cerrarSemana(lunes), 0); // no se cierra dos veces

    store.registrarPago(prima.id, 10000);
    expect(store.saldoTotal, 5000);

    // Los datos se guardan y se vuelven a cargar.
    final otra = AppStore();
    await otra.cargar();
    expect(otra.saldoDe(prima.id), 5000);
  });

  test('una persona con varias tarifas', () async {
    final store = AppStore();
    await store.cargar();
    store.agregarPersona('Prima', [
      Tarifa(id: 'c', nombre: 'Corto', valor: 5000),
      Tarifa(id: 'l', nombre: 'Largo', valor: 8000),
    ]);
    final prima = store.personas.first;
    final lunes = inicioSemana(DateTime(2026, 11, 4));
    store.cambiarViajes(lunes, prima.id, 'c', 2);
    store.cambiarViajes(sumarDias(lunes, 1), prima.id, 'l', 1);

    expect(store.conteoSemana(lunes)[prima.id], 3);
    expect(store.montoSemana(lunes, prima), 18000);

    // No se puede borrar una tarifa que ya tiene viajes.
    expect(store.editarPersona(prima, 'Prima', [prima.tarifas.first]),
        isNotNull);

    expect(store.cerrarSemana(lunes), 18000);
    expect(store.semanasCerradas.first.lineas.first.detalle,
        '2 × Corto, 1 × Largo');
  });

  test('los datos viejos (una tarifa) se siguen leyendo', () async {
    SharedPreferences.setMockInitialValues({
      'finanzas_datos_v1':
          '{"personas":[{"id":"p1","nombre":"Prima","tarifa":5000}],'
              '"viajes":{"2026-11-02":{"p1":3}}}',
    });
    final store = AppStore();
    await store.cargar();
    final prima = store.personas.first;
    expect(prima.tarifas.single.valor, 5000);
    expect(store.montoSemana(DateTime(2026, 11, 2), prima), 15000);
  });

  test('formato de dinero', () {
    expect(dinero(0), '\$ 0');
    expect(dinero(5000), '\$ 5.000');
    expect(dinero(1234567), '\$ 1.234.567');
    expect(leerDinero('12.500'), 12500);
  });

  testWidgets('la app abre en la semana', (tester) async {
    final store = AppStore();
    await store.cargar();
    await tester.pumpWidget(FinanzasApp(store: store));
    expect(find.text('Viajes de la semana'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();
    expect(find.text('Agregar'), findsOneWidget);
  });
}

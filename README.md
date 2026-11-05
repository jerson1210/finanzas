# 🚗 Mis viajes

App para Android que lleva la cuenta de los viajes que le haces a otras personas
y de cuánto te deben, semana a semana.

¿Llevas a tu prima al trabajo, a un amigo a la universidad o a los niños al colegio?
Anotas cada viaje con un toque y la app hace las cuentas por ti.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-app-3DDC84?logo=android&logoColor=white)

---

## ✨ Qué hace

| | |
|---|---|
| 👥 **Personas con varias tarifas** | Cada persona puede tener una o varias tarifas, por ejemplo *Corto* $5.000 y *Largo* $8.000. |
| 📅 **Viajes de la semana** | Eliges a la persona y marcas con **−** y **+** los viajes de cada día, de lunes a domingo. |
| 🧮 **Cuentas automáticas** | Ves al instante cuántos viajes lleva cada uno y cuánto te debe esa semana. |
| 🔒 **Cerrar semana** | Al terminar la semana pasas lo que te deben a la cuenta. Si te equivocaste, la puedes reabrir. |
| 💰 **Cuenta y pagos** | Llevas el saldo de cada persona, registras lo que te van pagando y ves el historial. |
| 📱 **Sin internet** | Todo se guarda en el celular. No necesitas cuenta ni conexión. |

## 🧭 Cómo se usa

1. **Personas**: agrega a quien llevas y cuánto cobras por viaje.
   Si tienes varios precios, usa **"Agregar otra tarifa"**.
2. **Semana**: toca a la persona en la lista de arriba y suma sus viajes en cada día.
3. **Cerrar semana**: al final de la semana toca **"Cerrar semana y pasar a la cuenta"**.
4. **Cuenta**: cuando te paguen, registra el pago y el saldo se actualiza solo.

## 🗂️ Estructura del proyecto

```
lib/
├── main.dart            # Arranque de la app y barra de pestañas
├── store.dart           # Datos, cálculos y guardado en el celular
├── utils.dart           # Fechas y formato de dinero ($ 12.500)
└── screens/
    ├── semana.dart      # Pestaña Semana: viajes por día
    ├── cuenta.dart      # Pestaña Cuenta: saldos y pagos
    └── personas.dart    # Pestaña Personas: nombres y tarifas
test/
└── widget_test.dart     # Pruebas automáticas
```

## 🛠️ Cómo correrla

Necesitas tener instalado [Flutter](https://docs.flutter.dev/get-started/install).

```bash
# Descargar las dependencias
flutter pub get

# Abrir la app en el celular o el emulador conectado
flutter run

# Generar el instalador (APK) para Android
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

Para correr las pruebas:

```bash
flutter test
```

## 📦 Tecnologías

- **Flutter** con Material 3 (con modo claro y oscuro)
- **shared_preferences** para guardar los datos en el celular

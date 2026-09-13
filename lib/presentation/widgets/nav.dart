import 'package:flutter/material.dart';

/// Navegación imperativa mínima: sin paquetes de rutas.
Future<T?> pushScreen<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

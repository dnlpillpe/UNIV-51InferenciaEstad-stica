import 'package:flutter/material.dart';

/// Traduce los nombres de icono del contenido JSON a iconos de Material.
IconData iconFor(String name) {
  switch (name) {
    case 'groups':
      return Icons.groups_rounded;
    case 'stacked':
      return Icons.stacked_bar_chart_rounded;
    case 'interval':
      return Icons.straighten_rounded;
    case 'gavel':
      return Icons.gavel_rounded;
    case 'decision':
      return Icons.fact_check_rounded;
    case 'city':
      return Icons.location_city_rounded;
    case 'machine':
      return Icons.precision_manufacturing_rounded;
    case 'rain':
      return Icons.water_drop_rounded;
    case 'world':
      return Icons.public_rounded;
    case 'room':
      return Icons.meeting_room_rounded;
    case 'terrain':
      return Icons.terrain_rounded;
    case 'water':
      return Icons.water_rounded;
    case 'click':
      return Icons.ads_click_rounded;
    case 'memory':
      return Icons.memory_rounded;
    case 'storefront':
      return Icons.storefront_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'receipt':
      return Icons.receipt_long_rounded;
    case 'psychology':
      return Icons.psychology_rounded;
    case 'eco':
      return Icons.eco_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'bedtime':
      return Icons.bedtime_rounded;
    default:
      return Icons.insights_rounded;
  }
}

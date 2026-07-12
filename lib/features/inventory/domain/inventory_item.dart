import 'package:docentral/features/inventory/domain/inventory_category.dart';

/// Domain-facing inventory item model, decoupled from Drift's generated
/// row class for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.onHandQuantity,
    required this.lowStockThreshold,
  });

  final String id;
  final String name;
  final InventoryCategory category;
  final String unit;
  final int onHandQuantity;
  final int lowStockThreshold;

  bool get isLowStock => onHandQuantity <= lowStockThreshold;
}

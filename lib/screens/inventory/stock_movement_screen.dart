// Stock movement history screen with timeline audit trail.

import 'package:flutter/material.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../widgets/catalog/stock_badge_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/common/vynex_card.dart';

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key, required this.productId});

  final int productId;

  @override
  State<StockMovementScreen> createState() =>
      _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  Product? _product;
  List<StockMovement> _allMovements = [];
  String _typeFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final product = await db.getProductById(widget.productId);
      final movements = await db.getStockMovements(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _allMovements = movements;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StockMovement> get _filteredMovements {
    if (_typeFilter == 'all') return _allMovements;
    return _allMovements
        .where((m) => m.movementType == _typeFilter)
        .toList();
  }

  int get _totalIn {
    return _allMovements
        .where((m) => m.quantity > 0)
        .fold(0, (sum, m) => sum + m.quantity);
  }

  int get _totalOut {
    return _allMovements
        .where((m) => m.quantity < 0)
        .fold(0, (sum, m) => sum + m.quantity.abs());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Stock History',
          showBack: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final product = _product;
    if (product == null) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: VynexAppBar(
          title: 'Stock History',
          showBack: true,
        ),
        body: Center(child: Text('Product not found')),
      );
    }

    final movements = _filteredMovements;
    final unit = product.unit;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const VynexAppBar(
        title: 'Stock History',
        showBack: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: VynexCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  StockBadgeWidget(product: product),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _summaryStat(
                  'Total Movements',
                  '${_allMovements.length}',
                  AppColors.black,
                ),
                const SizedBox(width: 16),
                _summaryStat(
                  'Total In',
                  '+$_totalIn',
                  AppColors.success,
                ),
                const SizedBox(width: 16),
                _summaryStat(
                  'Total Out',
                  '-$_totalOut',
                  AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('All', 'all'),
                _filterChip('Restocked', 'restock'),
                _filterChip('Sold', 'sale'),
                _filterChip('Adjusted', 'adjustment'),
                _filterChip('Initial', 'initial'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: movements.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.history_rounded,
                    title: 'No stock history yet',
                    subtitle: 'Stock movements appear here when you '
                        'restock, sell or adjust this product',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      return _MovementTimelineItem(
                        movement: movements[index],
                        unit: unit,
                        isLast: index == movements.length - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.midGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _typeFilter = value),
        selectedColor: AppColors.gold.withValues(alpha: 0.3),
        checkmarkColor: AppColors.black,
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? AppColors.black : AppColors.midGrey,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        ),
        side: BorderSide(
          color: selected ? AppColors.gold : AppColors.lightGrey,
        ),
      ),
    );
  }
}

class _MovementTimelineItem extends StatelessWidget {
  const _MovementTimelineItem({
    required this.movement,
    required this.unit,
    required this.isLast,
  });

  final StockMovement movement;
  final String unit;
  final bool isLast;

  Color get _dotColor {
    switch (movement.movementType) {
      case 'restock':
      case 'initial':
        return AppColors.success;
      case 'sale':
        return AppColors.danger;
      case 'adjustment':
        return movement.quantity > 0
            ? AppColors.info
            : AppColors.warning;
      default:
        return AppColors.midGrey;
    }
  }

  Color get _qtyColor =>
      movement.quantity >= 0 ? AppColors.success : AppColors.danger;

  String get _qtyText {
    if (movement.quantity > 0) {
      return '+${movement.quantity} ${unit}s';
    }
    return '${movement.quantity} ${unit}s';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dotColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.lightGrey,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        movement.typeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _qtyText,
                        style: TextStyle(
                          color: _qtyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _buildSubtitle(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.midGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (movement.referenceType == 'sale')
                        _referencePill('SALE', AppColors.teal)
                      else if (movement.referenceType == 'purchase')
                        _referencePill('PURCHASE', AppColors.gold),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final date = Formatters.formatDate(movement.dateRecorded);
    if (movement.note != null && movement.note!.isNotEmpty) {
      return '$date | ${movement.note}';
    }
    return date;
  }

  Widget _referencePill(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

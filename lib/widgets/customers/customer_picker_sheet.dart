// customer_picker_sheet.dart
// Bottom sheet for searching and selecting a customer.
// Returns selected Customer or null if cancelled.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database_helper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/customer.dart';
import '../common/empty_state_widget.dart';

class CustomerPickerSheet extends StatefulWidget {
  const CustomerPickerSheet({super.key});

  static Future<Customer?> show(BuildContext context) async {
    return showModalBottomSheet<Customer?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.70,
        child: const CustomerPickerSheet(),
      ),
    );
  }

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  final _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filtered = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      _allCustomers = await DatabaseHelper().getCustomers();
      _applyFilter(_query);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String query) {
    _query = query;
    if (query.trim().isEmpty) {
      _filtered = List.from(_allCustomers);
    } else {
      final lower = query.toLowerCase();
      _filtered = _allCustomers
          .where(
            (c) =>
                c.name.toLowerCase().contains(lower) ||
                (c.phone?.toLowerCase().contains(lower) ?? false) ||
                (c.email?.toLowerCase().contains(lower) ?? false),
          )
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.midGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Customer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.black,
                    ),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.search,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by name or phone...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: _applyFilter,
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            InkWell(
              onTap: () {
                Navigator.pop(context, null);
                context.push(AppRoutes.addCustomer);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Add New Customer',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                      ),
                    )
                  : _allCustomers.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.people_outline_rounded,
                          title: 'No customers yet',
                          subtitle:
                              'Add your first customer to link sales.',
                        )
                      : _filtered.isEmpty
                          ? const EmptyStateWidget(
                              icon: Icons.search_off_rounded,
                              title: 'No customers found',
                              subtitle: 'Try a different search term',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                16,
                              ),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final customer = _filtered[index];
                                final initial =
                                    customer.name.isNotEmpty
                                        ? customer.name[0].toUpperCase()
                                        : '?';
                                return Material(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => Navigator.pop(
                                      context,
                                      customer,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.gold
                                                  .withValues(alpha: 0.15),
                                              border: Border.all(
                                                color: AppColors.gold,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                color: AppColors.gold,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  customer.name,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (customer.phone != null &&
                                                    customer
                                                        .phone!.isNotEmpty)
                                                  Text(
                                                    customer.phone!,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.midGrey,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

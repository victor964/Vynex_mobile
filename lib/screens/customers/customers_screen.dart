// Customers list screen with search, summary and customer cards.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/vynex_app_bar.dart';
import '../../widgets/customers/customer_list_item.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    await context.read<CustomerProvider>().loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: VynexAppBar(
        title: 'Customers',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_rounded,
              color: AppColors.gold,
            ),
            onPressed: () => context.push(AppRoutes.addCustomer),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        onPressed: () => context.push(AppRoutes.addCustomer),
        child: const Icon(Icons.person_add_rounded),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.customers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _onRefresh,
            child: Column(
              children: [
                _buildSummaryStrip(provider),
                _buildSearchBar(provider),
                Expanded(child: _buildCustomerList(provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryStrip(CustomerProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text(
            '${provider.totalCustomers} Customers',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.gold,
            ),
          ),
          const Spacer(),
          if (provider.customersWithDebt > 0)
            Text(
              '${provider.customersWithDebt} with outstanding debts',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CustomerProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                Icons.person_search,
                color: AppColors.gold,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: provider.setSearchQuery,
              ),
            ),
            if (provider.searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.gold,
                  size: 20,
                ),
                onPressed: provider.clearSearch,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(CustomerProvider provider) {
    final customers = provider.filteredCustomers;
    final hasSearch = provider.searchQuery.isNotEmpty;

    if (customers.isEmpty && hasSearch) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'No customers found',
            subtitle: 'Try searching by name or phone number',
          ),
        ],
      );
    }

    if (customers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyStateWidget(
            icon: Icons.people_outline_rounded,
            title: 'No customers yet',
            subtitle: 'Add customers to track their purchase '
                'history and link sales to them',
            actionLabel: 'Add First Customer',
            onAction: () => context.push(AppRoutes.addCustomer),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return CustomerListItem(
          customer: customer,
          lastPurchaseDate:
              provider.lastPurchaseDates[customer.id],
          hasOutstandingDebt:
              provider.customerHasOutstandingDebt(customer.id!),
        );
      },
    );
  }
}

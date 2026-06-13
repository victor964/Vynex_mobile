// Settings screen with profile, backup, restore, and security.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/debug_log.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/backup_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/business_settings.dart';
import '../../core/utils/category_icons.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/vynex_button.dart';
import '../../widgets/common/vynex_card.dart';
import '../../widgets/catalog/category_sheets.dart';
import '../../widgets/common/vynex_text_field.dart';

/// Business settings, backup, restore, and security screen.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currencyController = TextEditingController();
  final _taglineController = TextEditingController();

  bool _isSaving = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _restoreFileName;
  bool _controllersReady = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final cached = context.read<SettingsProvider>().settings;
    if (cached != null) {
      _populateFromSettings(cached);
      _controllersReady = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndPopulate();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _currencyController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  Future<void> _loadAndPopulate() async {
    final provider = context.read<SettingsProvider>();
    final hadCache = provider.settings != null;

    try {
      await provider.loadSettings(showLoading: !hadCache);
    } catch (e) {
      logDebug('Settings screen load error: $e');
    }

    if (!mounted) return;

    final settings = provider.settings;
    if (settings == null) {
      setState(() {
        _loadFailed = true;
        _controllersReady = true;
      });
      return;
    }

    _populateFromSettings(settings);
    setState(() {
      _controllersReady = true;
      _loadFailed = false;
    });
  }

  void _populateFromSettings(BusinessSettings? settings) {
    if (settings == null) return;
    _businessNameController.text = settings.businessName;
    _ownerNameController.text = settings.ownerName;
    _phoneController.text = settings.phoneNumber;
    _currencyController.text = settings.currencyLabel;
    _taglineController.text = settings.businessTagline;
  }

  void _onFieldChanged() {
    setState(() {});
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SettingsProvider>();
    if (provider.settings == null) return;

    setState(() => _isSaving = true);

    final updated = provider.settings!.copyWith(
      businessName: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      currencyLabel: _currencyController.text.trim(),
      businessTagline: _taglineController.text.trim(),
    );

    final success = await provider.updateSettings(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        'Settings saved successfully',
      );
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to save settings',
      );
    }
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    final success = await BackupService.backupDatabase();
    if (!mounted) return;
    setState(() => _isBackingUp = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        'Backup ready. Choose where to save it.',
      );
    } else {
      SnackBarHelper.showError(
        context,
        'Backup failed. Please try again.',
      );
    }
  }

  Future<void> _performRestore() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Restore Database',
      message: 'This will replace ALL your current data '
          'with the selected backup file. '
          'This cannot be undone. Continue?',
      confirmLabel: 'Yes, Restore',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    setState(() {
      _isRestoring = true;
      _restoreFileName = p.basename(filePath);
    });

    final restoreResult = await BackupService.restoreDatabase(filePath);

    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (restoreResult.success) {
      await context.read<SettingsProvider>().loadSettings();
      if (!mounted) return;
      await context.read<PurchaseProvider>().loadPurchases();
      if (!mounted) return;
      await context.read<SaleProvider>().loadSales();
      if (!mounted) return;
      await context.read<DebtProvider>().loadDebts();
      if (!mounted) return;
      await context.read<ReportProvider>().loadReport();
      if (!mounted) return;
      _populateFromSettings(context.read<SettingsProvider>().settings);
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(context, restoreResult.message);
      context.go(AppRoutes.dashboard);
    } else {
      SnackBarHelper.showError(context, restoreResult.message);
    }
  }

  Future<void> _onLockApp() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Lock App?',
      message: 'You will return to the PIN login screen.',
      confirmLabel: 'Lock',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _onResetSettings() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset Settings',
      message: 'Reset all business profile information '
          'to default values? Your PIN and data '
          'are not affected.',
      confirmLabel: 'Reset',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.resetToDefaults();

    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      _populateFromSettings(provider.settings);
      setState(() {});
      SnackBarHelper.showSuccess(context, 'Settings reset');
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to reset settings',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        automaticallyImplyLeading: false,
        title: Text(
          settings.businessName,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: !_controllersReady
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _loadFailed
              ? _buildLoadErrorBody()
              : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileSection(),
                      const SizedBox(height: 12),
                      _buildCategoriesSection(),
                      const SizedBox(height: 12),
                      _buildPreviewSection(),
                      const SizedBox(height: 12),
                      _buildSecuritySection(),
                      const SizedBox(height: 12),
                      _buildDataManagementSection(),
                      const SizedBox(height: 12),
                      _buildDangerZone(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadErrorBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load settings. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            VynexButton.primary(
              label: 'Retry',
              isFullWidth: false,
              onPressed: () {
                setState(() {
                  _controllersReady = false;
                  _loadFailed = false;
                });
                _loadAndPopulate();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return VynexCard(
      hasAccent: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.person_rounded,
            title: 'Business Profile',
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                VynexTextField(
                  label: 'Business Name',
                  hint: 'e.g. Kamau General Store',
                  controller: _businessNameController,
                  onChanged: (_) => _onFieldChanged(),
                  validator: (v) =>
                      Validators.required(v, 'Business name'),
                ),
                const SizedBox(height: 12),
                VynexTextField(
                  label: 'Owner Name',
                  hint: 'e.g. James Kamau',
                  controller: _ownerNameController,
                  onChanged: (_) => _onFieldChanged(),
                ),
                const SizedBox(height: 12),
                VynexTextField(
                  label: 'Phone Number',
                  hint: 'e.g. 0712 345 678',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  onChanged: (_) => _onFieldChanged(),
                  validator: Validators.phoneNumber,
                ),
                const SizedBox(height: 12),
                VynexTextField(
                  label: 'Currency Label',
                  hint: 'e.g. KES',
                  controller: _currencyController,
                  onChanged: (_) => _onFieldChanged(),
                  validator: (v) =>
                      Validators.required(v, 'Currency label'),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'This label appears on all prices.',
                      style: TextStyle(
                        color: AppColors.midGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                VynexTextField(
                  label: 'Business Tagline (Optional)',
                  hint: 'e.g. Quality at Your Doorstep',
                  controller: _taglineController,
                  onChanged: (_) => _onFieldChanged(),
                ),
                const SizedBox(height: 16),
                VynexButton.primary(
                  label: 'Save Settings',
                  isLoading: _isSaving,
                  onPressed: _saveSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return VynexCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.local_offer_rounded,
            title: 'Product Categories',
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your product categories',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<CategoryProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.categories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }

              final categories = provider.categories;
              if (categories.isEmpty) {
                return const Text(
                  'No categories yet.',
                  style: TextStyle(color: AppColors.midGrey, fontSize: 13),
                );
              }

              return Column(
                children: [
                  for (final cat in categories)
                    _CategorySettingsRow(
                      category: cat,
                      onEdit: () => showEditCategoryBottomSheet(
                        context,
                        cat,
                      ),
                      onDelete: () => _deleteCategory(cat),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showAddCategoryBottomSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Category'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isPredefined) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Category?',
      message: 'Delete "${category.name}"? Products in this category '
          'will become uncategorized.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final success = await context.read<CategoryProvider>().deleteCategory(
          category.id!,
        );

    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(context, 'Category deleted');
    } else {
      SnackBarHelper.showError(context, 'Failed to delete category');
    }
  }

  Widget _buildPreviewSection() {
    final name = _businessNameController.text.trim().isEmpty
        ? 'Vynex'
        : _businessNameController.text.trim();
    final tagline = _taglineController.text.trim().isEmpty
        ? 'Business Manager'
        : _taglineController.text.trim();
    final owner = _ownerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final currency = _currencyController.text.trim().isEmpty
        ? 'KES'
        : _currencyController.text.trim();

    return VynexCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.preview_rounded,
            title: 'Live Preview',
            titleColor: AppColors.gold,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.midGrey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.gold, height: 1),
                const SizedBox(height: 8),
                _PreviewRow(label: 'Owner:', value: owner),
                _PreviewRow(label: 'Phone:', value: phone),
                _PreviewRow(
                  label: 'Currency:',
                  value: currency,
                  valueColor: AppColors.gold,
                  valueBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is how your business info appears on exports.',
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return VynexCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.lock_rounded,
            title: 'Security',
          ),
          _SettingsNavRow(
            icon: Icons.shield_rounded,
            title: 'Change PIN',
            subtitle: 'Update your 4-digit app PIN',
            onTap: () => context.push(AppRoutes.changePin),
          ),
          const Divider(color: AppColors.lightGrey, height: 1),
          _SettingsNavRow(
            icon: Icons.logout_rounded,
            title: 'Lock App',
            subtitle: 'Return to the PIN login screen',
            onTap: _onLockApp,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return VynexCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.storage_rounded,
            title: 'Data Management',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_download_outlined,
                color: AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Your Data',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Save a copy to WhatsApp, Telegram or Google Drive',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VynexButton.primary(
            label: 'Backup Now',
            icon: Icons.cloud_download_outlined,
            isLoading: _isBackingUp,
            onPressed: _performBackup,
          ),
          const SizedBox(height: 8),
          const Text(
            "File name includes today's date for easy tracking.",
            style: TextStyle(
              color: AppColors.midGrey,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.lightGrey, thickness: 2),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restore from Backup',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Replace current data with a backup file',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Warning: Restoring will replace ALL current data. '
                    'This cannot be undone.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _isRestoring ? null : _performRestore,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
              ),
              child: _isRestoring
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.warning,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Select Backup File'),
                      ],
                    ),
            ),
          ),
          if (_restoreFileName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Selected: $_restoreFileName',
              style: const TextStyle(
                color: AppColors.midGrey,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.restart_alt_rounded,
                color: AppColors.danger,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Settings to Default',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Restore business profile to defaults. '
                      'PIN is not affected.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _onResetSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 40),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable settings row with icon, title, and chevron.
class _SettingsNavRow extends StatelessWidget {
  const _SettingsNavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.titleColor = AppColors.black,
  });

  final IconData icon;
  final String title;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _CategorySettingsRow extends StatelessWidget {
  const _CategorySettingsRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            categoryIconFromName(category.iconName),
            color: categoryColorFromHex(category.colorHex),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
          ),
          if (category.isPredefined)
            const Text(
              'Default',
              style: TextStyle(
                color: AppColors.midGrey,
                fontSize: 11,
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 20,
              ),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.black,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.midGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight:
                    valueBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

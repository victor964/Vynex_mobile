// Bottom sheets for adding and editing product categories.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../common/vynex_button.dart';
import '../common/vynex_text_field.dart';

/// Preset swatch colors for custom categories.
const List<({String label, String hex})> categoryColorPresets = [
  (label: 'Gold', hex: 'FFD700'),
  (label: 'Green', hex: '4CAF50'),
  (label: 'Blue', hex: '2196F3'),
  (label: 'Orange', hex: 'FF5722'),
  (label: 'Purple', hex: '9C27B0'),
  (label: 'Teal', hex: '00BCD4'),
  (label: 'Red', hex: 'DC3545'),
  (label: 'Grey', hex: '607D8B'),
];

/// Shows a bottom sheet to add a new category.
Future<void> showAddCategoryBottomSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => const _CategoryFormSheet(),
  );
}

/// Shows a bottom sheet to edit an existing category.
Future<void> showEditCategoryBottomSheet(
  BuildContext context,
  Category category,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _CategoryFormSheet(category: category),
  );
}

/// Sentinel returned when user opens add-category from picker.
const int kCategoryPickerAddNew = -1;

/// Shows category picker for product forms.
Future<int?> showCategoryPickerSheet(
  BuildContext context, {
  int? selectedCategoryId,
  bool allowAddNew = true,
}) async {
  return showModalBottomSheet<int?>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return _CategoryPickerSheet(
        selectedCategoryId: selectedCategoryId,
        allowAddNew: allowAddNew,
      );
    },
  );
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final Category? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedHex = 'FFD700';
  bool _isSaving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedHex = widget.category!.colorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<CategoryProvider>();
    final categories = provider.categories;
    final maxSort = categories.isEmpty
        ? 0
        : categories.map((c) => c.sortOrder).reduce(
              (a, b) => a > b ? a : b,
            );

    bool success;
    if (_isEditing) {
      final updated = widget.category!.copyWith(
        name: _nameController.text.trim(),
        colorHex: _selectedHex,
      );
      success = await provider.updateCategory(updated);
    } else {
      final newCategory = Category(
        name: _nameController.text.trim(),
        colorHex: _selectedHex,
        iconName: 'category',
        sortOrder: maxSort + 1,
      );
      success = await provider.addCategory(newCategory);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.lightImpact();
      SnackBarHelper.showSuccess(
        context,
        _isEditing ? 'Category updated' : 'Category added',
      );
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(
        context,
        'Failed to save category',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Category' : 'Add Category',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 16),
            VynexTextField(
              label: 'Category Name',
              hint: 'e.g. Electronics',
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Category name'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Color',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categoryColorPresets.map((preset) {
                final color = categoryColorFromHex(preset.hex);
                final isSelected = _selectedHex == preset.hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedHex = preset.hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: isSelected
                          ? Border.all(color: AppColors.black, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            VynexButton.primary(
              label: _isEditing ? 'Save Changes' : 'Add Category',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    this.selectedCategoryId,
    this.allowAddNew = true,
  });

  final int? selectedCategoryId;
  final bool allowAddNew;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.black,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: AppColors.midGrey),
            title: const Text('None'),
            trailing: selectedCategoryId == null
                ? const Icon(Icons.check, color: AppColors.gold)
                : null,
            onTap: () => Navigator.pop(context, null),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat.id == selectedCategoryId;
                return ListTile(
                  leading: Icon(
                    categoryIconFromName(cat.iconName),
                    color: categoryColorFromHex(cat.colorHex),
                  ),
                  title: Text(cat.name),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.gold)
                      : null,
                  onTap: () => Navigator.pop(context, cat.id),
                );
              },
            ),
          ),
          if (allowAddNew) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppColors.gold,
              ),
              title: const Text(
                'Add New Category',
                style: TextStyle(color: AppColors.gold),
              ),
              onTap: () {
                Navigator.pop(context, kCategoryPickerAddNew);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

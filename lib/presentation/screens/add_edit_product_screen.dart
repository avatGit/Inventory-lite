import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:inventory_lite/data/models/product.dart';
import 'package:inventory_lite/providers/catalog_providers.dart';
import 'package:inventory_lite/features/barcode/presentation/screens/barcode_scanner_screen.dart';

/// Screen for creating a new product or editing an existing one.
/// When [product] is null, the screen operates in "create" mode.
class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();

  // --- State ---
  String? _selectedCategoryId;
  bool _isSaving = false;

  /// Whether we are editing an existing product or creating a new one.
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _stockController.text = product.currentStock.toString();
    _barcodeController.text = product.barcode ?? '';
    _selectedCategoryId = product.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // BARCODE SCANNER INTEGRATION

  /// Opens the barcode scanner and updates the barcode field with the result.
  Future<void> _scanBarcode() async {
    final scannedCode = await openBarcodeScanner(context);

    if (scannedCode != null && mounted) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
    }
  }

  // FORM VALIDATION & SUBMISSION

  /// Validates the form and saves the product to Firestore.
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(productRepositoryProvider);

      final product = Product(
        id: _isEditing ? widget.product!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        price: int.parse(_priceController.text.trim()),
        currentStock: _isEditing
            ? widget.product!.currentStock
            : int.parse(_stockController.text.trim()),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
      );

      if (_isEditing) {
        await repository.updateProduct(product);
      } else {
        await repository.addProduct(product);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Produit modifié avec succès'
                : 'Produit ajouté avec succès',
          ),
          backgroundColor: const Color(0xFF16A34A), // Success green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement : $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Scrollable Form ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Product Name ---
                      _buildSectionLabel('Informations du produit', theme),
                      const SizedBox(height: 12),
                      _buildNameField(),
                      const SizedBox(height: 16),

                      // --- Category Selector ---
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),

                      // --- Price & Stock Row ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPriceField()),
                          if (!_isEditing) ...[
                            const SizedBox(width: 16),
                            Expanded(child: _buildStockField()),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Barcode Section ---
                      _buildSectionLabel('Code-barres (optionnel)', theme),
                      const SizedBox(height: 12),
                      _buildBarcodeField(),
                    ],
                  ),
                ),
              ),
            ),

            // --- Save Button (Fixed at bottom) ---
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // WIDGET BUILDERS

  Widget _buildSectionLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: const Color(0xFF475569), // Slate Grey
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nom du produit *',
        hintText: 'Ex : Sac de riz 25 kg',
        prefixIcon: Icon(Icons.inventory_2_outlined),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le nom du produit est obligatoire';
        }
        if (value.trim().length < 2) {
          return 'Le nom doit contenir au moins 2 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(
        'Erreur de chargement des catégories : $error',
        style: const TextStyle(color: Color(0xFFDC2626)),
      ),
      data: (categories) {
        final selectableCategories = categories
            .where((c) => c.id != 'all')
            .toList();

        if (selectableCategories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Warning BG
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD97706)),
            ),
            child: const Text(
              'Aucune catégorie disponible. Veuillez en créer une d\'abord.',
              style: TextStyle(color: Color(0xFF92400E)),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Catégorie *',
            prefixIcon: Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
          items: selectableCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCategoryId = value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une catégorie';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Prix (FCFA) *',
        hintText: 'Ex : 1500',
        prefixIcon: Icon(Icons.payments_outlined),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le prix est obligatoire';
        }
        final price = int.tryParse(value.trim());
        if (price == null) {
          return 'Prix invalide';
        }
        if (price <= 0) {
          return 'Le prix doit être supérieur à 0';
        }
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: const InputDecoration(
        labelText: 'Stock initial *',
        hintText: 'Ex : 10',
        prefixIcon: Icon(Icons.numbers),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le stock est obligatoire';
        }
        final stock = int.tryParse(value.trim());
        if (stock == null) {
          return 'Stock invalide';
        }
        if (stock < 0) {
          return 'Le stock ne peut pas être négatif';
        }
        return null;
      },
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: _barcodeController,
      decoration: InputDecoration(
        labelText: 'Code-barres',
        hintText: 'Scannez ou saisissez manuellement',
        prefixIcon: const Icon(Icons.qr_code),
        border: const OutlineInputBorder(),
        // --- SCANNER BUTTON ---
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scanner un code-barres',
          onPressed: _scanBarcode,
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF1E40AF), // Primary Blue
          ),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveProduct,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isEditing ? Icons.save : Icons.add),
            label: Text(
              _isSaving
                  ? 'Enregistrement...'
                  : _isEditing
                  ? 'Enregistrer les modifications'
                  : 'Ajouter le produit',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF), // Primary Blue
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

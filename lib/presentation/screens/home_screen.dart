import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:inventory_lite/data/models/product.dart';
import 'package:inventory_lite/data/models/stock_movement.dart';
import 'package:inventory_lite/providers/catalog_providers.dart';
import './add_edit_product_screen.dart';
import './add_movement_screen.dart';

// DESIGN TOKENS (InventoryLite Design System)

const Color _primaryBlue = Color(0xFF1E40AF);
const Color _backgroundColor = Color(0xFFF8FAFC);
const Color _surfaceColor = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _borderColor = Color(0xFFE2E8F0);
const Color _successGreen = Color(0xFF16A34A);
const Color _successBg = Color(0xFFDCFCE7);
const Color _warningAmber = Color(0xFFD97706);
const Color _warningBg = Color(0xFFFEF3C7);
const Color _dangerRed = Color(0xFFDC2626);
const Color _dangerBg = Color(0xFFFEE2E2);

/// Threshold below which a product is considered "low stock".
const int _lowStockThreshold = 5;

/// Formats a movement date in a human-friendly French format.
String _formatMovementDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return "À l'instant";
  } else if (difference.inMinutes < 60) {
    return 'Il y a ${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return 'Il y a ${difference.inHours} h';
  } else if (difference.inDays < 7) {
    // e.g., "lundi"
    return DateFormat.EEEE('fr_FR').format(date);
  } else {
    // e.g., "17 sept. 2026"
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  }
}

// HOME SCREEN (DASHBOARD)

/// The main dashboard screen: summary cards + recent movements + quick actions.
///
/// Uses [ConsumerStatefulWidget] instead of [ConsumerWidget] because the
/// Speed Dial requires local state and an [AnimationController].
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isDialOpen = false;
  late final AnimationController _dialController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void dispose() {
    _dialController.dispose();
    super.dispose();
  }

  // NAVIGATION

  void _toggleDial() {
    setState(() {
      _isDialOpen = !_isDialOpen;
      _isDialOpen ? _dialController.forward() : _dialController.reverse();
    });
  }

  void _closeDial() {
    setState(() {
      _isDialOpen = false;
      _dialController.reverse();
    });
  }

  void _navigateToAddProduct() {
    _closeDial();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
  }

  void _navigateToAddMovement() {
    _closeDial();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMovementScreen()),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      floatingActionButton: _buildSpeedDial(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSummarySection(productsAsync),
            const SizedBox(height: 28),
            _buildSectionTitle('Derniers Mouvements'),
            const SizedBox(height: 12),
            Expanded(child: _buildRecentMovements()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'InventoryLite',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Suivez votre inventaire en temps réel',
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // SUMMARY CARDS

  Widget _buildSummarySection(AsyncValue<List<Product>> productsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: productsAsync.when(
        loading: () => const _SummarySkeleton(),
        error: (error, _) =>
            _SummaryError(onRetry: () => ref.invalidate(productsProvider)),
        data: (products) {
          final totalProducts = products.length;
          final lowStockCount = products
              .where((p) => p.currentStock <= _lowStockThreshold)
              .length;

          return Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.inventory_2_outlined,
                  value: '$totalProducts',
                  label: 'Produits',
                  iconColor: _primaryBlue,
                  iconBg: const Color(0xFFEFF6FF),
                  cardBg: _surfaceColor,
                  borderColor: _borderColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.warning_amber_rounded,
                  value: '$lowStockCount',
                  label: 'Stock faible',
                  iconColor: _warningAmber,
                  iconBg: const Color(0xFFFFFBEB),
                  cardBg: _warningBg,
                  borderColor: const Color(0xFFFDE68A),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // RECENT MOVEMENTS

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMovements() {
    final movementsAsync = ref.watch(recentMovementsProvider);

    return movementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _MovementsError(
        onRetry: () => ref.invalidate(recentMovementsProvider),
      ),
      data: (movements) {
        if (movements.isEmpty) {
          return _buildEmptyMovements();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: movements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _MovementTile(movement: movements[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyMovements() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_vert, color: _primaryBlue, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun mouvement pour le moment',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Utilisez le bouton + pour enregistrer\nvotre première entrée ou sortie de stock',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // SPEED DIAL (QUICK ACTIONS)

  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: _isDialOpen
              ? FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _dialController,
                    curve: Curves.easeOut,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDialActions(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        _buildMainFab(),
      ],
    );
  }

  Widget _buildDialActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildDialAction(
          label: 'Nouveau produit',
          icon: Icons.add_box_outlined,
          heroTag: 'dial_new_product',
          onTap: _navigateToAddProduct,
        ),
        const SizedBox(height: 12),
        _buildDialAction(
          label: 'Scan & Mouvement',
          icon: Icons.qr_code_scanner,
          heroTag: 'dial_scan_move',
          onTap: _navigateToAddMovement,
        ),
      ],
    );
  }

  Widget _buildDialAction({
    required String label,
    required IconData icon,
    required String heroTag,
    required VoidCallback onTap,
  }) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onTap,
      backgroundColor: _surfaceColor,
      foregroundColor: _textPrimary,
      elevation: 2,
      icon: Icon(icon, color: _primaryBlue, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMainFab() {
    return FloatingActionButton.extended(
      heroTag: 'dial_main',
      onPressed: _toggleDial,
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: AnimatedRotation(
        turns: _isDialOpen ? 0.125 : 0.0, // 45° rotation when open
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: const Icon(Icons.add),
      ),
      label: Text(
        _isDialOpen ? 'Fermer' : 'Actions',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// SUMMARY CARD WIDGET

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final Color cardBg;
  final Color borderColor;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// SUMMARY LOADING SKELETON

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SkeletonBox()),
        SizedBox(width: 16),
        Expanded(child: _SkeletonBox()),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: _borderColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// SUMMARY ERROR STATE

class _SummaryError extends StatelessWidget {
  final VoidCallback onRetry;

  const _SummaryError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _dangerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dangerRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: _dangerRed, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Impossible de charger les statistiques',
            style: TextStyle(fontWeight: FontWeight.w600, color: _dangerRed),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Réessayer'),
            style: FilledButton.styleFrom(backgroundColor: _dangerRed),
          ),
        ],
      ),
    );
  }
}

// MOVEMENTS ERROR STATE

class _MovementsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _MovementsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _dangerRed, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger les mouvements',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(backgroundColor: _primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}

// MOVEMENT TILE WIDGET

class _MovementTile extends ConsumerWidget {
  final StockMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productName = ref.watch(productNameProvider(movement.productId));
    final isEntry = movement.type == MovementType.inStock;

    final accentColor = isEntry ? _successGreen : _dangerRed;
    final accentBg = isEntry ? _successBg : _dangerBg;
    final icon = isEntry ? Icons.arrow_downward : Icons.arrow_upward;
    final quantityText = isEntry
        ? '+${movement.quantity}'
        : '-${movement.quantity}';

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accentBg, shape: BoxShape.circle),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        title: Text(
          productName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatMovementDate(movement.date),
          style: const TextStyle(fontSize: 12, color: _textSecondary),
        ),
        trailing: Text(
          quantityText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: accentColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

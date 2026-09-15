import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/product_repository.dart';
import '../../orders/data/cart_provider.dart';
import '../../price_prediction/presentation/price_trend_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends ConsumerState<ProductDetailScreen> {
  double _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync =
        ref.watch(singleProductProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  },
),        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Couldn\'t load product.\n\n$err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (product) {
          if (product == null) {
            return const Center(
              child: Text('Product not found.'),
            );
          }

          if (_quantity > product.quantity && product.quantity > 0) {
            _quantity = product.quantity;
          }

          final outOfStock = product.quantity <= 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (_, _, _) => const Center(
                                child: Icon(
                                  Icons.eco_outlined,
                                  size: 80,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.eco_outlined,
                                size: 80,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  product.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),

                const SizedBox(height: 5),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.category,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Rs. ${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                Text(
                  'per ${product.unit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      outOfStock
                          ? Icons.remove_circle_outline
                          : Icons.inventory_2_outlined,
                      size: 18,
                      color: outOfStock
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      outOfStock
                          ? 'Out of stock'
                          : '${product.quantity} ${product.unit} available',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: outOfStock
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                PriceTrendCard(category: product.category),

                const SizedBox(height: 18),

                _InfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: product.address,
                ),

                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'About this product',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],

                if (!outOfStock) ...[
                  const SizedBox(height: 22),

                  Text(
                    'Quantity',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _quantity <= 1
                              ? null
                              : () {
                                  setState(() {
                                    _quantity -= 1;
                                  });
                                },
                          icon: const Icon(
                            Icons.remove,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Text(
                              '${_quantity.toStringAsFixed(
                                _quantity % 1 == 0 ? 0 : 1,
                              )} ${product.unit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity >= product.quantity
                              ? null
                              : () {
                                  setState(() {
                                    _quantity += 1;
                                  });
                                },
                          icon: const Icon(
                            Icons.add,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                ],

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: outOfStock
                        ? null
                        : () {
                            ref
                                .read(cartProvider.notifier)
                                .addItem(product, _quantity);

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${product.name} added to cart',
                                ),
                                action: SnackBarAction(
                                  label: 'VIEW CART',
                                  onPressed: () {
                                    context.push('/cart');
                                  },
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      outOfStock
                          ? 'Out of Stock'
                          : 'Add to Cart',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}







import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/product_repository.dart';
import '../data/wishlist_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../../models/product_model.dart';
import '../../../services/location_service.dart';

class BrowseProductsScreen extends ConsumerStatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  ConsumerState<BrowseProductsScreen> createState() =>
      _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends ConsumerState<BrowseProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _sortByNearby = false;
  double? _myLat;
  double? _myLng;
  bool _loadingLocation = false;

  Future<void> _enableNearbySort() async {
    setState(() => _loadingLocation = true);

    final position = await locationServiceInstance.getCurrentPosition();

    if (!mounted) return;

    if (position != null) {
      setState(() {
        _myLat = position.latitude;
        _myLng = position.longitude;
        _sortByNearby = true;
        _loadingLocation = false;
      });
    } else {
      setState(() => _loadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Check permissions.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    final wishlistAsync = user != null
        ? ref.watch(wishlistProvider(user.uid))
        : const AsyncValue<List<String>>.data([]);

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
        ),
        title: const Text(
          'Marketplace',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Wishlist',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push('/wishlist'),
          ),
          IconButton(
            tooltip: 'Orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push('/orders'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search fruits, vegetables...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final item in const [
                  'All',
                  'Vegetables',
                  'Fruits',
                  'Grains',
                  'Dairy',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: _selectedCategory == item,
                      onSelected: (_) {
                        setState(() => _selectedCategory = item);
                      },
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  avatar: Icon(
                    Icons.near_me_outlined,
                    size: 18,
                    color: _sortByNearby
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : null,
                  ),
                  label: _loadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Nearby first'),
                  selected: _sortByNearby,
                  onSelected: (selected) {
                    if (selected) {
                      _enableNearbySort();
                    } else {
                      setState(() => _sortByNearby = false);
                    }
                  },
                ),
                const Spacer(),
                productsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (products) => Text(
                    '${products.length} products',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Couldn\'t load products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              data: (products) {
                var filtered = products.where((product) {
                  return product.name.toLowerCase().contains(_searchQuery) ||
                      product.category.toLowerCase().contains(_searchQuery);
                }).toList();

                if (_sortByNearby && _myLat != null && _myLng != null) {
                  filtered.sort((a, b) {
                    if (a.latitude == null || a.longitude == null) {
                      return 1;
                    }

                    if (b.latitude == null || b.longitude == null) {
                      return -1;
                    }

                    final distA = locationServiceInstance.calculateDistanceKm(
                      _myLat!,
                      _myLng!,
                      a.latitude!,
                      a.longitude!,
                    );

                    final distB = locationServiceInstance.calculateDistanceKm(
                      _myLat!,
                      _myLng!,
                      b.latitude!,
                      b.longitude!,
                    );

                    return distA.compareTo(distB);
                  });
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.storefront_outlined
                                : Icons.search_off_outlined,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No products available'
                                : 'No matching products',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Check back soon for fresh listings.'
                                : 'Try searching for something else.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final wishlist = wishlistAsync.value ?? [];

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final isWishlisted = wishlist.contains(product.id);

                    String? distanceLabel;

                    if (_sortByNearby &&
                        _myLat != null &&
                        _myLng != null &&
                        product.latitude != null &&
                        product.longitude != null) {
                      final distance = locationServiceInstance
                          .calculateDistanceKm(
                            _myLat!,
                            _myLng!,
                            product.latitude!,
                            product.longitude!,
                          );

                      distanceLabel = '${distance.toStringAsFixed(1)} km';
                    }

                    return _ProductCard(
                      product: product,
                      isWishlisted: isWishlisted,
                      distanceLabel: distanceLabel,
                      onTap: () => context.push('/product/${product.id}'),
                      onWishlistTap: user == null
                          ? null
                          : () => ref
                                .read(wishlistRepositoryProvider)
                                .toggleWishlist(
                                  user.uid,
                                  product.id,
                                  !isWishlisted,
                                ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isWishlisted;
  final String? distanceLabel;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;

  const _ProductCard({
    required this.product,
    required this.isWishlisted,
    required this.distanceLabel,
    required this.onTap,
    required this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outOfStock = product.quantity <= 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, _, _) => const Center(
                              child: Icon(Icons.eco_outlined, size: 48),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.eco_outlined, size: 48),
                          ),
                  ),

                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: theme.colorScheme.surface.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onWishlistTap,
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 19,
                            color: isWishlisted
                                ? Colors.red
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (distanceLabel != null)
                    Positioned(
                      left: 7,
                      bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          distanceLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  if (outOfStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.38),
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Rs. ${product.price.toStringAsFixed(0)} / ${product.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

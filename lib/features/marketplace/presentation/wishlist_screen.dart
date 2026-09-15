import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/wishlist_repository.dart';
import '../data/product_repository.dart';
import '../../auth/data/auth_repository.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final wishlistAsync = ref.watch(wishlistProvider(user.uid));
    final allProductsAsync = ref.watch(activeProductsProvider);

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
),        title: const Text('Wishlist')),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text('Something went wrong. Please try again.')),
        data: (wishlistIds) {
          if (wishlistIds.isEmpty) {
            return const Center(child: Text('No saved items yet.'));
          }
          return allProductsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const Center(child: Text('Something went wrong. Please try again.')),
            data: (allProducts) {
              final saved = allProducts.where((p) => wishlistIds.contains(p.id)).toList();
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: saved.length,
                itemBuilder: (context, index) {
                  final p = saved[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.eco, color: Colors.green),
                      title: Text(p.name),
                      subtitle: Text('Rs. ${p.price.toStringAsFixed(0)}/'),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => ref
                            .read(wishlistRepositoryProvider)
                            .toggleWishlist(user.uid, p.id, false),
                      ),
                      onTap: () => context.push('/product/${p.id}'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}




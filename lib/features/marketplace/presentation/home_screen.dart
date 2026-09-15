import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return profile.when(
      loading: () => const _LoadingHome(),
      error: (_, _) => const _ProfileErrorHome(),
      data: (user) {
        if (user == null) {
          return const _ProfileErrorHome();
        }

        final role = user.role.toLowerCase();

        if (role == 'seller') {
          return const _SellerHome();
        }

        if (role == 'both') {
          return const _BuyerHome(showSellerButton: true);
        }

        if (role == 'buyer') {
          return const _BuyerHome();
        }

        return const _ProfileErrorHome();
      },
    );
  }
}

class _BuyerHome extends StatefulWidget {
  final bool showSellerButton;

  const _BuyerHome({this.showSellerButton = false});

  @override
  State<_BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<_BuyerHome> {
  String search = '';
  String category = 'All';

  final categories = const [
    ('All', Icons.apps),
    ('Vegetables', Icons.eco),
    ('Fruits', Icons.apple),
    ('Grains', Icons.grain),
    ('Dairy', Icons.local_drink),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F3),
        elevation: 0,
        title: const Text(
          'FarmerConnect',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final filtered = docs.where((doc) {
            final d = doc.data();
            final name = (d['name'] ?? '').toString().toLowerCase();
            final cat = (d['category'] ?? '').toString();

            final matchesSearch =
                search.trim().isEmpty ||
                name.contains(search.trim().toLowerCase());

            String normalizeCategory(String value) {
              final normalized = value.trim().toLowerCase();

              switch (normalized) {
                case 'vegetable':
                case 'vegetables':
                  return 'vegetables';

                case 'fruit':
                case 'fruits':
                  return 'fruits';

                case 'grain':
                case 'grains':
                  return 'grains';

                case 'dairy':
                case 'dairies':
                  return 'dairy';

                default:
                  return normalized;
              }
            }

            final matchesCategory =
                category == 'All' ||
                normalizeCategory(cat) == normalizeCategory(category);

            return matchesSearch && matchesCategory;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: InputDecoration(
                    hintText: 'Search fresh products...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: const Color(0xFFE6F2D8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Fresh from\nlocal farmers ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.local_florist_rounded,
                        size: 58,
                        color: Colors.green.shade700,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = categories[index];
                      final selected = category == item.$1;

                      return GestureDetector(
                        onTap: () => setState(() => category = item.$1),
                        child: Container(
                          width: 82,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF2E7D32)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.$2,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF2E7D32),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.$1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Fresh picks',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (widget.showSellerButton)
                      TextButton(
                        onPressed: () => context.push('/my-listings'),
                        child: const Text('Seller tools'),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        'No items to show',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .72,
                        ),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final d = doc.data();
                      final image = d['imageUrl']?.toString() ?? '';
                      final name = d['name']?.toString() ?? 'Product';
                      final price = d['price']?.toString() ?? '0';
                      final unit = d['unit']?.toString() ?? '';

                      return GestureDetector(
                        onTap: () => context.push('/product/${doc.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: image.isEmpty
                                      ? Container(
                                          color: const Color(0xFFEFF4E8),
                                          child: const Center(
                                            child: Icon(
                                              Icons.eco_rounded,
                                              size: 48,
                                            ),
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: image,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (_, _, _) => const Icon(
                                            Icons.image_not_supported_outlined,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. $price / $unit',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _BottomNav(
        current: 0,
        onTap: (index) {
          if (index == 1) context.go('/browse');
          if (index == 2) context.go('/cart');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }
}

class _SellerHome extends StatelessWidget {
  const _SellerHome();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F3),
        elevation: 0,
        title: const Text(
          'Seller Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F2D8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow your marketplace ',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text('Manage your products, orders and sales from one place.'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: uid == null
                ? null
                : FirebaseFirestore.instance
                      .collection('products')
                      .where('sellerId', isEqualTo: uid)
                      .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_rounded,
                      size: 38,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text('Your listings'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          _SellerAction(
            icon: Icons.add_circle_outline_rounded,
            title: 'Add Product',
            subtitle: 'List fresh produce for buyers',
            onTap: () => context.push('/add-product'),
          ),
          _SellerAction(
            icon: Icons.inventory_2_outlined,
            title: 'My Listings',
            subtitle: 'Edit and manage your products',
            onTap: () => context.push('/my-listings'),
          ),
          _SellerAction(
            icon: Icons.receipt_long_outlined,
            title: 'Seller Orders',
            subtitle: 'View and manage incoming orders',
            onTap: () => context.push('/seller-orders'),
          ),
          _SellerAction(
            icon: Icons.bar_chart_rounded,
            title: 'Analytics',
            subtitle: 'Track your marketplace performance',
            onTap: () => context.push('/seller-analytics'),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: 0,
        onTap: (index) {
          if (index == 1) context.go('/my-listings');
          if (index == 2) context.go('/seller-orders');
          if (index == 3) context.go('/profile');
        },
        labels: const ['Home', 'Listings', 'Orders', 'Profile'],
        icons: const [
          Icons.home_rounded,
          Icons.inventory_2_outlined,
          Icons.receipt_long_outlined,
          Icons.person_outline_rounded,
        ],
      ),
    );
  }
}

class _SellerAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SellerAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6F2D8),
          child: Icon(icon, color: const Color(0xFF2E7D32)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  final List<String> labels;
  final List<IconData> icons;

  const _BottomNav({
    required this.current,
    required this.onTap,
    this.labels = const ['Home', 'Browse', 'Cart', 'Profile'],
    this.icons = const [
      Icons.home_rounded,
      Icons.grid_view_rounded,
      Icons.shopping_cart_outlined,
      Icons.person_outline_rounded,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current,
      onDestinationSelected: onTap,
      destinations: List.generate(
        labels.length,
        (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
      ),
    );
  }
}

class _ProfileErrorHome extends StatelessWidget {
  const _ProfileErrorHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 52),
              const SizedBox(height: 16),
              const Text(
                'Profile could not be loaded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please try again. Your account role was not changed.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

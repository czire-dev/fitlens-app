import 'package:flutter/material.dart';

import 'features/catalog/catalog_page.dart';

enum _Destination {
  shop('Shop', Icons.storefront_outlined, Icons.storefront),
  myFit(
    'My fit',
    Icons.straighten_outlined,
    Icons.straighten,
    'Your measurements and fit preferences will appear here.',
  ),
  cart(
    'Cart',
    Icons.shopping_bag_outlined,
    Icons.shopping_bag,
    'The shirts and sizes you add will appear here.',
  ),
  orders(
    'Orders',
    Icons.receipt_long_outlined,
    Icons.receipt_long,
    'You’ll be able to see your past orders here.',
  );

  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon, [
    this.description,
  ]);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? description;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _Destination _selected = _Destination.shop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected == _Destination.shop ? 'FitLens' : _selected.label,
        ),
      ),
      body: IndexedStack(
        index: _selected.index,
        children: [
          for (final destination in _Destination.values)
            ExcludeFocus(
              excluding: destination != _selected,
              child: switch (destination.description) {
                final String description => _PlaceholderPage(
                  icon: destination.icon,
                  description: description,
                ),
                null => const CatalogPage(),
              },
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected.index,
        onDestinationSelected: (index) {
          setState(() => _selected = _Destination.values[index]);
        },
        destinations: [
          for (final destination in _Destination.values)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.icon, required this.description});

  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 36, color: colors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Work in progress',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(description, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

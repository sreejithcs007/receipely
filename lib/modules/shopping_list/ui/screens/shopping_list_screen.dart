import 'package:flutter/material.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/app_bar/app_appbar.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<ShoppingItem> _items = [
    ShoppingItem(
      name: 'Organic Quinoa grains',
      quantity: '200g',
      category: 'Vegetables & Grains',
    ),
    ShoppingItem(
      name: 'Halved Cherry Tomatoes',
      quantity: '100g',
      category: 'Vegetables & Grains',
    ),
    ShoppingItem(
      name: 'Fresh Avocado',
      quantity: '1 unit',
      category: 'Vegetables & Grains',
    ),
    ShoppingItem(
      name: 'Greek Feta Cheese',
      quantity: '50g',
      category: 'Dairy & Cheese',
    ),
    ShoppingItem(
      name: 'Organic Salmon Fillet',
      quantity: '300g',
      category: 'Meat & Seafood',
    ),
  ];

  void _toggleChecked(int index) {
    setState(() {
      _items[index].isChecked = !_items[index].isChecked;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Grouping items by category
    final Map<String, List<ShoppingItem>> groupedItems = {};
    for (var item in _items) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    return Scaffold(
      backgroundColor: context.white.c50,
      appBar: const AppAppBar(title: 'Shopping List', showBackButton: true),
      body:
          _items.isEmpty
              ? const Center(child: Text('Your shopping list is empty.'))
              : ListView(
                padding: const EdgeInsets.all(Dimensions.space24),
                children:
                    groupedItems.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: context.typography.textSm.bold.copyWith(
                              color: context.primary.c500,
                            ),
                          ),
                          const SizedBox(height: Dimensions.space8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: entry.value.length,
                            separatorBuilder:
                                (context, index) =>
                                    const SizedBox(height: Dimensions.space10),
                            itemBuilder: (context, index) {
                              final item = entry.value[index];
                              final int globalIndex = _items.indexOf(item);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.space12,
                                  vertical: Dimensions.space8,
                                ),
                                decoration: BoxDecoration(
                                  color: context.grey.c50,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusMd,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item.isChecked,
                                      activeColor: context.primary.c500,
                                      onChanged: (_) => _toggleChecked(globalIndex),
                                    ),
                                    const SizedBox(width: Dimensions.space8),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: context
                                            .typography
                                            .textSm
                                            .semibold
                                            .copyWith(
                                              color:
                                                  item.isChecked
                                                      ? context.grey.c400
                                                      : context.grey.c900,
                                              decoration:
                                                  item.isChecked
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      item.quantity,
                                      style: context
                                          .typography
                                          .textXs
                                          .regular
                                          .copyWith(color: context.grey.c500),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: Dimensions.space24),
                        ],
                      );
                    }).toList(),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.primary.c500,
        child: Icon(Icons.add, color: context.white.c50),
        onPressed: () {},
      ),
    );
  }
}

class ShoppingItem {
  final String name;
  final String quantity;
  final String category;
  bool isChecked;

  ShoppingItem({
    required this.name,
    required this.quantity,
    required this.category,
    this.isChecked = false,
  });
}

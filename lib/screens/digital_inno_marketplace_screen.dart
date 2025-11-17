import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DigitalInnoMarketplaceScreen extends StatefulWidget {
  const DigitalInnoMarketplaceScreen({super.key});

  @override
  State<DigitalInnoMarketplaceScreen> createState() =>
      _DigitalInnoMarketplaceScreenState();
}

class _DigitalInnoMarketplaceScreenState
    extends State<DigitalInnoMarketplaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Innovation Marketplace'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 优化的 Firestore 查询 - 避免 ANR 问题
        stream: _firestore
            .collection('products')
            .limit(20) // 限制查询数量，避免大量数据导致 ANR
            .snapshots()
            .timeout(
              const Duration(seconds: 10), // 添加超时处理
              onTimeout: (sink) {
                sink.addError(TimeoutException('Query timeout'));
              },
            ),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // 加载状态处理
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading products...'),
                ],
              ),
            );
          }

          // 错误处理
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {}); // 重新加载
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // 无数据处理
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No products available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 显示产品列表
          final products = snapshot.data!.docs;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // 刷新数据
            },
            child: ListView.builder(
              itemCount: products.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final product = products[index].data() as Map<String, dynamic>;
                final productId = products[index].id;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        product['name']?.toString().substring(0, 1).toUpperCase() ??
                            'P',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      product['name']?.toString() ?? 'Unknown Product',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          product['description']?.toString() ??
                              'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Price: \$${product['price']?.toString() ?? 'N/A'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {
                        _showProductDetails(context, productId, product);
                      },
                    ),
                    onTap: () {
                      _showProductDetails(context, productId, product);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProductDetails(
    BuildContext context,
    String productId,
    Map<String, dynamic> product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']?.toString() ?? 'Product Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: $productId'),
              const SizedBox(height: 8),
              Text(
                'Description: ${product['description']?.toString() ?? 'N/A'}',
              ),
              const SizedBox(height: 8),
              Text('Price: \$${product['price']?.toString() ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                'Category: ${product['category']?.toString() ?? 'N/A'}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a product name'),
                  ),
                );
                return;
              }

              try {
                await _firestore.collection('products').add({
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'category': categoryController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

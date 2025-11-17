import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_products/src/data/products_repository.dart';

final allProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  final productsRepository = ref.watch(productsRepositoryProvider);
  return productsRepository.watchAllProducts();
});
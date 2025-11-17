import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_products/src/data/products_repository.dart';

final productsStreamProvider =
    StreamProvider.family<List<Product>, String>((ref, categoryId) {
  final productsRepository = ref.watch(productsRepositoryProvider);
  return productsRepository.watchProducts(categoryId);
});
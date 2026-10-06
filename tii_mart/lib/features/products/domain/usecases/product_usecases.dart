import '../entities/product.dart';
import '../repositories/product_repository.dart';

class WatchSellerProducts {
  const WatchSellerProducts(this._repo);
  final ProductRepository _repo;

  Stream<List<Product>> call(String ownerId) =>
      _repo.watchProductsByOwner(ownerId);
}

class GetProduct {
  const GetProduct(this._repo);
  final ProductRepository _repo;

  Future<Product> call(String id) => _repo.getProduct(id);
}

class SaveProduct {
  const SaveProduct(this._repo);
  final ProductRepository _repo;

  Future<String> call(Product product) => _repo.saveProduct(product);
}

class DeleteProduct {
  const DeleteProduct(this._repo);
  final ProductRepository _repo;

  Future<void> call(String id) => _repo.deleteProduct(id);
}

class WatchActiveProducts {
  const WatchActiveProducts(this._repo);
  final ProductRepository _repo;

  Stream<List<Product>> call() => _repo.watchActiveProducts();
}

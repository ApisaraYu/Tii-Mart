import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Stream<List<Product>> watchProductsByOwner(String ownerId) =>
      _remote.watchByOwner(ownerId);

  @override
  Future<Product> getProduct(String id) => _remote.get(id);

  @override
  Future<String> saveProduct(Product product) => _remote.save(product);

  @override
  Future<void> deleteProduct(String id) => _remote.delete(id);
}

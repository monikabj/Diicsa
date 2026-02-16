import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'productos';

  Stream<List<ProductoModel>> getProductosPorAnaquel(int anaquel) {
    return _db
        .collection(collection)
        .where('anaquel', isEqualTo: anaquel)
        .orderBy('seccion')
        .orderBy('codigoInterno')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductoModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> agregarProducto(ProductoModel producto) async {
    await _db.collection(collection).add(producto.toMap());
  }


  Future<String> subirImagenProducto({
    required File imagen,
    required String productoId,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('productos')
        .child('$productoId.jpg');

    await ref.putFile(imagen);

    return await ref.getDownloadURL();
  }

  Future<void> registrarMovimiento({
    required String productoId,
    required int cantidad,
    required String tipo, 
  }) async {
    final productoRef = _db.collection(collection).doc(productoId);
    final productoSnap = await productoRef.get();

    if (!productoSnap.exists) {
      throw Exception('Producto no encontrado');
    }

    final data = productoSnap.data()!;

    int cantidadInicial = data['cantidadInicial'] ?? 0;
    int cantidadDisponible = data['cantidadDisponible'] ?? 0;
    int cantidadTotal = data['cantidadTotal'] ?? cantidadInicial;
    int cantidadSalidas = data['cantidadSalidas'] ?? 0;

    if (tipo == 'entrada') {
      cantidadDisponible += cantidad;
      cantidadTotal += cantidad;
    } else if (tipo == 'salida') {
      if (cantidad > cantidadDisponible) {
        throw Exception('Stock insuficiente');
      }
      cantidadDisponible -= cantidad;
      cantidadSalidas += cantidad;
    } else {
      throw Exception('Tipo de movimiento inválido');
    }


    await productoRef.update({
      'cantidadDisponible': cantidadDisponible,
      'cantidadTotal': cantidadTotal,
      'cantidadSalidas': cantidadSalidas,
    });

    await _db.collection('movimientos').add({
      'productoId': productoId,
      'cantidad': cantidad,
      'tipo': tipo,
      'fecha': Timestamp.now(),
    });
  }
}
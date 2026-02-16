import 'package:cloud_firestore/cloud_firestore.dart';

class ProductoModel {
  final String id;
  final int anaquel;
  final String seccion;
  final String segmento;
  final String codigoInterno;
  final String descripcion;
  final String numeroParte;
  final String marca;

  final int cantidadInicial;
  final int cantidadDisponible;
  final int cantidadTotal;
  final int cantidadSalidas;

  final Timestamp createdAt;

  ProductoModel({
    required this.id,
    required this.anaquel,
    required this.seccion,
    required this.segmento,
    required this.codigoInterno,
    required this.descripcion,
    required this.numeroParte,
    required this.marca,
    required this.cantidadInicial,
    required this.cantidadDisponible,
    required this.cantidadTotal,
    required this.cantidadSalidas,
    required this.createdAt,
  });

  factory ProductoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProductoModel(
      id: doc.id,
      anaquel: data['anaquel'],
      seccion: data['seccion'],
      segmento: data['segmento'],
      codigoInterno: data['codigoInterno'],
      descripcion: data['descripcion'],
      numeroParte: data['numeroParte'],
      marca: data['marca'],
      cantidadInicial: data['cantidadInicial'],
      cantidadDisponible: data['cantidadDisponible'],
      cantidadTotal: data['cantidadTotal'],
      cantidadSalidas: data['cantidadSalidas'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'anaquel': anaquel,
      'seccion': seccion,
      'segmento': segmento,
      'codigoInterno': codigoInterno,
      'descripcion': descripcion,
      'numeroParte': numeroParte,
      'marca': marca,
      'cantidadInicial': cantidadInicial,
      'cantidadDisponible': cantidadDisponible,
      'cantidadTotal': cantidadTotal,
      'cantidadSalidas': cantidadSalidas,
      'createdAt': createdAt,
    };
  }
}

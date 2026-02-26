import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_producto_screen.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String filtro = '';

  Stream<QuerySnapshot> _productosStream() {
    return FirebaseFirestore.instance
        .collection('productos')
        .orderBy('codigoInterno')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: azulDiicsa,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, '/agregar-producto');
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buscador(),
          const Divider(),
          Expanded(child: _listaProductos()),
        ],
      ),
    );
  }

  // ================= BUSCADOR =================
  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar producto',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            filtro = value.toLowerCase().trim();
          });
        },
      ),
    );
  }

  // ================= LISTA =================
  Widget _listaProductos() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productosStream(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final codigo =
              (data['codigoInterno'] ?? '').toString().toLowerCase();
          final desc =
              (data['descripcion'] ?? '').toString().toLowerCase();
          final marca =
              (data['marca'] ?? '').toString().toLowerCase();
          final anaquel =
              (data['anaquel'] ?? '').toString().toLowerCase();
          final seccion =
              (data['seccion'] ?? '').toString().toLowerCase();
          final numeroParte =
              (data['numeroParte'] ?? '').toString().toLowerCase();

          return codigo.contains(filtro) ||
              desc.contains(filtro) ||
              marca.contains(filtro) ||
              anaquel.contains(filtro) ||
              seccion.contains(filtro) ||
              numeroParte.contains(filtro);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Sin productos'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(
                  data['codigoInterno'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['descripcion'] ?? ''),
                    Text(
                      'N° Parte: ${data['numeroParte'] ?? '—'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Marca: ${data['marca'] ?? '—'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Ubicación: Anaquel ${data['anaquel'] ?? '—'} · Sección ${data['seccion'] ?? '—'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  (data['cantidadDisponible'] ?? 0).toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetalleProductoScreen(docId: d.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class TrabajadorHomeScreen extends StatefulWidget {
  const TrabajadorHomeScreen({super.key});

  @override
  State<TrabajadorHomeScreen> createState() =>
      _TrabajadorHomeScreenState();
}

class _TrabajadorHomeScreenState extends State<TrabajadorHomeScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String filtro = '';
  String nombreUsuario = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        nombreUsuario = doc.data()?['nombre'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulDiicsa,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            Text(
              nombreUsuario,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Inventario'),
            Tab(text: 'Herramientas'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              _buscador(),
              const Divider(),
              Expanded(child: _inventarioProductos()),
            ],
          ),
          Column(
            children: [
              _buscador(),
              const Divider(),
              Expanded(child: _inventarioHerramientas()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: const InputDecoration(
          hintText:
              'Buscar por código, número de parte, descripción o marca',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) {
          setState(() => filtro = v.toLowerCase());
        },
      ),
    );
  }

  Widget _inventarioProductos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productos')
          .orderBy('codigoInterno')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;

          final texto = (
            '${d['codigoInterno']} '
            '${d['numeroParte'] ?? ''} '
            '${d['descripcion']} '
            '${d['marca'] ?? ''} '
            '${d['segmento'] ?? ''} '
            '${d['seccion']}'
          ).toLowerCase();

          return texto.contains(filtro);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Sin productos'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final existencia = d['cantidadDisponible'] ?? 0;

            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: _miniaturaImagen(d),
                title: Text(
                  d['codigoInterno'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['descripcion'] ?? ''),
                    Text('N° Parte: ${d['numeroParte'] ?? '—'}'),
                    Text('Marca: ${d['marca'] ?? '—'}'),
                  ],
                ),
                trailing: Text(
                  existencia.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        existencia <= 0 ? Colors.red : Colors.black,
                  ),
                ),
                onTap: () => _detalleProducto(context, d),
              ),
            );
          },
        );
      },
    );
  }

  Widget _inventarioHerramientas() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('herramientas')
          .orderBy('codigoInterno')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;

          final texto = (
            '${d['codigoInterno']} '
            '${d['descripcion']} '
            '${d['marca']} '
            '${d['seccion']}'
          ).toLowerCase();

          return texto.contains(filtro);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Sin herramientas'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final imgs = d['imagenesBase64'];
            final existencia = d['cantidadDisponible'] ?? 0;

            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: imgs != null &&
                        imgs is List &&
                        imgs.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          base64Decode(imgs.first),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.handyman, color: azulDiicsa),
                title: Text(
                  d['codigoInterno'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(d['descripcion'] ?? ''),
                trailing: Text(
                  existencia.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        existencia <= 0 ? Colors.red : Colors.black,
                  ),
                ),
                onTap: () => _detalleHerramienta(context, d),
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniaturaImagen(Map<String, dynamic> data) {
    final img = data['imagenBase64'];

    if (img != null && img.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          base64Decode(img),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }

    return const Icon(Icons.image_not_supported);
  }

  void _detalleProducto(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(d['codigoInterno'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d['imagenBase64'] != null &&
                  d['imagenBase64'].toString().isNotEmpty)
                Image.memory(
                  base64Decode(d['imagenBase64']),
                  height: 200,
                  fit: BoxFit.contain,
                ),
              const SizedBox(height: 12),
              Text('Descripción: ${d['descripcion'] ?? ''}'),
              Text('Número de parte: ${d['numeroParte'] ?? '—'}'),
              Text('Marca: ${d['marca'] ?? '—'}'),
              const SizedBox(height: 8),
              Text(
                'Ubicación: Anaquel ${d['anaquel']} - ${d['seccion']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Existencia: ${d['cantidadDisponible'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

void _detalleHerramienta(BuildContext context, Map<String, dynamic> d) {
  final imgs = d['imagenesBase64'];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(d['codigoInterno'] ?? ''),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            if (imgs != null && imgs is List && imgs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: Image.memory(
                    base64Decode(imgs.first),
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            Text('Descripción: ${d['descripcion'] ?? ''}'),
            Text('Marca: ${d['marca'] ?? ''}'),

            const SizedBox(height: 8),

            Text(
              'Ubicación: ${d['organizador']} - ${d['seccion']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(
              'Existencia: ${d['cantidadDisponible'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
}
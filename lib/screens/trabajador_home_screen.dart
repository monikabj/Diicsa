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

  // ================= UI PRINCIPAL =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          indicatorColor: Colors.white,
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

  // ================= BUSCADOR =================
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

  // ================= PRODUCTOS =================
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
            '${d['codigoInterno'] ?? ''} '
            '${d['numeroParte'] ?? ''} '
            '${d['descripcion'] ?? ''} '
            '${d['marca'] ?? ''} '
            '${d['anaquel'] ?? ''} '
            '${d['seccion'] ?? ''}'
          ).toLowerCase();

          return texto.contains(filtro);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Sin productos'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final existencia = d['cantidadDisponible'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: _miniatura(d),
                title: Text(
                  d['codigoInterno'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['descripcion'] ?? ''),
                    Text('N° Parte: ${d['numeroParte'] ?? '—'}'),
                    Text(
                      'Ubicación: Anaquel ${d['anaquel'] ?? '—'} - ${d['seccion'] ?? '—'}',
                    ),
                  ],
                ),
                trailing: Text(
                  existencia.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: existencia <= 0 ? Colors.red : Colors.black,
                  ),
                ),
                onTap: () => _detalleConCarrusel(context, d),
              ),
            );
          },
        );
      },
    );
  }

  // ================= HERRAMIENTAS =================
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
            '${d['codigoInterno'] ?? ''} '
            '${d['numeroParte'] ?? ''} '
            '${d['descripcion'] ?? ''} '
            '${d['marca'] ?? ''} '
            '${d['organizador'] ?? ''} '
            '${d['seccion'] ?? ''}'
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
            final existencia = d['cantidadDisponible'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: _miniatura(d),
                title: Text(
                  d['codigoInterno'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['descripcion'] ?? ''),
                    Text('N° Parte: ${d['numeroParte'] ?? '—'}'),
                    Text(
                      'Ubicación: ${d['organizador'] ?? '—'} - ${d['seccion'] ?? '—'}',
                    ),
                  ],
                ),
                trailing: Text(
                  existencia.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: existencia <= 0 ? Colors.red : Colors.black,
                  ),
                ),
                onTap: () => _detalleConCarrusel(context, d),
              ),
            );
          },
        );
      },
    );
  }

  // ================= MINIATURA =================
  Widget _miniatura(Map<String, dynamic> d) {
    final List imagenes = d['imagenesBase64'] ?? [];

    if (imagenes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          base64Decode(imagenes.first),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }

    return const Icon(Icons.image_not_supported);
  }

  // ================= DIÁLOGO =================
  void _detalleConCarrusel(BuildContext context, Map<String, dynamic> d) {
    final List imagenes = d['imagenesBase64'] ?? [];
    final PageController controller = PageController();
    int paginaActual = 0;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: 420,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [

                        Text(
                          d['codigoInterno'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (imagenes.isNotEmpty)
                          SizedBox(
                            height: 260,
                            child: PageView.builder(
                              controller: controller,
                              itemCount: imagenes.length,
                              onPageChanged: (index) {
                                setStateDialog(() {
                                  paginaActual = index;
                                });
                              },
                              itemBuilder: (_, index) {
                                return Image.memory(
                                  base64Decode(imagenes[index]),
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          )
                        else
                          const SizedBox(
                            height: 260,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 100,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        Text('Descripción: ${d['descripcion'] ?? ''}'),
                        Text('N° Parte: ${d['numeroParte'] ?? '—'}'),
                        Text('Marca: ${d['marca'] ?? ''}'),

                        if (d.containsKey('anaquel'))
                          Text(
                            'Ubicación: Anaquel ${d['anaquel'] ?? '—'} - ${d['seccion'] ?? '—'}',
                          ),

                        if (d.containsKey('organizador'))
                          Text(
                            'Ubicación: ${d['organizador'] ?? '—'} - ${d['seccion'] ?? '—'}',
                          ),

                        const SizedBox(height: 20),

                        Text(
                          'Existencia: ${d['cantidadDisponible'] ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulDiicsa,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(45),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
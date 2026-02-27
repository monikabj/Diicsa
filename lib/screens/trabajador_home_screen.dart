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

  // ================= UI =================
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

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: const InputDecoration(
          hintText:
              'Buscar productos',
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
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(d['descripcion'] ?? ''),
    const SizedBox(height: 4),
    Text(
      'N° Parte: ${d['numeroParte'] ?? '—'}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
    Text(
      'Marca: ${d['marca'] ?? '—'}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
  ],
     ),
                onTap: () => _detalleConCarrusel(context, d),
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
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(d['descripcion'] ?? ''),
    const SizedBox(height: 4),
    Text(
      'N° Parte: ${d['numeroParte'] ?? '—'}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
    Text(
      'Marca: ${d['marca'] ?? '—'}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
  ],
),
                onTap: () => _detalleConCarrusel(context, d),
              ),
            );
          },
        );
      },
    );
  }

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

  // ================= DETALLE MEJORADO =================
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
              borderRadius: BorderRadius.circular(25),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 430,
              ),
              child: Column(
                children: [

                  // ================= HEADER =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: azulDiicsa,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['codigoInterno'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'N° Parte: ${d['numeroParte'] ?? '—'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Marca: ${d['marca'] ?? '—'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // ================= CONTENIDO SCROLL =================
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [

                          // ================= IMAGEN =================
                          if (imagenes.isNotEmpty)
                            Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: PageView.builder(
                                    controller: controller,
                                    itemCount: imagenes.length,
                                    onPageChanged: (index) {
                                      setStateDialog(() {
                                        paginaActual = index;
                                      });
                                    },
                                    itemBuilder: (_, index) {
                                      return ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                        child: Image.memory(
                                          base64Decode(imagenes[index]),
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  '${paginaActual + 1} / ${imagenes.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),

                                const SizedBox(height: 12),

                                if (imagenes.length > 1)
                                  SizedBox(
                                    height: 55,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: imagenes.length,
                                      itemBuilder: (_, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            controller.jumpToPage(index);
                                          },
                                          child: Container(
                                            margin:
                                                const EdgeInsets.symmetric(horizontal: 6),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: paginaActual == index
                                                    ? azulDiicsa
                                                    : Colors.grey.shade300,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                base64Decode(imagenes[index]),
                                                width: 55,
                                                height: 55,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),

                          const SizedBox(height: 20),

                          // ================= DESCRIPCIÓN =================
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  d['descripcion'] ?? '',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ================= EXISTENCIA =================
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Existencia: ${d['cantidadDisponible'] ?? 0}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (d['cantidadDisponible'] ?? 0) <= 0
                                    ? Colors.red
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: azulDiicsa,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cerrar',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}
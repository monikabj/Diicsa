import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar usuarios'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final doc = users[i];
              final data = doc.data() as Map<String, dynamic>;

              final email = data['email'];
              final rol = data['rol'];
              final activo = data['activo'] ?? false;

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    rol == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.badge,
                    color: azulDiicsa,
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Rol: ${rol.toUpperCase()}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      // ACTIVAR / DESACTIVAR
                      Switch(
                        value: activo,
                        activeColor: azulDiicsa,
                        onChanged: (v) async {
                          await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(doc.id)
                              .update({'activo': v});
                        },
                      ),

                      // ELIMINAR
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Eliminar usuario',
                        onPressed: () =>
                            _confirmarEliminacion(context, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _confirmarEliminacion(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text(
          '¿Seguro que deseas eliminar este usuario?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .delete();

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> crearAdmin({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('usuarios').doc(uid).set({
      'email': email,
      'nombre': nombre,
      'rol': 'admin',
      'activo': true,
      'intentosFallidos': 0,
      'bloqueado': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> crearTrabajador({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('usuarios').doc(uid).set({
      'email': email,
      'nombre': nombre,
      'rol': 'trabajador',
      'activo': true,
      'intentosFallidos': 0,
      'bloqueado': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<Map<String, dynamic>> obtenerUsuario(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Usuario no registrado en el sistema');
    }

    return doc.data()!;
  }


 Future<void> recuperarPassword(String email) async {
  await _auth.sendPasswordResetEmail(email: email);
}

  Future<void> logout() async {
    await _auth.signOut();
  }

  bool passwordSegura(String password) {
    final regex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'
        );
    return regex.hasMatch(password);
  }


Future<void> registrarIntentoFallido(String uid) async {
  final ref = _db.collection('usuarios').doc(uid);

  await _db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) return;

    final intentos = (snap['intentosFallidos'] ?? 0) + 1;

    tx.update(ref, {
      'intentosFallidos': intentos,
      'bloqueado': intentos >= 5, 
    });
  });
}


Future<void> reiniciarIntentos(String uid) async {
  await _db.collection('usuarios').doc(uid).update({
    'intentosFallidos': 0,
    'bloqueado': false,
  });
}

}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class FirebaseService {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  User? get user => auth.currentUser;

Future<void> guardarTokenNotificaciones(String parejaId) async {
  final token = await FirebaseMessaging.instance.getToken();

  if (token == null || user == null) return;

  await db.collection('parejas').doc(parejaId).update({
    'tokensNotificaciones.${user!.uid}': token,
  });
}

  Stream<User?> authChanges() => auth.authStateChanges();

  Future<UserCredential> register(String email, String password) =>
      auth.createUserWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> login(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> logout() => auth.signOut();

  Future<String> createPareja({
  required String nombre,
  required String miNombre,
}) async {
    final uid = user!.uid;
    final code = await _uniqueCode();
    final ref = db.collection('parejas').doc();
    await ref.set({
      'nombre': nombre.trim().isEmpty ? 'Nuestra pareja' : nombre.trim(),
      'creadorId': uid,
      'miembros': [uid],
'nombresMiembros': {
  uid: miNombre.trim().isEmpty ? 'Tú' : miNombre.trim(),
},
      'codigoUnion': code,
      'saldoInicial': 0.0,
'saldoInicialMiembro1': 0.0,
'saldoInicialMiembro2': 0.0,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    await db.collection('codigosUnion').doc(code).set({
      'parejaId': ref.id,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> joinPareja(String code) async {
    final uid = user!.uid;
    final normalized = code.trim().toUpperCase();
    final codeDoc = await db.collection('codigosUnion').doc(normalized).get();
    if (!codeDoc.exists) throw Exception('Código no válido.');
    final parejaId = codeDoc.data()!['parejaId'] as String;
    final ref = db.collection('parejas').doc(parejaId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('La pareja no existe.');
    final miembros = List<String>.from(snap.data()?['miembros'] ?? const []);
    if (miembros.contains(uid)) return parejaId;
    if (miembros.length >= 2) throw Exception('Esta cuenta de pareja ya tiene dos miembros.');
    await ref.update({
  'miembros': FieldValue.arrayUnion([uid]),
  'nombresMiembros.$uid': 'Tu pareja',
});
    return parejaId;
  }

Stream<QuerySnapshot<Map<String, dynamic>>> movimientos(String parejaId) =>
    db
        .collection('parejas')
        .doc(parejaId)
        .collection('movimientos')
        .orderBy('fecha', descending: true)
        .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> objetivos(String parejaId) =>
    db
        .collection('parejas')
        .doc(parejaId)
        .collection('objetivos')
        .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> pareja(String parejaId) =>
      db.collection('parejas').doc(parejaId).snapshots();

  Future<void> guardarSaldosIniciales(
  String parejaId,
  double miembro1,
  double miembro2,
) =>
    db.collection('parejas').doc(parejaId).update({
      'saldoInicialMiembro1': miembro1,
      'saldoInicialMiembro2': miembro2,
      'saldoInicial': miembro1 + miembro2,
    });

Future<void> ajustarSaldo({
  required String parejaId,
  required double cantidad,
  required bool sumar,
}) async {
  if (cantidad <= 0) return;

  await db
      .collection('parejas')
      .doc(parejaId)
      .collection('movimientos')
      .add({
    'concepto': sumar ? 'Ajuste de saldo +' : 'Ajuste de saldo -',
    'cantidad': cantidad,
    'ingreso': sumar,
    'categoria': 'Ajuste de saldo',
    'esObjetivo': false,
    'esTransferencia': false,
    'esAjuste': true,
    'destinatarioId': '',
    'fecha': FieldValue.serverTimestamp(),
    'usuarioId': user!.uid,
  });
}
Future<void> guardarMiNombre(
  String parejaId,
  String nombre,
) =>
    db.collection('parejas').doc(parejaId).update({
      'nombresMiembros.${user!.uid}':
          nombre.trim().isEmpty ? 'Sin nombre' : nombre.trim(),
});

 Future<void> anadirMovimiento({
  required String parejaId,
  required String concepto,
  required double cantidad,
  required bool ingreso,
  required String categoria,
}) =>
    db.collection('parejas').doc(parejaId).collection('movimientos').add({
      'concepto': concepto.trim(),
      'cantidad': cantidad,
      'ingreso': ingreso,
      'categoria': categoria,
      'fecha': FieldValue.serverTimestamp(),
      'usuarioId': user!.uid,
    });

Future<void> transferirDinero({
  required String parejaId,
  required String destinatarioId,
  required double cantidad,
}) async {
  final uid = user!.uid;

  if (cantidad <= 0) {
    throw Exception('La cantidad debe ser mayor que 0.');
  }

  if (uid == destinatarioId) {
    throw Exception('No puedes transferirte dinero a ti mismo.');
  }

  final parejaRef = db.collection('parejas').doc(parejaId);
  final parejaSnap = await parejaRef.get();

  if (!parejaSnap.exists) {
    throw Exception('No se ha encontrado la pareja.');
  }

  final datos = parejaSnap.data()!;

  final miembros = List<String>.from(
    datos['miembros'] ?? const [],
  );

  if (!miembros.contains(uid) || !miembros.contains(destinatarioId)) {
    throw Exception('Los dos usuarios deben pertenecer a la pareja.');
  }

  final movimientosSnap = await parejaRef
      .collection('movimientos')
      .orderBy('fecha')
      .get();

  double saldo = 0;

  final posicion = miembros.indexOf(uid);

  if (posicion == 0) {
    saldo =
        (datos['saldoInicialMiembro1'] as num?)?.toDouble() ?? 0;
  } else {
    saldo =
        (datos['saldoInicialMiembro2'] as num?)?.toDouble() ?? 0;
  }

  for (final doc in movimientosSnap.docs) {
    final movimiento = doc.data();

    if (movimiento['esObjetivo'] == true) {
      continue;
    }

    final cantidadMovimiento =
        (movimiento['cantidad'] as num?)?.toDouble() ?? 0;

    final esTransferencia =
        movimiento['esTransferencia'] as bool? ?? false;

    if (esTransferencia) {
      final emisor =
          movimiento['usuarioId'] as String? ?? '';
      final receptor =
          movimiento['destinatarioId'] as String? ?? '';

      if (emisor == uid) {
        saldo -= cantidadMovimiento;
      } else if (receptor == uid) {
        saldo += cantidadMovimiento;
      }

      continue;
    }

    final usuarioMovimiento =
        movimiento['usuarioId'] as String? ?? '';

    if (usuarioMovimiento != uid) {
      continue;
    }

    final ingreso =
        movimiento['ingreso'] as bool? ?? false;

    if (ingreso) {
      saldo += cantidadMovimiento;
    } else {
      saldo -= cantidadMovimiento;
    }
  }

  if (cantidad > saldo) {
    throw Exception(
      'No tienes suficiente dinero para hacer esta transferencia.',
    );
  }

  final nombres =
      Map<String, dynamic>.from(
    datos['nombresMiembros'] ?? {},
  );

  final nombreEmisor =
      nombres[uid]?.toString() ?? 'Tú';

  final nombreDestinatario =
      nombres[destinatarioId]?.toString() ?? 'Tu pareja';

  await parejaRef.collection('movimientos').add({
    'concepto': '$nombreEmisor → $nombreDestinatario',
    'cantidad': cantidad,
    'ingreso': false,
    'esObjetivo': false,
    'esTransferencia': true,
    'usuarioId': uid,
    'destinatarioId': destinatarioId,
    'fecha': FieldValue.serverTimestamp(),
  });
}  Future<void> borrarMovimiento(String parejaId, String movimientoId) => db
      .collection('parejas')
      .doc(parejaId)
      .collection('movimientos')
      .doc(movimientoId)
      .delete();
  
  Future<void> crearObjetivo({
  required String parejaId,
  required String nombre,
  required double objetivo,
}) =>
    db
        .collection('parejas')
        .doc(parejaId)
        .collection('objetivos')
        .add({
      'nombre': nombre.trim(),
      'objetivo': objetivo,
      'ahorrado': 0.0,
      'aportadoMiembro1': 0.0,
      'aportadoMiembro2': 0.0,
      'creadoEn': FieldValue.serverTimestamp(),
    });

Future<void> aportarObjetivo({
  required String parejaId,
  required String objetivoId,
  required double cantidad,
}) async {
  final uid = user!.uid;

  if (cantidad <= 0) {
    throw Exception('La cantidad debe ser mayor que 0.');
  }

  final parejaRef = db.collection('parejas').doc(parejaId);
  final objetivoRef =
      parejaRef.collection('objetivos').doc(objetivoId);

  final parejaSnap = await parejaRef.get();
  final objetivoSnap = await objetivoRef.get();

  if (!parejaSnap.exists || !objetivoSnap.exists) {
    throw Exception('No se ha encontrado la pareja o el objetivo.');
  }

  final parejaData = parejaSnap.data()!;
  final objetivoData = objetivoSnap.data()!;

  final miembros = List<String>.from(
    parejaData['miembros'] ?? const [],
  );

  final posicion = miembros.indexOf(uid);

  if (posicion == -1) {
    throw Exception('No perteneces a esta pareja.');
  }

  final saldo = posicion == 0
      ? (parejaData['saldoInicialMiembro1'] as num?)
              ?.toDouble() ??
          0
      : (parejaData['saldoInicialMiembro2'] as num?)
              ?.toDouble() ??
          0;

  if (cantidad > saldo) {
    throw Exception('No tienes suficiente dinero en tu cuenta.');
  }

  final ahorrado =
      (objetivoData['ahorrado'] as num?)?.toDouble() ?? 0;

  final objetivo =
      (objetivoData['objetivo'] as num?)?.toDouble() ?? 0;

  if (ahorrado + cantidad > objetivo) {
    throw Exception(
      'No puedes aportar más de lo que falta para el objetivo.',
    );
  }

  final batch = db.batch();

  batch.update(
    objetivoRef,
    {
      'ahorrado': FieldValue.increment(cantidad),
    },
  );

  if (posicion == 0) {
    batch.update(
      parejaRef,
      {
        'saldoInicialMiembro1':
            FieldValue.increment(-cantidad),
      },
    );
  } else {
    batch.update(
      parejaRef,
      {
        'saldoInicialMiembro2':
            FieldValue.increment(-cantidad),
      },
    );
  }

  await batch.commit();
await parejaRef.collection('movimientos').add({
  'concepto': 'Aportación al objetivo: ${objetivoData['nombre']}',
  'cantidad': cantidad,
  'ingreso': false,
  'esObjetivo': true,
  'fecha': FieldValue.serverTimestamp(),
  'usuarioId': uid,
});}

Future<void> retirarObjetivo({
  required String parejaId,
  required String objetivoId,
  required double cantidad,
}) async {
  final uid = user!.uid;

  if (cantidad <= 0) {
    throw Exception('La cantidad debe ser mayor que 0.');
  }

  final parejaRef = db.collection('parejas').doc(parejaId);
  final objetivoRef =
      parejaRef.collection('objetivos').doc(objetivoId);

  final parejaSnap = await parejaRef.get();
  final objetivoSnap = await objetivoRef.get();

  if (!parejaSnap.exists || !objetivoSnap.exists) {
    throw Exception('No se ha encontrado la pareja o el objetivo.');
  }

  final parejaData = parejaSnap.data()!;
  final objetivoData = objetivoSnap.data()!;

  final miembros = List<String>.from(
    parejaData['miembros'] ?? const [],
  );

  final posicion = miembros.indexOf(uid);

  if (posicion == -1) {
    throw Exception('No perteneces a esta pareja.');
  }

  final ahorrado =
      (objetivoData['ahorrado'] as num?)?.toDouble() ?? 0;

  if (cantidad > ahorrado) {
    throw Exception(
      'No hay suficiente dinero en el objetivo.',
    );
  }

  final batch = db.batch();

  batch.update(
    objetivoRef,
    {
      'ahorrado': FieldValue.increment(-cantidad),
    },
  );

  if (posicion == 0) {
    batch.update(
      parejaRef,
      {
        'saldoInicialMiembro1':
            FieldValue.increment(cantidad),
      },
    );
  } else {
    batch.update(
      parejaRef,
      {
        'saldoInicialMiembro2':
            FieldValue.increment(cantidad),
      },
    );
  }

  await batch.commit();
await parejaRef.collection('movimientos').add({
  'concepto': 'Retirada del objetivo: ${objetivoData['nombre']}',
  'cantidad': cantidad,
  'ingreso': true,
  'esObjetivo': true,
  'fecha': FieldValue.serverTimestamp(),
  'usuarioId': uid,
});}

  Future<void> borrarObjetivo({
    required String parejaId,
    required String objetivoId,
  }) =>
      db
          .collection('parejas')
          .doc(parejaId)
          .collection('objetivos')
          .doc(objetivoId)
          .delete();

  Future<String> _uniqueCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    var n = now;
    while (true) {
      final code = List.generate(6, (_) {
        final i = n % chars.length;
        n = (n ~/ chars.length) + 17;
        return chars[i];
      }).join();
      final exists = await db.collection('codigosUnion').doc(code).get();
      if (!exists.exists) return code;
      n += 31;
    }
  }
StreamSubscription escucharMovimientos(
  String parejaId,
  void Function(String titulo, String mensaje) mostrar,
) {
  return db
      .collection('parejas')
      .doc(parejaId)
      .collection('movimientos')
      .orderBy('fecha', descending: true)
      .snapshots()
      .listen((snapshot) {
    for (final cambio in snapshot.docChanges) {
      if (cambio.type != DocumentChangeType.added) {
        continue;
      }

      final datos = cambio.doc.data();

      if (datos == null) {
        continue;
      }

final usuarioMovimiento = datos['usuarioId'] as String? ?? '';

print('MOVIMIENTO DE: $usuarioMovimiento');
print('USUARIO ACTUAL: ${user?.uid}');

if (usuarioMovimiento == user?.uid) {
  continue;
}
      final concepto =
          datos['concepto'] as String? ?? 'Nuevo movimiento';
      final cantidad =
          (datos['cantidad'] as num?)?.toDouble() ?? 0;

      final textoCantidad =
          cantidad.toStringAsFixed(2).replaceAll('.', ',');

      mostrar(
        'Nuevo movimiento',
        '$concepto: $textoCantidad €',
      );
    }
  });
}
Future<void> comprobarGastosRecurrentes(String parejaId) async {
  final uid = user?.uid;
  if (uid == null) return;

  final ahora = DateTime.now();

  final consulta = await db
      .collection('parejas')
      .doc(parejaId)
      .collection('gastosRecurrentes')
      .where('activo', isEqualTo: true)
      .get();

  for (final doc in consulta.docs) {
    final datos = doc.data();

    final frecuencia = datos['frecuencia'] as String? ?? 'Mensual';
    final esIngreso = datos['esIngreso'] as bool? ?? false;
    final cantidad = (datos['cantidad'] as num?)?.toDouble() ?? 0;
    final concepto = datos['concepto'] as String? ?? '';
    final categoria = datos['categoria'] as String? ?? 'Otros';
    final dia = datos['dia'] as int? ?? 1;
    final diaSemana = datos['diaSemana'] as int? ?? 1;
    final mes = datos['mes'] as int? ?? 1;

    if (cantidad <= 0 || concepto.isEmpty) continue;

    final creado = (datos['creado'] as Timestamp?)?.toDate();

    DateTime? fechaCorrespondiente;

    if (frecuencia == 'Semanal') {
      final diferencia =
          (ahora.weekday - diaSemana + 7) % 7;

      fechaCorrespondiente = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
      ).subtract(Duration(days: diferencia));
    } else if (frecuencia == 'Mensual') {
      final ultimoDia =
          DateTime(ahora.year, ahora.month + 1, 0).day;

      fechaCorrespondiente = DateTime(
        ahora.year,
        ahora.month,
        dia > ultimoDia ? ultimoDia : dia,
      );
    } else if (frecuencia == 'Anual') {
      final ultimoDia =
          DateTime(ahora.year, mes + 1, 0).day;

      fechaCorrespondiente = DateTime(
        ahora.year,
        mes,
        dia > ultimoDia ? ultimoDia : dia,
      );
    }

    if (fechaCorrespondiente == null) continue;

    if (creado != null &&
        fechaCorrespondiente.isBefore(
          DateTime(creado.year, creado.month, creado.day),
        )) {
      continue;
    }

    final fechaRegistro = DateTime(
      fechaCorrespondiente.year,
      fechaCorrespondiente.month,
      fechaCorrespondiente.day,
    );

    final fechaKey =
        '${fechaRegistro.year}-'
        '${fechaRegistro.month.toString().padLeft(2, '0')}-'
        '${fechaRegistro.day.toString().padLeft(2, '0')}';

    final ultimaFecha = datos['ultimaFecha'] as String?;

    if (ultimaFecha == fechaKey) {
      continue;
    }

    await db
        .collection('parejas')
        .doc(parejaId)
        .collection('movimientos')
        .add({
      'concepto': concepto,
      'cantidad': cantidad,
      'ingreso': esIngreso,
      'categoria': categoria,
      'esObjetivo': false,
      'esTransferencia': false,
      'destinatarioId': '',
      'fecha': Timestamp.fromDate(fechaRegistro),
      'usuarioId': uid,
      'recurrenteId': doc.id,
'esRecurrente': true,
    });

    await doc.reference.update({
      'ultimaFecha': fechaKey,
    });
  }
}
}

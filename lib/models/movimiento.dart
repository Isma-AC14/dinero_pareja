import 'package:cloud_firestore/cloud_firestore.dart';

class Movimiento {
  final String id;
  final String concepto;
  final double cantidad;
  final bool ingreso;
final bool esObjetivo;
final bool esTransferencia;
final bool esAjuste;
final String destinatarioId;
final bool esRecurrente;
  final DateTime fecha;
  final String usuarioId;

  const Movimiento({
    required this.id,
    required this.concepto,
    required this.cantidad,
    required this.ingreso,
required this.esObjetivo,
required this.esTransferencia,
required this.esAjuste,
required this.esRecurrente,
required this.destinatarioId,
    required this.fecha,
    required this.usuarioId,
  });

  factory Movimiento.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final timestamp = d['fecha'] as Timestamp?;
    return Movimiento(
      id: doc.id,
      concepto: d['concepto'] as String? ?? '',
      cantidad: (d['cantidad'] as num?)?.toDouble() ?? 0,
      ingreso: d['ingreso'] as bool? ?? false,
esObjetivo: d['esObjetivo'] as bool? ?? false,
esTransferencia: d['esTransferencia'] as bool? ?? false,
esAjuste: d['esAjuste'] as bool? ?? false,
esRecurrente: d['esRecurrente'] as bool? ?? false,
destinatarioId: d['destinatarioId'] as String? ?? '',
      fecha: timestamp?.toDate() ?? DateTime.now(),
      usuarioId: d['usuarioId'] as String? ?? '',
    );
  }
}

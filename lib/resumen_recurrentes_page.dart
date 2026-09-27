import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResumenRecurrentesPage extends StatelessWidget {
  final String parejaId;

  const ResumenRecurrentesPage({
    super.key,
    required this.parejaId,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen recurrentes'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('parejas')
            .doc(parejaId)
            .collection('gastosRecurrentes')
            .where('activo', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar los recurrentes:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final documentos = snapshot.data?.docs ?? [];

          double gastosMensuales = 0;
          double ingresosMensuales = 0;

          for (final doc in documentos) {
            final datos = doc.data();

            final cantidad =
                (datos['cantidad'] as num?)?.toDouble() ?? 0;

            final frecuencia =
                datos['frecuencia'] as String? ?? 'Mensual';

            final esIngreso =
                datos['esIngreso'] as bool? ?? false;

            double mensual = 0;

            if (frecuencia == 'Mensual') {
              mensual = cantidad;
            } else if (frecuencia == 'Semanal') {
              mensual = cantidad * 52 / 12;
            } else if (frecuencia == 'Anual') {
              mensual = cantidad / 12;
            }

            if (esIngreso) {
              ingresosMensuales += mensual;
            } else {
              gastosMensuales += mensual;
            }
          }

          final diferencia =
              ingresosMensuales - gastosMensuales;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Gastos recurrentes mensuales',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${gastosMensuales.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Ingresos recurrentes mensuales',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${ingresosMensuales.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Resultado mensual',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${diferencia.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        diferencia >= 0
                            ? 'Después de los movimientos recurrentes'
                            : 'Los gastos recurrentes superan los ingresos recurrentes',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Movimientos activos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (documentos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No hay movimientos recurrentes activos.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...documentos.map((doc) {
                  final datos = doc.data();

                  final cantidad =
                      (datos['cantidad'] as num?)?.toDouble() ?? 0;

                  final frecuencia =
                      datos['frecuencia'] as String? ?? 'Mensual';

                  final esIngreso =
                      datos['esIngreso'] as bool? ?? false;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          esIngreso
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                        ),
                      ),
                      title: Text(
                        datos['concepto'] as String? ?? '',
                      ),
                      subtitle: Text(
                        '${esIngreso ? 'Ingreso' : 'Gasto'} · $frecuencia',
                      ),
                      trailing: Text(
                        '${cantidad.toStringAsFixed(2)} €',
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
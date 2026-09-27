import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ResumenPage extends StatefulWidget {
  final String parejaId;

  const ResumenPage({
    super.key,
    required this.parejaId,
  });

  @override
  State<ResumenPage> createState() => _ResumenPageState();
}

class _ResumenPageState extends State<ResumenPage> {
  DateTime mesSeleccionado = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    final dinero = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen mensual'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('parejas')
            .doc(widget.parejaId)
            .collection('movimientos')
            .orderBy('fecha', descending: true)
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
                'Error al cargar el resumen:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          double ingresos = 0;
          double gastos = 0;

          final Map<String, double> gastosPorCategoria = {};

          for (final doc in snapshot.data?.docs ?? []) {
            final datos = doc.data();

            if (datos['esObjetivo'] == true ||
                datos['esTransferencia'] == true) {
              continue;
            }

            final fecha = datos['fecha'] as Timestamp?;

            if (fecha == null) {
              continue;
            }

            final fechaMovimiento = fecha.toDate();

            if (fechaMovimiento.year != mesSeleccionado.year ||
                fechaMovimiento.month != mesSeleccionado.month) {
              continue;
            }

            final cantidad =
                (datos['cantidad'] as num?)?.toDouble() ?? 0;

            final ingreso =
                datos['ingreso'] as bool? ?? false;

            if (ingreso) {
              ingresos += cantidad;
            } else {
              gastos += cantidad;

              final categoria =
                  datos['categoria'] as String? ?? 'Otros';

              gastosPorCategoria[categoria] =
                  (gastosPorCategoria[categoria] ?? 0) + cantidad;
            }
          }

          final balance = ingresos - gastos;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                mesSeleccionado = DateTime(
                                  mesSeleccionado.year,
                                  mesSeleccionado.month - 1,
                                );
                              });
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            DateFormat(
                              'MMMM yyyy',
                              'es_ES',
                            ).format(mesSeleccionado),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                mesSeleccionado = DateTime(
                                  mesSeleccionado.year,
                                  mesSeleccionado.month + 1,
                                );
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Balance del mes',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dinero.format(balance),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_downward),
                            const SizedBox(height: 8),
                            const Text('Ingresos'),
                            const SizedBox(height: 6),
                            Text(
                              dinero.format(ingresos),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_upward),
                            const SizedBox(height: 8),
                            const Text('Gastos'),
                            const SizedBox(height: 6),
                            Text(
                              dinero.format(gastos),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gastos por categoría',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (gastosPorCategoria.isEmpty)
                        const Text(
                          'No hay gastos con categoría.',
                        )
                      else
                        ...gastosPorCategoria.entries.map(
                          (entrada) => Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entrada.key),
                                Text(
                                  dinero.format(entrada.value),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
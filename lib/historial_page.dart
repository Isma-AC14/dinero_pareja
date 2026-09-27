import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/movimiento.dart';

class HistorialPage extends StatefulWidget {
  final String parejaId;

  const HistorialPage({
    super.key,
    required this.parejaId,
  });

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
  }
  String filtro = 'Todos';
DateTime mesSeleccionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
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
                'Error al cargar el historial:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final todosLosMovimientos = (snapshot.data?.docs ?? [])
              .map(Movimiento.fromDoc)
              .toList();

          final movimientos = todosLosMovimientos.where((m) {
final fecha = m.fecha;

if (fecha.year != mesSeleccionado.year ||
    fecha.month != mesSeleccionado.month) {
  return false;
}
           if (filtro == 'Ingresos') {
  return m.ingreso &&
      !m.esObjetivo &&
      !m.esTransferencia &&
      !m.esAjuste;
}

if (filtro == 'Gastos') {
  return !m.ingreso &&
      !m.esObjetivo &&
      !m.esTransferencia &&
      !m.esAjuste;
}

            if (filtro == 'Objetivos') {
              return m.esObjetivo;
            }

            if (filtro == 'Transferencias') {
              return m.esTransferencia;
            }

            return true;
          }).toList();

          return Column(
            children: [
Padding(
  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        DateFormat('MMMM yyyy', 'es_ES').format(mesSeleccionado),
        style: Theme.of(context).textTheme.titleMedium,
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
),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: DropdownButtonFormField<String>(
                  initialValue: filtro,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar movimientos',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Todos',
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem(
                      value: 'Ingresos',
                      child: Text('Ingresos'),
                    ),
                    DropdownMenuItem(
                      value: 'Gastos',
                      child: Text('Gastos'),
                    ),
                    DropdownMenuItem(
                      value: 'Objetivos',
                      child: Text('Objetivos'),
                    ),
                    DropdownMenuItem(
                      value: 'Transferencias',
                      child: Text('Transferencias'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      filtro = valor;
                    });
                  },
                ),
              ),
              Expanded(
                child: movimientos.isEmpty
                    ? Center(
                        child: Text(
                          filtro == 'Todos'
                              ? 'Todavía no hay movimientos.'
                              : 'No hay movimientos de este tipo.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: movimientos.length,
                        itemBuilder: (context, index) {
                          final m = movimientos[index];

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  m.esTransferencia
                                      ? Icons.swap_horiz
                                      : m.esObjetivo
                                          ? Icons.savings
                                          : m.ingreso
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                ),
                              ),
                              title: Text(m.concepto),
                              subtitle: Text(
  '${DateFormat(
    'dd/MM/yyyy HH:mm',
  ).format(m.fecha)}'
  '${m.esRecurrente ? '\n🔄 Recurrente' : ''}',
),
                              trailing: Text(
                                '${m.esTransferencia || m.esObjetivo ? '' : m.ingreso ? '+' : '-'}'
                                '${NumberFormat.currency(
                                  locale: 'es_ES',
                                  symbol: '€',
                                  decimalDigits: 2,
                                ).format(m.cantidad)}',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
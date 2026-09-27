import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class ObjetivosPage extends StatefulWidget {
  final String parejaId;

  const ObjetivosPage({
    super.key,
    required this.parejaId,
  });

  @override
  State<ObjetivosPage> createState() => _ObjetivosPageState();
}

class _ObjetivosPageState extends State<ObjetivosPage> {
  final money = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
  );

  Future<void> nuevoObjetivo() async {
    final nombre = TextEditingController();
    final cantidad = TextEditingController();

    final resultado = await showDialog<List<dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo objetivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ejemplo: Parque Warner',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantidad,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad objetivo',
                suffixText: '€',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final objetivo = double.tryParse(
                cantidad.text.replaceAll(',', '.'),
              );

              if (nombre.text.trim().isNotEmpty &&
                  objetivo != null &&
                  objetivo > 0) {
                Navigator.pop(
                  context,
                  [
                    nombre.text.trim(),
                    objetivo,
                  ],
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (resultado == null) return;

    await firebase.crearObjetivo(
      parejaId: widget.parejaId,
      nombre: resultado[0] as String,
      objetivo: resultado[1] as double,
    );
  }

  Future<void> aportarDinero(
  String objetivoId,
  double ahorrado,
  double objetivo,
) async {
  final cantidad = TextEditingController();

  final valor = await showDialog<double>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Añadir dinero'),
      content: TextField(
        controller: cantidad,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: const InputDecoration(
          labelText: 'Cantidad',
          suffixText: '€',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final numero = double.tryParse(
              cantidad.text.replaceAll(',', '.'),
            );

            if (numero != null && numero > 0) {
              Navigator.pop(context, numero);
            }
          },
          child: const Text('Añadir'),
        ),
      ],
    ),
  );

  if (valor == null) return;

  try {
    await firebase.aportarObjetivo(
      parejaId: widget.parejaId,
      objetivoId: objetivoId,
      cantidad: valor,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dinero añadido al objetivo'),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }
}

Future<void> retirarDinero(
  String objetivoId,
  double ahorrado,
) async {
  final cantidad = TextEditingController();

  final valor = await showDialog<double>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Retirar dinero'),
      content: TextField(
        controller: cantidad,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: const InputDecoration(
          labelText: 'Cantidad',
          suffixText: '€',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final numero = double.tryParse(
              cantidad.text.replaceAll(',', '.'),
            );

            if (numero != null && numero > 0) {
              Navigator.pop(context, numero);
            }
          },
          child: const Text('Retirar'),
        ),
      ],
    ),
  );

  if (valor == null) return;

  try {
    await firebase.retirarObjetivo(
      parejaId: widget.parejaId,
      objetivoId: objetivoId,
      cantidad: valor,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dinero retirado del objetivo'),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: nuevoObjetivo,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firebase.objetivos(widget.parejaId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Error al cargar los objetivos:\n\n${snapshot.error}',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

if (!snapshot.hasData) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

          final objetivos = snapshot.data!.docs;

          if (objetivos.isEmpty) {
            return const Center(
              child: Text(
                'Todavía no tienes objetivos.\n\nPulsa + para crear uno.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: objetivos.length,
            itemBuilder: (context, index) {
              final doc = objetivos[index];
              final data = doc.data();

              final nombre = data['nombre']?.toString() ?? '';
              final objetivo =
                  (data['objetivo'] as num?)?.toDouble() ?? 0;
              final ahorrado =
                  (data['ahorrado'] as num?)?.toDouble() ?? 0;

              final progreso = objetivo > 0
                  ? (ahorrado / objetivo).clamp(0.0, 1.0)
                  : 0.0;

              final completado = ahorrado >= objetivo;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flag,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              nombre,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                          ),
                          IconButton(
  onPressed: () => aportarDinero(
    doc.id,
    ahorrado,
    objetivo,
  ),
  icon: const Icon(Icons.add_circle_outline),
  tooltip: 'Añadir dinero',
),

IconButton(
  onPressed: () => retirarDinero(
    doc.id,
    ahorrado,
  ),
  icon: const Icon(Icons.remove_circle_outline),
  tooltip: 'Retirar dinero',
),
       
                   IconButton(
                            onPressed: () async {
                              await firebase.borrarObjetivo(
                                parejaId: widget.parejaId,
                                objetivoId: doc.id,
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '${money.format(ahorrado)} / ${money.format(objetivo)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),

                      const SizedBox(height: 8),

                      LinearProgressIndicator(
                        value: progreso,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progreso * 100).toStringAsFixed(0)}%',
                          ),
                          if (completado)
                            const Text(
                              '¡Objetivo conseguido!',
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
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
}
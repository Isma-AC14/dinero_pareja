import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GastosRecurrentesPage extends StatefulWidget {
  final String parejaId;

  const GastosRecurrentesPage({
    super.key,
    required this.parejaId,
  });

  @override
  State<GastosRecurrentesPage> createState() =>
      _GastosRecurrentesPageState();
}

class _GastosRecurrentesPageState
    extends State<GastosRecurrentesPage> {
@override
void initState() {
  super.initState();
  cargarNombresMiembros();
}
  final db = FirebaseFirestore.instance;

Map<String, String> nombresMiembros = {};

String nombreCreador(String? creadorId) {
  if (creadorId == null || creadorId.isEmpty) {
    return 'Desconocido';
  }

  return nombresMiembros[creadorId] ?? 'Desconocido';
}
  Future<void> agregarGastoRecurrente() async {
    final concepto = TextEditingController();
    final cantidad = TextEditingController();

    String categoria = 'Casa';
String frecuencia = 'Mensual';
bool esIngreso = false;
int dia = 1;
int diaSemana = 1;
int mes = 1;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nuevo gasto recurrente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: concepto,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidad,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      suffixText: '€',
                    ),
                  ),
                  const SizedBox(height: 12),
DropdownButtonFormField<bool>(
  initialValue: esIngreso,
  decoration: const InputDecoration(
    labelText: 'Tipo',
  ),
  items: const [
    DropdownMenuItem(
      value: false,
      child: Text('Gasto'),
    ),
    DropdownMenuItem(
      value: true,
      child: Text('Ingreso'),
    ),
  ],
  onChanged: (valor) {
    if (valor != null) {
      setDialogState(() {
        esIngreso = valor;
      });
    }
  },
),
const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Casa',
                        child: Text('Casa'),
                      ),
                      DropdownMenuItem(
                        value: 'Comida',
                        child: Text('Comida'),
                      ),
                      DropdownMenuItem(
                        value: 'Coche',
                        child: Text('Coche'),
                      ),
                      DropdownMenuItem(
                        value: 'Ocio',
                        child: Text('Ocio'),
                      ),
                      DropdownMenuItem(
                        value: 'Compras',
                        child: Text('Compras'),
                      ),
                      DropdownMenuItem(
                        value: 'Salud',
                        child: Text('Salud'),
                      ),
                      DropdownMenuItem(
                        value: 'Transporte',
                        child: Text('Transporte'),
                      ),
                      DropdownMenuItem(
                        value: 'Otros',
                        child: Text('Otros'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setDialogState(() {
                          categoria = valor;
                        });
                      }
                    },
                  ),

const SizedBox(height: 12),

if (frecuencia == 'Semanal')
  DropdownButtonFormField<int>(
    initialValue: diaSemana,
    decoration: const InputDecoration(
      labelText: 'Día de la semana',
    ),
    items: const [
      DropdownMenuItem(value: 1, child: Text('Lunes')),
      DropdownMenuItem(value: 2, child: Text('Martes')),
      DropdownMenuItem(value: 3, child: Text('Miércoles')),
      DropdownMenuItem(value: 4, child: Text('Jueves')),
      DropdownMenuItem(value: 5, child: Text('Viernes')),
      DropdownMenuItem(value: 6, child: Text('Sábado')),
      DropdownMenuItem(value: 7, child: Text('Domingo')),
    ],
    onChanged: (valor) {
      if (valor != null) {
        setDialogState(() {
          diaSemana = valor;
        });
      }
    },
  ),

if (frecuencia == 'Mensual')
  DropdownButtonFormField<int>(
    initialValue: dia,
    decoration: const InputDecoration(
      labelText: 'Día de cobro',
    ),
    items: List.generate(
      31,
      (index) => DropdownMenuItem(
        value: index + 1,
        child: Text('Día ${index + 1}'),
      ),
    ),
    onChanged: (valor) {
      if (valor != null) {
        setDialogState(() {
          dia = valor;
        });
      }
    },
  ),

if (frecuencia == 'Anual') ...[
  DropdownButtonFormField<int>(
    initialValue: mes,
    decoration: const InputDecoration(
      labelText: 'Mes',
    ),
    items: const [
      DropdownMenuItem(value: 1, child: Text('Enero')),
      DropdownMenuItem(value: 2, child: Text('Febrero')),
      DropdownMenuItem(value: 3, child: Text('Marzo')),
      DropdownMenuItem(value: 4, child: Text('Abril')),
      DropdownMenuItem(value: 5, child: Text('Mayo')),
      DropdownMenuItem(value: 6, child: Text('Junio')),
      DropdownMenuItem(value: 7, child: Text('Julio')),
      DropdownMenuItem(value: 8, child: Text('Agosto')),
      DropdownMenuItem(value: 9, child: Text('Septiembre')),
      DropdownMenuItem(value: 10, child: Text('Octubre')),
      DropdownMenuItem(value: 11, child: Text('Noviembre')),
      DropdownMenuItem(value: 12, child: Text('Diciembre')),
    ],
    onChanged: (valor) {
      if (valor != null) {
        setDialogState(() {
          mes = valor;
        });
      }
    },
  ),
  const SizedBox(height: 12),
  DropdownButtonFormField<int>(
    initialValue: dia,
    decoration: const InputDecoration(
      labelText: 'Día',
    ),
    items: List.generate(
      31,
      (index) => DropdownMenuItem(
        value: index + 1,
        child: Text('Día ${index + 1}'),
      ),
    ),
    onChanged: (valor) {
      if (valor != null) {
        setDialogState(() {
          dia = valor;
        });
      }
    },
  ),
],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: frecuencia,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Mensual',
                        child: Text('Mensual'),
                      ),
                      DropdownMenuItem(
                        value: 'Semanal',
                        child: Text('Semanal'),
                      ),
                      DropdownMenuItem(
                        value: 'Anual',
                        child: Text('Anual'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setDialogState(() {
                          frecuencia = valor;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final importe = double.tryParse(
                    cantidad.text.replaceAll(',', '.'),
                  );

                  if (concepto.text.trim().isEmpty ||
                      importe == null ||
                      importe <= 0) {
                    return;
                  }

                  await db
                      .collection('parejas')
                      .doc(widget.parejaId)
                      .collection('gastosRecurrentes')
                      .add({
                    'concepto': concepto.text.trim(),
                    'cantidad': importe,
                    'categoria': categoria,
                    'frecuencia': frecuencia,
'esIngreso': esIngreso,
'dia': dia,
'diaSemana': diaSemana,
'mes': mes,
'creadorId': FirebaseAuth.instance.currentUser!.uid,
'activo': true,
                    'creado': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    if (resultado == true && mounted) {
      setState(() {});
    }
  }

String _nombreDiaSemana(int dia) {
  const dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  return dias[dia - 1];
}

String _nombreMes(int mes) {
  const meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return meses[mes - 1];
}

Future<void> editarGastoRecurrente(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) async {
  final datos = doc.data();

  final concepto = TextEditingController(
    text: datos['concepto'] as String? ?? '',
  );

  final cantidad = TextEditingController(
    text: ((datos['cantidad'] as num?)?.toDouble() ?? 0)
        .toString(),
  );

  String categoria = datos['categoria'] as String? ?? 'Otros';
  String frecuencia = datos['frecuencia'] as String? ?? 'Mensual';
  bool esIngreso = datos['esIngreso'] as bool? ?? false;
  int dia = datos['dia'] as int? ?? 1;
  int diaSemana = datos['diaSemana'] as int? ?? 1;
  int mes = datos['mes'] as int? ?? 1;

  await showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar movimiento recurrente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: concepto,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidad,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      suffixText: '€',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool>(
                    initialValue: esIngreso,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: false,
                        child: Text('Gasto'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Ingreso'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setDialogState(() {
                          esIngreso = valor;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Casa',
                        child: Text('Casa'),
                      ),
                      DropdownMenuItem(
                        value: 'Comida',
                        child: Text('Comida'),
                      ),
                      DropdownMenuItem(
                        value: 'Coche',
                        child: Text('Coche'),
                      ),
                      DropdownMenuItem(
                        value: 'Ocio',
                        child: Text('Ocio'),
                      ),
                      DropdownMenuItem(
                        value: 'Compras',
                        child: Text('Compras'),
                      ),
                      DropdownMenuItem(
                        value: 'Salud',
                        child: Text('Salud'),
                      ),
                      DropdownMenuItem(
                        value: 'Transporte',
                        child: Text('Transporte'),
                      ),
                      DropdownMenuItem(
                        value: 'Otros',
                        child: Text('Otros'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setDialogState(() {
                          categoria = valor;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: frecuencia,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Mensual',
                        child: Text('Mensual'),
                      ),
                      DropdownMenuItem(
                        value: 'Semanal',
                        child: Text('Semanal'),
                      ),
                      DropdownMenuItem(
                        value: 'Anual',
                        child: Text('Anual'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setDialogState(() {
                          frecuencia = valor;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (frecuencia == 'Semanal')
                    DropdownButtonFormField<int>(
                      initialValue: diaSemana,
                      decoration: const InputDecoration(
                        labelText: 'Día de la semana',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Lunes'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Martes'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Miércoles'),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text('Jueves'),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text('Viernes'),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child: Text('Sábado'),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child: Text('Domingo'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() {
                            diaSemana = valor;
                          });
                        }
                      },
                    ),
                  if (frecuencia == 'Mensual')
                    DropdownButtonFormField<int>(
                      initialValue: dia,
                      decoration: const InputDecoration(
                        labelText: 'Día de cobro',
                      ),
                      items: List.generate(
                        31,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('Día ${index + 1}'),
                        ),
                      ),
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() {
                            dia = valor;
                          });
                        }
                      },
                    ),
                  if (frecuencia == 'Anual') ...[
                    DropdownButtonFormField<int>(
                      initialValue: mes,
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Enero'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Febrero'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Marzo'),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text('Abril'),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text('Mayo'),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child: Text('Junio'),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child: Text('Julio'),
                        ),
                        DropdownMenuItem(
                          value: 8,
                          child: Text('Agosto'),
                        ),
                        DropdownMenuItem(
                          value: 9,
                          child: Text('Septiembre'),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text('Octubre'),
                        ),
                        DropdownMenuItem(
                          value: 11,
                          child: Text('Noviembre'),
                        ),
                        DropdownMenuItem(
                          value: 12,
                          child: Text('Diciembre'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() {
                            mes = valor;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: dia,
                      decoration: const InputDecoration(
                        labelText: 'Día',
                      ),
                      items: List.generate(
                        31,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('Día ${index + 1}'),
                        ),
                      ),
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() {
                            dia = valor;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final importe = double.tryParse(
                    cantidad.text.replaceAll(',', '.'),
                  );

                  if (concepto.text.trim().isEmpty ||
                      importe == null ||
                      importe <= 0) {
                    return;
                  }

                  await doc.reference.update({
                    'concepto': concepto.text.trim(),
                    'cantidad': importe,
                    'categoria': categoria,
                    'frecuencia': frecuencia,
                    'esIngreso': esIngreso,
                    'dia': dia,
                    'diaSemana': diaSemana,
                    'mes': mes,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> cargarNombresMiembros() async {
  final doc = await db
      .collection('parejas')
      .doc(widget.parejaId)
      .get();

  final datos = doc.data();

  if (datos == null) return;

  final nombres = datos['nombresMiembros'];

  if (nombres is Map) {
    setState(() {
      nombresMiembros = nombres.map(
        (clave, valor) => MapEntry(
          clave.toString(),
          valor.toString(),
        ),
      );
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos recurrentes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: agregarGastoRecurrente,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('parejas')
            .doc(widget.parejaId)
            .collection('gastosRecurrentes')
            .orderBy('creado', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar los gastos:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final gastos = snapshot.data?.docs ?? [];

          if (gastos.isEmpty) {
            return const Center(
              child: Text(
                'Todavía no hay gastos recurrentes.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: gastos.length,
            itemBuilder: (context, index) {
              final doc = gastos[index];
              final datos = doc.data();

              final cantidad =
                  (datos['cantidad'] as num?)?.toDouble() ?? 0;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.repeat),
                  ),
                  title: Text(
                    datos['concepto'] as String? ?? '',
                  ),
                  subtitle: Text(
  '${datos['esIngreso'] == true ? 'Ingreso' : 'Gasto'} · '
  '${datos['categoria'] ?? 'Otros'} · '
  '${datos['frecuencia'] ?? 'Mensual'} · '
  '${datos['frecuencia'] == 'Semanal'
      ? _nombreDiaSemana(datos['diaSemana'] as int? ?? 1)
      : datos['frecuencia'] == 'Mensual'
          ? 'Día ${datos['dia'] ?? 1}'
          : '${_nombreMes(datos['mes'] as int? ?? 1)} '
            'día ${datos['dia'] ?? 1}'}'
  '\nCreado por: ${nombreCreador(datos['creadorId'] as String?)}',
),
                  trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      '${cantidad.toStringAsFixed(2)} €',
    ),

IconButton(
  icon: const Icon(Icons.edit_outlined),
  onPressed: () {
    editarGastoRecurrente(doc);
  },
),
    IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () async {
        await doc.reference.delete();
      },
    ),
Switch(
  value: datos['activo'] as bool? ?? true,
  onChanged: (valor) async {
    await doc.reference.update({
      'activo': valor,
    });
  },
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
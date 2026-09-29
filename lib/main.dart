import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/movimiento.dart';
import 'services/firebase_service.dart';
import 'objetivos_page.dart';
import 'historial_page.dart';
import 'gastos_recurrentes_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'resumen_page.dart';
import 'resumen_recurrentes_page.dart';

late FirebaseService firebase;

final FlutterLocalNotificationsPlugin notificaciones =
    FlutterLocalNotificationsPlugin();

Future<void> mostrarNotificacion(String titulo, String mensaje) async {
  const detallesAndroid = AndroidNotificationDetails(
    'movimientos',
    'Movimientos',
    channelDescription: 'Notificaciones de movimientos de la pareja',
    importance: Importance.high,
    priority: Priority.high,
  );

  const detalles = NotificationDetails(
    android: detallesAndroid,
  );

  await notificaciones.show(
  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  title: titulo,
  body: mensaje,
  notificationDetails: detalles,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const DineroParejaApp());
}
class DineroParejaApp extends StatelessWidget {
  const DineroParejaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
  debugShowCheckedModeBanner: false,
  title: ':€',
  theme: ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.pink,
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF171717),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.pink,
      foregroundColor: Colors.black,
    ),
  ),
  home: const Scaffold(
  backgroundColor: Colors.black,
  body: Center(
    child: Text(
      'DINERO DE LOS DOS',
      style: TextStyle(
        color: Colors.pink,
        fontSize: 24,
      ),
    ),
  ),
),
);
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: firebase.authChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == null ? const LoginPage() : const ParejaPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false, loading = false;
  String? error;

  Future<void> submit() async {
    setState(() { loading = true; error = null; });
    try {
      if (register) {
        await firebase.register(email.text, password.text);
      } else {
        await firebase.login(email.text, password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'No se ha podido iniciar sesión.');
    } catch (_) {
      setState(() => error = 'Ha ocurrido un error.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(children: [
                Image.asset('assets/logo_ia.png', width: 100, height: 100),
const SizedBox(height: 16),
                const SizedBox(height: 16),
                Text(':€', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 28),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : submit, child: loading ? const CircularProgressIndicator() : Text(register ? 'Crear cuenta' : 'Entrar'))),
                TextButton(onPressed: loading ? null : () => setState(() { register = !register; error = null; }), child: Text(register ? 'Ya tengo una cuenta' : 'Crear una cuenta')),
              ]),
            ),
          ),
        ),
      );
}

class ParejaPage extends StatefulWidget {
  const ParejaPage({super.key});
  @override
  State<ParejaPage> createState() => _ParejaPageState();
}

class _ParejaPageState extends State<ParejaPage> {
  String? parejaId;
  bool buscando = true;

  @override
  void initState() { super.initState(); _buscarPareja(); }

  Future<void> _buscarPareja() async {
    final uid = firebase.user!.uid;
    final q = await firebase.db.collection('parejas').where('miembros', arrayContains: uid).limit(1).get();
    if (mounted) setState(() { parejaId = q.docs.isEmpty ? null : q.docs.first.id; buscando = false; });
  }

  Future<void> crear() async {
    final nombre = TextEditingController(text: 'Nuestra pareja');
final miNombre = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('Crear cuenta de pareja'),
      content: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    TextField(
      controller: nombre,
      decoration: const InputDecoration(labelText: 'Nombre de la pareja'),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: miNombre,
      decoration: const InputDecoration(labelText: 'Tu nombre'),
    ),
  ],
),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, nombre.text), child: const Text('Crear'))],
    ));
    if (result == null) return;
    final id = await firebase.createPareja(
  nombre: result,
  miNombre: miNombre.text,
);
    if (mounted) setState(() => parejaId = id);
  }

  Future<void> unirse() async {
    final code = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('Unirse a vuestra pareja'),
      content: TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código de 6 caracteres')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, code.text), child: const Text('Unirse'))],
    ));
    if (result == null) return;
    try {
      final id = await firebase.joinPareja(result);
      if (mounted) setState(() => parejaId = id);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  @override
  Widget build(BuildContext context) {
    if (buscando) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    if (parejaId == null) {
      return Scaffold(
        appBar: AppBar(
          actions: [

            IconButton(onPressed: firebase.logout, icon: const Icon(Icons.logout)),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Primero conecta los dos móviles.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: crear,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear pareja'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: unirse,
                  icon: const Icon(Icons.link),
                  label: const Text('Unirme con un código'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return HomePage(parejaId: parejaId!);
  }
}

class HomePage extends StatefulWidget {
  final String parejaId;
  const HomePage({super.key, required this.parejaId});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final money = NumberFormat.currency(locale: 'es_ES', symbol: '€');

@override
void initState() {
  super.initState();
  firebase.guardarTokenNotificaciones(widget.parejaId);
firebase.escucharMovimientos(
  widget.parejaId,
  mostrarNotificacion,
);
firebase.comprobarGastosRecurrentes(widget.parejaId);
}

  Future<void> saldoInicial(
  double miActual,
  double parejaActual,
  bool soyMiembro1,
) async {
  final miembro1 = TextEditingController(
    text: miActual == 0 ? '' : miActual.toStringAsFixed(2),
  );

  final miembro2 = TextEditingController(
    text: parejaActual == 0 ? '' : parejaActual.toStringAsFixed(2),
  );

  final valores = await showDialog<List<double>>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Dinero inicial'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: miembro1,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Lo que pones tú',
              suffixText: '€',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: miembro2,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Lo que pone tu pareja',
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
            final uno = double.tryParse(
              miembro1.text.replaceAll(',', '.'),
            ) ?? 0;

            final dos = double.tryParse(
              miembro2.text.replaceAll(',', '.'),
            ) ?? 0;

            Navigator.pop(context, [uno, dos]);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );

  if (valores != null) {
    final miembro1 = soyMiembro1 ? valores[0] : valores[1];
final miembro2 = soyMiembro1 ? valores[1] : valores[0];

await firebase.guardarSaldosIniciales(
  widget.parejaId,
  miembro1,
  miembro2,
);
  }
}

Future<void> ajustarSaldo() async {
  final cantidad = TextEditingController();
  bool sumar = true;

  final resultado = await showDialog<List<dynamic>>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Ajustar saldo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<bool>(
                initialValue: sumar,
                decoration: const InputDecoration(
                  labelText: 'Tipo de ajuste',
                ),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('⬆️ Subir saldo'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('⬇️ Bajar saldo'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setDialogState(() {
                      sumar = valor;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidad,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
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
                final valor = double.tryParse(
                  cantidad.text.replaceAll(',', '.'),
                );

                if (valor == null || valor <= 0) return;

                Navigator.pop(context, [valor, sumar]);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );

  if (resultado == null) return;

  final cantidadAjuste = resultado[0] as double;
  final sumarAjuste = resultado[1] as bool;

  await firebase.ajustarSaldo(
    parejaId: widget.parejaId,
    cantidad: cantidadAjuste,
    sumar: sumarAjuste,
  );
}

  Future<void> movimiento(bool ingreso) async {
    final concepto = TextEditingController();
final cantidad = TextEditingController();
String categoria = 'Otros';
    final m = await showDialog<List<dynamic>>(context: context, builder: (_) => AlertDialog(title: Text(ingreso ? 'Añadir ingreso' : 'Añadir gasto'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: concepto, decoration: const InputDecoration(labelText: 'Concepto')), const SizedBox(height: 10),
if (!ingreso)
  DropdownButtonFormField<String>(
    initialValue: categoria,
    decoration: const InputDecoration(
      labelText: 'Categoría',
    ),
    items: const [
      DropdownMenuItem(value: 'Casa', child: Text('Casa')),
      DropdownMenuItem(value: 'Comida', child: Text('Comida')),
      DropdownMenuItem(value: 'Coche', child: Text('Coche')),
      DropdownMenuItem(value: 'Ocio', child: Text('Ocio')),
      DropdownMenuItem(value: 'Compras', child: Text('Compras')),
      DropdownMenuItem(value: 'Salud', child: Text('Salud')),
      DropdownMenuItem(value: 'Transporte', child: Text('Transporte')),
      DropdownMenuItem(value: 'Otros', child: Text('Otros')),
    ],
    onChanged: (valor) {
      if (valor != null) categoria = valor;
    },
  ),
const SizedBox(height: 10), TextField(controller: cantidad, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cantidad', suffixText: '€'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { final c = double.tryParse(cantidad.text.replaceAll(',', '.')); if (concepto.text.trim().isNotEmpty && c != null && c > 0) Navigator.pop(context, [concepto.text.trim(), c, categoria]); }, child: const Text('Guardar'))]));
    if (m != null) {
  await firebase.anadirMovimiento(
    parejaId: widget.parejaId,
    concepto: m[0] as String,
    cantidad: m[1] as double,
    ingreso: ingreso,
    categoria: m[2] as String,
  );
}
  }

Future<void> transferencia(
  List<String> miembros,
  String miUid,
) async {  final cantidad = TextEditingController();

  final otrosMiembros =
      miembros.where((id) => id != miUid).toList();

  if (otrosMiembros.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todavía no hay otro miembro en la pareja.'),
      ),
    );
    return;
  }

  final destinatario = otrosMiembros.first;

  final resultado = await showDialog<double>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Pasar dinero'),
      content: TextField(
        controller: cantidad,
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
            final c = double.tryParse(
              cantidad.text.replaceAll(',', '.'),
            );

            if (c != null && c > 0) {
              Navigator.pop(context, c);
            }
          },
          child: const Text('Pasar dinero'),
        ),
      ],
    ),
  );

  if (resultado == null) return;

  try {
    await firebase.transferirDinero(
      parejaId: widget.parejaId,
      destinatarioId: destinatario,
      cantidad: resultado,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dinero transferido correctamente.'),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firebase.pareja(widget.parejaId),
      builder: (context, parejaSnap) {
        final data = parejaSnap.data?.data() ?? {};
        final inicial = (data['saldoInicial'] as num?)?.toDouble() ?? 0;
final saldoMiembro1 =
    (data['saldoInicialMiembro1'] as num?)?.toDouble() ?? 0;

final saldoMiembro2 =
    (data['saldoInicialMiembro2'] as num?)?.toDouble() ?? 0;

final miembros = List<String>.from(data['miembros'] ?? const []);

final miUid = firebase.user!.uid;
final nombresMiembros =
    Map<String, dynamic>.from(data['nombresMiembros'] ?? {});

final soyMiembro1 =
    miembros.isNotEmpty && miembros[0] == miUid;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firebase.movimientos(widget.parejaId),
          builder: (context, movSnap) {
            final movimientos = (movSnap.data?.docs ?? []).map(Movimiento.fromDoc).toList();
            final ingresos = movimientos
    .where(
      (m) =>
          m.ingreso &&
          !m.esObjetivo &&
          !m.esTransferencia &&
          !m.esAjuste,
    )
    .fold<double>(0, (s, m) => s + m.cantidad);

final gastos = movimientos
    .where(
      (m) =>
          !m.ingreso &&
          !m.esObjetivo &&
          !m.esTransferencia &&
          !m.esAjuste,
    )
    .fold<double>(0, (s, m) => s + m.cantidad);
            final ajustes = movimientos
    .where((m) => m.esAjuste)
    .fold<double>(
      0,
      (s, m) => s + (m.ingreso ? m.cantidad : -m.cantidad),
    );

final total = inicial + ingresos - gastos + ajustes;
double miSaldo = soyMiembro1 ? saldoMiembro1 : saldoMiembro2;
double saldoPareja = soyMiembro1 ? saldoMiembro2 : saldoMiembro1;

for (final m in movimientos) {
  if (m.esObjetivo) continue;

  if (m.esAjuste) {
    if (m.usuarioId == miUid) {
      miSaldo += m.ingreso ? m.cantidad : -m.cantidad;
    } else {
      saldoPareja += m.ingreso ? m.cantidad : -m.cantidad;
    }
    continue;
  }

  if (m.esTransferencia) {
  final otroUid = miembros[soyMiembro1 ? 1 : 0];

  if (m.usuarioId == miUid) {
    miSaldo -= m.cantidad;
    saldoPareja += m.cantidad;
  } else if (m.destinatarioId == miUid) {
    miSaldo += m.cantidad;
    saldoPareja -= m.cantidad;
  } else if (m.usuarioId == otroUid) {
    saldoPareja -= m.cantidad;
    miSaldo += m.cantidad;
  } else if (m.destinatarioId == otroUid) {
    saldoPareja += m.cantidad;
    miSaldo -= m.cantidad;
  }

  continue;
}

  if (m.usuarioId == miUid) {
    miSaldo += m.ingreso ? m.cantidad : -m.cantidad;
  } else {
    saldoPareja += m.ingreso ? m.cantidad : -m.cantidad;
  }
}            final code = data['codigoUnion'] as String? ?? '';
final nombresMiembros =
    Map<String, dynamic>.from(data['nombresMiembros'] ?? {});

final miNombre =
    nombresMiembros[miUid]?.toString() ?? 'Sin nombre';

            return Scaffold(
              appBar: AppBar(
                title: Text(data['nombre'] as String? ?? 'Dinero de los dos'),
                actions: [
IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ObjetivosPage(
          parejaId: widget.parejaId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.flag_outlined),
  tooltip: 'Objetivos',
),
                  IconButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Código para tu pareja'),
                        content: SelectableText(code, style: Theme.of(context).textTheme.headlineMedium),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.group_outlined),
                  ),
IconButton(
  onPressed: () async {
    final controlador =
        TextEditingController(text: miNombre);

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              controlador.text,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoNombre != null) {
      await firebase.guardarMiNombre(
        widget.parejaId,
        nuevoNombre,
      );
    }
  },
  icon: const Icon(Icons.person),
),

IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumenPage(
          parejaId: widget.parejaId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.bar_chart),
  tooltip: 'Resumen mensual',
),

IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GastosRecurrentesPage(
          parejaId: widget.parejaId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.repeat),
  tooltip: 'Gastos recurrentes',
),

IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumenRecurrentesPage(
          parejaId: widget.parejaId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.summarize),
  tooltip: 'Resumen recurrentes',
),

IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistorialPage(
          parejaId: widget.parejaId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.history),
  tooltip: 'Historial',
),

                  IconButton(onPressed: firebase.logout, icon: const Icon(Icons.logout)),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('DINERO TOTAL'),
                          const SizedBox(height: 6),
                          Text(money.format(total), style: Theme.of(context).textTheme.headlineLarge),
                          const SizedBox(height: 12),
Row(
  children: [
    Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Text('TÚ'),
              const SizedBox(height: 4),
              Text(
                money.format(miSaldo),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    ),
    Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Text('TU PAREJA'),
              const SizedBox(height: 4),
              Text(
                money.format(saldoPareja),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
const SizedBox(height: 12),
Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text('Ingresos\n${money.format(ingresos)}', textAlign: TextAlign.center),
                              Text('Gastos\n${money.format(gastos)}', textAlign: TextAlign.center),
                            ],
                          ),
                          TextButton.icon(
  onPressed: () => ajustarSaldo(),
  icon: const Icon(Icons.edit),
  label: const Text('Ajustar saldo'),
),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => movimiento(true),
                          icon: const Icon(Icons.add),
                          label: const Text('Ingreso'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => movimiento(false),
                          icon: const Icon(Icons.remove),
                          label: const Text('Gasto'),
                        ),
                      ),
                    ],
                  ),

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () => transferencia(miembros, miUid),
    icon: const Icon(Icons.swap_horiz),
    label: const Text('Pasar dinero'),
  ),
),
                  const SizedBox(height: 18),
                  Text('Movimientos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...movimientos.take(5).map(
                    (m) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(m.ingreso ? Icons.arrow_downward : Icons.arrow_upward),
                        ),
                        title: Text(m.concepto),
                        subtitle: Text(
  '${nombresMiembros[m.usuarioId] ?? (m.usuarioId == miUid ? 'Tú' : 'Tu pareja')} · '
  '${DateFormat('dd/MM/yyyy HH:mm').format(m.fecha)}'
  '${m.esRecurrente ? '\n🔄 Recurrente' : ''}',
),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${m.ingreso ? '+' : '-'}${money.format(m.cantidad)}'),
                            IconButton(
                              onPressed: () => firebase.borrarMovimiento(widget.parejaId, m.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

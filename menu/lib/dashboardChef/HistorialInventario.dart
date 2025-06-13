import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu/dashboardChef/inventario.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:menu/dashboardChef/VistaDia.dart';
import 'package:menu/dashboardChef/InventarioDia.dart';

class HistorialInventarioScreen extends StatefulWidget {
  @override
  _HistorialInventarioScreenState createState() =>
      _HistorialInventarioScreenState();
}

class _HistorialInventarioScreenState extends State<HistorialInventarioScreen> {
  DateTime? _fechaSeleccionada;
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = false;
  bool _hayDatos = false;
  String _formatearHora(dynamic hora) {
    if (hora == null) return 'N/A';
    DateTime? date;
    if (hora is Timestamp) {
      date = hora.toDate();
    } else if (hora is DateTime) {
      date = hora;
    }
    if (date == null) return 'N/A';
    return TimeOfDay.fromDateTime(date).format(context);
  }

  Future<void> _generarYDescargarPDF() async {
    final pdf = pw.Document();

    final logo = pw.MemoryImage(
      (await rootBundle.load('lib/assets/logo.png')).buffer.asUint8List(),
    );

    final fechaStr =
        _fechaSeleccionada != null
            ? "${_fechaSeleccionada!.year}-${_fechaSeleccionada!.month.toString().padLeft(2, '0')}-${_fechaSeleccionada!.day.toString().padLeft(2, '0')}"
            : '';
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Center(child: pw.Image(logo, height: 60)),
              pw.Center(
                child: pw.Text(
                  'Inventario del Día',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Fecha: $fechaStr',
                  style: pw.TextStyle(fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 16),
              // ...existing code...
              pw.Table.fromTextArray(
                headers: ['Nombre', 'Categoría', 'Unidad', 'Cantidad Actual'],
                data:
                    _productos.map((producto) {
                      // Mostrar saldoFinal si existe, si no cantidad
                      final cantidadActual =
                          producto['saldoFinal'] ?? producto['cantidad'] ?? 0;
                      return [
                        producto['nombre'] ?? '',
                        producto['categoria'] ?? '',
                        producto['unidad'] ?? '',
                        cantidadActual.toString(),
                      ];
                    }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey900,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                cellStyle: pw.TextStyle(fontSize: 10),
                cellHeight: 25,
              ),

              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generado por Tap&Serve',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'inventario_dia_$fechaStr.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _seleccionarFecha,
          ),
        ],
      ),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : _fechaSeleccionada == null
              ? const Center(child: Text('Selecciona una fecha'))
              : !_hayDatos
              ? const Center(child: Text('No hay nada para mostrar'))
              : ListView.builder(
                itemCount: _productos.length,
                itemBuilder: (context, index) {
                  final producto = _productos[index];
                  final cantidad = producto['cantidad'] ?? 0;
                  final salida = producto['salida'] ?? 0;
                  final saldoFinal =
                      producto['saldoFinal'] ?? (cantidad - salida);

                  return ListTile(
                    leading:
                        producto['imagenUrl'] != null
                            ? Image.network(
                              producto['imagenUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : const Icon(Icons.fastfood),
                    title: Text(producto['nombre']),
                    subtitle: Text(
                      'Cantidad: $cantidad ${producto['unidad']}\n'
                      'Categoría: ${producto['categoria']}\n'
                      'Entrada: ${_formatearHora(producto['horaIngreso'])}\n'
                      'Saldo final: $saldoFinal',
                    ),
                  );
                },
              ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hayDatos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text('Descargar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: _generarYDescargarPDF,
                ),
              ),
            ),
          BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Día'),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Inventario',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Historial',
              ),
            ],
            currentIndex: 2, // 1 para resaltar "Historial"
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => VistaDiaScreen()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Inventario()),
                );
              } else if (index == 2) {
                // Ya estás en Historial, no hacer nada
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
        _cargando = true;
        _productos.clear();
      });

      final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      try {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('inventario_dia')
                .where('fecha', isGreaterThanOrEqualTo: inicioDelDia)
                .where('fecha', isLessThan: finDelDia)
                .get();

        if (snapshot.docs.isEmpty) {
          setState(() {
            _hayDatos = false;
            _cargando = false;
          });
        } else {
          final productos = <Map<String, dynamic>>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final listaProductos = (data['productos'] as List<dynamic>? ?? []);
            for (final producto in listaProductos) {
              productos.add({
                'nombre': producto['nombre'] ?? '',
                'categoria': producto['categoria'] ?? '',
                'cantidad': producto['cantidad'] ?? 0,
                'unidad': producto['unidad'] ?? '',
                'imagenUrl': producto['imagenUrl'],
                'horaIngreso': producto['horaIngreso'],
                'salida': producto['salida'] ?? 0,
                'horaSalida': producto['horaSalida'],
                'saldoFinal': producto['saldoFinal'],
              });
            }
          }

          setState(() {
            _productos = productos;
            _hayDatos = true;
            _cargando = false;
          });
        }
      } catch (e) {
        setState(() {
          _hayDatos = false;
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los datos')),
        );
      }
    }
  }
}

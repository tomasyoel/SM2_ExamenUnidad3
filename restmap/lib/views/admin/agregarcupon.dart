import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCouponPage extends StatefulWidget {
  const AddCouponPage({Key? key}) : super(key: key);

  @override
  _AddCouponPageState createState() => _AddCouponPageState();
}

class _AddCouponPageState extends State<AddCouponPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  Future<void> _addCoupon() async {
    if (_codeController.text.isEmpty || _discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todos los campos deben estar completos para agregar el cupón.')),
      );
      return;
    }

    int discount;
    try {
      discount = int.parse(_discountController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El descuento debe ser un número válido entre 0 y 100.')),
      );
      return;
    }

    if (discount < 0 || discount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El descuento debe ser un valor entre 0 y 100.')),
      );
      return;
    }

    CollectionReference coupons = FirebaseFirestore.instance.collection('cupones');

    await coupons.add({
      'codigo': _codeController.text,
      'descuento': discount,
      'activo': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cupón agregado exitosamente')),
    );

    _codeController.clear();
    _discountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Cupón'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Código del Cupón'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(labelText: 'Descuento (%)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCoupon,
              child: Text('Agregar Cupón'),
            ),
          ],
        ),
      ),
    );
  }
}

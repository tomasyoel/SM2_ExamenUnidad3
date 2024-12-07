import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PedidosDriverPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Function(String) onOrderSelected;

  PedidosDriverPage({super.key, required this.onOrderSelected});

  Future<void> _solicitarPedido(String orderId) async {
    await _firestore.collection('pedidos').doc(orderId).update({
      'driverId': FirebaseAuth.instance.currentUser!.uid,
      'orderStatus': 'en camino',
    });
    onOrderSelected(orderId);
  }

  bool _isEligibleForDelivery(
      Timestamp startTime, Timestamp endTime, String orderStatus) {
    final now = Timestamp.now();
    final timeLeft = endTime.toDate().difference(now.toDate()).inMinutes;

    if (orderStatus == 'listo') {
      return true;
    }
    if (orderStatus == 'preparando' && timeLeft >= 10) {
      return true;
    }
    return false;
  }

  Future<String> _getClientName(String clientId) async {
    final clientSnapshot =
        await _firestore.collection('usuarios').doc(clientId).get();
    if (clientSnapshot.exists) {
      final clientData = clientSnapshot.data()!;
      return clientData['nombres'] ?? 'Cliente';
    }
    return 'Cliente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Disponibles'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('pedidos')
            .where('orderStatus', whereIn: ['listo', 'preparando'])
            .where('modalidad', isEqualTo: 'Delivery')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var orders = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _isEligibleForDelivery(
                data['startTime'], data['endTime'], data['orderStatus']);
          }).toList();

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              var orderId = order.id;
              var orderData = order.data() as Map<String, dynamic>;
              return FutureBuilder<String>(
                future: _getClientName(orderData['clientId']),
                builder: (context, clientSnapshot) {
                  if (!clientSnapshot.hasData) {
                    return Card(
                      child: ListTile(
                        title: const Text('Cargando nombre del cliente...'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dirección: ${orderData['userAddress']}'),
                            Text('Total: S/. ${orderData['totalPrice']}'),
                            Text('Método de pago: ${orderData['metodoPago']}'),
                          ],
                        ),
                      ),
                    );
                  }
                  return Card(
                    child: ListTile(
                      title: Text('Pedido de ${clientSnapshot.data}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dirección: ${orderData['userAddress']}'),
                          Text('Total: S/. ${orderData['totalPrice']}'),
                          Text('Método de pago: ${orderData['metodoPago']}'),
                          if (orderData['metodoPago'] == 'contraEntrega')
                            Text(
                                'Submetodo de pago: ${orderData['subMetodoPago']}'),
                          if (orderData['metodoPago'] == 'contraEntrega' &&
                              orderData['subMetodoPago'] == 'efectivo')
                            Text(
                                'Monto a pagar: S/. ${orderData['montoAPagar']}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        child: const Text('Solicitar'),
                        onPressed: () => _solicitarPedido(orderId),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

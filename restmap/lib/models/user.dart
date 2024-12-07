import 'package:cloud_firestore/cloud_firestore.dart';

// class Address {
//   String id;
//   String name;
//   String address;
//   double latitude;
//   double longitude;
//   bool isDefault;

//   Address({
//     required this.id,
//     required this.name,
//     required this.address,
//     required this.latitude,
//     required this.longitude,
//     required this.isDefault,
//   });

//   factory Address.fromMap(Map<String, dynamic> data, String docId) {
//     return Address(
//       id: docId,
//       name: data['nombre'] ?? '',
//       address: data['direccion'] ?? '',
//       latitude: data['ubicacion']['latitud'] ?? 0.0,
//       longitude: data['ubicacion']['longitud'] ?? 0.0,
//       isDefault: data['predeterminada'] ?? false,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'nombre': name,
//       'direccion': address,
//       'ubicacion': {
//         'latitud': latitude,
//         'longitud': longitude,
//       },
//       'predeterminada': isDefault,
//     };
//   }
// }

class Address {
  String id;
  String name;
  String address;
  double latitude;
  double longitude;
  bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  factory Address.fromMap(String id, Map<String, dynamic> data) {
    return Address(
      id: id,
      name: data['nombre'] ?? '',
      address: data['direccion'] ?? '',
      latitude: data['latitud'] ?? 0.0,
      longitude: data['longitud'] ?? 0.0,
      isDefault: data['predeterminada'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': name,
      'direccion': address,
      'latitud': latitude,
      'longitud': longitude,
      'predeterminada': isDefault,
    };
  }
}

class User {
  String id;
  String name;
  String lastName;
  String email;
  String phoneNumber;
  String role;
  String vehicle;
  String plate;
  String dni;
  GeoPoint location;
  List<Address> addresses;

  User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.vehicle,
    required this.plate,
    required this.dni,
    required this.location,
    required this.addresses,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<dynamic> addressList = data['direcciones'] ?? [];
    List<Address> addresses = addressList.map((addr) {
      return Address.fromMap(addr, addr['codigo']);
    }).toList();

    return User(
      id: doc.id,
      name: data['name'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? '',
      vehicle: data['vehicle'] ?? '',
      plate: data['plate'] ?? '',
      dni: data['dni'] ?? '',
      location: data['location'] ?? const GeoPoint(0.0, 0.0),
      addresses: addresses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'vehicle': vehicle,
      'plate': plate,
      'dni': dni,
      'location': location,
      'direcciones': addresses.map((address) => address.toMap()).toList(),
    };
  }
}

Future<List<Address>> getUserAddresses(String userId) async {
  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).get();

  if (userDoc.exists) {
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    List<dynamic> addressList = userData['direcciones'] ?? [];

    return addressList
        .map((addr) => Address.fromMap(addr, addr['codigo']))
        .toList();
  }

  return [];
}

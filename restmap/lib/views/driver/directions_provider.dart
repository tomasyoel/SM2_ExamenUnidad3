// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
// import 'package:google_maps_webservice/directions.dart';

// class DirectionsProvider extends ChangeNotifier {
//   final GoogleMapsDirections directionsApi = GoogleMapsDirections(
//     apiKey: 'TU_API_KEY',
//   );

//   final Set<maps.Polyline> _route = {};

//   Set<maps.Polyline> get currentRoute => _route;

//   Future<void> findDirections(maps.LatLng from, maps.LatLng to) async {
//     _route.clear();

//     final directions = await directionsApi.directionsWithLocation(
//       Location(lat: from.latitude, lng: from.longitude),
//       Location(lat: to.latitude, lng: to.longitude),
//       travelMode: TravelMode.driving,
//     );

//     if (directions.isOkay) {
//       final route = directions.routes[0];
//       final polyline = route.overviewPolyline;

//       final points = _decodePolyline(polyline.points);

//       _route.add(maps.Polyline(
//         polylineId: maps.PolylineId('route'),
//         points: points,
//         color: Colors.blue,
//         width: 6,
//       ));
//     }

//     notifyListeners();
//   }

//   List<maps.LatLng> _decodePolyline(String poly) {
//     var list = poly.codeUnits;
//     var lList = [];
//     int index = 0;
//     int len = poly.length;
//     int c = 0;

//     do {
//       var shift = 0;
//       int result = 0;

//       do {
//         c = list[index] - 63;
//         result |= (c & 0x1F) << (shift * 5);
//         index++;
//         shift++;
//       } while (c >= 32);

//       if (result & 1 == 1) {
//         result = ~result;
//       }
//       var result1 = (result >> 1) * 0.00001;
//       lList.add(result1);
//     } while (index < len);

//     for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

//     List<maps.LatLng> points = [];
//     for (var i = 0; i < lList.length; i += 2) {
//       points.add(maps.LatLng(lList[i], lList[i + 1]));
//     }
//     return points;
//   }
// }

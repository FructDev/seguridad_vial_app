import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../../data/providers/zone_provider.dart';

class MapWidget extends StatefulWidget {
  MapWidget({Key? key}) : super(key: key);

  @override
  MapWidgetState createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  Completer<GoogleMapController> _controller = Completer();
  LocationData? _currentLocation;
  final Set<Marker> _markers = {};
  late ZoneProvider _zoneProvider;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _zoneProvider = Provider.of<ZoneProvider>(context, listen: false);
    _loadRiskZones();
    _zoneProvider.listenToReports(); // Escuchar reportes en tiempo real
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    Location location = new Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentLocation = await location.getLocation();
    setState(() {
      _loadingLocation = false;
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _loadRiskZones() async {
    await _zoneProvider.fetchRiskZones();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addZoneAndReportMarkers();
    });
  }

  void _addZoneAndReportMarkers() {
    _markers.clear();

    for (var zone in _zoneProvider.zones) {
      _markers.add(
        Marker(
          markerId: MarkerId('zone_${zone.id}'),
          position: LatLng(zone.latitude, zone.longitude),
          infoWindow: InfoWindow(
            title: zone.name,
            snippet: zone.description,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(zone.level)),
        ),
      );
    }

    for (var report in _zoneProvider.reports) {
      _markers.add(
        Marker(
          markerId: MarkerId('report_${report.id}'),
          position: LatLng(report.latitude, report.longitude),
          infoWindow: InfoWindow(
            title: "Reporte: ${report.type}",
            snippet: report.description,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () {
            _showReportDialog(report);
          },
        ),
      );
    }

    setState(() {});
  }

  double _getMarkerHue(int level) {
    switch (level) {
      case 1:
        return BitmapDescriptor.hueYellow;
      case 2:
        return BitmapDescriptor.hueOrange;
      case 3:
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _showReportDialog(Report report) {
    TextEditingController commentController = TextEditingController();
    double rating = report.rating ?? 0;
    String newStatus = report.status;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reporte: ${report.type}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(report.description),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Estado:'),
                      DropdownButton<String>(
                        value: newStatus,
                        onChanged: (String? newValue) {
                          setState(() {
                            newStatus = newValue!;
                          });
                        },
                        items: <String>['pendiente', 'resuelto']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Rating:'),
                      Slider(
                        value: rating,
                        onChanged: (newRating) {
                          setState(() {
                            rating = newRating;
                          });
                        },
                        divisions: 5,
                        min: 0,
                        max: 5,
                        label: "$rating estrellas",
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Agregar comentario',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (newStatus != report.status) {
                      await _zoneProvider.updateReportStatus(
                          report.id, newStatus);
                    }
                    if (rating != report.rating) {
                      await _zoneProvider.updateReportRating(report.id, rating);
                    }
                    if (commentController.text.isNotEmpty) {
                      await _zoneProvider.addCommentToReport(
                          report.id, commentController.text);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation != null
                ? LatLng(
                    _currentLocation!.latitude!, _currentLocation!.longitude!)
                : LatLng(18.4861, -69.9312),
            zoom: 12,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _setMapStyle(controller);
          },
        ),
        if (_loadingLocation)
          Center(
            child: CircularProgressIndicator(),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: _centerMap,
            child: Icon(
              Icons.my_location,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ],
    );
  }

  void _centerMap() async {
    final GoogleMapController controller = await _controller.future;
    if (_currentLocation != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentLocation!.latitude!,
              _currentLocation!.longitude!,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _setMapStyle(GoogleMapController controller) async {
    String style = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json');
    controller.setMapStyle(style);
  }
}

// lib/presentation/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../data/providers/report_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension StringCasingExtension on String {
  String capitalize() =>
      this.length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class ReportScreen extends StatefulWidget {
  ReportScreen({Key? key}) : super(key: key);

  @override
  ReportScreenState createState() => ReportScreenState();
}

class ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool useManualLocation = false;
  LatLng? _manualPosition;
  TextEditingController _addressController = TextEditingController();

  List<XFile>? _pickedImages;
  final ImagePicker _picker = ImagePicker();

  final List<String> _types = ['Accidente', 'Peligro', 'Tráfico', 'Otro'];

  final Map<String, List<String>> _categoriesByType = {
    'Accidente': ['Colisión de Vehículos', 'Atropello', 'Otro'],
    'Peligro': [
      'Condiciones Climáticas',
      'Infraestructura Defectuosa',
      'Iluminación'
    ],
    'Tráfico': ['Congestión', 'Obstrucción', 'Otro'],
    'Otro': ['Otro'],
  };

  List<String> _categories = [];

  final List<String> _visibilities = ['público', 'privado', 'grupo específico'];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<GeoPoint?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Provider.of<ReportProvider>(context, listen: false)
            .setError('Los servicios de ubicación están deshabilitados.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Provider.of<ReportProvider>(context, listen: false)
              .setError('Permisos de ubicación denegados.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Provider.of<ReportProvider>(context, listen: false).setError(
            'Permisos de ubicación permanentemente denegados. No podemos solicitar permisos.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      Provider.of<ReportProvider>(context, listen: false)
          .setError('Error al obtener la ubicación: $e');
      return null;
    }
  }

  Future<void> _selectLocationOnMap(BuildContext context) async {
    LatLng? selectedPosition = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocationMapScreen(),
      ),
    );

    if (selectedPosition != null) {
      setState(() {
        _manualPosition = selectedPosition;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ubicación seleccionada exitosamente.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se seleccionó ninguna ubicación.')),
      );
    }
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _pickedImages = images;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imágenes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo Reporte'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: Text('Usar ubicación manual'),
                    value: useManualLocation,
                    onChanged: (bool value) {
                      setState(() {
                        useManualLocation = value;
                        if (!value) {
                          _manualPosition = null;
                          _addressController.clear();
                        }
                      });
                    },
                  ),
                  if (useManualLocation) ...[
                    FormBuilderTextField(
                      name: 'address',
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Dirección'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'Ingrese una dirección'),
                        FormBuilderValidators.minLength(5,
                            errorText:
                                'La dirección debe tener al menos 5 caracteres'),
                        FormBuilderValidators.maxLength(100,
                            errorText:
                                'La dirección no puede exceder 100 caracteres'),
                      ]),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        String address = _addressController.text.trim();
                        if (address.isNotEmpty) {
                          GeoPoint? location =
                              await reportProvider.geocodeAddress(address);
                          if (location != null) {
                            setState(() {
                              _manualPosition =
                                  LatLng(location.latitude, location.longitude);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Dirección geocodificada exitosamente.')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Por favor, ingrese una dirección.')),
                          );
                        }
                      },
                      child: Text('Geocodificar Dirección'),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _selectLocationOnMap(context),
                      child: Text('Seleccionar en el Mapa'),
                    ),
                    SizedBox(height: 16),
                    if (_manualPosition != null)
                      Container(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _manualPosition!,
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId('manualLocation'),
                              position: _manualPosition!,
                              infoWindow:
                                  InfoWindow(title: 'Ubicación del Reporte'),
                            ),
                          },
                          onMapCreated: (GoogleMapController controller) {},
                        ),
                      ),
                  ],
                  SizedBox(height: 16),
                  FormBuilderDropdown<String>(
                    name: 'type',
                    decoration: InputDecoration(labelText: 'Tipo de Reporte'),
                    items: _types
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Seleccione un tipo de reporte'),
                    ]),
                    onChanged: (value) {
                      setState(() {
                        _categories = _categoriesByType[value!]!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  FormBuilderDropdown<String>(
                    name: 'category',
                    decoration: InputDecoration(labelText: 'Categoría'),
                    items: _categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Seleccione una categoría'),
                    ]),
                  ),
                  SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'description',
                    decoration: InputDecoration(labelText: 'Descripción'),
                    maxLines: 5,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Ingrese una descripción'),
                      FormBuilderValidators.minLength(10,
                          errorText:
                              'La descripción debe tener al menos 10 caracteres'),
                      FormBuilderValidators.maxLength(500,
                          errorText:
                              'La descripción no puede exceder 500 caracteres'),
                    ]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Adjuntar Imágenes (Opcional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _pickImages(context),
                    child: Text('Seleccionar Imágenes'),
                  ),
                  SizedBox(height: 8),
                  _pickedImages != null && _pickedImages!.isNotEmpty
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _pickedImages!.map((image) {
                            return Stack(
                              children: [
                                Image.file(
                                  File(image.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _pickedImages!.remove(image);
                                      });
                                    },
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        )
                      : Text('No hay imágenes seleccionadas.'),
                  SizedBox(height: 16),
                  FormBuilderDropdown<String>(
                    name: 'visibility',
                    decoration: InputDecoration(labelText: 'Visibilidad'),
                    items: _visibilities
                        .map((visibility) => DropdownMenuItem(
                              value: visibility,
                              child: Text(visibility.capitalize()),
                            ))
                        .toList(),
                    initialValue: 'público',
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Seleccione una visibilidad'),
                    ]),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: reportProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState?.saveAndValidate() ??
                                false) {
                              String type =
                                  _formKey.currentState!.value['type'];
                              String description =
                                  _formKey.currentState!.value['description'];
                              String category =
                                  _formKey.currentState!.value['category'];
                              String visibility =
                                  _formKey.currentState!.value['visibility'];

                              GeoPoint? location;
                              if (useManualLocation &&
                                  _manualPosition != null) {
                                location = GeoPoint(_manualPosition!.latitude,
                                    _manualPosition!.longitude);
                              } else {
                                location = await _getCurrentLocation();
                                if (location == null) {
                                  return;
                                }
                              }

                              String address = '';
                              if (useManualLocation &&
                                  _addressController.text.isNotEmpty) {
                                address = _addressController.text.trim();
                              } else {
                                if (location != null) {
                                  try {
                                    List<Placemark> placemarks =
                                        await placemarkFromCoordinates(
                                            location.latitude,
                                            location.longitude);
                                    if (placemarks.isNotEmpty) {
                                      Placemark placemark = placemarks.first;
                                      address =
                                          "${placemark.street}, ${placemark.locality}, ${placemark.country}";
                                    }
                                  } catch (e) {
                                    print('Error al obtener la dirección: $e');
                                  }
                                }
                              }

                              List<String> imageUrls = [];
                              if (_pickedImages != null &&
                                  _pickedImages!.isNotEmpty) {
                                imageUrls = await reportProvider
                                    .uploadImages(_pickedImages!);
                              }

                              bool success = await reportProvider.createReport(
                                type: type,
                                description: description,
                                category: category,
                                visibility: visibility,
                                location: location!,
                                address: address,
                                images: imageUrls,
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        SizedBox(width: 10),
                                        Text('¡Reporte creado exitosamente!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );

                                _formKey.currentState?.reset();
                                setState(() {
                                  _pickedImages = null;
                                  _manualPosition = null;
                                  _addressController.clear();
                                  useManualLocation = false;
                                });

                                // Redirigir al HomeScreen o Mapa después de crear el reporte
                                Navigator.pushNamed(context, '/home_screen');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          reportProvider.errorMessage ??
                                              'Error al enviar el reporte.')),
                                );
                              }
                            }
                          },
                    child: reportProvider.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Enviar Reporte'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (reportProvider.errorMessage != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        reportProvider.errorMessage!,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        reportProvider.clearError();
                      },
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SelectLocationMapScreen extends StatefulWidget {
  @override
  _SelectLocationMapScreenState createState() =>
      _SelectLocationMapScreenState();
}

class _SelectLocationMapScreenState extends State<SelectLocationMapScreen> {
  LatLng? _selectedPosition;
  GoogleMapController? _controller;

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  void _confirmSelection() {
    if (_selectedPosition != null) {
      Navigator.pop(context, _selectedPosition);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor, seleccione una ubicación en el mapa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Seleccionar Ubicación'),
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _confirmSelection,
            ),
          ],
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(18.3969028, -70.1034766),
            zoom: 10,
          ),
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
          onTap: _onMapTapped,
          markers: _selectedPosition != null
              ? {
                  Marker(
                    markerId: MarkerId('selectedLocation'),
                    position: _selectedPosition!,
                    infoWindow: InfoWindow(title: 'Ubicación Seleccionada'),
                  ),
                }
              : {},
        ));
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/utils/api_functions.dart' as api;
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart'; // For checking login status

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomTypeController = TextEditingController();
  final _roomPriceController = TextEditingController();
  XFile? _imageFile;
  bool _isLoading = false;
  List<String> _roomTypes = []; // To be fetched from API

  @override
  void initState() {
    super.initState();
    _fetchRoomTypes();
  }

  Future<void> _fetchRoomTypes() async {
    // Ensure user is logged in before fetching, or handle public access if applicable
    // For now, assuming it's a protected action or types are public
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // if (!authProvider.isLoggedIn) {
    //   // Handle not logged in, maybe redirect or show message
    //   return;
    // }
    try {
      setState(() => _isLoading = true);
      final types = await api.getRoomTypes();
      if (mounted) {
        setState(() {
          _roomTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load room types: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for the room.')),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final roomPrice = double.tryParse(_roomPriceController.text);
      if (roomPrice == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid room price.')));
        setState(() => _isLoading = false);
        return;
      }

      bool success = await api.addRoom(
        _imageFile!.path,
        _roomTypeController
            .text, // This should be the selected room type string
        roomPrice,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room added successfully!')),
          );
          // Optionally navigate away or clear form
          _formKey.currentState?.reset();
          _roomTypeController
              .clear(); // If using Dropdown, this might need different handling
          _roomPriceController.clear();
          setState(() {
            _imageFile = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add room. Please try again.'),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _roomTypeController.dispose();
    _roomPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in, redirect if not (example)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      // This is a simple way, ideally use GoRouter's redirect for cleaner navigation
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   GoRouter.of(context).go('/login');
      // });
      // return const Scaffold(body: Center(child: Text("Please login to add a room.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Room')),
      body:
          _isLoading &&
                  _roomTypes
                      .isEmpty // Show loader if fetching room types initially
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _roomTypes.isNotEmpty
                          ? DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Room Type',
                            ),
                            value:
                                _roomTypes.contains(_roomTypeController.text)
                                    ? _roomTypeController.text
                                    : null,
                            items:
                                _roomTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _roomTypeController.text = newValue ?? "";
                              });
                            },
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please select a room type'
                                        : null,
                          )
                          : const Text(
                            "Loading room types or no room types available...",
                          ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _roomPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Room Price (per night)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter room price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _imageFile == null
                          ? TextButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Select Room Photo'),
                            onPressed: _pickImage,
                          )
                          : Column(
                            children: [
                              Image.file(File(_imageFile!.path), height: 150),
                              TextButton(
                                onPressed: _pickImage,
                                child: const Text('Change Photo'),
                              ),
                            ],
                          ),
                      const SizedBox(height: 20),
                      if (_isLoading &&
                          _roomTypes
                              .isNotEmpty) // Show loader only for submission if types are loaded
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Add Room'),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}

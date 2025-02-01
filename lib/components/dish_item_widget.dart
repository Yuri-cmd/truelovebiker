// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class DishItemWidget extends StatefulWidget {
  final String name;
  final String price;
  final bool isActive;
  final String imageUrl;
  final Function(bool) onToggle;

  const DishItemWidget({
    Key? key,
    required this.name,
    required this.price,
    required this.isActive,
    required this.imageUrl,
    required this.onToggle,
  }) : super(key: key);

  @override
  _DishItemWidgetState createState() => _DishItemWidgetState();
}

class _DishItemWidgetState extends State<DishItemWidget> {
  late bool status;

  @override
  void initState() {
    super.initState();
    status = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            widget.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child; // Si ya se cargó la imagen
              } else {
                return Image.asset(
                  'images/default.jpg', // Imagen por defecto mientras carga
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                );
              }
            },
          ),
        ),
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'S/. ${widget.price}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: SizedBox(
          width: 60.0,
          child: FlutterSwitch(
            width: 55.0,
            height: 25.0,
            valueFontSize: 12.0,
            toggleSize: 18.0,
            value: status,
            borderRadius: 30.0,
            padding: 4.0,
            activeColor: Colors.pink,
            inactiveColor: Colors.grey.shade300,
            onToggle: (val) {
              setState(() {
                status = val;
                widget.onToggle(val); // Llama al callback proporcionado
              });
            },
          ),
        ),
      ),
    );
  }
}

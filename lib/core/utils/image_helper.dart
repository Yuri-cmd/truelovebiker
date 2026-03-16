import 'package:flutter/material.dart';

Widget getMetodoPagoImage(String? tipoPago) {
  String imageName;

  switch (tipoPago?.toLowerCase()) {
    case 'yape':
      imageName = 'yape.png';
      break;
    case 'plin':
      imageName = 'plin.png';
      break;
    case 'efectivo':
      imageName = 'efectivo.png';
      break;
    case 'pos tarjeta credito':
    case 'pos':
      imageName = 'pos.png';
      break;
    default:
      return const SizedBox(); // No imagen si no se reconoce
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(
      12,
    ), // Mitad del ancho/alto para que sea circular
    child: Image.asset(
      'images/$imageName',
      width: 24,
      height: 24,
      fit: BoxFit.cover,
    ),
  );
}

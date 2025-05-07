import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/screen/home_screen.dart';
import 'package:truelovebiker/services/api.dart';

class RatingScreen extends StatefulWidget {
  final int idPedido;
  const RatingScreen({super.key, required this.idPedido});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _restaurantRating = 0;
  int _motorcycleRating = 0;
  bool _isLoading = false;
  final TextEditingController _restaurantCommentController =
      TextEditingController();
  final TextEditingController _motorcycleCommentController =
      TextEditingController();

  final Map<int, String> _defaultComments = {
    1: "Muy malo. No lo recomiendo.",
    2: "Podría mejorar bastante.",
    3: "Aceptable, pero no excelente.",
    4: "Muy bueno, quedé satisfecho.",
    5: "¡Excelente servicio! Totalmente recomendado.",
  };

  void _submitRating() async {
    setState(() => _isLoading = true);

    bool success = await ApiService.submitRating(
      idPedido: widget.idPedido,
      restaurantRating: _restaurantRating,
      restaurantComment: _restaurantCommentController.text,
      motorcycleRating: _motorcycleRating,
      motorcycleComment: _motorcycleCommentController.text,
    );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Calificación enviada con éxito")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar la calificación")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          title: Text("Calificar Pedido"),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildRatingCard(
                    title: "Califica el restaurante",
                    rating: _restaurantRating,
                    onRatingUpdate: (value) => _restaurantRating = value,
                    commentController: _restaurantCommentController,
                    hintText: "Escribe un comentario sobre el restaurante",
                  ),
                  SizedBox(height: 20),
                  _buildRatingCard(
                    title: "Califica al Cliente",
                    rating: _motorcycleRating,
                    onRatingUpdate: (value) => _motorcycleRating = value,
                    commentController: _motorcycleCommentController,
                    hintText: "Escribe un comentario sobre el cliente",
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitRating,
                      child:
                          _isLoading
                              ? SpinKitFadingCube(
                                color: Colors.white,
                                size: 24.0,
                              )
                              : Text(
                                "Enviar",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: SpinKitFadingCube(color: Colors.white, size: 50.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard({
    required String title,
    required int rating,
    required Function(int) onRatingUpdate,
    required TextEditingController commentController,
    required String hintText,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      onRatingUpdate(index + 1);
                      if (_defaultComments.containsKey(index + 1)) {
                        commentController.text = _defaultComments[index + 1]!;
                      }
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 10),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: hintText,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

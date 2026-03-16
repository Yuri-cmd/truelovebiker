class Biker {
  final int id;
  final int userId;
  final String? name;
  final String? email;
  final String? celular;
  final String? dni;
  final String? direccion;
  final String? departamento;
  final int activo;
  final int aprobado;

  Biker({
    required this.id,
    required this.userId,
    this.name,
    this.email,
    this.celular,
    this.dni,
    this.direccion,
    this.departamento,
    this.activo = 0,
    this.aprobado = 0,
  });

  factory Biker.fromJson(Map<String, dynamic> json) {
    return Biker(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      celular: json['celular'],
      dni: json['dni'],
      direccion: json['direccion'],
      departamento: json['departamento'],
      activo: int.tryParse(json['activo'].toString()) ?? 0,
      aprobado: int.tryParse(json['aprobado'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'celular': celular,
      'dni': dni,
      'direccion': direccion,
      'departamento': departamento,
      'activo': activo,
      'aprobado': aprobado,
    };
  }
}

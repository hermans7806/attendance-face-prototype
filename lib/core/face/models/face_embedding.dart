class FaceEmbedding {
  const FaceEmbedding({required this.values, required this.createdAt});

  final List<double> values;
  final DateTime createdAt;

  int get dimension => values.length;
}

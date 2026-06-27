void main() {
  dynamic balBody = {
    "success": true,
    "data": {
      "coins": 150,
      "totalSpent": 0
    }
  };
  final coins = balBody['data']?['coins'] ?? balBody['coins'] ?? 0;
  print("Coins: \$coins");
}

class DepthEntity {
  DepthEntity(this.price, this.vol);
  double price;
  double vol;

  @override
  String toString() {
    return 'Data{price: $price, vol: $vol}';
  }
}

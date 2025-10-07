part of 'order_bloc.dart';

@freezed
class OrderState with _$OrderState {
  const factory OrderState.initial() = _Initial;
  const factory OrderState.loading() = _Loading;
  const factory OrderState.success({
    required List<OrderItem> products,
    required int totalQuantity,
    required int totalPrice,
    required String paymentMethod,
    required int nominalBayar,
    required int idKasir,
    required String namaKasir,
    required String customerName,
    required String transactionId,
  }) = _Success;
  const factory OrderState.error(String message) = _Error;
}

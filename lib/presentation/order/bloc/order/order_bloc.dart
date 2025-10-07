import 'package:bloc/bloc.dart';
import 'package:flutter_pos_app/data/datasources/auth_local_datasource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../home/models/order_item.dart';

part 'order_event.dart';
part 'order_state.dart';
part 'order_bloc.freezed.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc()
      : super(const _Success(
          products: [],
          totalQuantity: 0,
          totalPrice: 0,
          paymentMethod: '',
          nominalBayar: 0,
          idKasir: 0,
          namaKasir: '',
          customerName: '',
          transactionId: '',
        )) {
    on<_AddPaymentMethod>((event, emit) async {
      emit(const _Loading());
      final userData = await AuthLocalDatasource().getAuthData();

      // Generate unique transaction ID
      final uuid = Uuid();
      final String transactionId = uuid.v4();

      // Add logging
      print('Generated UUID: $transactionId');
      print('Payment Method: ${event.paymentMethod}');
      print('Customer Name: ${event.customerName}');

      emit(_Success(
        products: event.orders,
        totalQuantity: event.orders.fold(
            0, (previousValue, element) => previousValue + element.quantity),
        totalPrice: event.orders.fold(
            0,
            (previousValue, element) =>
                previousValue + (element.quantity * element.product.price)),
        paymentMethod: event.paymentMethod,
        nominalBayar: 0,
        idKasir: userData.user.id,
        namaKasir: userData.user.name,
        customerName: event.customerName,
        transactionId: transactionId,
      ));
    });

    on<_AddNominalBayar>((event, emit) {
      var currentStates = state as _Success;
      emit(const _Loading());

      emit(_Success(
        products: currentStates.products,
        totalQuantity: currentStates.totalQuantity,
        totalPrice: currentStates.totalPrice,
        paymentMethod: currentStates.paymentMethod,
        nominalBayar: event.nominal,
        idKasir: currentStates.idKasir,
        namaKasir: currentStates.namaKasir,
        customerName: currentStates.customerName,
        transactionId: currentStates.transactionId,
      ));
    });

    //started
    on<_Started>((event, emit) {
      emit(const _Loading());
      emit(const _Success(
        products: [],
        totalQuantity: 0,
        totalPrice: 0,
        paymentMethod: '',
        nominalBayar: 0,
        idKasir: 0,
        namaKasir: '',
        customerName: '',
        transactionId: '',
      ));
    });
  }
}

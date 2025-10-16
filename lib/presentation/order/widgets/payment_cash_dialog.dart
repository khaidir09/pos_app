import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_app/core/extensions/build_context_ext.dart';
import 'package:flutter_pos_app/core/extensions/int_ext.dart';
import 'package:flutter_pos_app/core/extensions/string_ext.dart';
import 'package:flutter_pos_app/data/datasources/product_local_datasource.dart';
import 'package:flutter_pos_app/presentation/order/bloc/order/order_bloc.dart';
import 'package:flutter_pos_app/presentation/order/models/order_model.dart';
import 'package:flutter_pos_app/presentation/order/widgets/payment_success_dialog.dart';
import 'package:intl/intl.dart';

import '../../../core/components/buttons.dart';
import '../../../core/components/custom_text_field.dart';
import '../../../core/components/spaces.dart';
import '../../../core/constants/colors.dart';

class PaymentCashDialog extends StatefulWidget {
  final int price;
  final String paymentMethod; // Tambahkan ini
  const PaymentCashDialog({
    super.key,
    required this.price,
    required this.paymentMethod,
  });

  @override
  State<PaymentCashDialog> createState() => _PaymentCashDialogState();
}

class _PaymentCashDialogState extends State<PaymentCashDialog> {
  TextEditingController?
      priceController; // = TextEditingController(text: widget.price.currencyFormatRp);

  @override
  void initState() {
    priceController =
        TextEditingController(text: widget.price.currencyFormatRp);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Stack(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.highlight_off),
            color: AppColors.primary,
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text(
                'Pembayaran - ${widget.paymentMethod}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SpaceHeight(16.0),
          CustomTextField(
            controller: priceController!,
            label: '',
            showLabel: false,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final int priceValue = value.toIntegerFromText;
              priceController!.text = priceValue.currencyFormatRp;
              priceController!.selection = TextSelection.fromPosition(
                  TextPosition(offset: priceController!.text.length));
            },
          ),
          const SpaceHeight(16.0),
          const SpaceHeight(30.0),
          BlocConsumer<OrderBloc, OrderState>(
            listener: (context, state) {
              state.maybeWhen(
                orElse: () {},
                success: (data, qty, total, payment, nominal, idKasir,
                    namaKasir, customerName, transactionId) {
                  final orderModel = OrderModel(
                      transactionId: transactionId,
                      paymentMethod: payment,
                      nominalBayar: nominal,
                      orders: data,
                      totalQuantity: qty,
                      totalPrice: total,
                      idKasir: idKasir,
                      namaKasir: namaKasir,
                      //tranction time format 2024-01-03T22:12:22
                      transactionTime: DateFormat('yyyy-MM-ddTHH:mm:ss')
                          .format(DateTime.now()),
                      isSync: false);

                  // Add logging
                  print('=== ORDER DATA ===');
                  print('Transaction ID: ${orderModel.transactionId}');
                  print('Payment Method: ${orderModel.paymentMethod}');
                  print('Total Amount: ${orderModel.totalPrice}');
                  print('Items: ${orderModel.orders.length}');
                  print('Transaction Time: ${orderModel.transactionTime}');
                  print('================');

                  ProductLocalDatasource.instance.saveOrder(orderModel);
                  context.pop();
                  showDialog(
                    context: context,
                    builder: (context) => const PaymentSuccessDialog(),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(orElse: () {
                return const SizedBox();
              }, success: (data, qty, total, payment, _, idKasir, nameKasir,
                  transactionId, __) {
                return Button.filled(
                  onPressed: () {
                    //check if price is empty
                    if (priceController!.text.isEmpty) {
                      //show dialog error
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: const Text('Please input the price'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          });
                      return;
                    }

                    //if price less than total price
                    if (priceController!.text.toIntegerFromText < total) {
                      //show dialog error
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: const Text(
                                  'The nominal is less than the total price'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          });
                      return;
                    }
                    context.read<OrderBloc>().add(OrderEvent.addNominalBayar(
                          priceController!.text.toIntegerFromText,
                        ));
                  },
                  label: 'Bayar',
                );
              }, error: (message) {
                return const SizedBox();
              });
            },
          ),
        ],
      ),
    );
  }
}

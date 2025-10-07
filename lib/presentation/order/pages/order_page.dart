import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_app/core/constants/colors.dart';
import 'package:flutter_pos_app/core/extensions/build_context_ext.dart';
import 'package:flutter_pos_app/core/extensions/string_ext.dart';
import 'package:flutter_pos_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_pos_app/presentation/home/bloc/checkout/checkout_bloc.dart';
import 'package:flutter_pos_app/presentation/home/models/order_item.dart';
import 'package:flutter_pos_app/presentation/home/pages/dashboard_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/assets/assets.gen.dart';
import '../../../core/components/buttons.dart';
import '../../../core/components/menu_button.dart';
import '../../../core/components/spaces.dart';
import '../../../data/dataoutputs/cwb_print.dart';
import '../bloc/order/order_bloc.dart';
import '../widgets/order_card.dart';
import '../widgets/payment_cash_dialog.dart';
// import '../widgets/payment_qris_dialog.dart';
import '../widgets/process_button.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final indexValue = ValueNotifier(0);
  final TextEditingController orderNameController = TextEditingController();
  final TextEditingController tableNumberController = TextEditingController();

  List<OrderItem> orders = [];

  int totalPrice = 0;

  // Tambahkan fungsi ini di dalam class State widget Anda
  Future<String> _generateQueueNumber() async {
    final prefs = await SharedPreferences.getInstance();
    // Format tanggal saat ini menjadi 'Tahun-Bulan-Tanggal', misal: '2025-07-30'
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Kunci untuk menyimpan data di SharedPreferences
    const String lastDateKey = 'last_queue_date';
    const String lastNumberKey = 'last_queue_number';

    // Ambil tanggal dan nomor terakhir yang tersimpan
    final String? savedDate = prefs.getString(lastDateKey);
    int nextNumber = 1; // Default nomor antrian adalah 1

    // Jika tanggal yang tersimpan sama dengan hari ini, naikkan nomor antrian
    if (savedDate == currentDate) {
      final int lastNumber = prefs.getInt(lastNumberKey) ?? 0;
      nextNumber = lastNumber + 1;
    }
    // Jika tanggal beda (atau belum ada), nomor antrian tetap 1 (reset)

    // Simpan tanggal hari ini dan nomor antrian yang baru
    await prefs.setString(lastDateKey, currentDate);
    await prefs.setInt(lastNumberKey, nextNumber);

    // Format nomor agar lebih rapi (misal: A-001, A-002)
    return 'A-${nextNumber.toString().padLeft(3, '0')}';
  }

  int calculateTotalPrice(List<OrderItem> orders) {
    return orders.fold(
        0,
        (previousValue, element) =>
            previousValue + element.product.price * element.quantity);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const paddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.push(const DashboardPage());
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              // 1. Generate nomor antrian sebelum menampilkan dialog
              final String queueNumber = await _generateQueueNumber();

              // Bersihkan controller sebelum dialog muncul
              tableNumberController.clear();
              orderNameController.clear();

              // 2. Tampilkan dialog
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    // Tampilkan nomor antrian di judul dialog
                    title: Text('Open Bill (Antrian: $queueNumber)'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Nomor Meja (Opsional)',
                          ),
                          keyboardType: TextInputType.number,
                          controller: tableNumberController,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Nama Pelanggan',
                          ),
                          controller: orderNameController,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Batal'),
                      ),
                      BlocBuilder<CheckoutBloc, CheckoutState>(
                        builder: (context, state) {
                          return state.maybeWhen(
                            orElse: () {
                              return const SizedBox.shrink();
                            },
                            success: (data, qty, total, draftName) {
                              return Button.outlined(
                                onPressed: () async {
                                  final authData =
                                      await AuthLocalDatasource().getAuthData();

                                  // 3. Gabungkan nama pelanggan dengan nomor antrian
                                  final String finalOrderName = orderNameController
                                          .text.isNotEmpty
                                      ? '${orderNameController.text} - $queueNumber'
                                      : queueNumber; // Jika nama kosong, gunakan nomor antrian saja

                                  // 4. Gunakan 'finalOrderName' untuk menyimpan dan mencetak
                                  context.read<CheckoutBloc>().add(
                                        CheckoutEvent.saveDraftOrder(
                                          tableNumberController
                                              .text.toIntegerFromText,
                                          finalOrderName, // Gunakan nama yang sudah digabung
                                        ),
                                      );

                                  final printInt =
                                      await CwbPrint.instance.printChecker(
                                    data,
                                    tableNumberController.text.toInt,
                                    finalOrderName, // Gunakan nama yang sudah digabung
                                    authData.user.name,
                                  );

                                  CwbPrint.instance.printReceipt(printInt);

                                  context.read<CheckoutBloc>().add(
                                        const CheckoutEvent.started(),
                                      );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Save Draft Order Success'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );

                                  context
                                      .pushReplacement(const DashboardPage());
                                },
                                label: 'Simpan',
                                fontSize: 14,
                                height: 40,
                                width: 140,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.save_as_outlined,
              color: Colors.white,
            ),
          ),
          const SpaceWidth(8),
        ],
      ),
      body: BlocBuilder<CheckoutBloc, CheckoutState>(
        builder: (context, state) {
          return state.maybeWhen(orElse: () {
            return const Center(
              child: Text('No Data'),
            );
          }, success: (data, qty, total, draftName) {
            if (data.isEmpty) {
              return const Center(
                child: Text('No Data'),
              );
            }

            totalPrice = total;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: data.length,
              separatorBuilder: (context, index) => const SpaceHeight(20.0),
              itemBuilder: (context, index) => OrderCard(
                padding: paddingHorizontal,
                data: data[index],
                onDeleteTap: () {
                  context.read<CheckoutBloc>().add(
                        CheckoutEvent.removeProduct(data[index].product),
                      );
                },
              ),
            );
          });
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<CheckoutBloc, CheckoutState>(
              builder: (context, state) {
                return state.maybeWhen(
                  orElse: () {
                    return const SizedBox.shrink();
                  },
                  success: (data, qty, total, draftName) {
                    return ValueListenableBuilder(
                      valueListenable: indexValue,
                      builder: (context, value, _) => Row(
                        children: [
                          Flexible(
                            child: MenuButton(
                              iconPath: Assets.icons.cash.path,
                              label: 'TUNAI',
                              isActive: value == 1,
                              onPressed: () {
                                indexValue.value = 1;
                                context.read<OrderBloc>().add(
                                    OrderEvent.addPaymentMethod(
                                        'Tunai', data, draftName));
                              },
                            ),
                          ),
                          const SpaceWidth(16.0),
                          Flexible(
                            child: MenuButton(
                              iconPath: Assets.icons.qrCode.path,
                              label: 'QR',
                              isActive: value == 2,
                              onPressed: () {
                                indexValue.value = 2;
                                context.read<OrderBloc>().add(
                                    OrderEvent.addPaymentMethod(
                                        'QRIS', data, draftName));
                              },
                            ),
                          ),
                          const SpaceWidth(16.0),
                          Flexible(
                            child: MenuButton(
                              iconPath: Assets.icons.debit.path,
                              label: 'TRANSFER',
                              isActive: value == 3,
                              onPressed: () {
                                indexValue.value = 3;
                                context.read<OrderBloc>().add(
                                    OrderEvent.addPaymentMethod(
                                        'Transfer', data, draftName));
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SpaceHeight(20.0),
            ProcessButton(
              price: 0,
              onPressed: () async {
                if (indexValue.value == 0) return;

                String paymentMethod = switch (indexValue.value) {
                  1 => 'Tunai',
                  2 => 'QRIS',
                  3 => 'Transfer',
                  _ => 'Tunai',
                };

                showDialog(
                  context: context,
                  builder: (context) => PaymentCashDialog(
                    price: totalPrice,
                    paymentMethod: paymentMethod,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

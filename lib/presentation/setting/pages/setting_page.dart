import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_app/core/constants/colors.dart';
import 'package:flutter_pos_app/core/extensions/build_context_ext.dart';
import 'package:flutter_pos_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_pos_app/presentation/auth/pages/login_page.dart';
import 'package:flutter_pos_app/presentation/home/pages/dashboard_page.dart';
import 'package:flutter_pos_app/presentation/setting/bloc/report/close_cashier/close_cashier_bloc.dart';
import 'package:flutter_pos_app/presentation/setting/pages/manage_printer_page.dart';
import 'package:flutter_pos_app/presentation/setting/pages/report/report_page.dart';
import 'package:flutter_pos_app/presentation/setting/pages/save_server_key_page.dart';
import 'package:flutter_pos_app/presentation/setting/pages/sync_data_page.dart';

import '../../../core/assets/assets.gen.dart';
import '../../../core/components/menu_button.dart';
import '../../../core/components/spaces.dart';
import '../../home/bloc/logout/logout_bloc.dart';
import '../bloc/sync_order/sync_order_bloc.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              context.push(const DashboardPage());
            },
          ),
          centerTitle: true,
          title: const Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            const SpaceHeight(20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Flexible(
                    child: MenuButton(
                      iconPath: Assets.images.sync.path,
                      label: 'Sinkronisasi Data',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SyncDataPage()));
                      },
                      isImage: true,
                    ),
                  ),
                ],
              ),
            ),
            const SpaceHeight(20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Flexible(
                    child: MenuButton(
                      iconPath: Assets.images.manageQr.path,
                      label: 'QRIS Server Key',
                      onPressed: () => context.push(const SaveServerKeyPage()),
                      isImage: true,
                    ),
                  ),
                  const SpaceWidth(15.0),
                  Flexible(
                    child: MenuButton(
                      iconPath: Assets.images.managePrinter.path,
                      label: 'Atur Printer',
                      onPressed: () {
                        context.push(const ManagePrinterPage());
                      },
                      isImage: true,
                    ),
                  ),
                ],
              ),
            ),
            const SpaceHeight(20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Flexible(
                    child: MenuButton(
                      iconPath: Assets.images.report.path,
                      label: 'Laporan',
                      onPressed: () => context.push(const ReportPage()),
                      isImage: true,
                    ),
                  ),
                  const SpaceWidth(15.0),
                  Flexible(
                    child: BlocListener<SyncOrderBloc, SyncOrderState>(
                      listener: (context, state) {
                        state.maybeMap(
                          orElse: () {},
                          successCloseChasier: (_) {
                            context.read<CloseCashierBloc>().add(
                                  const CloseCashierEvent.closeCashier(),
                                );

                            context.pushReplacement(const LoginPage());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.green,
                                content: Text('Tutup Kasir Berhasil'),
                              ),
                            );
                          },
                        );
                      },
                      child: MenuButton(
                        iconPath: Assets.images.close.path,
                        label: 'Tutup Kasir',
                        onPressed: () async {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Tutup Kasir'),
                                  content: const Text(
                                      'Apakah kamu yakin ingin menutup kasir?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.read<SyncOrderBloc>().add(
                                              const SyncOrderEvent
                                                  .sendOrderForCloseChasier(),
                                            );
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Ya'),
                                    ),
                                  ],
                                );
                              });
                          // context.read<SyncOrderBloc>().add(
                          //     const SyncOrderEvent.sendOrderForCloseChasier());
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => const SyncDataPage()));
                        },
                        isImage: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SpaceHeight(60),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocConsumer<LogoutBloc, LogoutState>(
                listener: (context, state) {
                  state.maybeMap(
                    orElse: () {},
                    success: (_) {
                      AuthLocalDatasource().removeAuthData();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                    },
                  );
                },
                builder: (context, state) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      context
                          .read<LogoutBloc>()
                          .add(const LogoutEvent.logout());
                    },
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
        )));
  }
}

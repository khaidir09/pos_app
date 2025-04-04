import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_app/core/extensions/build_context_ext.dart';

import '../../../core/components/spaces.dart';

import '../../home/pages/dashboard_page.dart';
import '../bloc/history/history_bloc.dart';

import '../widgets/history_transaction_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryEvent.fetch());
  }

  @override
  Widget build(BuildContext context) {
    const paddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              context.push(const DashboardPage());
            },
          ),
          title: const Text('Riwayat Transaksi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              )),
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            return state.maybeWhen(orElse: () {
              return const Center(
                child: Text('No data'),
              );
            }, loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }, success: (data) {
              if (data.isEmpty) {
                return const Center(
                  child: Text('No data'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                itemCount: data.length,
                separatorBuilder: (context, index) => const SpaceHeight(8.0),
                itemBuilder: (context, index) => HistoryTransactionCard(
                  padding: paddingHorizontal,
                  data: data[index],
                ),
              );
            });
          },
        ));
  }
}

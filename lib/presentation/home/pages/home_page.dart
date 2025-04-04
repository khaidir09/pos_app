import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_app/core/constants/colors.dart';
import 'package:flutter_pos_app/core/extensions/build_context_ext.dart';
import 'package:flutter_pos_app/presentation/draft_order/pages/draft_order_page.dart';
import 'package:flutter_pos_app/presentation/home/bloc/product/product_bloc.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../core/assets/assets.gen.dart';
import '../../../core/components/menu_button.dart';
import '../../../core/components/search_input.dart';
import '../../../core/components/spaces.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../bloc/category/category_bloc.dart';
import '../widgets/product_card.dart';
import '../widgets/product_empty.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  final indexValue = ValueNotifier(0);
  String shopName = 'Toko Saya'; // Default value

  @override
  void initState() {
    _loadShopName();

    context.read<ProductBloc>().add(const ProductEvent.fetchLocal());
    context.read<CategoryBloc>().add(const CategoryEvent.getCategoriesLocal());
    AuthLocalDatasource().getPrinter().then((value) async {
      if (value.isNotEmpty) {
        await PrintBluetoothThermal.connect(macPrinterAddress: value);
      }
    });
    super.initState();
  }

  void onCategoryTap(int index) {
    searchController.clear();
    indexValue.value = index; // Update value notifier
  }

  Future<void> _loadShopName() async {
    final name = await AuthLocalDatasource().getShopName();
    setState(() {
      shopName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        title: Text(
          shopName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push(const DraftOrderPage());
            },
            icon: const Icon(Icons.note_alt_rounded, color: AppColors.white),
          ),
          const SpaceWidth(8)
        ],
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SearchInput(
            controller: searchController,
            onChanged: (value) {
              if (value.length > 3) {
                context
                    .read<ProductBloc>()
                    .add(ProductEvent.searchProduct(value));
              }
              if (value.isEmpty) {
                context
                    .read<ProductBloc>()
                    .add(const ProductEvent.fetchAllFromState());
              }
            },
          ),
          const SpaceHeight(16.0),
          BlocBuilder<CategoryBloc, CategoryState>(builder: (context, state) {
            return state.maybeWhen(
              orElse: () => const SizedBox(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => Center(child: Text(message)),
              loadedLocal: (categories) {
                return ValueListenableBuilder<int>(
                  valueListenable: indexValue,
                  builder: (context, currentIndex, _) {
                    return SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(
                            height: 80,
                            width: 90,
                            child: MenuButton(
                                iconPath: Assets.icons.allCategories.path,
                                label: 'Semua',
                                isActive: currentIndex == 0,
                                onPressed: () {
                                  onCategoryTap(0);
                                  context
                                      .read<ProductBloc>()
                                      .add(const ProductEvent.fetchLocal());
                                }),
                          ),
                          const SpaceWidth(10.0),
                          ...categories
                              .map(
                                (e) => SizedBox(
                                  height: 80,
                                  width: 90,
                                  child: MenuButton(
                                    iconPath: Assets.icons.allCategories.path,
                                    label: e.name,
                                    isActive: currentIndex == e.id,
                                    onPressed: () {
                                      onCategoryTap(e.id);
                                      context.read<ProductBloc>().add(
                                          ProductEvent.fetchByCategory(e.name));
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }),
          const SpaceHeight(16.0),
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              return state.maybeWhen(orElse: () {
                return const SizedBox();
              }, loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }, error: (message) {
                return Center(
                  child: Text(message),
                );
              }, success: (products) {
                if (products.isEmpty) return const ProductEmpty();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 0.75,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemBuilder: (context, index) => ProductCard(
                    data: products[index],
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

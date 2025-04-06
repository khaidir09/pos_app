import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_app/core/extensions/string_ext.dart';
import 'package:flutter_pos_app/data/datasources/auth_local_datasource.dart';
import 'package:flutter_pos_app/data/models/response/auth_response_model.dart';
import 'package:flutter_pos_app/presentation/setting/models/category_model.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/components/buttons.dart';
import '../../../core/components/custom_dropdown.dart';
import '../../../core/components/custom_text_field.dart';
import '../../../core/components/image_picker_widget.dart';
import '../../../core/components/spaces.dart';
import '../../../data/models/response/category_response_model.dart';
import '../../../data/models/response/product_response_model.dart';
import '../../home/bloc/category/category_bloc.dart';
import '../../home/bloc/product/product_bloc.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  TextEditingController? nameController;
  TextEditingController? priceController;
  TextEditingController? stockController;

  Category? category;
  User? user;

  XFile? imageFile;

  bool isBestSeller = false;

  final List<CategoryModel> categories = [
    CategoryModel(name: 'Drink', value: 'drink'),
    CategoryModel(name: 'Food', value: 'food'),
    CategoryModel(name: 'Snack', value: 'snack'),
  ];

  @override
  void initState() {
    nameController = TextEditingController();
    priceController = TextEditingController();
    stockController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    nameController!.dispose();
    priceController!.dispose();
    stockController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Tambah Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CustomTextField(
            controller: nameController!,
            label: 'Nama Produk',
          ),
          const SpaceHeight(16.0),
          CustomTextField(
            controller: priceController!,
            label: 'Harga Produk',
            keyboardType: TextInputType.number,
            onChanged: (value) {},
          ),
          const SpaceHeight(16.0),
          ImagePickerWidget(
            label: 'Gambar',
            onChanged: (file) {
              if (file == null) {
                return;
              }
              imageFile = file;
            },
          ),
          const SpaceHeight(16.0),
          CustomTextField(
            controller: stockController!,
            label: 'Stok',
            keyboardType: TextInputType.number,
          ),
          const SpaceHeight(16.0),
          Row(
            children: [
              Checkbox(
                value: isBestSeller,
                onChanged: (value) {
                  setState(() {
                    isBestSeller = value!;
                  });
                },
              ),
              const Text('Best Seller'),
            ],
          ),
          const SpaceHeight(16.0),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              List<Category> categories = [];
              state.maybeWhen(
                orElse: () {},
                loadedLocal: (data) {
                  categories = data;
                },
              );
              return CustomDropdown<Category>(
                value: categories.first,
                items: categories,
                label: 'Kategori',
                onChanged: (value) {
                  category = value!;
                },
              );
            },
          ),
          const SpaceHeight(16.0),
          Row(
            children: [
              Expanded(
                child: Button.outlined(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  label: 'Batal',
                ),
              ),
              const SpaceWidth(16.0),
              Expanded(
                child: BlocConsumer<ProductBloc, ProductState>(
                  listener: (context, state) {
                    state.maybeMap(
                      orElse: () {},
                      success: (_) {
                        Navigator.pop(context);
                      },
                    );
                  },
                  builder: (context, state) {
                    return state.maybeWhen(orElse: () {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }, loading: () {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }, success: (_) {
                      return Button.filled(
                        onPressed: () async {
                          final String name = nameController!.text;
                          final int price =
                              priceController!.text.toIntegerFromText;
                          final int stock =
                              stockController!.text.toIntegerFromText;
                          final authData =
                              await AuthLocalDatasource().getAuthData();
                          final Product product = Product(
                              name: name,
                              price: price,
                              stock: stock,
                              category: category!.name,
                              categoryId: category!.id,
                              userId: authData.user.id,
                              isBestSeller: isBestSeller,
                              image: imageFile!.path);

                          context.read<ProductBloc>().add(
                              ProductEvent.addProduct(product, imageFile!));
                        },
                        label: 'Simpan',
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SpaceHeight(20.0),
        ],
      ),
    );
  }
}

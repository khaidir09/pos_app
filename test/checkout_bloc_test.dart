import 'package:flutter_pos_app/data/models/response/product_response_model.dart';
import 'package:flutter_pos_app/presentation/home/bloc/checkout/checkout_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckoutBloc', () {
    late CheckoutBloc checkoutBloc;

    setUp(() {
      checkoutBloc = CheckoutBloc();
    });

    tearDown(() {
      checkoutBloc.close();
    });

    test('initial state is CheckoutState.success with empty products', () {
      expect(
        checkoutBloc.state,
        const CheckoutState.success(
          [],
          0,
          0,
          'customer',
        ),
      );
    });

    test('emits new state with product when CheckoutEvent.addCheckout is added',
        () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        price: 100,
        stock: 10,
        image: '',
        categoryId: 1,
        isAvailable: 1,
      );

      checkoutBloc.add(CheckoutEvent.addCheckout(product));

      expect(
        checkoutBloc.stream,
        emitsInOrder([
          const CheckoutState.loading(),
          CheckoutState.success(
            [
              (
                product: product,
                quantity: 1,
              )
            ],
            1,
            100,
            'customer',
          ),
        ]),
      );
    });

    test('emits initial state when CheckoutEvent.started is added', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        price: 100,
        stock: 10,
        image: '',
        categoryId: 1,
        isAvailable: 1,
      );

      // Add a product to make the state non-initial
      checkoutBloc.add(CheckoutEvent.addCheckout(product));

      // Wait for the previous event to be processed
      Future.delayed(const Duration(milliseconds: 100), () {
        // Dispatch the started event to clear the checkout
        checkoutBloc.add(const CheckoutEvent.started());
      });

      // Assert that the state is reset to the initial state
      expect(
        checkoutBloc.stream,
        emitsInOrder([
          const CheckoutState.loading(),
          CheckoutState.success(
            [
              (
                product: product,
                quantity: 1,
              )
            ],
            1,
            100,
            'customer',
          ),
          const CheckoutState.loading(),
          const CheckoutState.success(
            [],
            0,
            0,
            'customer',
          ),
        ]),
      );
    });
  });
}
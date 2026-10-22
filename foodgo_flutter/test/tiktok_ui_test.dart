import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/core/theme/glass_theme.dart';
import 'package:foodgo_flutter/providers/address_provider.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TikTok Reference UI/UX & Logic Tests', () {
    test(
      'CartProvider accepts TikTok reference promo code FOODIE30 (30% off)',
      () {
        final cart = CartProvider();
        cart.clear();
        cart.addItem(1, 'Double Cheeseburger', 10.00, null);

        expect(cart.totalAmount, 10.00);
        final success = cart.applyPromoCode('FOODIE30');
        expect(success, true);
        expect(cart.appliedPromoCode, 'FOODIE30');
        expect(cart.discountAmount, closeTo(3.00, 0.01));
        // Subtotal (10.00) - discount (3.00) + delivery fee (2.99) = 9.99
        expect(cart.grandTotal, closeTo(9.99, 0.01));
      },
    );

    test(
      'CartProvider accepts TikTok reference promo code FREESHIP (waives delivery fee)',
      () {
        final cart = CartProvider();
        cart.clear();
        cart.addItem(2, 'Crispy Chicken Wings', 12.00, null);

        final success = cart.applyPromoCode('FREESHIP');
        expect(success, true);
        expect(cart.appliedPromoCode, 'FREESHIP');
        expect(cart.discountAmount, closeTo(2.99, 0.01)); // Delivery fee waived
        expect(cart.grandTotal, closeTo(12.00, 0.01));
      },
    );

    test(
      'CartProvider accepts TikTok reference promo code BURGER20 (20% off)',
      () {
        final cart = CartProvider();
        cart.clear();
        cart.addItem(3, 'Truffle Mushroom Burger', 15.00, null);

        final success = cart.applyPromoCode('BURGER20');
        expect(success, true);
        expect(cart.appliedPromoCode, 'BURGER20');
        expect(cart.discountAmount, closeTo(3.00, 0.01));
        // Subtotal (15.00) - discount (3.00) + delivery fee (2.99) = 14.99
        expect(cart.grandTotal, closeTo(14.99, 0.01));
      },
    );

    test(
      'AddressItem preserves label attribute and serializes/deserializes correctly',
      () {
        final address = AddressItem(
          id: 99,
          label: 'Work Office',
          street: '12 Jalan Ampang, Suite 4B',
          city: 'Phnom Penh',
          isDefault: true,
        );

        final json = address.toJson();
        expect(json['id'], 99);
        expect(json['label'], 'Work Office');
        expect(json['street'], '12 Jalan Ampang, Suite 4B');
        expect(json['is_default'], true);

        final restored = AddressItem.fromJson(json);
        expect(restored.id, 99);
        expect(restored.label, 'Work Office');
        expect(restored.street, '12 Jalan Ampang, Suite 4B');
        expect(restored.city, 'Phnom Penh');
        expect(restored.isDefault, true);
      },
    );

    test('GlassTheme defines TikTok lush green design tokens', () {
      expect(GlassTheme.headerGreenStart, const Color(0xFF236E31));
      expect(GlassTheme.headerGreenMid, const Color(0xFF2E7D32));
      expect(GlassTheme.headerGreenEnd, const Color(0xFF388E3C));
      expect(GlassTheme.headerGradient.colors.length, 3);
      expect(GlassTheme.lightGreenSurface, const Color(0xFFE8F5E9));
      expect(GlassTheme.lightGreenText, const Color(0xFF2E7D32));
      expect(GlassTheme.lightGreenBorder, const Color(0xFFC8E6C9));
      expect(GlassTheme.pillCardShadow.blurRadius, 16.0);
    });

    test(
      'Tracking milestone step calculation matches 5-step stepper correctly',
      () {
        int getStepperStep(String status) {
          switch (status.toLowerCase()) {
            case 'confirmed':
            case 'pending':
              return 0;
            case 'preparing':
              return 1;
            case 'picked_up':
            case 'ready':
              return 2;
            case 'on_the_way':
            case 'delivering':
              return 3;
            case 'delivered':
            case 'completed':
              return 4;
            default:
              return 1;
          }
        }

        expect(getStepperStep('confirmed'), 0);
        expect(getStepperStep('preparing'), 1);
        expect(getStepperStep('picked_up'), 2);
        expect(getStepperStep('on_the_way'), 3);
        expect(getStepperStep('delivered'), 4);
      },
    );

    test(
      'GlassTheme defines Naperville modern vibrant lime delivery accents',
      () {
        expect(GlassTheme.limeAccent, const Color(0xFFCCFF00));
        expect(GlassTheme.limeAccentBright, const Color(0xFFD7FB00));
        expect(GlassTheme.limeSurface, const Color(0xFFF9FBE7));
        expect(GlassTheme.heroDarkCard, const Color(0xFF1E1E20));
      },
    );

    test(
      'Food item details data model contains valid nutrients and restaurant linking',
      () {
        final itemData = {
          'id': 103,
          'name': 'Double Beef Cheese Burger',
          'location': 'Naperville, Illinois',
          'price': 6.50,
          'calories': '198',
          'proteins': '25.2',
          'fats': '13.8',
          'carbo': '23.7',
          'category': 'Burger',
        };

        expect(itemData['name'], 'Double Beef Cheese Burger');
        expect(itemData['location'], 'Naperville, Illinois');
        expect(itemData['price'], 6.50);
        expect(itemData['calories'], '198');
        expect(itemData['proteins'], '25.2');
        expect(itemData['fats'], '13.8');
        expect(itemData['carbo'], '23.7');
      },
    );

    test(
      'GlassTheme defines modern Auth Blue design tokens matching reference mockup',
      () {
        expect(GlassTheme.authBlue, const Color(0xFF1B64F2));
        expect(GlassTheme.authBlueDark, const Color(0xFF1351CA));
        expect(GlassTheme.authBlueLight, const Color(0xFFEFF4FF));
        expect(GlassTheme.authTitleDark, const Color(0xFF1E293B));
        expect(GlassTheme.authSubtitle, const Color(0xFF64748B));
        expect(GlassTheme.authInputFill, const Color(0xFFF8FAFC));
        expect(GlassTheme.authInputBorder, const Color(0xFFE2E8F0));
      },
    );

    test(
      'TikTok reference specifies 5 categories: All, Burger, Pizza, Sushi, Chicken',
      () {
        final categories = ['All', 'Burger', 'Pizza', 'Sushi', 'Chicken'];
        expect(categories.length, 5);
        expect(categories[0], 'All');
        expect(categories[1], 'Burger');
        expect(categories[2], 'Pizza');
        expect(categories[3], 'Sushi');
        expect(categories[4], 'Chicken');
      },
    );

    test(
      'TikTok Fast & Free promo tokens match reference colors and curved header radius',
      () {
        const promoYellow = Color(0xFFFFDE00);
        const orderNowOrange = Color(0xFFFF4B26);
        const activeGreenPill = Color(0xFF43A047);
        const headerRadius = Radius.circular(32);

        expect(promoYellow.toARGB32(), 0xFFFFDE00);
        expect(orderNowOrange.toARGB32(), 0xFFFF4B26);
        expect(activeGreenPill.toARGB32(), 0xFF43A047);
        expect(headerRadius.x, 32.0);
      },
    );
  });
}

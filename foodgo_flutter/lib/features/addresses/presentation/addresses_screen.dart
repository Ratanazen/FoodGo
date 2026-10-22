import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../providers/address_provider.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  void _showAddAddressSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final streetController = TextEditingController();
    final cityController = TextEditingController(text: 'Phnom Penh');
    final zipController = TextEditingController(text: '12000');
    bool isDefault = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ResponsiveBottomSheet(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GlassTheme.dialogDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Delivery Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Street address
                    TextFormField(
                      controller: streetController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Street Address, Apartment, or Building',
                        labelStyle: TextStyle(color: GlassTheme.textMuted),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: GlassTheme.primaryGreen,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter street address'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // City
                    TextFormField(
                      controller: cityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'City / District',
                        labelStyle: TextStyle(color: GlassTheme.textMuted),
                        prefixIcon: const Icon(
                          Icons.location_city,
                          color: GlassTheme.primaryGreen,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter city'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Postal Code
                    TextFormField(
                      controller: zipController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Postal / Area Code',
                        labelStyle: TextStyle(color: GlassTheme.textMuted),
                        prefixIcon: const Icon(
                          Icons.pin_drop_outlined,
                          color: GlassTheme.primaryGreen,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Set Default switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Set as Default Delivery Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch.adaptive(
                          value: isDefault,
                          activeTrackColor: GlassTheme.primaryGreen,
                          onChanged: (val) =>
                              setSheetState(() => isDefault = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);

                                await context
                                    .read<AddressProvider>()
                                    .addAddress(
                                      street: streetController.text,
                                      city: cityController.text,
                                      zipCode: zipController.text,
                                      isDefault: isDefault,
                                    );

                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Address added successfully!',
                                      ),
                                      backgroundColor: GlassTheme.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Save Address',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Saved Addresses',
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: GlassTheme.primaryGreen),
            tooltip: 'Add Address',
            onPressed: () => _showAddAddressSheet(context),
          ),
        ],
      ),
      body: ResponsiveWebContainer(
        maxWidth: 760,
        child: addressProvider.isLoading && addresses.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: GlassTheme.primaryGreen,
                ),
              )
            : addresses.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off_outlined,
                        size: 64,
                        color: GlassTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No saved addresses yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a delivery address to order food faster',
                        style: TextStyle(color: GlassTheme.textMuted),
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        text: 'Add New Address',
                        icon: Icons.add,
                        onPressed: () => _showAddAddressSheet(context),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ...addresses.map((addr) {
                    return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: addr.isDefault
                                        ? GlassTheme.primaryGreen.withValues(
                                            alpha: 0.2,
                                          )
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    addr.isDefault
                                        ? Icons.home
                                        : Icons.location_on_outlined,
                                    color: addr.isDefault
                                        ? GlassTheme.primaryGreen
                                        : Colors.white70,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              addr.street,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (addr.isDefault)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: GlassTheme.primaryGreen
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Default',
                                                style: TextStyle(
                                                  color:
                                                      GlassTheme.primaryGreen,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${addr.city}, Cambodia',
                                        style: TextStyle(
                                          color: GlassTheme.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (!addr.isDefault)
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () => addressProvider
                                                  .setDefaultAddress(addr.id),
                                              icon: const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: GlassTheme.primaryGreen,
                                              ),
                                              label: const Text(
                                                'Set as Default',
                                                style: TextStyle(
                                                  color:
                                                      GlassTheme.primaryGreen,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.white38,
                                            ),
                                            tooltip: 'Delete',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              addressProvider.deleteAddress(
                                                addr.id,
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Address deleted',
                                                  ),
                                                  duration: Duration(
                                                    seconds: 1,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.08, end: 0);
                  }),
                  const SizedBox(height: 16),
                  GlassButton(
                    text: 'Add New Address',
                    icon: Icons.add,
                    onPressed: () => _showAddAddressSheet(context),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                ],
              ),
      ),
    );
  }
}

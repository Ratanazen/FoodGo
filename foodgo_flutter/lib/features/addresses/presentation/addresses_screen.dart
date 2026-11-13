import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../providers/address_provider.dart';
import '../../../../screens/map_screen_location.dart';
import '../../../core/utils/location_helper.dart';
import '../../../services/api_service.dart';
import '../../../widgets/location_picker_modal.dart';
import 'package:latlong2/latlong.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  void _showAddAddressSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    bool isDefault = false;
    bool isSaving = false;
    bool isLocating = false;
    double? detectedLat;
    double? detectedLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddressControllersScope(
        builder: (streetController, cityController, zipController) => ResponsiveBottomSheet(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? GlassTheme.dialogDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
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
                              color: isDark ? Colors.white24 : Colors.black26,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Delivery Address',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : GlassTheme.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                              onPressed: () => Navigator.pop(sheetCtx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: isLocating
                                    ? null
                                    : () async {
                                        setSheetState(() => isLocating = true);
                                        final loc = await getDeviceLocation();
                                        if (loc != null) {
                                          final details =
                                              await LocationHelper.resolveLocation(
                                                loc.latitude,
                                                loc.longitude,
                                              );
                                          setSheetState(() {
                                            isLocating = false;
                                            detectedLat = loc.latitude;
                                            detectedLng = loc.longitude;
                                            streetController.text =
                                                details.fullAddress;
                                            cityController.text = details.city;
                                          });
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.my_location,
                                                      color: GlassTheme
                                                          .primaryGreen,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'GPS located: ${details.title}',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else {
                                          setSheetState(
                                            () => isLocating = false,
                                          );
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not get GPS location. Please enter address manually.',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GlassTheme.primaryGreen.withValues(
                                      alpha: isDark ? 0.12 : 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: GlassTheme.primaryGreen.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isLocating)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: GlassTheme.primaryGreen,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.my_location,
                                          size: 16,
                                          color: GlassTheme.primaryGreen,
                                        ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          isLocating
                                              ? 'Locating...'
                                              : 'GPS Location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: GlassTheme.primaryGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final result = await LocationPickerModal.show(
                                    context,
                                    initialPosition:
                                        detectedLat != null &&
                                            detectedLng != null
                                        ? LatLng(detectedLat!, detectedLng!)
                                        : null,
                                  );
                                  if (result != null) {
                                    setSheetState(() {
                                      detectedLat = result.latitude;
                                      detectedLng = result.longitude;
                                      streetController.text =
                                          result.fullAddress;
                                      cityController.text = result.city;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.map_outlined,
                                        size: 16,
                                        color: GlassTheme.royalSmalt,
                                      ),
                                      const SizedBox(width: 6),
                                      const Flexible(
                                        child: Text(
                                          'Show on Map',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: GlassTheme.royalSmalt,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Street address
                        TextFormField(
                          controller: streetController,
                          style: TextStyle(
                            color: isDark ? Colors.white : GlassTheme.textDark,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Street Address, Apartment, or Building',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? GlassTheme.textMuted
                                  : const Color(0xFF64748B),
                            ),
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              color: GlassTheme.primaryGreen,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter street address'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // City
                        TextFormField(
                          controller: cityController,
                          style: TextStyle(
                            color: isDark ? Colors.white : GlassTheme.textDark,
                          ),
                          decoration: InputDecoration(
                            labelText: 'City / District',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? GlassTheme.textMuted
                                  : const Color(0xFF64748B),
                            ),
                            prefixIcon: const Icon(
                              Icons.location_city,
                              color: GlassTheme.primaryGreen,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter city'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Postal Code
                        TextFormField(
                          controller: zipController,
                          style: TextStyle(
                            color: isDark ? Colors.white : GlassTheme.textDark,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Postal / Area Code',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? GlassTheme.textMuted
                                  : const Color(0xFF64748B),
                            ),
                            prefixIcon: const Icon(
                              Icons.pin_drop_outlined,
                              color: GlassTheme.primaryGreen,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Set Default switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Set as Default Delivery Address',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : GlassTheme.textDark,
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
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setSheetState(() => isSaving = true);

                                    try {
                                      await context
                                          .read<AddressProvider>()
                                          .addAddress(
                                            street: streetController.text
                                                .trim(),
                                            city: cityController.text.trim(),
                                            zipCode: zipController.text.trim(),
                                            isDefault: isDefault,
                                            lat: detectedLat,
                                            lng: detectedLng,
                                          );

                                      if (sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Address added successfully!',
                                            ),
                                            backgroundColor:
                                                GlassTheme.primaryGreen,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        setSheetState(() => isSaving = false);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to save address: ${ApiService.formatError(e)}',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            icon: Icon(Icons.add, color: GlassTheme.primaryGreen),
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
                                            alpha: isDark ? 0.2 : 0.12,
                                          )
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.04,
                                                )),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    addr.isDefault
                                        ? Icons.home
                                        : Icons.location_on_outlined,
                                    color: addr.isDefault
                                        ? GlassTheme.primaryGreen
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF64748B)),
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
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: isDark
                                                  ? Colors.white38
                                                  : const Color(0xFF94A3B8),
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

class _AddressControllersScope extends StatefulWidget {
  final Widget Function(
    TextEditingController streetController,
    TextEditingController cityController,
    TextEditingController zipController,
  )
  builder;

  const _AddressControllersScope({required this.builder});

  @override
  State<_AddressControllersScope> createState() =>
      _AddressControllersScopeState();
}

class _AddressControllersScopeState extends State<_AddressControllersScope> {
  final _streetController = TextEditingController();
  final _cityController = TextEditingController(text: 'Phnom Penh');
  final _zipController = TextEditingController(text: '12000');

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_streetController, _cityController, _zipController);
  }
}

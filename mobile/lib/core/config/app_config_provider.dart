import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../network/api_client.dart'; // We'll adjust path if needed

class AppConfigState {
  final String brandName;
  final String logoUrl;
  final String contactPhone;
  final bool isLoading;

  AppConfigState({
    required this.brandName,
    required this.logoUrl,
    required this.contactPhone,
    required this.isLoading,
  });

  AppConfigState copyWith({
    String? brandName,
    String? logoUrl,
    String? contactPhone,
    bool? isLoading,
  }) {
    return AppConfigState(
      brandName: brandName ?? this.brandName,
      logoUrl: logoUrl ?? this.logoUrl,
      contactPhone: contactPhone ?? this.contactPhone,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfigState> {
  AppConfigNotifier()
      : super(AppConfigState(
          brandName: 'Klinik Gigi',
          logoUrl: '',
          contactPhone: '',
          isLoading: true,
        )) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load from cache first
    final cachedBrand = prefs.getString('app_config_brand');
    final cachedLogo = prefs.getString('app_config_logo');
    final cachedPhone = prefs.getString('app_config_phone');
    
    if (cachedBrand != null) {
      state = state.copyWith(
        brandName: cachedBrand,
        logoUrl: cachedLogo ?? '',
        contactPhone: cachedPhone ?? '',
        isLoading: false,
      );
    }

    try {
      // Hardcode API URL or fetch from ApiClient env. For now assuming api_client logic exists.
      // Usually there's a base url. Let's use standard URL logic:
      final response = await http.get(Uri.parse('https://nfmtech.my.id/product/klinik/api/v1/settings/public'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final brandName = data['brand_name'] ?? 'Klinik Gigi';
        final logoUrl = data['logo_url'] ?? '';
        final contactPhone = data['contact_phone'] ?? '';

        await prefs.setString('app_config_brand', brandName);
        await prefs.setString('app_config_logo', logoUrl);
        await prefs.setString('app_config_phone', contactPhone);

        state = state.copyWith(
          brandName: brandName,
          logoUrl: logoUrl,
          contactPhone: contactPhone,
          isLoading: false,
        );
      }
    } catch (e) {
      // Ignore network errors, stick to cache or defaults
      state = state.copyWith(isLoading: false);
    }
  }
}

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfigState>((ref) {
  return AppConfigNotifier();
});

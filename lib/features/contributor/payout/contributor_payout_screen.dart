import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/providers/contributor_provider.dart';

class ContributorPayoutScreen extends StatefulWidget {
  const ContributorPayoutScreen({super.key});

  @override
  State<ContributorPayoutScreen> createState() => _ContributorPayoutScreenState();
}

class _ContributorPayoutScreenState extends State<ContributorPayoutScreen> {
  String _selectedMethod = 'paypal';
  
  // Controllers
  final _paypalEmailController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _accNumberController = TextEditingController();
  String _accType = 'savings';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPayoutData();
  }

  @override
  void dispose() {
    _paypalEmailController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _accNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.dio.get('/auth/me');
      final rawData = response.data['data'] ?? response.data;
      
      final payout = rawData['payoutInfo'];

      if (payout != null) {
        setState(() {
          _selectedMethod = payout['method'] ?? 'paypal';
          _paypalEmailController.text = payout['paypalEmail'] ?? '';
          if (payout['jamaicanBank'] != null) {
            _bankNameController.text = payout['jamaicanBank']['bankName'] ?? '';
            _branchNameController.text = payout['jamaicanBank']['branchName'] ?? '';
            _accNumberController.text = payout['jamaicanBank']['accountNumber'] ?? '';
            _accType = payout['jamaicanBank']['accountType'] ?? 'savings';
          } else if (payout['bankAccount'] != null) {
            // Fallback to generic bankAccount field
            _bankNameController.text = payout['bankAccount']['bankName'] ?? '';
            _branchNameController.text = payout['bankAccount']['branchName'] ?? '';
            _accNumberController.text = payout['bankAccount']['accountNumber'] ?? '';
            _accType = payout['bankAccount']['accountType'] ?? 'savings';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading payout settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePayoutSettings() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ContributorProvider>();
      
      Map<String, dynamic>? bankAccountData;
      if (_selectedMethod == 'bank') {
        bankAccountData = {
          'bankName': _bankNameController.text.trim(),
          'branchName': _branchNameController.text.trim(),
          'accountNumber': _accNumberController.text.trim(),
          'accountType': _accType,
        };
      }

      final success = await provider.updatePayout(
        method: _selectedMethod,
        paypalEmail: _selectedMethod == 'paypal' ? _paypalEmailController.text.trim() : null,
        bankAccount: bankAccountData,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payout details saved successfully'), backgroundColor: AppColors.primary),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Failed to update payout settings'), backgroundColor: AppColors.destructive),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payout Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHOOSE METHOD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMethodSelector(),
                  const SizedBox(height: 32),
                  
                  if (_selectedMethod == 'paypal') _buildPaypalFields(),
                  if (_selectedMethod == 'bank') _buildBankFields(),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePayoutSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMethodSelector() {
    final methods = [
      {'id': 'paypal', 'label': 'PayPal', 'icon': Icons.payment},
      {'id': 'bank', 'label': 'Bank Transfer', 'icon': Icons.account_balance},
    ];

    return Row(
      children: methods.map((m) {
        final isSelected = _selectedMethod == m['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMethod = m['id'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary.withOpacity(0.12) : AppColors.card,
                border: Border.all(
                  color: isSelected ? AppColors.secondary : Colors.white.withOpacity(0.04),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    m['icon'] as IconData,
                    color: isSelected ? AppColors.secondary : AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.mutedForeground,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaypalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYPAL EMAIL',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedForeground, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _paypalEmailController,
          hint: 'Enter your PayPal email address',
          icon: Icons.email_outlined,
        ),
      ],
    );
  }

  Widget _buildBankFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BANK DETAILS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedForeground, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Bank Name',
          value: _bankNameController.text,
          items: ['NCB', 'Scotiabank', 'Sagicor', 'JMMB', 'FGB', 'Other'],
          onChanged: (val) => setState(() => _bankNameController.text = val!),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _branchNameController,
          hint: 'Branch Name',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _accNumberController,
          hint: 'Account Number',
          icon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Account Type',
          value: _accType,
          items: ['savings', 'checking'],
          onChanged: (val) => setState(() => _accType = val!),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.foreground, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.mutedForeground, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          border: InputBorder.none,
        ),
        dropdownColor: AppColors.card,
        style: const TextStyle(color: AppColors.foreground, fontSize: 14),
        items: items.map((i) => DropdownMenuItem(
          value: i,
          child: Text(i, style: const TextStyle(color: AppColors.foreground)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

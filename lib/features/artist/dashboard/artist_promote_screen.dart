import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_colors.dart';

class ArtistPromoteScreen extends StatefulWidget {
  const ArtistPromoteScreen({super.key});

  @override
  State<ArtistPromoteScreen> createState() => _ArtistPromoteScreenState();
}

class _ArtistPromoteScreenState extends State<ArtistPromoteScreen> {
  double _budget = 100.0;
  String? _selectedTrack;
  final List<String> _regions = ['United States', 'UK'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Create Promotion', style: TextStyle(color: AppColors.foreground)),
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Select Track'),
            const SizedBox(height: 10),
            _buildDropdown(),
            const SizedBox(height: 30),
            
            _buildSectionHeader('Target Regions'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _regions.map((region) => Chip(
                label: Text(region, style: const TextStyle(color: Colors.white)),
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                side: const BorderSide(color: AppColors.primary),
              )).toList(),
            ),
            const SizedBox(height: 30),

            _buildSectionHeader('Budget'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('\$50', style: TextStyle(color: AppColors.mutedForeground)),
                Expanded(
                  child: Slider(
                    value: _budget,
                    min: 50,
                    max: 1000,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.muted,
                    onChanged: (val) => setState(() => _budget = val),
                  ),
                ),
                const Text('\$1000+', style: TextStyle(color: AppColors.mutedForeground)),
              ],
            ),
            Center(
              child: Text('\$${_budget.toInt()}', style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign launched successfully!')));
                  Navigator.pop(context);
                },
                child: const Text('Launch Campaign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: AppColors.card,
          hint: const Text('Select a track to promote', style: TextStyle(color: AppColors.mutedForeground)),
          value: _selectedTrack,
          items: const [
            DropdownMenuItem(value: 'track1', child: Text('Nova Drift', style: TextStyle(color: AppColors.foreground))),
            DropdownMenuItem(value: 'track2', child: Text('Celestial', style: TextStyle(color: AppColors.foreground))),
          ],
          onChanged: (val) => setState(() => _selectedTrack = val),
        ),
      ),
    );
  }
}

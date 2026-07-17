import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _welcomeCoinsCtrl = TextEditingController();
  final _refereeRewardCtrl = TextEditingController();
  final _referrerRewardCtrl = TextEditingController();
  final _approvalRewardCtrl = TextEditingController();
  final _commissionRateCtrl = TextEditingController();
  final _appNameCtrl = TextEditingController();
  final _appLogoUrlCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  @override
  void dispose() {
    _welcomeCoinsCtrl.dispose();
    _refereeRewardCtrl.dispose();
    _referrerRewardCtrl.dispose();
    _approvalRewardCtrl.dispose();
    _commissionRateCtrl.dispose();
    _appNameCtrl.dispose();
    _appLogoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchConfig() async {
    setState(() => _loading = true);
    try {
      final response = await AdminApiService.request('GET', '/api/admin/config');
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        final config = response.data['data'];
        setState(() {
          _welcomeCoinsCtrl.text = (config['initialWelcomeCoins'] ?? 0).toString();
          _refereeRewardCtrl.text = (config['referralRefereeReward'] ?? 50).toString();
          _referrerRewardCtrl.text = (config['referralReferrerReward'] ?? 50).toString();
          _approvalRewardCtrl.text = (config['noteApprovalReward'] ?? 50).toString();
          _commissionRateCtrl.text = (config['platformCommissionRate'] ?? 10).toString();
          _appNameCtrl.text = (config['appName'] ?? 'EduMarket').toString();
          _appLogoUrlCtrl.text = (config['appLogoUrl'] ?? '').toString();
        });
      } else {
        _snack('Failed to fetch settings.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final response = await AdminApiService.request(
        'PUT',
        '/api/admin/config',
        data: {
          'initialWelcomeCoins': int.tryParse(_welcomeCoinsCtrl.text.trim()) ?? 0,
          'referralRefereeReward': int.tryParse(_refereeRewardCtrl.text.trim()) ?? 50,
          'referralReferrerReward': int.tryParse(_referrerRewardCtrl.text.trim()) ?? 50,
          'noteApprovalReward': int.tryParse(_approvalRewardCtrl.text.trim()) ?? 50,
          'platformCommissionRate': int.tryParse(_commissionRateCtrl.text.trim()) ?? 10,
          'appName': _appNameCtrl.text.trim(),
          'appLogoUrl': _appLogoUrlCtrl.text.trim(),
        },
      );

      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        _snack('Configuration updated successfully! 🎉', kSuccess);
      } else {
        _snack('Failed to save settings.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          isMobile
                              ? 'Platform Config'
                              : 'Platform Configuration & Economy Settings',
                          style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage coins distribution, referral rates, and commission fees.',
                          style: GoogleFonts.inter(color: kTextMuted, fontSize: 13),
                        ),
                        const Divider(height: 40, color: kBorder),

                        // Forms card
                        Container(
                          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.settings_suggest_rounded,
                                      color: kPrimary, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Coin Economy Configuration',
                                      style: GoogleFonts.inter(
                                          color: kTextPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              _buildConfigField(
                                label: 'Initial Welcome Coins',
                                hint: 'Coins rewarded to any newly signed up user',
                                controller: _welcomeCoinsCtrl,
                                icon: Icons.star_border_rounded,
                              ),
                              const SizedBox(height: 20),

                              _buildConfigField(
                                label: 'Note Approval Reward (Coins)',
                                hint: 'Coins given to creator when note is approved',
                                controller: _approvalRewardCtrl,
                                icon: Icons.card_giftcard_rounded,
                              ),
                              const SizedBox(height: 20),

                              _buildConfigField(
                                label: 'Referral Sign-up Reward (Referee)',
                                hint: 'Coins awarded to new user signing up via code',
                                controller: _refereeRewardCtrl,
                                icon: Icons.person_add_alt_1_rounded,
                              ),
                              const SizedBox(height: 20),

                              _buildConfigField(
                                label: 'Referral Invite Reward (Referrer)',
                                hint: 'Coins awarded to inviter when code is redeemed',
                                controller: _referrerRewardCtrl,
                                icon: Icons.group_add_rounded,
                              ),
                              const SizedBox(height: 20),

                              _buildConfigField(
                                label: 'Platform Commission Rate (%)',
                                hint: 'Percentage deducted on peer-to-peer coins transactions',
                                controller: _commissionRateCtrl,
                                icon: Icons.percent_rounded,
                                isPercentage: true,
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                label: 'Application Branding Name',
                                hint: 'Customer-facing app title (e.g. EduMarket)',
                                controller: _appNameCtrl,
                                icon: Icons.badge_rounded,
                              ),
                              const SizedBox(height: 20),

                              // Logo URL + Upload
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Application Branding Logo (URL)',
                                      style: GoogleFonts.inter(
                                          color: kTextPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Logo icon link or upload an image',
                                      style: GoogleFonts.inter(
                                          color: kTextMuted, fontSize: 11)),
                                  const SizedBox(height: 8),
                                  if (isMobile)
                                    Column(children: [
                                      TextFormField(
                                        controller: _appLogoUrlCtrl,
                                        style: GoogleFonts.inter(
                                            color: kTextPrimary, fontSize: 14),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Value cannot be empty';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.image_rounded,
                                              color: kTextMuted, size: 20),
                                          suffixIcon: _uploadingLogo
                                              ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                          strokeWidth: 2)))
                                              : null,
                                          filled: true,
                                          fillColor: kSurfaceHigh,
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide.none),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: kPrimary, width: 2)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _uploadingLogo
                                              ? null
                                              : () async {
                                                  setState(
                                                      () => _uploadingLogo = true);
                                                  final url =
                                                      await AdminApiService
                                                          .uploadImage();
                                                  if (url != null) {
                                                    _appLogoUrlCtrl.text = url;
                                                    _snack('Logo uploaded!',
                                                        kSuccess);
                                                  }
                                                  setState(
                                                      () => _uploadingLogo = false);
                                                },
                                          icon: const Icon(
                                              Icons.upload_file_rounded),
                                          label: const Text('Upload Logo'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                kPrimary.withValues(alpha: 0.1),
                                            foregroundColor: kPrimary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    ])
                                  else
                                    Row(children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _appLogoUrlCtrl,
                                          style: GoogleFonts.inter(
                                              color: kTextPrimary, fontSize: 14),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return 'Value cannot be empty';
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                                Icons.image_rounded,
                                                color: kTextMuted,
                                                size: 20),
                                            suffixIcon: _uploadingLogo
                                                ? const Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2)))
                                                : null,
                                            filled: true,
                                            fillColor: kSurfaceHigh,
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                    color: kPrimary, width: 2)),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _uploadingLogo
                                            ? null
                                            : () async {
                                                setState(
                                                    () => _uploadingLogo = true);
                                                final url =
                                                    await AdminApiService
                                                        .uploadImage();
                                                if (url != null) {
                                                  _appLogoUrlCtrl.text = url;
                                                  _snack(
                                                      'Logo uploaded successfully!',
                                                      kSuccess);
                                                }
                                                setState(
                                                    () => _uploadingLogo = false);
                                              },
                                        icon: const Icon(
                                            Icons.upload_file_rounded),
                                        label: const Text('Upload Logo'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              kPrimary.withValues(alpha: 0.1),
                                          foregroundColor: kPrimary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 18),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          elevation: 0,
                                        ),
                                      ),
                                    ]),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Save button - full width on mobile
                              SizedBox(
                                width: isMobile ? double.infinity : 220,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _saveConfig,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                      : Text('Save Configurations',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );

  }

  Widget _buildConfigField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPercentage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(hint, style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: kTextPrimary, fontSize: 14),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Value cannot be empty';
            final val = int.tryParse(v);
            if (val == null) return 'Enter a valid number';
            if (val < 0) return 'Cannot be negative';
            if (isPercentage && val > 100) return 'Percentage cannot exceed 100%';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kTextMuted, size: 20),
            filled: true,
            fillColor: kSurfaceHigh,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(hint, style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: kTextPrimary, fontSize: 14),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Value cannot be empty';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kTextMuted, size: 20),
            filled: true,
            fillColor: kSurfaceHigh,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

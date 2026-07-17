class OnboardingCache {
  static final OnboardingCache instance = OnboardingCache._internal();
  OnboardingCache._internal();

  // Keep API matching for splash screen & onboarding
  final List<dynamic> controllers = [null, null, null];

  Future<void> preload() async {
    // No-op for local gif assets
  }

  void dispose() {
    // No-op for local gif assets
  }
}

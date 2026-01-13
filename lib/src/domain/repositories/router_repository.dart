abstract class RouterRepository {
  bool isOnboardingCompleted();

  bool isUserLoggedIn();

  void saveOnboardingAsCompleted();

  // Methods for handling intended routes after login
  void saveIntendedRoute(String route);

  String? getIntendedRoute();

  void clearIntendedRoute();
}

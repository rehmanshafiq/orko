enum AppRoute {
  splash('/splash'),
  onboarding('/onboarding'),
  login('/login'),
  bottomNavigation('/home');

  const AppRoute(this.path);

  final String path;
}

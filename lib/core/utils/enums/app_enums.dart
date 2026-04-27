enum AppRoute {
  splash('/splash'),
  onboarding('/login'),
  bottomNavigation('/home');

  const AppRoute(this.path);

  final String path;
}

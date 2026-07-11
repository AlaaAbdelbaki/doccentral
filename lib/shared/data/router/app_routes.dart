/// Route registry. Each entry carries both the GoRouter path and route name
/// so navigation never relies on hardcoded strings.
enum AppRoutes {
  calendar(path: '/calendar', name: 'calendar'),
  patients(path: '/patients', name: 'patients'),
  inventory(path: '/inventory', name: 'inventory'),
  dayCloseout(path: '/day-closeout', name: 'dayCloseout'),
  settings(path: '/settings', name: 'settings'),
  signUp(path: '/sign-up', name: 'signUp'),
  signIn(path: '/sign-in', name: 'signIn');

  const AppRoutes({required this.path, required this.name});

  final String path;
  final String name;
}

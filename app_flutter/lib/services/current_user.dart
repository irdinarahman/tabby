/// Small in-memory holder for the logged-in user's id, populated right
/// after login/register/app-start (see main.dart). Screens use this to
/// work out which `tab_member` row is "you" within a given tab, since a
/// tab's members are keyed by tab_member id, not user id.
class CurrentUser {
  CurrentUser._();
  static final CurrentUser instance = CurrentUser._();

  String? id;
  String? name;
}

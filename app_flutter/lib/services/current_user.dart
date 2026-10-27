/// In-memory holder for the logged-in user, filled at login/register and
/// restored from local storage at app start. Screens use [id] to work out
/// which tab_member row is "you" inside a given tab.
class CurrentUser {
  CurrentUser._();
  static final CurrentUser instance = CurrentUser._();

  String? id;
  String? name;
  String? email;

  void clear() {
    id = null;
    name = null;
    email = null;
  }
}

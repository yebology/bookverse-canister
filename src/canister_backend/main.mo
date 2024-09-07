import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";

actor {

  private var user_subscriptions = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var author_subscribers = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);

  public shared({ caller }) func subscribeAuthor(_author : Principal) : async() {
    await _addUserSubscriptions(caller, _author);
    await _addAuthorSubscribers(caller, _author);
  };

  public query func getAuthorSubscribers(_author : Principal) : async([Principal]) {
    return switch (author_subscribers.get(_author)) {
      case (?subs) { subs; };
      case (_) { [] };
    };
  };

  public query func getUserSubscriptions(_user: Principal) : async ([Principal]) {
    return switch (user_subscriptions.get(_user)) {
      case (?subs) { subs; };
      case (_) { []; };
    };
  };

  private func _addUserSubscriptions(_user : Principal, _author : Principal) : async() {
    let subscriptions = switch (user_subscriptions.get(_user)) {
      case (?subs) { subs };
      case (_) { [] };
    };
    let updated_subscriptions = Array.append(subscriptions, [_author]);
    user_subscriptions.put(_user, updated_subscriptions);
  };

  private func _addAuthorSubscribers(_user : Principal, _author : Principal) : async() {
    let subscribers = switch (author_subscribers.get(_author)) {
      case (?subs) { subs };
      case (_) { [] };
    };
    let updated_subscribers = Array.append(subscribers, [_user]);
    author_subscribers.put(_author, updated_subscribers);
  }

};

import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Error "mo:base/Error";
// import Debug "mo:base/Debug";
// import Type "types/type";
import PointClass "class/point";

// make normal actor again after testing
actor class Main() {

  private type Point = PointClass.Point;

  private var point : Point = PointClass.Point("BookPoint", "BP");

  private var user_subscriptions = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var author_subscribers = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var subscription_price = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

  // delete after testing
  public func dummyMint(caller : Principal, _amount : Nat) : async() {
    point.mint(caller, 100);
  };

  public shared({ caller }) func goPremium(_price : Nat) : async () {
    await _checkSubscriptionPrice(_price);
    await _addSubscriptionPrice(caller, _price);
  };

  // change to shared caller again after testing
  public func subscribeAuthor(caller : Principal, _author : Principal) : async() {
    await _paySubscriptions(caller, _author);
    await _addUserSubscriptions(caller, _author);
    await _addAuthorSubscribers(caller, _author);
  };

  public query func getAuthorSubscribers(_author : Principal) : async([Principal]) {
    return switch (author_subscribers.get(_author)) {
      case (?subs) { subs; };
      case (null) { [] };
    };
  };

  public query func getUserSubscriptions(_user: Principal) : async([Principal]) {
    return switch (user_subscriptions.get(_user)) {
      case (?subs) { subs; };
      case (null) { []; };
    };
  };

  public query func getSubscriptionPrice(_author: Principal) : async(Nat) {
    return switch (subscription_price.get(_author)) {
      case (?price) { price };
      case (null) { throw Error.reject("Invalid author.") }
    };
  };

  public query func getUserPoints(_user : Principal) : async(Nat) {
    return point.getUserPoints(_user);
  };

  private func _hasEnoughPoints(_require: Nat, _amount: Nat) : async() {
    if (_amount < _require) {
      throw Error.reject("Not enough points.");
    }
  };

  private func _checkSubscriptionPrice(_price : Nat) : async() {
    if (_price <= 0) {
        throw Error.reject("Invalid subscription price.");
    };
  };

  private func _addSubscriptionPrice(_author : Principal, _amount : Nat) : async() {
      switch (subscription_price.get(_author)) {
        case (null) { subscription_price.put(_author, _amount); };
        case (?_) { throw Error.reject("Already Premium.") };
    };
  };

  private func _paySubscriptions(_user : Principal, _author : Principal) : async() {
    let require = await _getSubscriptionPrice(_author);
    let amount = point.getUserPoints(_user);
    await _hasEnoughPoints(require, amount);
    await _movePoint(_user, _author, require);
  };

  private func _movePoint(_user : Principal, _author : Principal, _amount : Nat) : async () {
    point.transfer(_user, _author, _amount);
  };

  private func _addUserSubscriptions(_user : Principal, _author : Principal) : async() {
    let subscriptions = switch (user_subscriptions.get(_user)) {
      case (?subs) { subs };
      case (null) { [] };
    };
    let updated_subscriptions = Array.append(subscriptions, [_author]);
    user_subscriptions.put(_user, updated_subscriptions);
  };

  private func _addAuthorSubscribers(_user : Principal, _author : Principal) : async() {
    let subscribers = switch (author_subscribers.get(_author)) {
      case (?subs) { subs };
      case (null) { [] };
    };
    let updated_subscribers = Array.append(subscribers, [_user]);
    author_subscribers.put(_author, updated_subscribers);
  };

  private query func _getSubscriptionPrice(_author : Principal) : async(Nat) {
    return switch (subscription_price.get(_author)) {
      case (?price) { price };
      case (null) { throw Error.reject("Invalid author.") }
    };
  };

  // private query func _getGiftPrice(_id: Nat) : async(Nat) {
  //   let found_gift = Array.find<Gift>(gifts, func (x : Gift) {
  //     return x.id == _id;
  //   });

  //   switch (found_gift) {
  //     case (?gift) { return gift.price; };
  //     case (_) { throw Error.reject("Invalid gift id!"); };
  //   };
  // }

};

import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Type "types/type";
import Class "class/point";

actor {

  private type Gift = Type.Gift;
  private type Point = Class.Point;

  private var gifts : [Gift] = [];

  private var owner : Principal = Principal.fromText("aaa-aaa");
  private var point : Point = Class.Point("BookPoint", "BP");

  private var user_subscriptions = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var author_subscribers = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);

  public shared({ caller }) func addNewGifts(_image: Text, _name: Text, _price: Nat) : async() {
    await _onlyOwner(caller);
    let new_gift : Gift = {
      id = Array.size(gifts);
      image = _image;
      name = _name;
      price = _price
    };
    gifts := Array.append<Gift>(gifts, [new_gift]);
  };

  public shared({ caller }) func swapPointWithGift(_id : Nat) : async() {
    await _checkUserPoints(_id, caller);
    
  };

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

  public query func getUserSubscriptions(_user: Principal) : async([Principal]) {
    return switch (user_subscriptions.get(_user)) {
      case (?subs) { subs; };
      case (_) { []; };
    };
  };

  private func _onlyOwner(_user : Principal) : async() {
    if (owner != _user) {
      throw Error.reject("Unauthorized user");
    }
  };

  private func _checkUserPoints(_id : Nat, _user : Principal) : async() {
    let _require = await _getGiftPrice(_id);
    let _amount = point.getUserPoints(_user);
    await _hasEnoughPoints(_require, _amount);
  };

  private func _hasEnoughPoints(_require: Nat, _amount: Nat) : async() {
    if (_amount < _require) {
      throw Error.reject("Not enough points");
    }
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
  };

  private query func _getGiftPrice(_id: Nat) : async(Nat) {
    let found_gift = Array.find<Gift>(gifts, func (x : Gift) {
      return x.id == _id;
    });

    switch (found_gift) {
      case (?gift) { return gift.price; };
      case (_) { throw Error.reject("Invalid gift id!"); };
    };
  }

};

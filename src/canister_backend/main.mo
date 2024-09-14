import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
import Type "types/type";
import PointClass "class/point";

// make normal actor again after testing
actor class Main() {

  private type Point = PointClass.Point;
  private type Task = Type.Task;

  private var point : Point = PointClass.Point("BookPoint", "BP");
  private var owner : Principal = Principal.fromText("wo5qg-ysjiq-5da"); // change before deploy

  private var tasks : [Task] = [];
  private var genres : [Text] = [
    "Horror", "Science Fiction", "Mystery", 
    "Dystopian", "Utopian", "Fantasy", 
    "Romance", "Fiction", "Non-Fiction", 
    "Thriller", "Adventure", "Crime", 
    "Comedy", "Western", "Biography", 
    "History", "Sports", "Cooking", "Art"  
  ];

  private var user_subscriptions = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var author_subscribers = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var subscription_price = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
  private var completed_tasks = HashMap.HashMap<Principal, [Nat]>(0, Principal.equal, Principal.hash);
  private var current_book = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

  // delete after testing
  public func dummyMint(caller : Principal, _amount : Nat) : async() {
    point.mint(caller, 100);
  };

  public shared({ caller }) func goPremium(_price : Nat) : async () {
    Debug.print(Principal.toText(caller)); // delete before deploy
    await _checkSubscriptionPrice(_price);
    await _addSubscriptionPrice(caller, _price);
  };

  // change to shared caller again after testing
  public func subscribeAuthor(caller : Principal, _author : Principal) : async() {
    await _paySubscriptions(caller, _author);
    await _addUserSubscriptions(caller, _author);
    await _addAuthorSubscribers(caller, _author);
  };

  public shared({ caller }) func addCurrentBook(_id : Nat) : async() {
    await _addCurrentBook(caller, _id);
  };

  public shared({ caller }) func addTask(name : Text, url : Text, point : Nat) : async() {
    await _onlyOwner(caller);
    await _checkTaskInput(name, url, point);
    await _addTaskInput(name, url, point);
  };

  public shared({ caller }) func doTask(_id : Nat) : async() {
    let (is_there, gain) = await _checkExistingTask(_id);
    if (is_there) {
      await _addCompletedTask(caller, _id);
      await _addUserPointFromTask(caller, gain);
    }
  };

  public query func getAuthorSubscribers(_author : Principal) : async(Nat) {
    return switch (author_subscribers.get(_author)) {
      case (?subs) { subs.size(); };
      case (null) { 0 };
    };
  };

  public query func getUserSubscriptions(_user: Principal) : async(Nat) {
    return switch (user_subscriptions.get(_user)) {
      case (?subs) { subs.size(); };
      case (null) { 0; };
    };
  };

  public query func getSubscriptionPrice(_author: Principal) : async(Nat) {
    return switch (subscription_price.get(_author)) {
      case (?price) { price };
      case (null) { throw Error.reject("Invalid author.") }
    };
  };

  public query func getCurrentBook(_user: Principal) : async(Bool, Nat) {
    return switch (current_book.get(_user)) {
      case (?book) { (true, book); };
      case (null) { (false, 0); };
    }
  };

  public query func getTasks() : async([Task]) {
    return tasks;
  };

  public query func getCompletedTasks(_user : Principal) : async([Nat]) {
    return switch (completed_tasks.get(_user)) {
      case (?complete) { complete };
      case (null) { []; };
    }
  };

  public query func getPoints(_user : Principal) : async(Nat) {
    return point.getUserPoints(_user);
  };

  private func _onlyOwner(_user : Principal) : async() {
    if (owner != _user) {
      throw Error.reject("Invalid owner.");
    }
  };

  private func _checkTaskInput(_name : Text, _url : Text, _point : Nat) : async() {
    if (_name == "" or _url == "" or _point <= 0) {
      throw Error.reject("Invalid task input.");
    }
  };

  private func _hasEnoughPoints(_require: Nat, _amount: Nat) : async() {
    if (_amount < _require) {
      throw Error.reject("Not enough points.");
    }
  };

  private func _checkExistingTask(_id : Nat) : async(Bool, Nat) {
    return switch (Array.find<Task>(tasks, func(x : Task) {
      x.id == _id
    })) {
      case (?founded) { (true, founded.point); };
      case (null) { throw Error.reject("Task id not found."); };
    };
  };

  private func _checkSubscriptionPrice(_price : Nat) : async() {
    if (_price <= 0) {
        throw Error.reject("Invalid subscription price.");
    };
  };

  private func _addTaskInput(_name : Text, _url : Text, _point : Nat) : async() {
    let task : Task = {
      id = tasks.size();
      name = _name;
      url = _url;
      point = _point;
    };
    tasks := Array.append(tasks, [task]);
  };

  private func _addCurrentBook(_user : Principal, _id : Nat) : async() {
    current_book.put(_user, _id);
  };

  private func _addCompletedTask(_user : Principal, _id : Nat) : async() {
    let completed = switch(completed_tasks.get(_user)) {
      case (?tasks) { tasks };
      case (null) { [] };
    };
    let updated = Array.append(completed, [_id]);
    completed_tasks.put(_user, updated); 
  };

  private func _addUserPointFromTask(_user : Principal, _gain : Nat) : async() {
    point.mint(_user, _gain);
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

  private func _movePoint(_user : Principal, _author : Principal, _amount : Nat) : async() {
    point.transfer(_user, _author, _amount);
  };

  private func _addUserSubscriptions(_user : Principal, _author : Principal) : async() {
    let subscriptions = switch (user_subscriptions.get(_user)) {
      case (?subs) { subs };
      case (null) { [] };
    };
    let updated = Array.append(subscriptions, [_author]);
    user_subscriptions.put(_user, updated);
  };

  private func _addAuthorSubscribers(_user : Principal, _author : Principal) : async() {
    let subscribers = switch (author_subscribers.get(_author)) {
      case (?subs) { subs };
      case (null) { [] };
    };
    let updated = Array.append(subscribers, [_user]);
    author_subscribers.put(_author, updated);
  };

  private query func _getSubscriptionPrice(_author : Principal) : async(Nat) {
    return switch (subscription_price.get(_author)) {
      case (?price) { price };
      case (null) { throw Error.reject("Invalid author.") }
    };
  };

};

import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Type "types/type";
import PointClass "class/point";

actor {

  private type Point = PointClass.Point;
  private type Task = Type.Task;
  private type Book = Type.Book;

  private var point : Point = PointClass.Point();

  private var tasks : [Task] = [];
  private var books : [Book] = [];

  private var genres : [Text] = [
    "Horror", "Science Fiction", "Mystery", 
    "Dystopian", "Utopian", "Fantasy", 
    "Romance", "Fiction", "Non-Fiction", 
    "Thriller", "Adventure", "Crime", 
    "Comedy", "Western", "Biography", 
    "History", "Sports", "Cooking", "Art"  
  ];

  private var key = "";

  private var user_subscriptions = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var user_bookmarks = HashMap.HashMap<Principal, [Nat]>(0, Principal.equal, Principal.hash);
  private var author_subscribers = HashMap.HashMap<Principal, [Principal]>(0, Principal.equal, Principal.hash);
  private var subscription_price = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
  private var completed_tasks = HashMap.HashMap<Principal, [Nat]>(0, Principal.equal, Principal.hash);
  private var current_book = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
  private var book_readers = HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);

  public shared({ caller }) func goPremium(_price : Nat) : async () {
    await _checkSubscriptionPrice(_price);
    await _addSubscriptionPrice(caller, _price);
  };

  public shared({ caller }) func subscribeAuthor( _author : Principal) : async() {
    await _paySubscriptions(caller, _author);
    await _addUserSubscriptions(caller, _author);
    await _addAuthorSubscribers(caller, _author);
  };

  public shared({ caller }) func readBook(_id : Nat) : async() {
    await _readBook(_id);
    await _addCurrentBook(caller, _id);
  };

  public func addTask(_name : Text, _url : Text, _point : Nat, _key : Text) : async() {
    await _onlyOwner(_key);
    await _checkTaskInput(_name, _url, _point);
    await _addTaskInput(_name, _url, _point);
  };

  public shared({ caller }) func doTask(_id : Nat) : async() {
    let (is_there, gain) = await _checkExistingTask(_id);
    if (is_there) {
      await _addCompletedTask(caller, _id);
      await _addUserPointFromTask(caller, gain);
    }
  };

  public shared({ caller }) func addToBookmark(_id : Nat) : async(){
      await _addBookToUserBookmark(caller, _id);
  };

  public shared({ caller }) func removeFromBookmark(_id : Nat) : async(){
      await _removeBookFromUserBookmark(caller, _id);
  };

  public shared({ caller }) func addBook(title: Text, synopsis: Text, year: Nat, genre: Text, cover: Text, file: Text) : async() {
      await _checkBookInput(title, synopsis, year, genre, cover, file);
      await _addBookInput(title, synopsis, year, genre, caller, cover, file)
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

  public query func getBookReaders(_id : Nat) : async(Nat) {
    return switch(book_readers.get(_id)) {
      case (?founded) { founded; };
      case (null) { 0; };
    }
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

  public query func getGenres() : async([Text]) {
    return genres;
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

  public query func getBooks() : async([Book]) {
    return books;
  };

  public query func getBookmarks(_user : Principal) : async([Nat]) {
    return switch (user_bookmarks.get(_user)) {
      case (?bookmarks) { bookmarks };
      case (null) { []; };
    }
  };

public query func getUploadedBooks(_user: Principal) : async [Book] {
    let userBooks = Array.filter<Book>(books, func (book: Book) : Bool {
        book.author == _user
    });

    return userBooks;
};

  private func _onlyOwner(_key : Text) : async() {
    if (key == "") {
      key := _key;
    }
    else if (key != _key) {
      throw Error.reject("Non-authorized owner.");
    };
  };

  private func _checkTaskInput(_name : Text, _url : Text, _point : Nat) : async() {
    if (_name == "" or _url == "" or _point <= 0) {
      throw Error.reject("Invalid task input.");
    };
  };

  private func _hasEnoughPoints(_require: Nat, _amount: Nat) : async() {
    if (_amount < _require) {
      throw Error.reject("Not enough points.");
    };
  };

  private func _checkExistingTask(_id : Nat) : async(Bool, Nat) {
    return switch (Array.find<Task>(tasks, func(x : Task) {
      x.id == _id;
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

  private func _checkBookInput(_title: Text, _synopsis: Text, _year: Nat, _genre: Text, _cover: Text, _file: Text) : async() {
    if (_title == "" or _synopsis == "" or _year == 0 or _genre == "" or _cover == "" or _file == ""){
      throw Error.reject("Invalid book input.");
    };
  };

  private func _readBook(_id : Nat) : async() {
    let book_exist = Array.find<Book>(books, func(x : Book) { x.id == _id });
    if (book_exist == null) {
      throw Error.reject("Book id not found.");
    };
    
    switch (book_readers.get(_id)) {
      case (?founded) {
        let updated_readers = founded + 1;
          book_readers.put(_id, updated_readers);
        };
      case (null) {
        book_readers.put(_id, 1);
      }
    }
  };

  private func _addBookInput(_title : Text, _synopsis : Text, _year : Nat, _genre : Text, _author : Principal, _cover : Text, _file : Text) : async(){
    let book : Book = {
        id = books.size();
        title = _title;
        synopsis = _synopsis;
        year = _year;
        genre = _genre;
        author = _author;
        cover = _cover;
        file = _file;
    };
    books := Array.append(books, [book]);
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

  private func _addBookToUserBookmark(_user : Principal, _id : Nat) : async() {
    let bookmarks = switch (user_bookmarks.get(_user)) {
      case (?books) { books };
      case (null) { [] };
    };
      let updated = Array.append(bookmarks, [_id]);
      user_bookmarks.put(_user, updated);
  };

  private func _removeBookFromUserBookmark(_user: Principal, _id: Nat) : async () {
    let bookmarks = switch (user_bookmarks.get(_user)) {
        case (?books) { books };
        case null { [] };
    };
    let updated = Array.filter<Nat>(bookmarks, func (book: Nat) : Bool {
        book != _id
    });
    user_bookmarks.put(_user, updated);
  };
};

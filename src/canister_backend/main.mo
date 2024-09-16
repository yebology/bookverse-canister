import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Type "types/type";

actor {

  private type Task = Type.Task;
  private type Book = Type.Book;

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

  private var user_points = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
  private var user_bookmarks = HashMap.HashMap<Principal, [Nat]>(0, Principal.equal, Principal.hash);
  private var completed_tasks = HashMap.HashMap<Principal, [Nat]>(0, Principal.equal, Principal.hash);
  private var current_book = HashMap.HashMap<Principal, Text>(0, Principal.equal, Principal.hash);
  private var book_readers = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);

  public shared({ caller }) func readBook(_title : Text) : async() {
    await _readBook(_title);
    await _addCurrentBook(caller, _title);
  };

  public shared({ caller }) func donateToAuthor(_author : Principal, _amount : Nat) : async() {
    await _checkUserPoints(caller, _amount);
    await _transferPoint(caller, _author, _amount);
  };

  public shared({ caller }) func doTask(_id : Nat) : async() {
    let (is_there, gain) = await _checkExistingTask(_id);
    if (is_there) {
      await _addCompletedTask(caller, _id);
      await _mintPoint(caller, gain);
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

  public func addTask(_name : Text, _url : Text, _point : Nat, _key : Text) : async() {
    await _onlyOwner(_key);
    await _checkTaskInput(_name, _url, _point);
    await _addTaskInput(_name, _url, _point);
  };

  public query func getBookReaders(_title : Text) : async(Nat) {
    return switch(book_readers.get(_title)) {
      case (?founded) { founded; };
      case (null) { 0; };
    }
  };

  public query func getCurrentBook(_user: Principal) : async(Bool, Text) {
    return switch (current_book.get(_user)) {
      case (?book) { (true, book); };
      case (null) { (false, ""); };
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
    return switch (user_points.get(_user)) {
      case (?points) { points };
      case (null) { 0 };
    };
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

  private func _checkUserPoints(_user : Principal, _amount : Nat) : async() {
    switch (user_points.get(_user)) {
      case (?points) { 
        if (points < _amount) {
          throw Error.reject("Insufficient points.");
        }
      };
      case (null) { 
        throw Error.reject("Insufficient points.");
      }
    }
  };

  private func _checkTaskInput(_name : Text, _url : Text, _point : Nat) : async() {
    if (_name == "" or _url == "" or _point <= 0) {
      throw Error.reject("Invalid task input.");
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

  private func _checkBookInput(_title: Text, _synopsis: Text, _year: Nat, _genre: Text, _cover: Text, _file: Text) : async() {
    if (_title == "" or _synopsis == "" or _year == 0 or _genre == "" or _cover == "" or _file == ""){
      throw Error.reject("Invalid book input.");
    };
  };

  private func _readBook(_title : Text) : async() {
    let book_exist = Array.find<Book>(books, func(x : Book) { x.title== _title });
    if (book_exist == null) {
      throw Error.reject("Book not found.");
    };
    
    switch (book_readers.get(_title)) {
      case (?founded) {
        let updated_readers = founded + 1;
          book_readers.put(_title, updated_readers);
        };
      case (null) {
        book_readers.put(_title, 1);
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

  private func _addCurrentBook(_user : Principal, _title : Text) : async() {
    current_book.put(_user, _title);
  };

  private func _addCompletedTask(_user : Principal, _id : Nat) : async() {
    let completed = switch(completed_tasks.get(_user)) {
      case (?tasks) { tasks };
      case (null) { [] };
    };
    let updated = Array.append(completed, [_id]);
    completed_tasks.put(_user, updated); 
  };

  private func _transferPoint(_from : Principal, _to : Principal, _amount : Nat) : async() {
    await _burnPoint(_from, _amount);
    await _mintPoint(_to, _amount);
  };

  private func _mintPoint(_user : Principal, _gain : Nat) : async() {
    let current_points = await _getUserPoints(_user);
    let updated_points = current_points + _gain;
    user_points.put(_user, updated_points);
  };

  private func _burnPoint(_user : Principal, _amount : Nat) : async() {
    let current_points =  await _getUserPoints(_user);
    switch (current_points >= _amount) {
      case (true) { 
        let updated_points = (current_points - _amount) : Nat;
        user_points.put(_user, updated_points);
      };
      case (false) {
        throw Error.reject("Not enough point.")
       };
    };
  };

  private func _getUserPoints(_user : Principal) : async(Nat) {
    return switch (user_points.get(_user)) {
      case (?points) { points };
      case (null) { 0 };
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

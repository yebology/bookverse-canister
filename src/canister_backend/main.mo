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
  private var donation_total = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
  private var donation_amount = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

  public shared({ caller }) func readBook(_title : Text) : async() {
    await _checkExistingBookByTitle(_title);
    await _readBook(_title);
    await _addCurrentBook(caller, _title);
  };

  public shared({ caller }) func donateToAuthor(_author : Principal, _amount : Nat) : async() {
    await _checkUserPoints(caller, _amount);
    await _transferPoint(caller, _author, _amount);
    await _updateDonationRecord(caller, _amount);
  };

  public shared({ caller }) func doTask(_id : Nat) : async() {
    let gain = await _checkExistingTaskAndGetPoint(_id);
    let (available, tasks) = await _checkAvailableTask(caller, _id);
    if (available) {
      await _addCompletedTask(caller, tasks, _id);
      await _mintPoint(caller, gain);
    }
    else {
      throw Error.reject("Reentrant tasks are not allowed.")
    }
  };

  public shared({ caller }) func addToBookmark(_id : Nat) : async() {
    await _checkExistingBookById(_id);
    let (available, bookmarks) = await _checkAvailableBookmark(caller, _id);
    if (available) {
      await _addBookToUserBookmark(caller, bookmarks, _id);
    }
    else  {
      throw Error.reject("Reentrant bookmarks are not allowed.")
    }
  };

  public shared({ caller }) func removeFromBookmark(_id : Nat) : async() {
    await _checkExistingBookById(_id);
    let (available, bookmarks) = await _checkAvailableBookmark(caller, _id);
    if (not available) {
      await _removeBookFromUserBookmark(caller, _id);
    }
    else {
      throw Error.reject("Book not found in bookmarks.")
    }
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

  public query func getTasks() : async([Task]) {
    return tasks;
  };

  public query func getGenres() : async([Text]) {
    return genres;
  };

  public query func getBooks() : async([Book]) {
    return books;
  };

  public query func getDonationAmount(_user : Principal) : async(Nat) {
    return switch(donation_amount.get(_user)) {
      case (?amount) { amount; };
      case (null) { 0; };
    }
  };

  public query func getDonationTotal(_user : Principal) : async(Nat) {
    return switch(donation_total.get(_user)) {
      case (?total) { total; };
      case (null) { 0; };
    }
  };

  public query func getUploadedBooks(_user: Principal) : async [Book] {
    let userBooks = Array.filter<Book>(books, func (book: Book) : Bool {
        book.author == _user
    });

    return userBooks;
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

  public query func getBookmarks(_user : Principal) : async([Nat]) {
    return switch (user_bookmarks.get(_user)) {
      case (?bookmarks) { bookmarks };
      case (null) { []; };
    }
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

  private func _checkExistingTaskAndGetPoint(_id : Nat) : async(Nat) {
    return switch (Array.find<Task>(tasks, func(task : Task) {
      task.id == _id;
    })) {
      case (?founded) { founded.point; };
      case (null) { throw Error.reject("Task id not found."); };
    };
  };

  private func _checkExistingBookById(_id : Nat) : async() {
    return switch (Array.find<Book>(books, func (book : Book) {
      book.id == _id
    })) {
      case (null) { throw Error.reject("Book id not found.") };
      case (?_) { };
    }
  };

  private func _checkExistingBookByTitle(_title : Text) : async() {
    return switch (Array.find<Book>(books, func (book : Book) {
      book.title == _title
    })) {
      case (null) { throw Error.reject("Book title not found.") };
      case (?_) { };
    }
  };

  private func _checkAvailableTask(_user : Principal, _id : Nat) : async(Bool, [Nat]) {
    return switch (completed_tasks.get(_user)) {
      case (?completed) {
        let find = Array.find<Nat>(completed, func(id : Nat) : Bool {
          id == _id
        });
        if (find == null) {
          (true, completed)
        }
        else {
          (false, [])
        }
      };
      case (null) { (true, []) }
    }
  };

  private func _checkAvailableBookmark(_user : Principal, _id : Nat) : async(Bool, [Nat]) {
    return switch (user_bookmarks.get(_user)) {
      case (?books) { 
        let find = Array.find<Nat>(books, func(id : Nat) : Bool {
          id == _id
        });
        if (find == null) {
          (true, books)
        }
        else {
          (false, [])
        }
      };
      case (null) { (true, []) };
    };
  };

  private func _checkBookInput(_title: Text, _synopsis: Text, _year: Nat, _genre: Text, _cover: Text, _file: Text) : async() {
    if (_title == "" or _synopsis == "" or _year == 0 or _genre == "" or _cover == "" or _file == ""){
      throw Error.reject("Invalid book input.");
    };
  };

  private func _readBook(_title : Text) : async() {
    let book_exist = Array.find<Book>(books, func(x : Book) { x.title == _title });
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

  private func _updateDonationRecord(_user : Principal, _amount : Nat) : async() {
    await _updateDonationTotal(_user);
    await _updateDonationAmount(_user, _amount);
  };

  private func _updateDonationTotal(_user : Principal) : async() {
    let current_total = switch (donation_total.get(_user)) {
      case (?points) { points };
      case (null) { 0 };
    };
    let updated_total = current_total + 1;
    donation_total.put(_user, updated_total);
  };

  private func _updateDonationAmount(_user : Principal, _amount : Nat) : async() {
    let current_amount = switch (donation_amount.get(_user)) {
      case (?points) { points };
      case (null) { 0 };
    };
    let updated_amount = current_amount + _amount;
    donation_amount.put(_user, updated_amount);
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

  private func _addCompletedTask(_user : Principal, _tasks : [Nat], _id : Nat) : async() {
    let updated = Array.append(_tasks, [_id]);
    completed_tasks.put(_user, updated); 
  };
  
  private func _addBookToUserBookmark(_user : Principal, _bookmarks : [Nat], _id : Nat) : async() {
    let updated = Array.append(_bookmarks, [_id]);
    user_bookmarks.put(_user, updated);
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

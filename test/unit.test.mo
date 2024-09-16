import {test} "mo:test/async";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Actor "../src/canister_backend/main";

let user = Principal.fromText("ihmrf-7yaaa");
let author = Principal.fromText("wo5qg-ysjiq-5da");

await test("successfully add task and do task", func() : async() {
    let instance = await Actor.Main();
    await instance.addTask("Lorem ipsum", "https://lorem", 20, "Joren");
    await instance.addTask("Dolor sit amet", "https://lorem", 10, "Joren");
    await instance.doTask(1);
    let tasks = await instance.getTasks();
    let completed = await instance.getCompletedTasks(author);
    let completed_index = completed[0];
    let userPoint = await instance.getPoints(author);
    assert(2 == tasks.size());
    assert(1 == completed.size());
    assert(1 == completed_index);
    assert(10 == userPoint);
});

await test("successfully donate", func() : async() {
    let instance = await Actor.Main();
    await instance.dummyMint(100);
    await instance.donateToAuthor(user, 50);
    let receiverPoint = await instance.getPoints(user);
    let senderPoint = await instance.getPoints(author);
    assert(50 == receiverPoint);
    assert(50 == senderPoint);
});

await test("successfully get current book", func() : async() {
    let instance = await Actor.Main();
    await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
    await instance.readBook("Test");
    let (is_there, current_book) = await instance.getCurrentBook(author);
    let book_readers = await instance.getBookReaders("Test");
    if (is_there) {
        assert("Test" == current_book);
        assert(1 == book_readers);
    }
    else {
        throw Error.reject("Book not found.");
    }
});

await test("succesfully throw insufficient points", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.dummyMint(50);
        await instance.donateToAuthor(user, 100);
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Insufficient points.");
    }
});

await test("successfully throw non-authorized owner", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addTask("Lorem ipsum", "https://lorem", 20, "Joren");
        await instance.addTask("Dolor sit amet", "https://lorem", 10, "Hayya");
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Non-authorized owner.");
    }
});

await test("successfully throw invalid task input", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addTask("", "https://lorem", 0, "");
    }
    catch(err) {
        let message = Error.message(err);
        assert(message == "Invalid task input.");
    }
});

await test("successfully throw task id not found", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.doTask(0);
    }
    catch(err) {
        let message = Error.message(err);
        assert(message == "Task id not found.");
    }
});

await test("successfully add a book and get books", func() : async() {
        let instance = await Actor.Main();
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        let uploaded = await instance.getUploadedBooks(author);
        assert(uploaded.size() == 1);
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        let allbooks = await instance.getBooks();
        assert(allbooks.size() == 2);
}); 

await test("successfully added a book to bookmarks", func() : async() {
        let instance = await Actor.Main();
        await instance.addToBookmark(1);
        let bookmarked = await instance.getBookmarks(author);
        assert(bookmarked.size() == 1);
});

await test("removed book from bookmarks", func() : async() {
        let instance = await Actor.Main();
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        await instance.addToBookmark(1);
        let bookmarked = await instance.getBookmarks(author);
        await instance.removeFromBookmark(1);
        let removed = await instance.getBookmarks(author);
        assert(bookmarked.size() == 1);
        assert(removed.size() == 0);
}); 

await test("successfully throw invalid add a book", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addBook("", "", 2000, "Genre", "Cover", "File");
    }
    catch(err) {
        let message = Error.message(err);
        assert(message == "Invalid book input.");
    }
}); 


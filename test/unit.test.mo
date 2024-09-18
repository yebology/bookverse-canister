import {test} "mo:test/async";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Actor "../src/canister_backend/main";

let alice = Principal.fromText("ihmrf-7yaaa");
let bob = Principal.fromText("wo5qg-ysjiq-5da");

await test("successfully add task and do task", func() : async() {
    let instance = await Actor.Main();
    await instance.addTask("Lorem ipsum", "https://lorem", 20, "Joren");
    await instance.addTask("Dolor sit amet", "https://lorem", 10, "Joren");
    await instance.doTask(1);
    let tasks = await instance.getTasks();
    let completed = await instance.getCompletedTasks(bob);
    let completed_index = completed[0];
    let userPoint = await instance.getPoints(bob);
    assert(2 == tasks.size());
    assert(1 == completed.size());
    assert(1 == completed_index);
    assert(10 == userPoint);
});

await test("successfully donate", func() : async() {
    let instance = await Actor.Main();
    await instance.dummyMint(100);
    await instance.donateToAuthor(alice, 50);
    let receiverPoint = await instance.getPoints(alice);
    let senderPoint = await instance.getPoints(bob);
    let senderDonationTotal = await instance.getDonationTotal(bob);
    let senderDonationAmount = await instance.getDonationAmount(bob);
    assert(50 == receiverPoint);
    assert(50 == senderPoint);
    assert(1 == senderDonationTotal);
    assert(50 == senderDonationAmount);
});

await test("successfully get current book", func() : async() {
    let instance = await Actor.Main();
    await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
    await instance.readBook("Test");
    let (is_there, current_book) = await instance.getCurrentBook(bob);
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
        await instance.donateToAuthor(alice, 100);
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

await test("successfully throw reentrant task are not allowed", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addTask("Lorem ipsum", "https://lorem", 20, "Joren");
        await instance.doTask(0);
        await instance.doTask(0);
    }
    catch(err) {
        let message = Error.message(err);
        assert(message == "Reentrant tasks are not allowed.");
    }
});

await test("successfully throw book id not found", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addToBookmark(0);
        assert(true == true);
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Book id not found.");
    }
});

await test("successfully throw book title not found", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.readBook("A");
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Book title not found.");
    }
});

await test("successfully throw reentrant bookmarks are not allowed", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        await instance.addToBookmark(0);
        await instance.addToBookmark(0);
    }
    catch(err) {
        let message = Error.message(err);
        assert(message == "Reentrant bookmarks are not allowed.");
    }
});

await test("successfully throw book not found in bookmarks", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        await instance.removeFromBookmark(0);
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Book not found in bookmarks.")
    }
});

await test("successfully add a book and get books", func() : async() {
        let instance = await Actor.Main();
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        let uploaded = await instance.getUploadedBooks(bob);
        assert(uploaded.size() == 1);
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        let allbooks = await instance.getBooks();
        assert(allbooks.size() == 2);
}); 

await test("successfully added a book to bookmarks", func() : async() {
        let instance = await Actor.Main();
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        await instance.addToBookmark(0);
        let bookmarked = await instance.getBookmarks(bob);
        assert(bookmarked.size() == 1);
});

await test("removed book from bookmarks", func() : async() {
        let instance = await Actor.Main();
        await instance.addBook("Test", "Text", 2000, "Text", "Text", "Text");
        await instance.addToBookmark(0);
        let bookmarked = await instance.getBookmarks(bob);
        await instance.removeFromBookmark(0);
        let removed = await instance.getBookmarks(bob);
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


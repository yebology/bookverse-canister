import {test} "mo:test/async";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Actor "../src/canister_backend/main";

let user = Principal.fromText("ihmrf-7yaaa");
let author = Principal.fromText("wo5qg-ysjiq-5da");

await test("successfully author go premium and user can subscribe author", func() : async() {
    let instance = await Actor.Main();
    await instance.dummyMint(user, 100);
    await instance.goPremium(10);
    await instance.subscribeAuthor(user, author);
    let authorBalance = await instance.getUserPoints(author);
    let userBalance = await instance.getUserPoints(user);
    let subscription = await instance.getUserSubscriptions(user);
    let subscriber = await instance.getAuthorSubscribers(author);
    assert(10 == authorBalance);
    assert(90 == userBalance);
    assert(1 == subscription);
    assert(1 == subscriber);
});

await test("successfully add task and do task", func() : async() {
    let instance = await Actor.Main();
    await instance.addTask("Lorem ipsum", "https://lorem", 20);
    await instance.addTask("Dolor sit amet", "https://lorem", 10);
    await instance.doTask(1);
    let tasks = await instance.getTasks();
    let completed = await instance.getCompletedTasks(author);
    let completed_index = completed[0];
    let userPoint = await instance.getUserPoints(author);
    assert(2 == tasks.size());
    assert(1 == completed.size());
    assert(1 == completed_index);
    assert(10 == userPoint);
});

await test("successfully throw invalid task input", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.addTask("", "https://lorem", 0);
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

await test("successfully throw invalid author", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.dummyMint(user, 100);
        await instance.goPremium(10);
        await instance.subscribeAuthor(user, Principal.fromText("5aqxw-hbbbb-bba"));
    }
    catch(err) {
        let message = Error.message(err);
        assert(message == "Invalid author.");
    }
});

await test("successfully throw not enough points", func() : async() {
    try {
        let instance = await Actor.Main();
        await instance.dummyMint(user, 5);
        await instance.goPremium(10);
        await instance.subscribeAuthor(user, author);
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Not enough points.");
    }
});

await test("successfully throw invalid subscription price", func() : async() {
     try {
        let instance =  await Actor.Main();
        await instance.goPremium(0);
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Invalid subscription price.");
    }
});

await test("successfully throw already premium", func() : async() {
    try {
        let instance =  await Actor.Main();
        await instance.goPremium(10);
        await instance.goPremium(10);
    }
    catch (err) {
        let message = Error.message(err);
        assert(message == "Already Premium.");
    }
});
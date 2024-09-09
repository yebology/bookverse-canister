import {test} "mo:test/async";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Actor "../src/canister_backend/main";

let user = Principal.fromText("ihmrf-7yaaa");
let author = Principal.fromText("wo5qg-ysjiq-5da");

await test("successfully go premium", func() : async() {
    let instance =  await Actor.Main();
    await instance.goPremium(10);
    let result = await instance.getSubscriptionPrice(author);
    assert(10 == result);
});

await test("successfully subscribe author", func() : async() {
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
    assert(1 == subscription.size());
    assert(1 == subscriber.size());
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
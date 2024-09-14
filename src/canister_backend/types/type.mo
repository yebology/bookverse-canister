import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

module {
    public type Task = {
        id: Nat;
        name: Text;
        url: Text;
        point: Nat;
    };

    public type Book = {
        id: Nat;
        title: Text;
        synopsis: Text;
        year: Nat;
        genre: Text;
        author: Principal;
        cover: Text;
        readers: Nat;
        file: Text;
    };
};

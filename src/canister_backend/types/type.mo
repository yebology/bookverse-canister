import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {
    public type Task = {
        id: Nat;
        name: Text;
        url: Text;
        point: Nat;
    };
};
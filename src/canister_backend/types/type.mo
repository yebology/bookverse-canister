import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {
    public type Gift = {
        id: Nat;
        image: Text;
        name: Text;
        price: Nat;
    };
};
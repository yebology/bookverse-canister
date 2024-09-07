import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";

actor class Point(_name : Text, _symbol : Text) {

    private let point_name : Text = _name;
    private let point_symbol : Text = _symbol;
    private var total_supply : Nat = 0;
    private var user_points = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
    
    public func mint(_wallet : Principal, _amount : Nat) : async() {
        await _addUserPoints(_wallet, _amount);
        await _addTotalSupply(_amount);
    };

    public func burn(_wallet : Principal, _amount : Nat) : async() {
        await _deductUserPoints(_wallet, _amount);
        await _deductTotalSupply(_wallet, _amount);
    };

    public query func getUserPoints(_wallet : Principal) : async(Nat) {
        let current_points = user_points.get(_wallet);
        return switch (current_points) {
            case (?current_points) current_points;
            case null 0;
        };
    };

    public query func getTotalSupply() : async(Nat) {
        return total_supply;
    };

    public query func getPointName() : async(Text) {
        return point_name;
    };

    public query func getPointSymbol() : async(Text) {
        return point_symbol;
    };

    private func _addUserPoints(_wallet : Principal, _amount : Nat) : async() {
        let current_points = await _getUserPoints(_wallet);
        let updated_points = current_points + _amount;
        user_points.put(_wallet, updated_points);
    };

    private func _addTotalSupply(_amount : Nat) : async() {
        total_supply += _amount;
    };

    private func _deductUserPoints(_wallet : Principal, _amount : Nat) : async () {
        let current_points = await _getUserPoints(_wallet);
        assert(current_points >= _amount);
        let updated_points = current_points - _amount;
        user_points.put(_wallet, updated_points);
    };

    private func _deductTotalSupply(_wallet : Principal, _amount : Nat) : async () {
        total_supply -= _amount;
    };
 
    private func _getUserPoints(_wallet : Principal) : async(Nat) {
        let current_points = user_points.get(_wallet);
        return switch (current_points) {
            case (?current_points) current_points;
            case null 0;
        };
    };
}
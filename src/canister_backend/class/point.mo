import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";

class Point() {

    private var total_supply : Nat = 0;
    private var user_points = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
    
    public func mint(_user : Principal, _amount : Nat) : () {
        _addUserPoints(_user, _amount);
        _addTotalSupply(_amount);
    };

    public func burn(_user : Principal, _amount : Nat) : () {
        _deductUserPoints(_user, _amount);
        _deductTotalSupply(_user, _amount);
    };

    public func transfer(_from : Principal, _to : Principal, _amount : Nat) : () {
        _deductUserPoints(_from, _amount);
        _addUserPoints(_to, _amount);
    };

    public func getUserPoints(_user : Principal) : (Nat) {
        return _getUserPoints(_user);
    };

    public func getTotalSupply() : (Nat) {
        return total_supply;
    };

    private func _addUserPoints(_user : Principal, _amount : Nat) : () {
        let current_points = _getUserPoints(_user);
        let updated_points = current_points + _amount;
        user_points.put(_user, updated_points);
    };

    private func _addTotalSupply(_amount : Nat) : () {
        total_supply += _amount;
    };

    private func _deductUserPoints(_user : Principal, _amount : Nat) : () {
        let current_points =  _getUserPoints(_user);
        assert(current_points >= _amount);
        let updated_points = current_points - _amount;
        user_points.put(_user, updated_points);
    };

    private func _deductTotalSupply(_user : Principal, _amount : Nat) : () {
        total_supply -= _amount;
    };
 
    private func _getUserPoints(_user : Principal) : (Nat) {
        return switch (user_points.get(_user)) {
            case (?points) { points };
            case (null) { 0 };
        };
    };
}
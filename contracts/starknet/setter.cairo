%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
@storage_var
func x() -> (res: felt) {
}

@storage_var
func L1_ADDRESS() -> (res: felt) {
}

@external
func set_l1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(l1_address: felt){
    L1_ADDRESS.write(l1_address);
    return ();
}

@l1_handler
func set_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(from_address: felt, _x: felt){
    alloc_locals;
    let (l1) = L1_ADDRESS.read();
    assert from_address = l1;
    x.write(_x);
    return();
}

@external
func read_x{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    alloc_locals;
    let res = x.read();
    return (res);
}
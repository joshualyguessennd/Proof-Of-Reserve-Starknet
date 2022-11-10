%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp, get_block_number
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le

@contract_interface
namespace IERC20 {
    func totalSupply()->(supply: felt) {
    }
}

struct Round {
    value: Uint256,
    block_number: Uint256,
}

@storage_var
func admin() -> (res: felt) {
}

@storage_var
func latest_reserves(asset: felt) -> (data: Round ) {
}

@storage_var
func latest_supply(asset: felt) -> (data: Round ) {
}

@storage_var
func token_pairs(l1_asset: felt) -> (l2_asset: felt ) {
}

@storage_var
func l1_aggregator() -> (res: felt) {
}


func only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (_admin) = admin.read();
    with_attr error_message("Admin: Called by a non-admin contract") {
        assert caller = _admin;
    }
    return ();
}

func only_l1_aggregator{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
} (sender: felt) {
    let (aggregator) = l1_aggregator.read();
    with_attr error_message("Aggregator: Called by a non-aggregator contract") {
        assert sender = aggregator;
    }
    return ();
}


@view
func get_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
)->(admin: felt) {
    let (_admin) = admin.read();
    return(admin=_admin);
}

// gets the latest reserves round published from l1
@view
func get_latest_reserves{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
}(
    asset: felt
) -> (data: Round){
   
    return latest_reserves.read(asset);
}

// gets the latest asset supply on l2
@view
func get_latest_supply{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
}(
    asset: felt
) -> (data: Round){

    return latest_supply.read(asset);

}


@constructor
func constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(_admin: felt) {
    admin.write(_admin);
    return ();
}



@external
func set_l1_aggregator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _l1_aggregator: felt
) {
    only_admin();
    l1_aggregator.write(_l1_aggregator);
    return ();
}

@external
func set_token_pairs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_asset: felt, l2_asset: felt
) {
    only_admin();
    token_pairs.write(l1_asset, l2_asset);
    return ();
}


@l1_handler
func post_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    from_address: felt, 
    asset:felt,
    reserves_low: felt,
    reserves_high: felt,
    block_number_low: felt,
    block_number_high: felt,
) {

    alloc_locals;
    only_l1_aggregator(from_address);
    let reserves = Uint256(reserves_low, reserves_high);
    with_attr error_message("High or low overflows 128 bit bound {reserves}") {
        uint256_check(reserves);
    }
    let block_number = Uint256(block_number_low, block_number_high);
    with_attr error_message("High or low overflows 128 bit bound {block_number}") {
        uint256_check(block_number);
    }
    let (l2_asset)=token_pairs.read(asset);//gets the l1 assets counterpart
    let round = Round(reserves, block_number);
    latest_reserves.write(l2_asset,round);
    return (); 
}

@external
func publish_l2_supply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(  
    asset:felt
){
    alloc_locals;
    let block_number : Uint256 = get_block_number();
    let supply: Uint256 = IERC20.totalSupply(contract_address=asset);
    let round = Round(supply, block_number);
    latest_supply.write(asset, round);
    return ();
}





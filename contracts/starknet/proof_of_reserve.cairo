%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp, get_block_number
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le
from openzeppelin.token.erc20.IERC20 import IERC20

struct Round {
    reserves: Uint256,
}

@storage_var
func contract_admin() -> (res: felt) {
}

@storage_var
func reserves_rounds(asset: felt, id: Uint256) -> (data: Round ) {
}

@storage_var
func supplies_rounds(asset: felt, id: felt) -> (data: Round ) {
}


// @storage_var
// func latest_round() -> (res: Uint256) {

// }


@storage_var
func l1_aggregator() -> (res: felt) {
}


func only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (admin) = contract_admin.read();
    with_attr error_message("Admin: Called by a non-admin contract") {
        assert caller = admin;
    }
    return ();
}

func only_l1_aggregator{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
} (sender: felt) {
    let (aggregator) = l1_aggregator.read();
    with_attr error_message("Aggregator: Called by a aggregator contract") {
        assert sender = aggregator;
    }
    return ();
}

@constructor
func constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(admin: felt) {
    contract_admin.write(admin);
    return ();
}


@view
func get_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
)->(admin: felt) {
    let (admin) = contract_admin.read();
    return(admin=admin);
}



@external
func set_l1_aggregator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _l1_aggregator: felt
) {
    only_admin();
    l1_aggregator.write(_l1_aggregator);
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
    let round = Round(reserves);
    reserves_rounds.write(asset, block_number, round);
    // latest_round.write(block_number);
    return (); 
}

@external
func publish_l2_supply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(  
    asset:felt
){
    alloc_locals;
    let (block_number) = get_block_number();
    // get the total supply presents on l2
    //TODO totalsupply should be <= to the lastest round from l1 data post
    let supply: Uint256 = IERC20.totalSupply(contract_address=asset);
    let round = Round(supply);
    // let _last_round = latest_round.read();
    // let _round: Round = reserves_rounds.read(asset, _last_round);
    // let _reserves: Uint256 = _round.reserves;
    // with_attr error_message("Invalid supply detected") {
    //     uint256_le(supply, _reserves);
    // }
    supplies_rounds.write(asset, block_number, round);
    return ();
}

// gets the latest reserves round published from l1
@view
func get_latest_reserves{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
}(
    asset: felt,
    block_number: Uint256
) -> (data: Round){
   
    return reserves_rounds.read(asset, block_number);
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

    return supplies_rounds.read(asset, 1);

}




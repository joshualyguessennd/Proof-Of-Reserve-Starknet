%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin, SignatureBuiltin
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.hash import hash2
from starknet.signature_verification import verify_signature, word_reverse_endian_64
from starkware.cairo.common.math_cmp import is_le_felt

struct Round {
    publisher: felt,
    reserves: felt,
    timestamp: felt,
}

@storage_var
func contract_admin() -> (res: felt) {
}

@storage_var
func reserves_rounds(asset: felt, id: felt) -> (data: Round ) {
}

@storage_var
func supplies_rounds(asset: felt, id: felt) -> (data: Round ) {
}

@storage_var
func authorized_publisher(public_key: felt) -> (state: felt) {
}


func only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (admin) = contract_admin.read();
    with_attr error_message("Admin: Called by a non-admin contract") {
        assert caller = admin;
    }
    return ();
}

@constructor
func constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(admin: felt, publisher: felt) {
    contract_admin.write(admin);
    authorized_publisher.write(publisher, TRUE);
    return ();
}

@view
func get_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
)->(admin: felt) {
    let (admin) = contract_admin.read();
    return(admin=admin);
}


@view
func is_publisher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt){
    let (res) = authorized_publisher.read(address);
    return(res=res);
}

@external
func add_publisher{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(new_publisher: felt) {
    only_admin();
    authorized_publisher.write(new_publisher, TRUE);
    return ();
}

///l1 message, to do generate the root and store directly from ethereum side
@l1_handler
func post_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    from_address: felt, 
    asset:felt,
    reserves:felt,
    timestamp: felt,
    r_low: felt,
    r_high: felt,
    s_low: felt,
    s_high: felt,
    v: felt,
    public_key: felt
) {

   //TODO: accepts messages comming from l1 aggregator only!!

    alloc_locals;
    let proposed_public_key = public_key;
    let (state) = authorized_publisher.read(public_key=proposed_public_key);
    // // verify if the post has the right to post data
    with_attr error_message("Address has no right to sign the message") {
        assert state = TRUE;
    }
    // // verify the signature of the sources
    with_attr error_message("Signature verification failed") {
        verify_signature(
           asset,
            reserves,
            r_low,
            r_high,
            s_low,
            s_high,
            v,
            public_key,
        );
    }
    let round = Round(public_key ,reserves, timestamp);
 
    reserves_rounds.write(asset, 1, round);
    return (); 
}

@external
func publish_l2_supply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(  
    asset:felt,
    supply: felt,
    timestamp: felt,
    r_low: felt,
    r_high: felt,
    s_low: felt,
    s_high: felt,
    v: felt,
    public_key: felt
){
    alloc_locals;
    let proposed_public_key = public_key;
    let (state) = authorized_publisher.read(public_key=proposed_public_key);
    // verify if the post has the right to post data
    with_attr error_message("Address has no right to sign the message") {
        assert state = TRUE;
    }
    // verify the signature of the sources
    with_attr error_message("Signature verification failed") {
        verify_signature(
            asset,
            supply,
            r_low,
            r_high,
            s_low,
            s_high,
            v,
            public_key,
        );
    }
   
   let round = Round(public_key ,supply, timestamp);
    supplies_rounds.write(asset, 1, round);
    
    return ();
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
   
    return reserves_rounds.read(asset, 1);
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




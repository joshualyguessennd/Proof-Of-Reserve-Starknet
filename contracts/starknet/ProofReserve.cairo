%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin, SignatureBuiltin
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.hash import hash2
from starknet.Library import verify_oracle_message, word_reverse_endian_64, OracleEntry, Entry
from starkware.cairo.common.math_cmp import is_le_felt

@storage_var
func contract_admin() -> (res: felt) {
}

@storage_var
func roots(public_key: felt, asset: felt, balance: felt, timestamp: felt) -> (res: felt) {
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
}(from_address: felt, asset_sym: felt,
    asset_name: felt,
    address_owner: felt,
    balance: felt,
    timestamp: felt,
    r_low: felt,
    r_high: felt,
    s_low: felt,
    s_high: felt,
    v: felt,
    public_key: felt) {
    alloc_locals;
    let proposed_public_key = public_key;
    let (state) = authorized_publisher.read(public_key=proposed_public_key);
    // verify if the post has the right to post data
    // with_attr error_message("Address has no right to sign the message") {
    //     assert state = TRUE;
    // }
    // verify the signature of the sources
    // with_attr error_message("Signature verification failed") {
    //     verify_oracle_message(
    //        asset_sym,
    //         asset_name,
    //         address_owner,
    //         balance,
    //         r_low,
    //         r_high,
    //         s_low,
    //         s_high,
    //         v,
    //         public_key,
    //     );
    // }
    let (root_) = calc_hash(0, 4, new(address_owner, asset_name, balance, timestamp));
    roots.write(address_owner, asset_name, balance, timestamp, root_);
    return ();
}

@external
func post_data_l2{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(  asset_sym: felt,
    asset_name: felt,
    address_owner: felt,
    balance: felt,
    timestamp: felt,
    r_low: felt,
    r_high: felt,
    s_low: felt,
    s_high: felt,
    v: felt,
    public_key: felt){
    alloc_locals;
    let proposed_public_key = public_key;
    let (state) = authorized_publisher.read(public_key=proposed_public_key);
    // verify if the post has the right to post data
    with_attr error_message("Address has no right to sign the message") {
        assert state = TRUE;
    }
    // verify the signature of the sources
    with_attr error_message("Signature verification failed") {
        verify_oracle_message(
            asset_sym,
            asset_name,
            address_owner,
            balance,
            r_low,
            r_high,
            s_low,
            s_high,
            v,
            public_key,
        );
    }
    let (root_) = calc_hash(0, 4, new(address_owner, asset_name, balance, timestamp));
    roots.write(address_owner, asset_name, balance, timestamp, root_);
    
    return ();
}

// user call this function to verify if a address had this balance
@view
func verify_balance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr,
        ecdsa_ptr : SignatureBuiltin*
}(
    leaf: felt, merkle_root: felt, proof_len: felt, proof: felt*
) -> (res:felt){
    alloc_locals;
    // calculate root
    let (root) = calc_hash(leaf, proof_len, proof);
    // check if the root is stored
    if(root==merkle_root){
        return (res=1);
    }
    return (res=0);
}

// generate hash
func calc_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    curr: felt, 
    proof_len: felt,
    proof: felt*
) -> (res: felt){
    alloc_locals;
    if (proof_len == 0) {
        return (res=curr);
    }

    local node;
    local proof_element = [proof];
    let le = is_le_felt(curr, proof_element);
    if (le==1){
        let (n) = hash2{hash_ptr=pedersen_ptr}(curr, proof_element);
        node = n;
    } else {
        let (n) = hash2{hash_ptr=pedersen_ptr}(proof_element, curr);
        node = n;
    }
    let (res) = calc_hash(node, proof_len-1, proof+1); 
    return (res=res);
}

// help function to get the exact hash stored by a publisher
@view
func get_root{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(public_key: felt, asset: felt, balance: felt, timestamp: felt) -> (res: felt) {
    alloc_locals;
    let (res) = roots.read(public_key, asset, balance, timestamp);
    return (res=res);
}
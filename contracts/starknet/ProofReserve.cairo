%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin, SignatureBuiltin
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.hash import hash2
from starknet.Library import verify_oracle_message, word_reverse_endian_64, OracleEntry, Entry
from starkware.cairo.common.math import unsigned_div_rem

@storage_var
func contract_admin() -> (res: felt) {
}

struct DataInfo {
    public_key: felt,
    asset: felt,
    balance: felt,
    // timestamp: felt,
}

// @storage_var
// func root(data: DataInfo) -> (res: felt) {
// }
@storage_var
func root(public_key: felt, asset: felt, balance: felt) -> (res: felt) {
}


// data type to store account and balance
// we'll hash the balance store and create a root





@storage_var
func authorized_publisher(public_key: felt) -> (state: felt) {
}
@contract_interface
namespace IOracleController {
    func publish_entry(entry: Entry) {
    }
    func get_decimals(key: felt) -> (decimals: felt) {
    }
    func get_admin_address() -> (admin_address: felt) {
    }
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
func isPublisher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt){
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

@l1_handler
func post_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(from_address: felt, asset_sym_little: felt,
    asset_name_little: felt,
    address_owner_little: felt,
    balance_little: felt,
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
    with_attr error_message("Address has no right to sign the message") {
        assert state = TRUE;
    }
    // verify the signature of the sources
    with_attr error_message("Signature verification failed") {
        verify_oracle_message(
           asset_sym_little,
            asset_name_little,
            address_owner_little,
            balance_little,
            r_low,
            r_high,
            s_low,
            s_high,
            v,
            public_key,
        );
    }
    //todo update the root, (format, address/balance)
    
    // update_root_hash()
    return ();
}

@external
func post_data_l2{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(  asset_sym_little: felt,
    asset_name_little: felt,
    address_owner_little: felt,
    balance_little: felt,
    r_low: felt,
    r_high: felt,
    s_low: felt,
    s_high: felt,
    v: felt,
    public_key: felt) -> (timestamp: felt){
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
            asset_sym_little,
            asset_name_little,
            address_owner_little,
            balance_little,
            r_low,
            r_high,
            s_low,
            s_high,
            v,
            public_key,
        );
    }
    let (timestamp) = get_block_timestamp();
    // add timestamp to the root
    let (root_) = create_root(address_owner_little, asset_name_little, balance_little);
    // store root
    // to do use timestamp as entry
    root.write(address_owner_little, asset_name_little, balance_little, root_);
    
    return (timestamp=timestamp);
}

// user call this function to verify if a address had this balance
@view
func verifyBalance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr,
        ecdsa_ptr : SignatureBuiltin*
}(
    address: felt, asset: felt, balance: felt
) -> (res:felt){
    alloc_locals;
    // generate a hash
    let (generate_root) = create_root(address, asset, balance);
    // get root store in the contract
    let (res) = root.read(address, asset, balance);

    if (generate_root == res) {
        return (res=1);
    }
    return (res=0);
}

//hash data and update a root
func create_root{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(public_key: felt, asset: felt, balance: felt) -> (res: felt){
    let res = public_key;
    let (res) = hash2{hash_ptr=pedersen_ptr}(res, asset);
    let (res) = hash2{hash_ptr=pedersen_ptr}(res, balance);
    return (res,);
}

@view
func get_root{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(public_key: felt, asset: felt, balance: felt) -> (res: felt) {
    alloc_locals;
    let (res) = root.read(public_key, asset, balance);
    return (res=res);
}

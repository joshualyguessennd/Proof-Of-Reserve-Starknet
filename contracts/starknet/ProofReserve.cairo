%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.starknet.library import verify_oracle_message, word_reverse_endian_64, OracleEntry, Entry


@storage_var
func contract_admin() -> (res: felt):
end 

@storage_var
func authorized_publisher(public_key: felt) -> (state: felt):
end

@contract_interface
namespace IOracleController:
    func publish_entry(entry: Entry):
    end
    func get_decimals(key: felt) -> (decimals: felt):
    end
    func get_admin_address() -> (admin_address: felt):
    end
end



func only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}():
    let (caller) = get_caller_address()
    let (admin) = contract_admin.read()
    with_attr error_message("Admin: Called by a non-admin contract"):
        assert caller = admin
    end
    return ()
end

@constructor
func constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}():
    contract_admin.write(1443903124408663179676923566941061880487545664188)
    authorized_publisher.write(761466874539515783303110363281120649054760260892, TRUE)
    return ()
end

@external
func add_publisher{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(new_publisher: felt):
    only_admin()
    authorized_publisher.write(new_publisher, TRUE)
    return ()
end

@l1_handler
func set_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(from_address: felt, entry: OracleEntry):
    alloc_locals
    let proposed_public_key = entry.public_key
    let (state) = authorized_publisher.read(public_key=proposed_public_key)
    with_attr error_message("Address has no right to sign the message"):
        assert state = TRUE
    end

    with_attr error_message("Signature verification failed"):
        verify_oracle_message(
            entry.asset_sym_little,
            entry.asset_name_little,
            entry.address_owner_little,
            entry.balance_little,
            entry.r_low,
            entry.r_high,
            entry.s_low,
            entry.s_high,
            entry.v,
            entry.public_key,
        )
    end
    return ()
end

@external
func set_data_l2{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(entry: OracleEntry):
    alloc_locals
    let proposed_public_key = entry.public_key
    let (state) = authorized_publisher.read(public_key=proposed_public_key)
    with_attr error_message("Address has no right to sign the message"):
        assert state = TRUE
    end

    with_attr error_message("Signature verification failed"):
        verify_oracle_message(
            entry.asset_sym_little,
            entry.asset_name_little,
            entry.address_owner_little,
            entry.balance_little,
            entry.r_low,
            entry.r_high,
            entry.s_low,
            entry.s_high,
            entry.v,
            entry.public_key,
        )
    end
    return ()
end

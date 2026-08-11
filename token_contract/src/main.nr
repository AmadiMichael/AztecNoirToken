use aztec::macros::aztec;

#[aztec]
pub contract Token {
    // Imports.
    use aztec::{
        macros::{
            events::event,
            functions::{authorize_once, external, initializer, internal, only_self, view},
            storage::storage,
        },
        messages::delivery::MessageDelivery,
        oracle::avm::address,
        protocol::address::AztecAddress,
        state_vars::{Map, Owned, PublicImmutable, PublicMutable},
    };
    use balance_set::BalanceSet;
    use compressed_string::FieldCompressedString;

    // Events.
    #[event]
    struct Transfer {
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
    }

    // State variables.
    #[storage]
    struct Storage<Context> {
        name: PublicImmutable<FieldCompressedString, Context>,
        symbol: PublicImmutable<FieldCompressedString, Context>,
        decimals: PublicImmutable<u8, Context>,
        owner: PublicImmutable<AztecAddress, Context>,
        total_supply: PublicMutable<u128, Context>,
        public_balances: Map<AztecAddress, PublicMutable<u128, Context>, Context>,
        private_balances: Owned<BalanceSet<Context>, Context>,
    }

    // Global values to use to prevent infinite circuit.
    global MAX_TF_NOTES: u32 = 2;
    global MAX_RECURSE_TF_NOTES: u32 = 8;

    /// @notice Initialize the token with the deployer being the minter.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param decimals The decimals of the token.
    #[initializer]
    #[external("public")]
    fn constructor(name: FieldCompressedString, symbol: FieldCompressedString, decimals: u8) {
        self.storage.name.initialize(name);
        self.storage.symbol.initialize(symbol);
        self.storage.decimals.initialize(decimals);
        self.storage.owner.initialize(self.msg_sender());
    }

    /// @notice Mint a public balance.
    /// @param to The address to mint the balance to.
    /// @param amount The amount to mint.
    #[external("public")]
    fn mint_public(to: AztecAddress, amount: u128) {
        // Revert if not owner.
        assert_eq(self.msg_sender(), self.storage.owner.read(), "Only owner");

        // Increase total supply.
        self.internal._increase_total_supply(amount);

        // Increase to's balance.
        self.internal._increase_public_balance(to, amount);

        // Emit an event.
        self.emit(Transfer { from: AztecAddress::zero(), to, amount });
    }

    /// @notice Mint a private balance.
    /// @param to The address to mint the balance to.
    /// @param amount The amount to mint.
    #[external("private")]
    fn mint_private(to: AztecAddress, amount: u128) {
        // Revert if not owner.
        assert_eq(self.msg_sender(), self.storage.owner.read(), "Only owner");

        // Increment to's balance.
        self.internal._increase_private_balance(to, amount);

        // Increment the total supply.
        self.enqueue_self.increase_total_supply(amount);
    }

    /// @notice Transfer a public balance from one address to another.
    /// @param from The address to transfer the balance from.
    /// @param to The address to transfer the balance to.
    /// @param amount The amount to transfer.
    /// @param authwit_nonce The nonce for the authorization witness.
    #[authorize_once("from", "authwit_nonce")]
    #[external("public")]
    fn transfer_from_public_to_public(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        // Deduct from `from`.
        self.internal._decrease_public_balance(from, amount);

        // Increment `to`'s balance.
        self.internal._increase_public_balance(to, amount);

        // Emit an event.
        self.emit(Transfer { from, to, amount });
    }

    /// @notice Transfer a private balance from one address to another's public balance.
    /// @param from The address to transfer the balance from.
    /// @param to The address to transfer the balance to.
    /// @param amount The amount to transfer.
    /// @param authwit_nonce The nonce for the authorization witness.
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_from_private_to_public(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        // Deduct from `from` private balance.
        self.internal._decrease_private_balance(from, amount);

        // Increase `to`'s public balance.
        self.enqueue_self.increase_public_balance(to, amount);
    }

    /// @notice Transfer a private balance from one address to another's private balance.
    /// @param from The address to transfer the balance from.
    /// @param to The address to transfer the balance to.
    /// @param amount The amount to transfer.
    /// @param authwit_nonce The nonce for the authorization witness.
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_from_private_to_private(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        // Deduct from `from` private balance.
        self.internal._decrease_private_balance(from, amount);

        // Increase `to`'s private balance.
        self.internal._increase_private_balance(to, amount);
    }

    /// @notice Transfer a public balance from one address to another's private balance.
    /// @param from The address to transfer the balance from.
    /// @param to The address to transfer the balance to.
    /// @param amount The amount to transfer.
    /// @param authwit_nonce The nonce for the authorization witness.
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_from_public_to_private(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        // Increment to's balance.
        self.internal._increase_private_balance(to, amount);

        // Decrease from's balance.
        self.enqueue_self.decrease_public_balance(from, amount);
    }

    /// @notice Helper function to increase the total supply.
    /// @dev Can only be called by the contract itself.
    ///      Used as an enqueued call for increasing the total supply in external private functions.
    /// @param amount The amount to increase the total supply by.
    #[external("public")]
    #[only_self]
    fn increase_total_supply(amount: u128) {
        self.internal._increase_total_supply(amount);
    }

    /// @notice Helper function to decrease the total supply.
    /// @dev Can only be called by the contract itself.
    ///      Used as an enqueued call for decreasing the total supply in external private functions.
    /// @param amount The amount to decrease the total supply by.
    #[external("public")]
    #[only_self]
    fn decrease_total_supply(amount: u128) {
        self.internal._decrease_total_supply(amount);
    }

    /// @notice Helper function to increase a public balance.
    /// @dev Can only be called by the contract itself.
    ///      Used as an enqueued call for increasing a public balance in external private functions.
    /// @param addr The address to increase the balance of.
    /// @param amount The amount to increase the balance by.
    #[external("public")]
    #[only_self]
    fn increase_public_balance(addr: AztecAddress, amount: u128) {
        self.internal._increase_public_balance(addr, amount);
    }

    /// @notice Helper function to decrease a public balance.
    /// @dev Can only be called by the contract itself.
    ///      Used as an enqueued call for decreasing a public balance in external private functions.
    /// @param addr The address to decrease the balance of.
    /// @param amount The amount to decrease the balance by.
    #[external("public")]
    #[only_self]
    fn decrease_public_balance(addr: AztecAddress, amount: u128) {
        self.internal._decrease_public_balance(addr, amount);
    }

    /// @notice Internal function to increase a public balance.
    /// @param addr The address to increase the balance of.
    /// @param amount The amount to increase the balance by.
    #[internal("public")]
    fn _increase_public_balance(addr: AztecAddress, amount: u128) {
        let new_balance = self.storage.public_balances.at(addr).read() + amount;
        self.storage.public_balances.at(addr).write(new_balance);
    }

    /// @notice Internal function to decrease a public balance.
    /// @param addr The address to decrease the balance of.
    /// @param amount The amount to decrease the balance by.
    #[internal("public")]
    fn _decrease_public_balance(addr: AztecAddress, amount: u128) {
        let balance = self.storage.public_balances.at(addr).read();
        assert(balance >= amount, "Insufficient public balance");

        self.storage.public_balances.at(addr).write(balance - amount);
    }

    /// @notice Internal function to increase the total supply.
    /// @param amount The amount to increase the total supply by.
    #[internal("public")]
    fn _increase_total_supply(amount: u128) {
        let new_total_supply = self.storage.total_supply.read() + amount;
        self.storage.total_supply.write(new_total_supply);
    }

    /// @notice Internal function to decrease the total supply.
    /// @param amount The amount to decrease the total supply by.
    #[internal("public")]
    fn _decrease_total_supply(amount: u128) {
        let total_supply = self.storage.total_supply.read();
        assert(total_supply >= amount, "Insufficient total supply");

        self.storage.total_supply.write(total_supply - amount);
    }

    /// @notice Internal function to increase a private balance.
    /// @param addr The address to increase the balance of.
    /// @param amount The amount to increase the balance by.
    #[internal("private")]
    fn _increase_private_balance(addr: AztecAddress, amount: u128) {
        self.storage.private_balances.at(addr).add(amount).deliver(
            MessageDelivery::onchain_constrained(),
        );
    }

    /// @notice Internal function to decrease a private balance.
    /// @param from The address to decrease the balance of.
    /// @param amount The amount to decrease the balance by.
    #[internal("private")]
    fn _decrease_private_balance(from: AztecAddress, amount: u128) {
        let change = self.internal._subtract_private_balance(from, amount, MAX_TF_NOTES);

        if change > 0 {
            self.storage.private_balances.at(from).add(change).deliver(
                MessageDelivery::onchain_constrained(),
            );
        }
    }

    /// @notice External function, expected to be called recursively,
    ///         if needed to prevent infinite circuit when consuming a private balance's notes.
    /// @dev Can only be called by the contract itself.
    /// @param from The address to decrease the balance of.
    /// @param amount The amount to decrease the balance by.
    /// @return The amount of notes consumed.
    #[external("private")]
    #[only_self]
    fn recurse_subtract_private_balance_internal(from: AztecAddress, amount: u128) -> u128 {
        self.internal._subtract_private_balance(from, amount, MAX_RECURSE_TF_NOTES)
    }

    /// @notice Internal function to subtract a private balance.
    /// @param from The address to subtract the balance of.
    /// @param amount The amount to subtract the balance by.
    /// @param max_notes The maximum number of notes to consume per `try_sub`.
    /// @return The amount of notes subtracted.
    #[internal("private")]
    fn _subtract_private_balance(from: AztecAddress, amount: u128, max_notes: u32) -> u128 {
        let consumed = self.storage.private_balances.at(from).try_sub(amount, max_notes);

        if consumed >= amount {
            consumed - amount
        } else {
            assert(consumed > 0, "Insufficient private balance");
            self.call_self.recurse_subtract_private_balance_internal(from, amount - consumed)
        }
    }

    // Getters.

    /// @notice Getter for the token name.
    #[external("public")]
    #[view]
    fn name() -> FieldCompressedString {
        self.storage.name.read()
    }

    /// @notice Getter for the token symbol.
    #[external("public")]
    #[view]
    fn symbol() -> FieldCompressedString {
        self.storage.symbol.read()
    }

    /// @notice Getter for the token decimals.
    #[external("public")]
    #[view]
    fn decimals() -> u8 {
        self.storage.decimals.read()
    }

    /// @notice Getter for the token owner.
    #[external("public")]
    #[view]
    fn owner() -> AztecAddress {
        self.storage.owner.read()
    }

    /// @notice Getter for the token name.
    #[external("public")]
    #[view]
    fn total_supply() -> u128 {
        self.storage.total_supply.read()
    }

    /// @notice Getter for a user's token public balance.
    /// @param addr Address to fetch the balance of.
    #[external("public")]
    #[view]
    fn public_balance(addr: AztecAddress) -> u128 {
        self.storage.public_balances.at(addr).read()
    }

    /// @notice Getter for a user's token private balance.
    /// @param addr Address to fetch the balance of.
    #[external("utility")]
    unconstrained fn private_balance(addr: AztecAddress) -> u128 {
        self.storage.private_balances.at(addr).balance_of()
    }
}

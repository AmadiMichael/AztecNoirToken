use aztec::macros::aztec;

#[aztec]
pub contract CallerContract {
    use aztec::{macros::{functions::external, storage::storage}, protocol::address::AztecAddress};
    use token_contract::Token;

    #[external("private")]
    fn deposit_from_private_to_public_vault(
        token_address: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        self.call(Token::at(token_address).transfer_from_private_to_public(
            self.msg_sender(),
            self.address,
            amount,
            authwit_nonce,
        ));
    }

    #[external("private")]
    fn deposit_from_public_to_private_vault(
        token_address: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        self.call(Token::at(token_address).transfer_from_public_to_private(
            self.msg_sender(),
            self.address,
            amount,
            authwit_nonce,
        ));
    }

    #[external("private")]
    fn deposit_from_private_to_private_vault(
        token_address: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        self.call(Token::at(token_address).transfer_from_private_to_private(
            self.msg_sender(),
            self.address,
            amount,
            authwit_nonce,
        ));
    }
}

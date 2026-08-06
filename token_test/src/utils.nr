use aztec::{protocol::address::AztecAddress, test::helpers::test_environment::TestEnvironment};
use compressed_string::FieldCompressedString;
use token_contract::Token;

// Deploy details.
pub global NAME: FieldCompressedString =
    FieldCompressedString::from_string("AztecNoirToken00000000000000000");
pub global SYMBOL: FieldCompressedString =
    FieldCompressedString::from_string("ANT0000000000000000000000000000");
pub global DECIMALS: u8 = 18;

pub unconstrained fn setup_deploy() -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    // Setup test env.
    let mut env = TestEnvironment::new();

    // Create deployer address.
    let deployer = env.create_light_account();

    // Create a user account.
    let user = env.create_contract_account();

    // Get constructor call.
    let constructor_call = Token::interface().constructor(NAME, SYMBOL, DECIMALS);

    // Deploy token.
    let token_address =
        env.deploy("@token_contract/Token").with_public_initializer(deployer, constructor_call);

    (env, deployer, user, token_address)
}

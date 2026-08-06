use aztec::{protocol::address::AztecAddress, test::helpers::test_environment::TestEnvironment};
use compressed_string::FieldCompressedString;
use token_contract::Token;

// Deploy details.
global NAME: FieldCompressedString =
    FieldCompressedString::from_string("AztecNoirToken00000000000000000");
global SYMBOL: FieldCompressedString =
    FieldCompressedString::from_string("ANT0000000000000000000000000000");
global DECIMALS: u8 = 18;

unconstrained fn setup_deploy() -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
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

#[test]
unconstrained fn test_constructor() {
    // Setup.
    let (env, deployer, _, token_address) = setup_deploy();
    let token_contract = Token::at(token_address);

    // Assert variables were set correctly.

    // Name is correct.
    let name = env.view_public(token_contract.name());
    assert_eq(name, NAME, "Incorrect name");

    // Symbol is correct.
    let symbol = env.view_public(token_contract.symbol());
    assert_eq(symbol, SYMBOL, "Incorrect symbol");

    // Decimals is correct.
    let decimals = env.view_public(token_contract.decimals());
    assert_eq(decimals, DECIMALS, "Incorrect decimals");

    // Owner is correct.
    let owner = env.view_public(token_contract.owner());
    assert_eq(owner, deployer, "Incorrect owner");

    // Total supply is 0.
    let total_supply = env.view_public(token_contract.total_supply());
    assert_eq(total_supply, 0, "Total supply is not 0");
}

#[test]
unconstrained fn test_mint_public() {
    // Setup.
    let (env, deployer, user, token_address) = setup_deploy();
    let token_contract = Token::at(token_address);

    // Get user's balance and total supply before.
    let bal_before = env.view_public(token_contract.public_balance(user));
    let total_supply_before = env.view_public(token_contract.total_supply());

    // Mint to user, using deployer.
    let amount = 1_000;
    env.call_public(deployer, token_contract.mint_public(user, amount));

    // Assert user's balance and total supply increased by 1_000.
    let bal_after = env.view_public(token_contract.public_balance(user));
    let total_supply_after = env.view_public(token_contract.total_supply());
    assert_eq(bal_after - bal_before, amount, "Balance Difference != amount");
    assert_eq(
        total_supply_after - total_supply_before,
        amount,
        "Total supply Difference != amount",
    );
}

#[test(should_fail_with = "Only owner")]
unconstrained fn test_mint_public_reverts_if_not_owner() {
    // Setup.
    let (env, _, user, token_address) = setup_deploy();
    let token_contract = Token::at(token_address);

    // Try call mint with user.
    env.call_public(user, token_contract.mint_public(user, 1_000));
}

#[test]
unconstrained fn test_mint_private() {
    // Setup.
    let (env, deployer, user, token_address) = setup_deploy();
    let token_contract = Token::at(token_address);

    // Get user's balance and total supply before.
    let bal_before = env.execute_utility(token_contract.private_balance(user));
    let total_supply_before = env.view_public(token_contract.total_supply());

    // Mint.
    let amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(user, amount));

    // Assert the balance and total supply increased by amount.
    let bal_after = env.execute_utility(token_contract.private_balance(user));
    let total_supply_after = env.view_public(token_contract.total_supply());
    assert_eq(bal_after - bal_before, amount, "Balance difference != amount");
    assert_eq(
        total_supply_after - total_supply_before,
        amount,
        "Total supply difference != amount",
    );
}

#[test(should_fail_with = "Only owner")]
unconstrained fn test_mint_private_reverts_if_not_owner() {
    // Setup.
    let (env, _, user, token_address) = setup_deploy();
    let token_contract = Token::at(token_address);

    // Try mint privately with user.
    env.call_private(user, token_contract.mint_private(user, 1_000));
}

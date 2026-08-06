use crate::utils::{DECIMALS, NAME, setup_deploy, SYMBOL};
use token_contract::Token;

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

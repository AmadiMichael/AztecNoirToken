use crate::utils;
use token_contract::Token;

#[test]
unconstrained fn test_burn_public() {
    // Setup.
    let (env, deployer, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Mint for user.
    let mint_amount = 1_000;
    env.call_public(deployer, token_contract.mint_public(user, mint_amount));

    // Get pre balances.
    let user_bal_before = env.view_public(token_contract.public_balance(user));
    let total_supply_before = env.view_public(token_contract.total_supply());

    // Burn from user.
    let burn_amount = 500;
    env.call_public(deployer, token_contract.burn_public(user, burn_amount));

    // Get post balances.
    let user_bal_after = env.view_public(token_contract.public_balance(user));
    let total_supply_after = env.view_public(token_contract.total_supply());

    // Assertions.
    assert_eq(
        user_bal_before - user_bal_after,
        mint_amount - burn_amount,
        "User balance did not decrease as expected",
    );
    assert_eq(
        total_supply_before - total_supply_after,
        mint_amount - burn_amount,
        "Total supply did not decrease as expected",
    );
}

#[test(should_fail_with = "Only owner")]
unconstrained fn test_burn_public_reverts_if_not_owner() {
    // Setup.
    let (env, _, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Try call burn with user.
    env.call_public(user, token_contract.burn_public(user, 1_000));
}

#[test(should_fail_with = "Insufficient public balance")]
unconstrained fn test_burn_public_reverts_if_insufficient_public_balance() {
    // Setup.
    let (env, deployer, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Try call burn with user.
    env.call_public(deployer, token_contract.burn_public(user, 1));
}

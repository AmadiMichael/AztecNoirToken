use crate::utils;
use token_contract::Token;

#[test]
unconstrained fn test_mint_private() {
    // Setup.
    let (env, deployer, user, token_address) = utils::setup_deploy();
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
    let (env, _, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Try mint privately with user.
    env.call_private(user, token_contract.mint_private(user, 1_000));
}

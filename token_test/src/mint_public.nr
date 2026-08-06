use crate::utils::setup_deploy;
use token_contract::Token;

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

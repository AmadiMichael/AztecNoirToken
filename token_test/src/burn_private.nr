use crate::utils;
use aztec::test::helpers::authwit as authwit_cheatcodes;
use mocks::CallerContract;
use token_contract::Token;

#[test]
unconstrained fn test_burn_private() {
    // Setup.
    let (env, deployer, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Mint for user.
    let mint_amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(user, mint_amount));

    // Get pre balances.
    let user_bal_before = env.execute_utility(token_contract.private_balance(user));
    let total_supply_before = env.view_public(token_contract.total_supply());

    // Burn from user.
    let burn_amount = 500;
    env.call_private(user, token_contract.burn_private(user, burn_amount, 0));

    // Get post balances.
    let user_bal_after = env.execute_utility(token_contract.private_balance(user));
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

#[test(should_fail_with = "Insufficient private balance")]
unconstrained fn test_burn_private_reverts_if_insufficient_public_balance() {
    // Setup.
    let (env, _, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Try call burn with user.
    env.call_private(user, token_contract.burn_private(user, 1, 0));
}

#[test]
unconstrained fn test_burn_private_authwit() {
    // Setup.
    let (env, deployer, user, token_address, caller_address) =
        utils::setup_and_deploy_caller_contract();
    let token_contract = Token::at(token_address);
    let caller_contract = CallerContract::at(caller_address);

    // Mint for deployer.
    let mint_amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(user, mint_amount));

    // Get balances before.
    let user_bal_before = env.execute_utility(token_contract.private_balance(user));
    let total_supply_before = env.view_public(token_contract.total_supply());

    // Transfer amount.
    let burn_amount = 500;

    // Authwit nonce.
    let authwit_nonce = 1;

    // Create authwit.
    authwit_cheatcodes::add_private_authwit_from_call(
        env,
        user,
        caller_address,
        token_contract.burn_private(user, burn_amount, authwit_nonce),
    );

    // Make the call to caller contract.
    env.call_private(
        user,
        caller_contract.call_burn_private(token_address, burn_amount, authwit_nonce),
    );

    // Get balances after.
    let user_bal_after = env.execute_utility(token_contract.private_balance(user));
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

#[test(should_fail_with = "Unknown auth witness for message hash 0x23f83de98c82487805705350bbfabbd4cc14823452bd8eec2c59cc50625afc7e")]
unconstrained fn test_burn_private_authwit_invalid_nonce() {
    // Setup.
    let (env, deployer, user, token_address, caller_address) =
        utils::setup_and_deploy_caller_contract();
    let token_contract = Token::at(token_address);
    let caller_contract = CallerContract::at(caller_address);

    // Mint for deployer.
    let mint_amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(user, mint_amount));

    // Transfer amount.
    let burn_amount = 500;

    // Authwit nonce. Note we do not mock it.
    let authwit_nonce = 1;

    // Make the call to caller contract.
    env.call_private(
        user,
        caller_contract.call_burn_private(token_address, burn_amount, authwit_nonce),
    );
}

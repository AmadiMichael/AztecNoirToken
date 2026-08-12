use crate::utils;
use aztec::test::helpers::authwit as authwit_cheatcodes;
use mocks::CallerContract::CallerContract;
use token_contract::Token;

#[test]
unconstrained fn test_transfer_from_private_to_private() {
    // Setup.
    let (env, deployer, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Mint to deployer.
    let mint_amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(deployer, mint_amount));

    // Get pre balances.
    let deployer_bal_before = env.execute_utility(token_contract.private_balance(deployer));
    let user_bal_before = env.execute_utility(token_contract.private_balance(user));

    // Transfer from deployer public balance to user's private balance.
    let tf_amount = 500;
    env.call_private(
        deployer,
        token_contract.transfer_from_private_to_private(deployer, user, tf_amount, 0),
    );

    // Get pre balances.
    let deployer_bal_after = env.execute_utility(token_contract.private_balance(deployer));
    let user_bal_after = env.execute_utility(token_contract.private_balance(user));

    // Assertions.
    assert_eq(
        deployer_bal_before - deployer_bal_after,
        mint_amount - tf_amount,
        "Deployer balance did not decrease as expected",
    );
    assert_eq(
        user_bal_after - user_bal_before,
        mint_amount - tf_amount,
        "User balance did not increase as expected",
    );
}

#[test(should_fail_with = "Insufficient private balance")]
unconstrained fn test_transfer_from_private_to_private_insufficient_balance() {
    // Setup.
    let (env, deployer, user, token_address) = utils::setup_deploy();
    let token_contract = Token::at(token_address);

    // Mint for deployer.
    let mint_amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(deployer, mint_amount));

    // Transfer from deployer to user.
    let tf_amount = 2_000;
    env.call_private(
        deployer,
        token_contract.transfer_from_private_to_private(deployer, user, tf_amount, 0),
    );
}

#[test]
unconstrained fn test_transfer_from_private_to_private_authwit() {
    // Setup.
    let (env, deployer, _, token_address, caller_address) =
        utils::setup_and_deploy_caller_contract();
    let token_contract = Token::at(token_address);
    let caller_contract = CallerContract::at(caller_address);

    // Mint for deployer.
    let mint_amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(deployer, mint_amount));

    // Get balances before.
    let deployer_bal_before = env.execute_utility(token_contract.private_balance(deployer));
    let caller_bal_before = env.execute_utility(token_contract.private_balance(caller_address));

    // Transfer amount.
    let tf_amount = 500;

    // Authwit nonce.
    let authwit_nonce = 1;

    // Create authwit.
    authwit_cheatcodes::add_private_authwit_from_call(
        env,
        deployer,
        caller_address,
        token_contract.transfer_from_private_to_private(
            deployer,
            caller_address,
            tf_amount,
            authwit_nonce,
        ),
    );

    // Make the call to caller contract.
    env.call_private(
        deployer,
        caller_contract.call_transfer_from_private_to_private(
            token_address,
            tf_amount,
            authwit_nonce,
        ),
    );

    // Get balances after.
    let deployer_bal_after = env.execute_utility(token_contract.private_balance(deployer));
    let caller_bal_after = env.execute_utility(token_contract.private_balance(caller_address));

    // Assertions.
    assert_eq(
        deployer_bal_before - deployer_bal_after,
        tf_amount,
        "Deployer balance did not decrease by expected amount",
    );
    assert_eq(
        caller_bal_after - caller_bal_before,
        tf_amount,
        "User balance did not increase as expected",
    );
}

#[test(should_fail_with = "Unknown auth witness for message hash 0x04ed14001f77b30791b4565240bea23b8d9d3a3035b078de2066acf508d00ad7")]
unconstrained fn test_transfer_from_private_to_private_authwit_invalid_nonce() {
    // Setup.
    let (env, deployer, _, token_address, caller_address) =
        utils::setup_and_deploy_caller_contract();
    let token_contract = Token::at(token_address);
    let caller_contract = CallerContract::at(caller_address);

    // Mint for deployer.
    let mint_amount = 1_000;
    env.call_private(deployer, token_contract.mint_private(deployer, mint_amount));

    // Transfer amount.
    let tf_amount = 500;

    // Authwit nonce. Note we do not mock it.
    let authwit_nonce = 1;

    // Make the call to caller contract.
    env.call_private(
        deployer,
        caller_contract.call_transfer_from_private_to_private(
            token_address,
            tf_amount,
            authwit_nonce,
        ),
    );
}

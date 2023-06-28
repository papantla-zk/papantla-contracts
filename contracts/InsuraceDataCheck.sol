// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.16;

import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";

// ***************************************
// *    Minimum Viable OOV3 Integration  *
// ***************************************

// This contract shows how to get up and running as quickly as possible with UMA's Optimistic Oracle V3.
// We make a simple data assertion about the real world and let the OOV3 arbitrate the outcome.

contract InsuranceDataCheck {
    // Create an Optimistic Oracle V3 instance at the deployed address on Görli.
    // Optimism mainnet 0x072819Bb43B50E7A251c64411e7aA362ce82803B
    OptimisticOracleV3Interface oov3 =
        OptimisticOracleV3Interface(0x263351499f82C107e540B01F0Ca959843e22464a);

    // Asserted claim. This is some truth statement about the world and can be verified by the network of disputers.
    //bytes public assertedClaim =
    //   bytes("Flight number 90901 was cancelled"); // AC306

    // Each assertion has an associated assertionID that uniquly identifies the assertion. We will store this here.
    bytes32 public assertionId;

    event SentMessage(address recipient, string message);

    // Assert the truth against the Optimistic Asserter. This uses the assertion with defaults method which defaults
    // all values, such as a) challenge window to 120 seconds (2 mins), b) identifier to ASSERT_TRUTH, c) bond currency
    //  to USDC and c) and default bond size to 0 (which means we dont need to worry about approvals in this example).
    function assertTruth(string memory flightId) public {
        string memory assertedClaim = "Was cancelled fligth number ";
        assertionId = oov3.assertTruthWithDefaults(
            bytes(string.concat(assertedClaim, flightId)),
            address(this)
        );
    }

    // Settle the assertion, if it has not been disputed and it has passed the challenge window, and return the result.
    // result
    function settleAndGetAssertionResult() public returns (bool) {
        return oov3.settleAndGetAssertionResult(assertionId);
    }

    // Just return the assertion result. Can only be called once the assertion has been settled.
    function getAssertionResult() external returns (bool) {
        bool result = oov3.getAssertionResult(assertionId);
        string memory message;
        if (result) {
            message = "Flight Was cancelled";
        } else {
            message = "Flight was not cancelled";
        }

        emit SentMessage(msg.sender, message);
        return result;
    }

    // Return the full assertion object contain all information associated with the assertion. Can be called any time.
    function getAssertion()
        public
        view
        returns (OptimisticOracleV3Interface.Assertion memory)
    {
        return oov3.getAssertion(assertionId);
    }
}

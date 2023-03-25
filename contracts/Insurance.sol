// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@hyperlane-xyz/core/interfaces/IMailbox.sol";

contract InsuranceArbitrator {
    using SafeERC20 for IERC20;
    IMailbox inbox; // mumbai 0xCC737a94FecaeC165AbCf12dED095BB13F037685
    // gnosis 0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70
    bytes32 public lastSender;
    string public lastMessage;

    // Stores state and parameters of insurance policy.
    struct InsurancePolicy {
        bool claimInitiated; // Claim state preventing simultaneous claim attempts.
        string insuredEvent; // Short description of insured event.
        address insuredAddress; // Beneficiary address eligible for insurance compensation.
        uint256 insuredAmount; // Amount of insurance coverage.
        string fligthId; // Fligth to insure
    }

    // References all active insurance policies by policyId.
    mapping(bytes32 => InsurancePolicy) public insurancePolicies;

    // Maps hash of initiated claims to their policyId.
    // This is used in callback function to potentially pay out the beneficiary.
    mapping(bytes32 => bytes32) public insuranceClaims;

    IERC20 public immutable currency; // Denomination token for insurance coverage and bonding.

    uint256 public constant MAX_EVENT_DESCRIPTION_SIZE = 6; // Insured event description should be concise.

    // Template for constructing ancillary data. The claim would insert insuredEvent in between when requesting
    // through Optimistic Oracle.
    string constant ancillaryDataHead =
        'q:"Had the following insured event occurred as of request timestamp: ';
    string constant ancillaryDataTail = '?"';

    /****************************************
     *                EVENTS                *
     ****************************************/

    event PolicyIssued(
        bytes32 indexed policyId,
        address indexed insurer,
        string insuredEvent,
        address indexed insuredAddress,
        uint256 insuredAmount,
        string fligthInsured
    );
    event ClaimSubmitted(
        uint256 claimTimestamp,
        bytes32 indexed claimId,
        bytes32 indexed policyId
    );
    event ClaimAccepted(bytes32 indexed claimId, bytes32 indexed policyId);
    event ClaimRejected(bytes32 indexed claimId, bytes32 indexed policyId);
    event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

    constructor(address _currency, address _inbox) {
        currency = IERC20(_currency);
        inbox = IMailbox(_inbox);
    }

    /**
     * @notice Deposits insuredAmount from the insurer and issues insurance policy to the insured beneficiary.
     * @dev This contract must be approved to spend at least insuredAmount of currency token.
     * @param insuredEvent short description of insured event. Potential verifiers should be able to evaluate whether
     * this event had occurred as of claim time with binary yes/no answer.
     * @param insuredAddress Beneficiary address eligible for insurance compensation.
     * @param insuredAmount Amount of insurance coverage.
     * @param fligthId Fligth to insure.
     * @return policyId Unique identifier of issued insurance policy.
     */
    function issueInsurance(
        string calldata insuredEvent,
        address insuredAddress,
        uint256 insuredAmount,
        string memory fligthId
    ) external returns (bytes32 policyId) {
        require(
            bytes(insuredEvent).length <= MAX_EVENT_DESCRIPTION_SIZE,
            "Event description too long"
        );
        require(insuredAddress != address(0), "Invalid insured address");
        require(insuredAmount > 0, "Amount should be above 0");
        policyId = _getPolicyId(
            block.number,
            insuredEvent,
            insuredAddress,
            insuredAmount
        );
        require(
            insurancePolicies[policyId].insuredAddress == address(0),
            "Policy already issued"
        );

        InsurancePolicy storage newPolicy = insurancePolicies[policyId];
        newPolicy.insuredEvent = insuredEvent;
        newPolicy.insuredAddress = insuredAddress;
        newPolicy.insuredAmount = insuredAmount;
        newPolicy.fligthId = fligthId;

        currency.safeTransferFrom(msg.sender, address(this), insuredAmount);

        emit PolicyIssued(
            policyId,
            msg.sender,
            insuredEvent,
            insuredAddress,
            insuredAmount,
            fligthId
        );
    }

    /**
     * @notice Anyone can submit insurance claim posting oracle bonding. Only one simultaneous claim per insurance
     * policy is allowed.
     * @dev This contract must be approved to spend at least (insuredAmount * oracleBondPercentage + finalFee) of
     * currency token. This call requests and proposes that insuredEvent had ocured through Optimistic Oracle.
     * @param policyId Identifier of claimed insurance policy.
     */
    function submitClaim(bytes32 policyId) external {
        require(
            keccak256(abi.encodePacked(lastMessage)) ==
                keccak256(abi.encodePacked("Flight Was cancelled")),
            "Invalid Claim"
        );
        InsurancePolicy storage claimedPolicy = insurancePolicies[policyId];
        require(
            claimedPolicy.insuredAddress != address(0),
            "Insurance not issued"
        );
        require(!claimedPolicy.claimInitiated, "Claim already initiated");
        claimedPolicy.claimInitiated = true;

        bytes memory ancillaryData = abi.encodePacked(
            ancillaryDataHead,
            claimedPolicy.insuredEvent,
            ancillaryDataTail
        );
        bytes32 claimId = _getClaimId(block.timestamp, ancillaryData);
        insuranceClaims[claimId] = policyId;

        uint256 proposerBond = (claimedPolicy.insuredAmount * 0.001e18) / 1e18; // 0.01%
        currency.safeTransferFrom(msg.sender, address(this), proposerBond); // deposita una comision al contrato

        emit ClaimSubmitted(block.timestamp, claimId, policyId);
    }

    function handle(
        uint32 _origin, // 420 Opt mainnet
        bytes32 _sender, // OracleDataCheck address
        bytes calldata _message // "Flight Was cancelled"
    ) external {
        lastSender = _sender;
        lastMessage = string(_message);

        emit ReceivedMessage(_origin, _sender, _message);
    }

    /******************************************
     *           INTERNAL FUNCTIONS           *
     ******************************************/

    function _getPolicyId(
        uint256 blockNumber,
        string memory insuredEvent,
        address insuredAddress,
        uint256 insuredAmount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    blockNumber,
                    insuredEvent,
                    insuredAddress,
                    insuredAmount
                )
            );
    }

    function _getClaimId(
        uint256 timestamp,
        bytes memory ancillaryData
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(timestamp, ancillaryData));
    }
}

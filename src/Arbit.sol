// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.15;

error notParty();
error notJudge();
error notJudgeOrParty();
error notValidWinner();
error notDecisionMaker();

contract Arbit {
    enum Status {
        Open,
        Closed,
        Judging,
        Rejected
    }
    enum DecisionMaker {
        Party1,
        Party2,
        Judge
    }

    struct Case {
        address party1;
        address party2;
        address judge;
        DecisionMaker decisionMaker;
        mapping(address => bool) approvals;
        Status status;
        address winner;
    }

    event CaseOpened(
        uint256 caseId,
        address party1,
        address party2,
        address judge
    );
    event CaseStarted(
        uint256 caseId,
        address party1,
        address party2,
        address judge
    );
    // might be unnecessary
    event CaseApproved(
        uint256 caseId,
        address party1,
        address party2,
        address judge
    );
    event CaseRejected(
        uint256 caseId,
        address party1,
        address party2,
        address judge
    );
    event CaseClosed(
        uint256 caseId,
        address party1,
        address party2,
        address judge,
        address winner
    );
    event CaseClosed(uint256 caseId, address winner, address judge);

    mapping(uint256 => Case) cases;
    uint256 internal caseIdCounter = 0;
    modifier isParty(uint256 caseId) {
        if (
            cases[caseId].party1 != msg.sender &&
            cases[caseId].party2 != msg.sender
        ) {
            revert notParty();
        }
        _;
    }
    modifier isJudge(uint256 caseId) {
        if (cases[caseId].judge != msg.sender) {
            revert notJudge();
        }
        _;
    }
    modifier isJudgeOrParty(uint256 caseId) {
        if (
            cases[caseId].judge != msg.sender &&
            cases[caseId].party1 != msg.sender &&
            cases[caseId].party2 != msg.sender
        ) {
            revert notJudgeOrParty();
        }
        _;
    }
    modifier isValidWinner(uint256 caseId, address winner) {
        if (cases[caseId].party1 != winner && cases[caseId].party2 != winner) {
            revert notValidWinner();
        }
        _;
    }
    modifier isDecisionMaker(uint256 caseId) {
        if (
            (cases[caseId].decisionMaker != DecisionMaker.Judge &&
                cases[caseId].judge != msg.sender) ||
            (cases[caseId].decisionMaker != DecisionMaker.Party1 &&
                cases[caseId].party1 != msg.sender) ||
            (cases[caseId].decisionMaker != DecisionMaker.Party2 &&
                cases[caseId].party2 != msg.sender)
        ) {
            revert notDecisionMaker();
        }
        _;
    }

    function openCase(address party2, address judge)
        public
        returns (uint256 caseId)
    {
        caseId = caseIdCounter;
        Case storage case_ = cases[caseId];
        case_.party1 = msg.sender;
        case_.party2 = party2;
        case_.judge = judge;
        case_.approvals[msg.sender] = true;
        case_.status = Status.Open;
        case_.winner = address(0x0);
        emit CaseOpened(caseId, case_.party1, case_.party2, case_.judge);
        caseIdCounter++;
        case_.decisionMaker = DecisionMaker.Party2;

        return caseId;
    }

    // function startCase(uint256 caseId, address judge) public {
    //     Case storage case_ = cases[caseId];
    //     require(msg.sender == case_.party2, "Only party2 can start a case");
    //     require(
    //         case_.decisionMaker == DecisionMaker.Party1,
    //         "Case is already started"
    //     );
    //     case_.decisionMaker = DecisionMaker.Party2;
    //     emit CaseStarted(caseId, case_.party1, case_.party2, case_.judge);
    // }

    function closeCase(uint256 caseId, address caseWinner)
        public
        isJudge(caseId)
        isValidWinner(caseId, caseWinner)
    {
        Case storage case_ = cases[caseId];
        case_.status = Status.Closed;
        case_.winner = caseWinner;
        emit CaseClosed(
            caseId,
            case_.party1,
            case_.party2,
            case_.judge,
            caseWinner
        );
    }

    function editCase(uint256 caseId, address newJudge) public isParty(caseId) {
        Case storage case_ = cases[caseId];
        case_.approvals[msg.sender] = true;
        if (case_.decisionMaker == DecisionMaker.Party1) {
            case_.decisionMaker = DecisionMaker.Party2;
            case_.approvals[case_.party2] = false;
        } else {
            case_.decisionMaker = DecisionMaker.Party1;
            case_.approvals[case_.party1] = false;
        }
        case_.judge = newJudge;
    }

    function approveCase(uint256 caseId) public isJudge(caseId) {
        Case storage case_ = cases[caseId];
        case_.approvals[msg.sender] = true;
        // might not need this
        emit CaseApproved(caseId, case_.party1, case_.party2, case_.judge);
    }

    // changing judge should reset approval
    // function changeJudge(uint256 caseId, address newJudge)
    //     public
    //     isParty(caseId)
    // {
    //     Case storage case_ = cases[caseId];
    //     case_.judge = newJudge;
    // }

    function sendToJudge(uint256 caseId) internal isParty(caseId) {
        Case storage case_ = cases[caseId];
        if (case_.approvals[case_.party1] && case_.approvals[case_.party2]) {
            // case_.judge = judge;
            case_.decisionMaker = DecisionMaker.Judge;
            emit CaseApproved(caseId, case_.party1, case_.party2, case_.judge);
        }
    }

    // function isApprovedByBoth(uint256 caseId) internal view returns (bool) {
    //     Case storage case_ = cases[caseId];
    //     return case_.approvals[case_.party1] && case_.approvals[case_.party2];
    // }

    // isDecisionMakerr may not be neccesary
    function judgeCase(uint256 caseId)
        public
        isJudge(caseId)
        isDecisionMaker(caseId)
    {
        Case storage case_ = cases[caseId];
        if (
            case_.decisionMaker == DecisionMaker.Judge &&
            case_.approvals[case_.party1] &&
            case_.approvals[case_.party2]
        ) {
            case_.status = Status.Judging;
            case_.approvals[case_.judge] = true;
        }
    }

    function rejectCase(uint256 caseId) internal isJudgeOrParty(caseId) {
        Case storage case_ = cases[caseId];
        if (case_.status == Status.Open) {
            case_.status = Status.Rejected;
            emit CaseRejected(caseId, case_.party1, case_.party2, case_.judge);
        }
    }

    function getCaseInfo(uint256 caseId)
        external
        view
        returns (
            address party1,
            address party2,
            address judge,
            address winner,
            Status,
            DecisionMaker,
            bool approvedByParty1,
            bool approvedByParty2,
            bool approvedByJudge
        )
    {
        Case storage case_ = cases[caseId];
        return (
            case_.party1,
            case_.party2,
            case_.judge,
            case_.winner,
            case_.status,
            case_.decisionMaker,
            case_.approvals[case_.party1],
            case_.approvals[case_.party2],
            case_.approvals[case_.judge]
        );
    }
}

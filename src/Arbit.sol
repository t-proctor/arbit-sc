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
    event CaseApproved(uint256 caseId, address approver, address nextApprover);
    event CaseEdited(uint256 caseId, address editor, address newJudge);
    event CaseRejected(uint256 caseId, address rejecter);
    event CaseJudging(uint256 caseId, address judge);
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
            (cases[caseId].decisionMaker == DecisionMaker.Judge &&
                cases[caseId].judge != msg.sender) ||
            (cases[caseId].decisionMaker == DecisionMaker.Party1 &&
                cases[caseId].party1 != msg.sender) ||
            (cases[caseId].decisionMaker == DecisionMaker.Party2 &&
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

    function closeCase(uint256 caseId, address caseWinner)
        public
        isJudge(caseId)
        isValidWinner(caseId, caseWinner)
    {
        Case storage case_ = cases[caseId];
        case_.status = Status.Closed;
        case_.winner = caseWinner;
        emit CaseClosed(caseId, case_.winner, case_.judge);
    }

    function editCase(uint256 caseId, address newJudge)
        public
        isParty(caseId)
        isDecisionMaker(caseId)
    {
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
        case_.approvals[case_.judge] = false;
        emit CaseEdited(caseId, msg.sender, case_.judge);
    }

    function approveCase(uint256 caseId)
        public
        isJudgeOrParty(caseId)
        isDecisionMaker(caseId)
    {
        Case storage case_ = cases[caseId];
        case_.approvals[msg.sender] = true;
        address nextApprover = address(0x0);
        if (case_.approvals[case_.party1] && case_.approvals[case_.party2]) {
            case_.decisionMaker = DecisionMaker.Judge;
            nextApprover = case_.judge;
        } else if (case_.decisionMaker == DecisionMaker.Party1) {
            case_.decisionMaker = DecisionMaker.Party2;
            nextApprover = case_.party2;
        } else {
            case_.decisionMaker = DecisionMaker.Party1;
            nextApprover = case_.party1;
        }
        emit CaseApproved(caseId, msg.sender, nextApprover);
    }

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
        emit CaseJudging(caseId, msg.sender);
    }

    function rejectCase(uint256 caseId)
        public
        isJudgeOrParty(caseId)
        isDecisionMaker(caseId)
    {
        Case storage case_ = cases[caseId];
        if (case_.status == Status.Open) {
            case_.status = Status.Rejected;
            emit CaseRejected(caseId, msg.sender);
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

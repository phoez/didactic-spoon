// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/src/Test.sol";
import { ConfidentialRockPaperScissors } from "../src/ConfidentialRockPaperScissors.sol";

contract ConfidentialRockPaperScissorsTest is Test {
    ConfidentialRockPaperScissors public rps;

    address internal player1 = address(0x1);
    address internal player2 = address(0x2);
    address internal player3 = address(0x3);

    function setUp() public {
        rps = new ConfidentialRockPaperScissors();
    }

    function _commitHash(
        ConfidentialRockPaperScissors.Move move,
        string memory nonce
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(uint8(move), nonce));
    }

    function _createAndCommitGame(
        address p1,
        address p2,
        ConfidentialRockPaperScissors.Move p1Move,
        ConfidentialRockPaperScissors.Move p2Move,
        string memory p1Nonce,
        string memory p2Nonce
    )
        internal
        returns (uint256 gameId)
    {
        vm.prank(p1);
        gameId = rps.createGame(p2, _commitHash(p1Move, p1Nonce));

        vm.prank(p2);
        rps.commitMove(gameId, _commitHash(p2Move, p2Nonce));
    }

    function _revealBothPlayers(
        uint256 gameId,
        address p1,
        address p2,
        ConfidentialRockPaperScissors.Move p1Move,
        ConfidentialRockPaperScissors.Move p2Move,
        string memory p1Nonce,
        string memory p2Nonce
    )
        internal
    {
        vm.prank(p1);
        rps.revealMove(gameId, p1Move, p1Nonce);

        vm.prank(p2);
        rps.revealMove(gameId, p2Move, p2Nonce);
    }

    function _assertGameResult(uint256 gameId, ConfidentialRockPaperScissors.Result expectedResult) internal {
        (,,,,,,,, bool finished, ConfidentialRockPaperScissors.Result result) = rps.games(gameId);
        assertTrue(finished, "Game should be finished");
        assertEq(uint256(result), uint256(expectedResult), "Result mismatch");
    }

    function test_Player1Wins() public {
        uint256 gameId = _createAndCommitGame(
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Rock,
            ConfidentialRockPaperScissors.Move.Scissors,
            "secret1",
            "secret2"
        );

        _revealBothPlayers(
            gameId,
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Rock,
            ConfidentialRockPaperScissors.Move.Scissors,
            "secret1",
            "secret2"
        );

        _assertGameResult(gameId, ConfidentialRockPaperScissors.Result.Player1Win);
    }

    function test_Draw() public {
        uint256 gameId = _createAndCommitGame(
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Paper,
            ConfidentialRockPaperScissors.Move.Paper,
            "secretA",
            "secretB"
        );

        _revealBothPlayers(
            gameId,
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Paper,
            ConfidentialRockPaperScissors.Move.Paper,
            "secretA",
            "secretB"
        );

        _assertGameResult(gameId, ConfidentialRockPaperScissors.Result.Draw);
    }

    function test_Player2Wins() public {
        uint256 gameId = _createAndCommitGame(
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Scissors,
            ConfidentialRockPaperScissors.Move.Rock,
            "nonce1",
            "nonce2"
        );

        _revealBothPlayers(
            gameId,
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Scissors,
            ConfidentialRockPaperScissors.Move.Rock,
            "nonce1",
            "nonce2"
        );

        _assertGameResult(gameId, ConfidentialRockPaperScissors.Result.Player2Win);
    }

    function test_RevertWhen_Player2CommitsTwice() public {
        vm.prank(player1);
        uint256 gameId = rps.createGame(player2, _commitHash(ConfidentialRockPaperScissors.Move.Rock, "x"));

        vm.prank(player2);
        rps.commitMove(gameId, _commitHash(ConfidentialRockPaperScissors.Move.Scissors, "y"));

        vm.prank(player2);
        vm.expectRevert();
        rps.commitMove(gameId, _commitHash(ConfidentialRockPaperScissors.Move.Paper, "z"));
    }

    function test_RevertWhen_RevealMismatchesCommit() public {
        uint256 gameId = _createAndCommitGame(
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Rock,
            ConfidentialRockPaperScissors.Move.Scissors,
            "secret",
            "secret2"
        );

        vm.prank(player1);
        vm.expectRevert();
        rps.revealMove(gameId, ConfidentialRockPaperScissors.Move.Paper, "wrongNonce");
    }

    function test_RevertWhen_NonPlayer2TriesToCommit() public {
        vm.prank(player1);
        uint256 gameId = rps.createGame(player2, _commitHash(ConfidentialRockPaperScissors.Move.Paper, "123"));

        vm.prank(player3);
        vm.expectRevert();
        rps.commitMove(gameId, _commitHash(ConfidentialRockPaperScissors.Move.Scissors, "abc"));
    }

    function test_RevertWhen_PlayerRevealsMoveTwice() public {
        uint256 gameId = _createAndCommitGame(
            player1,
            player2,
            ConfidentialRockPaperScissors.Move.Paper,
            ConfidentialRockPaperScissors.Move.Rock,
            "nonce",
            "nonce2"
        );

        vm.prank(player1);
        rps.revealMove(gameId, ConfidentialRockPaperScissors.Move.Paper, "nonce");

        vm.prank(player1);
        vm.expectRevert();
        rps.revealMove(gameId, ConfidentialRockPaperScissors.Move.Paper, "nonce");
    }
}

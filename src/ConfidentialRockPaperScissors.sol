// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ConfidentialRockPaperScissors {
    enum Move {
        None,
        Rock,
        Paper,
        Scissors
    }
    enum Result {
        Draw,
        Player1Win,
        Player2Win
    }

    struct Game {
        address player1;
        bytes32 player1Commit;
        Move player1Move;
        bool player1Revealed;

        address player2;
        bytes32 player2Commit;
        Move player2Move;
        bool player2Revealed;

        bool finished;
        Result result;
    }

    uint256 public gameCount;
    mapping(uint256 => Game) public games;

    event GameCreated(uint256 indexed gameId, address indexed player1, address indexed player2);
    event MoveCommitted(uint256 indexed gameId, address indexed player);
    event MoveRevealed(uint256 indexed gameId, address indexed player, Move move);
    event GameFinished(uint256 indexed gameId, Result result);

    // Player1 creates game with their commitment hash
    function createGame(address _player2, bytes32 _player1Commit) external returns (uint256) {
        require(_player2 != address(0), "Invalid player2 address");
        require(_player1Commit != 0, "Invalid commit");

        gameCount++;
        Game storage g = games[gameCount];
        g.player1 = msg.sender;
        g.player1Commit = _player1Commit;
        g.player2 = _player2;

        emit GameCreated(gameCount, msg.sender, _player2);
        emit MoveCommitted(gameCount, msg.sender);
        return gameCount;
    }

    // Player2 commits their move hash
    function commitMove(uint256 _gameId, bytes32 _commit) external {
        Game storage g = games[_gameId];
        require(!g.finished, "Game finished");
        require(msg.sender == g.player2, "Not player2");
        require(g.player2Commit == 0, "Player2 already committed");
        require(_commit != 0, "Invalid commit");

        g.player2Commit = _commit;
        emit MoveCommitted(_gameId, msg.sender);
    }

    // Either player reveals their move and nonce to prove commitment
    function revealMove(uint256 _gameId, Move _move, string calldata _nonce) external {
        Game storage g = games[_gameId];
        require(!g.finished, "Game finished");
        require(_move != Move.None, "Invalid move");

        bytes32 hash = _efficientKeccak256(_move, _nonce);

        if (msg.sender == g.player1) {
            require(!g.player1Revealed, "Player1 already revealed");
            require(hash == g.player1Commit, "Player1 commit mismatch");
            g.player1Move = _move;
            g.player1Revealed = true;
            emit MoveRevealed(_gameId, msg.sender, _move);
        } else if (msg.sender == g.player2) {
            require(!g.player2Revealed, "Player2 already revealed");
            require(hash == g.player2Commit, "Player2 commit mismatch");
            g.player2Move = _move;
            g.player2Revealed = true;
            emit MoveRevealed(_gameId, msg.sender, _move);
        } else {
            revert("Not a player");
        }

        if (g.player1Revealed && g.player2Revealed) {
            g.finished = true;
            g.result = _evaluateWinner(g.player1Move, g.player2Move);
            emit GameFinished(_gameId, g.result);
        }
    }

    // Efficient keccak256 hash calculation using inline assembly
    function _efficientKeccak256(Move move_, string memory nonce_) internal pure returns (bytes32 result) {
        bytes memory encoded = abi.encodePacked(uint8(move_), nonce_);
        assembly {
            result := keccak256(add(encoded, 32), mload(encoded))
        }
    }

    function _evaluateWinner(Move p1Move, Move p2Move) private pure returns (Result) {
        if (p1Move == p2Move) return Result.Draw;
        if (
            (p1Move == Move.Rock && p2Move == Move.Scissors) || (p1Move == Move.Paper && p2Move == Move.Rock)
                || (p1Move == Move.Scissors && p2Move == Move.Paper)
        ) {
            return Result.Player1Win;
        }
        return Result.Player2Win;
    }
}

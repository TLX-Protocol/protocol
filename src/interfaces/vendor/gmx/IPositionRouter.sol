// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPositionRouter {
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function getRequestQueueLengths()
        external
        view
        returns (uint256, uint256, uint256, uint256);

    function getIncreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function getDecreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionRequestKeys(
        uint256 index
    ) external view returns (bytes32);

    function decreasePositionRequestKeys(
        uint256 index
    ) external view returns (bytes32);

    function minExecutionFee() external view returns (uint256);
}

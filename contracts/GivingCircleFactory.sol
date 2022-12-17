// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IGivingCircle.sol";
import "./partialIERC20.sol";

//Will work really well when we can get a front end built
contract GivingCircleFactory is AccessControl {

    uint256 public givingCirclesCount;
    mapping (uint256 => address) public givingCircles;

    address public implementation;

    event CreatedNewCircle(address);

    function createGivingCircle(address _circleLeader, uint256 _beansToDispursePerAttendee, address _kycController, address _erc20Token, uint256 _fundingThreshold) public {
        address clone = Clones.clone(address(implementation));
        IGivingCircle(clone).initialize(
            _circleLeader,
            _beansToDispursePerAttendee,
            _kycController,
            _erc20Token,
            _fundingThreshold
        );

        givingCircles[givingCirclesCount] = clone;
        givingCirclesCount++;
        emit CreatedNewCircle(clone);
    }

    function setImplementation(address _implementation) external {
        _setImplementation(_implementation);
    }

    function _setImplementation(address _implementation) internal {
        require(_implementation != address(0), "Address cannot be zero address!");
        implementation = _implementation;
    }

    // import "./KYCController.sol";

    // KYCController kycToReference;

    // function setKycImplementation(address addr) public onlyRole(CIRCLE_ADMIN_ROLE) {
    //     kycToReference = KYCController(addr);
    // }
}
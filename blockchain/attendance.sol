// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Attendance {
    address public owner;

    mapping(address => bool) public isEmployee;
    // day => employee => present
    mapping(uint256 => mapping(address => bool)) private attendance;
    // day => employee => timestamp of check-in
    mapping(uint256 => mapping(address => uint256)) private checkInTime;

    event EmployeeAdded(address indexed employee);
    event EmployeeRemoved(address indexed employee);
    event AttendanceMarked(address indexed employee, uint256 indexed day, uint256 timestamp);

    error NotOwner();
    error NotEmployee();
    error AlreadyMarked();
    error ZeroAddress();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ---------- Admin ----------

    function addEmployee(address emp) external onlyOwner {
        if (emp == address(0)) revert ZeroAddress();
        isEmployee[emp] = true;
        emit EmployeeAdded(emp);
    }

    function removeEmployee(address emp) external onlyOwner {
        isEmployee[emp] = false;
        emit EmployeeRemoved(emp);
    }

    // ---------- Employee ----------

    function markAttendance() external {
        if (!isEmployee[msg.sender]) revert NotEmployee();

        uint256 day = currentDay();
        if (attendance[day][msg.sender]) revert AlreadyMarked();

        attendance[day][msg.sender] = true;
        checkInTime[day][msg.sender] = block.timestamp;

        emit AttendanceMarked(msg.sender, day, block.timestamp);
    }

    // ---------- Views ----------

    // Day index = days since Unix epoch (UTC)
    function currentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function wasPresent(address emp, uint256 day) external view returns (bool) {
        return attendance[day][emp];
    }

    function getCheckInTime(address emp, uint256 day) external view returns (uint256) {
        return checkInTime[day][emp];
    }
}
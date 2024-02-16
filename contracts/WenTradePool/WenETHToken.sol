//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IwenETHToken is IERC20Upgradeable {
    function mint(address _to, uint256 _value) external returns (bool);
    function burn(address _from, uint256 _value) external returns (bool);
}


interface IBlast {
  function configureClaimableGas() external;
  function configureGovernor(address governor) external;
}

contract WenETHToken is IwenETHToken, Ownable {
    string public constant name = "Wen ETH Compounding Token"; 
    string public constant symbol = "wenETH";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;
    IBlast public blast;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => bool) public operators;

    constructor(address _blast) {
    blast = IBlast(_blast);
    blast.configureClaimableGas();
   }

   /**
    @notice Set blast governor which is approved for cliaming gas fees. 
    @param _governor governor address
     */
    function setBlastGovernor(address _governor) external onlyOwner {
        blast.configureGovernor(_governor);
    }

    
    
    /**
     @notice Approve contracts to mint and renounce ownership
    @dev In production the only minters should be `WenTradePool`
             Addresses are given via dynamic array to allow extra minters during testing
     */
    function setOperator(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = true;
        }
    }

    /**
     @notice Revoke authority to mint and burn the given token.
     */
    function revokeOperator(address _operator) external onlyOwner {
        require(operators[_operator], "This address is not an operator");
        operators[_operator] = false;
    }

    function approve(address _spender, uint256 _value)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(
            allowance[_from][msg.sender] >= _value,
            "Insufficient allowance"
        );
        if (allowance[_from][msg.sender] != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        @notice Mint wenETN
        @param _value The amount of tokens to be minted
        @param _to receiver of the token
     */
    function mint(address _to, uint256 _value)
        external
        override
        onlyOperator
        returns (bool)
    {
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    /**
        @notice Burn wenETH
        @param _value The amount of tokens to be burned
     */
    function burn(address _from, uint256 _value)
        external
        override
        onlyOperator
        returns (bool)
    {
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(address(_from), address(0), _value);
        return true;
    }


    modifier onlyOperator() {
         require(operators[msg.sender], "Not a operators");
         _;
    }
}

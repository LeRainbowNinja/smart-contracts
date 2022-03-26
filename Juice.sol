// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./lib/SafeMath8.sol";
import "./owner/Operator.sol";
import "./interfaces/IOracle.sol";

/*
      Juice Finance - its a juicer                                                                                            
*/

contract Juice is ERC20Burnable, Operator {
    using SafeMath8 for uint8;
    using SafeMath for uint256;

    // Initial distribution for the first 24h genesis pools
    uint256 public constant INITIAL_GENESIS_POOL_DISTRIBUTION = 2400 ether;
    // Initial distribution for the day 2-5 JUICE-WETH LP -> JUICE pool
    uint256 public constant INITIAL_JUICE_POOL_DISTRIBUTION = 21600 ether;
    // Distribution for airdrops wallet
    uint256 public constant INITIAL_AIRDROP_WALLET_DISTRIBUTION = 1000 ether;

    // Have the rewards been distributed to the pools
    bool public rewardPoolDistributed = false;

    address public juiceOracle;

    /**
     * @notice Constructs the JUICE ERC-20 contract.
     */
    constructor() public ERC20("Juice Finance", "JUICE") {
        // Mints 1 JUICE to contract creator for initial pool setup
        _mint(msg.sender, 1 ether);   
    }

    function _getJuicePrice() internal view returns (uint256 _juicePrice) {
        try IOracle(juiceOracle).consult(address(this), 1e18) returns (uint144 _price) {
            return uint256(_price);
        } catch {
            revert("Juice: failed to fetch JUICE price from Oracle");
        }
    }

    function setJuiceOracle(address _juiceOracle) public onlyOperator {
        require(_juiceOracle != address(0), "oracle address cannot be 0 address");
        juiceOracle = _juiceOracle;
    }

    /**
     * @notice Operator mints JUICE to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of JUICE to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(
        address _genesisPool,
        address _juicePool,
        address _airdropWallet
    ) external onlyOperator {
        require(!rewardPoolDistributed, "only can distribute once");
        require(_genesisPool != address(0), "!_genesisPool");
        require(_juicePool != address(0), "!_juicePool");
        require(_airdropWallet != address(0), "!_airdropWallet");
        rewardPoolDistributed = true;
        _mint(_genesisPool, INITIAL_GENESIS_POOL_DISTRIBUTION);
        _mint(_juicePool, INITIAL_GRAPE_POOL_DISTRIBUTION);
        _mint(_airdropWallet, INITIAL_AIRDROP_WALLET_DISTRIBUTION);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}

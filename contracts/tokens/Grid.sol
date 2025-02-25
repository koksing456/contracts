// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../treasury/Treasury.sol";
import "../account/Administrator.sol";

/// @title GRID is the main token/currency contract for CryptoGrid game.
/// @notice GRID will facilitate player based transactions like selling their GPUs/CPUs./ASICs and land on the marketplace. It'll also be used to buy/rent land from the game where the tokens will be burned to ensure it will be sustainable.
/// @dev 750 million hard cap for the GRID token / 25 million tokens minted on contract deployment
contract Grid is Initializable, ERC20CappedUpgradeable {
	uint256 public constant MAXIMUM_SUPPLY = 750 * 1e24;
	uint256 public constant INITIAL_SUPPLY = 25 * 1e24;
	uint256 public constant INITIAL_TREASURY = 25 * 1e23;

	// token holders / spenders
	// address public marketing; // initial 10% allocation to marketing to gather new players to the game (5 year based schedule)

	// administrators that can handle grid token allocations
	// future: implement voting triad (or other governance option)
	Administrators public gridAdmin;

	// initial supply 10% allocation to treasury multi-sig to fund our operation costs and hire staff
	Treasury public treasury;

	// address public liquidityPool; // initial supply 30% allocation to liquidity pool on DEX like sushiswap
	// address public developmentSpender; // initial supply 25% approval to developer multi-sig wallet to fund development of the game
	// address public incentivesSpender; // initial supply 25% approval for incentives for players to stake their tokens into sushiswap farm and ensure stability of price

	/// @notice GRID contract startup
	/// @dev Name: CryptoGrid,  Symbol: GRID, Decimals: 18
	function initialize(address _admin2, address _admin3) external initializer {
		__ERC20_init("CryptoGrid", "GRID");
		__ERC20Capped_init_unchained(MAXIMUM_SUPPLY);

    // initial minting
		_mint(msg.sender, INITIAL_SUPPLY);

    // define initial admins
    address[3] memory initAdmin;
    initAdmin[0] = msg.sender;
    initAdmin[1] = _admin2;
    initAdmin[2] = _admin3;

    // set grid administrators
		gridAdmin = new Administrators(initAdmin);

    // define treasury contract mapping to grid token and treasury admins (same as grid)
    treasury = new Treasury(address(this), initAdmin);
    approve(msg.sender, INITIAL_SUPPLY);
    approve(address(this), INITIAL_SUPPLY);
    // transferFrom(address(this), address(treasury), INITIAL_TREASURY);
    require(transfer(address(treasury), INITIAL_TREASURY), 'Issues with initial treasury transfer');
    // initiateTreasuryFunds();

	}

	/// @notice define token contract administrators
	/// @dev setup administrator in a way that only one of the 3 admins can perform token actions
	/// @param _admin1 1st administrator
	/// @param _admin2 2nd administrator
	/// @param _admin3 3rd administrator
	function setGridAdminstrators(
		address _admin1,
		address _admin2,
		address _admin3
	) internal {
		// allow first call to anybody: contract creator + 2 admins
		// prevent 2nd call onwards if the caller is not admin
		if (gridAdmin.adminsAreDefined()) {
			require(gridAdmin.isAdminCaller(msg.sender), "Grid: must be token administrator");
		}
		address[3] memory _admin;
		_admin[0] = _admin1;
		_admin[1] = _admin2;
		_admin[2] = _admin3;
		gridAdmin.setAdminstrators(_admin);
	}

	/// @notice Ensure that administrators are set
	/// @dev Only allow function call if administrators are defined
	modifier definedAdmins() {
		require(gridAdmin.adminsAreDefined(), "Grid: administrators must be defined");
		_;
	}

	/// @notice Only token administrators
	/// @dev Only token admins can proceed to the next step
	modifier onlyAdmin() {
		require(gridAdmin.isAdminCaller(msg.sender), "Grid: must be token administrator");
		_;
	}

  function getTreasuryTokens() public view returns(uint256) {
    return treasury.getTokenBalance();
  }

	/// @notice Allocate token funds to treasury contract
	/// @dev Define a given amount to be transfered to treasury
	/// @param _amount amount to transfer
	function allocateTreasuryFunds(uint256 _amount) public onlyAdmin definedAdmins {
		treasury.depositToken(_amount);
	}

}

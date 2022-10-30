// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./base64.sol";

contract Astrobirdz is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter public tokenIds;

    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _marketPlaceAddress;
    address private _tokenAddress;
    string private _eggUri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/video_2022-04-15_14-40-52.mp4";

    // Rarity Classes
    enum Class {
    Common,
    Uncommon,
    Rare,
    Legendary
  }
  

    uint private _seed;

    
   uint8 private _burnPercent = 25;
    uint8 constant NUM_CLASSES = 4;
    // Starts From 0
    uint8 private constant UNIQUENFTS = 6;
   uint8 public _commonMatureAPY = 10;
   uint8 public _commonMaxMatureAPY = 15;
   uint8 public _unCommonMatureAPY = 15;
   uint8 public _unCommonMaxMatureAPY = 20;
   uint8 public _rareMatureAPY = 25;
   uint8 public _rareMaxMatureAPY = 30;
   uint8 public _legendaryMatureAPY = 50;
   uint8 public _legendaryMaxMatureAPY = 70;
   uint public commonMatureCost = 30000 * 10**18;
   uint public commonMaxMatureCost = 50000 * 10**18;
   uint public unCommonMatureCost = 50000 * 10**18;
   uint public unCommonMaxMatureCost = 70000 * 10**18;
   uint public rareMatureCost = 100000 * 10**18;
   uint public rareMaxMatureCost = 150000 * 10**18;
   uint public legendaryMatureCost = 150000 * 10**18;
   uint public legendaryMaxMatureCost = 200000 * 10**18;
   

    struct Attributes {
        string uniqueAttribute;
        uint8 speice;
        uint8 rarity;
        uint8 cannon;
        uint8 laser;
        uint8 bomb;
        uint8 shields;
        uint8 armour;
        uint8 health;
        //check if attributes are setted
        bool set;
    }

    struct EggHatch {
        uint hatchTime;
        bool hasAlreadyHatched;
        bool isHatching;
    }

    mapping(uint=>Attributes) private _tokenIdToAttributes;
    mapping(uint=>EggHatch) private _eggHatch;
    mapping(uint=>string) private _nftToUniqueAttr;
    

    // baby.mature,max mature bird level
    mapping(uint=>uint) public level;
    mapping(uint=>uint) private _rewardTime;

    event EggMinted(address indexed, uint indexed);
    event EggLocked(uint indexed, uint indexed);
    event EggRarity(uint indexed, uint indexed);
    event UpgradeMature(uint indexed, uint indexed);
    event UpgradeMaxMature(uint indexed, uint indexed);
    event Reward(uint indexed, uint indexed, uint indexed);

    constructor(address tokenAddress, address _marketAddress) ERC721("Astrobirdz", "ABZ") {
        _tokenAddress = tokenAddress;
        _marketPlaceAddress = _marketAddress;
    }

    function matureBirdCost(uint _tokenId) external view returns(uint) {
        require(level[_tokenId] == 1, "not baby bird, only baby bird can be upgraded");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMatureCost;
        } else  if(rar == 2) {
            cost = rareMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMatureCost;
        } 
        return cost;
    }

    function maxMatureBirdCost(uint _tokenId) external view returns(uint) {
        require(level[_tokenId] == 2, "not mature bird, only mature bird can be upgraded");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMaxMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMaxMatureCost;
        } else  if(rar == 2) {
            cost = rareMaxMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMaxMatureCost;
        } 
        return cost;
    }

    function getRarity(uint _tokenId) external view returns(string memory) {
        require(level[_tokenId] > 0, "not hatched yet");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        if(rar == 0) {
            return "Common";
        } else if(rar == 1) {
            return "UnCommon";
        } else if(rar == 2) {
            return "Rare";
        } else if(rar == 3) {
            return "Legendary";
        }
        return "Common";
    } 

    function changeCommonAPY(uint8 b, uint8 c) external onlyOwner {
        _commonMatureAPY = b;
        _commonMaxMatureAPY = c;   
    } 

    
    function changeUnCommonAPY(uint8 b, uint8 c) external onlyOwner {
        _unCommonMatureAPY = b;
        _unCommonMaxMatureAPY = c;   
    } 

    
    function changeRareAPY(uint8 b, uint8 c) external onlyOwner {
        _rareMatureAPY = b;
        _rareMaxMatureAPY = c;   
    } 

    
    function changeLegendaryAPY(uint8 b, uint8 c) external onlyOwner {
        _legendaryMatureAPY = b;
        _legendaryMaxMatureAPY = c;   
    } 

    function changeCost(uint a, uint b, uint c, uint d, uint e, uint f, uint g, uint h) external onlyOwner {
        commonMatureCost = a;
        commonMaxMatureCost = b;
        unCommonMatureCost = c;
        unCommonMaxMatureCost = d;
        rareMatureCost = e;
        rareMaxMatureCost = f;
        legendaryMatureCost = g;
        legendaryMaxMatureCost = h;
    }

     function setSeed(uint _s) external onlyOwner {
        _seed = _s;
    } 

    function changeTokenAddress(address _addr) external onlyOwner {
        _tokenAddress = _addr;
    }

    function mintEgg(uint tNumber)
        public
        onlyOwner
    {
        for(uint i = 0; i<tNumber; i++) {
             tokenIds.increment();

             uint256 newItemId = tokenIds.current();
            _mint(msg.sender, newItemId);
            setApprovalForAll(_marketPlaceAddress, true);

            level[newItemId] = 0;
        }
       emit EggMinted(msg.sender, tNumber);
    }


    function lockInIncubator(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");
        EggHatch memory eggHatch = _eggHatch[_tokenId];
        require(eggHatch.hasAlreadyHatched == false, "already hatched");

        eggHatch.isHatching = true;
        eggHatch.hasAlreadyHatched = true;
        eggHatch.hatchTime = block.timestamp + 7 days;
         _eggHatch[_tokenId] = eggHatch;
        emit EggLocked(_tokenId, eggHatch.hatchTime);
    }

    function hatchRemainingTime(uint _tokenId) public view returns(uint) {
         EggHatch memory eggHatch = _eggHatch[_tokenId];
         if(eggHatch.hatchTime <= block.timestamp) {
             return 0;
         }
         uint remainTime = eggHatch.hatchTime - block.timestamp;
         return remainTime;
    }

    function hatchEgg(uint _tokenId) public {
    require(ownerOf(_tokenId) == msg.sender, "Not Owner");
    EggHatch memory eggHatch = _eggHatch[_tokenId];
    require(eggHatch.isHatching == true, "Not Hatching");
    require(eggHatch.hatchTime <= block.timestamp,"Hatch Time Hasn't Passed Yet");
    
    eggHatch.isHatching = false;
    _eggHatch[_tokenId] = eggHatch;

    level[_tokenId] = 1;

    Attributes memory _attr = selectRandomNftWithAttributes(_tokenId);
    _attr = selectAttrbiutes(_attr);
    _tokenIdToAttributes[_tokenId] = _attr;
    emit EggRarity(_tokenId, _attr.rarity);
    }

    function selectRandomNftWithAttributes(uint _tokenId) internal returns(Attributes memory) {
        uint _rand = randomUniqueNft();
        Attributes memory _attr = _tokenIdToAttributes[_tokenId];
        if(_rand == 0) {
            _attr.uniqueAttribute = "Powerful Sharp Feet";
            _attr.speice = 0;
        } else if(_rand == 1) {
            _attr.uniqueAttribute = "Powerful Beak";
            _attr.speice = 1;
        } else if(_rand == 2) {
            _attr.uniqueAttribute = "Speed";
            _attr.speice = 2;
        } else if(_rand == 3) {
            _attr.uniqueAttribute = "Camoflauge";
            _attr.speice = 3;
        } else if(_rand == 4) {
            _attr.uniqueAttribute = "Strength";
            _attr.speice = 4;
        } else if(_rand == 5) {
            _attr.uniqueAttribute = "Intelligence";
            _attr.speice = 5;
        } 

        return _attr;
    }

     function randomUniqueNft() internal view returns (uint) {
        uint rand =  uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed)));
        return rand % UNIQUENFTS;
    }

    function randRarity(uint _randomNum, uint _num) internal view returns(uint8) {
         uint rand =  uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed, _randomNum))) % _num;
         return uint8(rand);
    }


    function randomNumProb() internal view returns(Class) {
        uint rand =  uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed))) % 100;
        uint[] memory _classProbabilities = new uint[](4);
        _classProbabilities[0] = 68;
        _classProbabilities[1] = 20;
        _classProbabilities[2] = 10;
        _classProbabilities[3] = 2;
        
         // Start at top class (length - 1)
        // skip common (0), we default to it
        for (uint i = _classProbabilities.length - 1; i > 0; i--) {
            uint probability = _classProbabilities[i];
            if(rand < probability) {
                return Class(i);
            } else {
                rand = rand - probability;
            }
        }

        return Class.Common; 
    }

    function selectAttrbiutes(Attributes memory attr) internal view returns(Attributes memory){
        Class _class = randomNumProb();
        
        
        if(_class == Class.Common) {
            
            attr.rarity = 0;
            attr.cannon = randRarity(230, 34);
            attr.laser = randRarity(10230, 34);
            attr.bomb = randRarity(12200, 34);
            attr.shields = randRarity(10560, 34);
            attr.armour = randRarity(10740, 34);
            attr.health = randRarity(10450, 34);
            attr.set = true;
            return attr;

        } else if(_class == Class.Uncommon) {
            
            attr.rarity = 1;
           attr.cannon = randRarity(230, 15) + 35;
            attr.laser = randRarity(10230, 15) + 35;
            attr.bomb = randRarity(12200, 15) + 35;
            attr.shields = randRarity(10560, 15) + 35;
            attr.armour = randRarity(10740, 15) + 35;
            attr.health = randRarity(10450, 15) + 35;
            attr.set = true;
            return attr;

        } else if(_class == Class.Rare) {

            attr.rarity = 2;
            attr.cannon = randRarity(230, 25) + 50;
            attr.laser = randRarity(10230, 25) + 50;
            attr.bomb = randRarity(12200, 25) + 50;
            attr.shields = randRarity(10560, 25) + 50;
            attr.armour = randRarity(10740, 25) + 50;
            attr.health = randRarity(10450, 25) + 50;
            attr.set = true;
            return attr;

        } else if(_class == Class.Legendary) {

            attr.rarity = 3;
            attr.cannon = randRarity(230, 25) + 75;
            attr.laser = randRarity(10230, 25) + 75;
            attr.bomb = randRarity(12200, 25) + 75;
            attr.shields = randRarity(10560, 25) + 75;
            attr.armour = randRarity(10740, 25) + 75;
            attr.health = randRarity(10450, 25) + 75;
            attr.set = true;
            return attr;

        }

    }

    function upgradeToMatureBird(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(level[_tokenId] == 1, "not baby bird, only baby bird can be upgraded");
        IERC20 token = IERC20(_tokenAddress);
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMatureCost;
        } else  if(rar == 2) {
            cost = rareMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMaxMatureCost;
        } 
        uint balance = token.balanceOf(msg.sender);
        require(balance >= cost, "low balance");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= cost, "Check the token allowance");
        uint burnAmount = cost.mul(_burnPercent).div(100);
        token.transferFrom(msg.sender, address(this), cost);
        token.transfer(_burnAddress, burnAmount);
        level[_tokenId] = 2;
        _rewardTime[_tokenId] = block.timestamp;
        emit UpgradeMature(_tokenId, cost);
    }

    function upgradeToMaxMatureBird(uint _tokenId) external {
         require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(level[_tokenId] == 2, "not mature bird, only mature bird can be upgraded");
        IERC20 token = IERC20(_tokenAddress);
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMaxMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMaxMatureCost;
        } else  if(rar == 2) {
            cost = rareMaxMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMaxMatureCost;
        } 
        uint balance = token.balanceOf(msg.sender);
        require(balance >= cost, "low balance");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= cost, "Check the token allowance");
        uint burnAmount = cost.mul(_burnPercent).div(100);
        uint remainingTokens = cost - burnAmount;
        token.transferFrom(msg.sender, address(this), remainingTokens);
        token.transfer(_burnAddress, burnAmount);
        level[_tokenId] = 3;
        withdrawReward(_tokenId);
        emit UpgradeMaxMature(_tokenId, cost);
    }


    function withdrawReward(uint _tokenId) public returns(uint) {
        require(ownerOf(_tokenId) == msg.sender, "not Owner");
        require(level[_tokenId] > 1, "only mature and max mature bird can withdraw");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint per;
        if(attr.rarity == 0) {
            if(level[_tokenId] == 2) {
                per = _commonMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _commonMaxMatureAPY;
            }
        } else if(attr.rarity == 1) {
           if(level[_tokenId] == 2) {
                per = _unCommonMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _unCommonMaxMatureAPY;
            }
        } else if(attr.rarity == 2) {
             if(level[_tokenId] == 2) {
                per = _rareMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _rareMaxMatureAPY;
            }
        } else if(attr.rarity == 3) {
            if(level[_tokenId] == 2) {
                per = _legendaryMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _legendaryMaxMatureAPY;
            }
        }
        per = per * 1000000000;
        uint perInSec = per / 31536000;
        uint bal = IERC20(_tokenAddress).balanceOf(address(this));
        bal = bal.div(1000000000);
        uint r =  bal.mul(perInSec).div(100);
        uint t = (block.timestamp).sub(_rewardTime[_tokenId]);
        r = r.mul(t);
        IERC20(_tokenAddress).transfer(msg.sender, r);
        _rewardTime[_tokenId] = block.timestamp;
        emit Reward(_tokenId, t, r);
        return r;
    }

     function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

   

     function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
         if(_tokenIdToAttributes[tokenId].set == false) {
             string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', uint2str(tokenId), '",',
                    '"image_data": "', _eggUri, '",',
                    '"description": "', 'An Egg"',
                    '}'   
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
        }

         string memory uri = "";

         if(level[tokenId] == 1) {
             if(_tokenIdToAttributes[tokenId].speice == 0) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/baby-eagle-complete.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 1) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Cockatiel.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 2) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Sparrow.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 3) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Cardinal.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 4) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Vulture.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 5) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Swan.mp4";
             }
         } else if(level[tokenId] == 2 || level[tokenId] == 3) {
              if(_tokenIdToAttributes[tokenId].speice == 0) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Golden%20Eagle.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 1) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Cockateil.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 2) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Sparrow.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 3) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Cardinal.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 4) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Vulture.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 5) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Swan.mp4";
             }
         }

         string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', uint2str(tokenId), '",',
                    '"image_data": "', uri, '",',
                    // '"description": "', 'Bird"', ',',
                    '"attributes": [{"trait_type": "Cannon", "value": "', uint2str(_tokenIdToAttributes[tokenId].cannon), '"},',
                    '{"trait_type": "Attribute", "value": "', _tokenIdToAttributes[tokenId].uniqueAttribute, '"},',
                    '{"trait_type": "Laser", "value": "', uint2str(_tokenIdToAttributes[tokenId].laser), '"},',
                    '{"trait_type": "Bomb", "value": "', uint2str(_tokenIdToAttributes[tokenId].bomb), '"},',
                    '{"trait_type": "Shields", "value": "', uint2str(_tokenIdToAttributes[tokenId].shields), '"},',
                    '{"trait_type": "Armour", "value": "', uint2str(_tokenIdToAttributes[tokenId].armour), '"},',
                    '{"trait_type": "Health", "value": "', uint2str(_tokenIdToAttributes[tokenId].health), '"}',
                    ']}'
                    
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
     }


}

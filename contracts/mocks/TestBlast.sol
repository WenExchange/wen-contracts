//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IBlast{
    // claim yield
    function claimYield(address contractAddress, address recipientOfYield, uint256 amount) external returns (uint256);
    function claimAllYield(address contractAddress, address recipientOfYield) external returns (uint256);
}



contract TestBlast is
   IBlast
{
    function claimYield(address contractAddress, address recipientOfYield, uint256 amount) override external returns (uint256) {
          require(address(this).balance >= amount, "Insufficient balance");
            payable(contractAddress).transfer(amount);
    }


    function claimAllYield(address contractAddress, address recipientOfYield) override external returns (uint256){
     require(address(this).balance >= 0, "Insufficient balance");
     payable(recipientOfYield).transfer(address(this).balance);
    }

     // 컨트랙트가 이더를 받을 수 있도록 하는 fallback 함수
    fallback() external payable {}
    receive() external payable {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract ZeroCouponBond {
    
    string public name="ZeroCouponBond";
    string public symbol="ZCB";
    
    struct InvestorBondData{
        address investor_address;
        uint256 total_face_value;
        uint256 total_bond_purchased;
        uint256 date_of_issue;
        uint256 date_of_maturity;
        uint256 total_return;
     
    }
    
    struct InvestorExchange{
        address investor_for_sell;
        address investor_for_buy;
        uint256 bond_exchange;
        uint256 wei_exchange;
        uint256 new_return;
    }
    
    struct PaymentHistory{
        uint256 amount_paid;
        uint256 date_of_payment;
        address investor_address;
    }
    
    
    event show(uint num_of_bond,uint256 total_face_value,uint256 date_of_issue,uint256 date_of_maturity,uint256 total_return);
    event show2(uint256 amount_paid,uint256 date_of_payment,address investor_address);
    event show3(uint256 wei_exchange);
    
    mapping(address=>InvestorExchange) investors_info_temp; // mapping for bond exchange information
    mapping(address=>InvestorBondData) public investors_info;  // mapping for investors who buy the bonds at at initial stage.(from issuer) 
    mapping(address=>InvestorBondData) public n_time_investors_info; // mapping for new investors who buy bond from other investor(resell)
    mapping(address=>PaymentHistory) public payment_info; // mapping of investors who has been paid the total return
     
    address[] public investorlist; // investors list
    address[] public investorlist_paid; // investors list who has been paid the total return
    

    // variables//
    uint256 return_at_maturity;
    uint256 total_num_bond;
    uint256 total_eth_for_bond;
    uint256 wei_for_each_token;
    uint256 eth_per_token;
    
    uint256 public remaining_bond;
    uint256 in_seconds; // used in  this simulation
    uint256 in_year; // not used in simulation, but can be used in real life
    uint256 sum_of_transferred_coupon;
    uint256 coupon_rate;
    uint256 term_in_year;
    uint256 num_investor;
    uint _decimal=18;
    
    uint256 purchased_bond;
    uint256 bond_purchasing_price;
    uint256 payment_return;
    uint256 payment;
    uint256 portion_of_return;
   
    address public _issuer; 
    address _investor;
    address payable Issure;
    
    
    constructor(uint256 coupon_rate_, uint256 total_num_bond_,uint256 in_second_, uint256 eth_per_token_) payable{
    
        coupon_rate=coupon_rate_;
        total_num_bond=total_num_bond_;
        coupon_rate=coupon_rate_;
        in_seconds=in_second_;
        remaining_bond=total_num_bond;
        
        wei_for_each_token=multiply(eth_per_token_,uint256(10),_decimal);
        total_eth_for_bond=eth_per_token;
        
       _issuer=msg.sender;
        Issure=payable(_issuer);
        
        //term_in_year=term_in_year_;// commented out due to simulation purpose
        //num_investor=0;
    }
    
    
    receive() external payable{} //for receving ether
    
    fallback() external payable{} // for receving ether
    
    // for checking total bond quantitiy
    function total_supply() public view returns(uint){
        return total_num_bond;
    }
    
    
    
    // for investment from investor
    function investment(uint256 purchase_bond) public payable returns(bool) {
        
        bond_purchasing_price= multiply(purchase_bond,wei_for_each_token,uint256(1));

        require(remaining_bond>=purchase_bond,"Do not have sufficient bond");
        remaining_bond-=purchase_bond;
       
        require(msg.value==bond_purchasing_price,"Did not found required amount");
        return_at_maturity=ZCB_calculation(bond_purchasing_price,coupon_rate,in_seconds);
        
        InvestorBondData storage investor= investors_info[msg.sender]; 
        investor.investor_address=msg.sender;
        investor.total_bond_purchased=purchase_bond;
        investor.total_face_value+=bond_purchasing_price;
        investor.date_of_issue=block.timestamp;
        investor.date_of_maturity= block.timestamp+in_seconds;
        
        investor.total_return=return_at_maturity;
        investorlist.push(msg.sender);
        Issure.transfer(msg.value);
        
        //uint256 value=365*term_in_year;
        //start_date=block.timestamp;
        // investor.date_of_maturity=(60 seconds*term_in_year)+block.timestamp;
        
        emit show(purchase_bond,bond_purchasing_price,block.timestamp,block.timestamp+in_seconds,investor.total_return); 
        return true;
    }
     
     // return future value to investor after maturity, who bought bonds from issuer 
     function return_to_old_investor (address investor_add) public payable the_issuer returns(bool) {
         
        PaymentHistory storage investor_return= payment_info[investor_add];
        InvestorBondData storage investor= investors_info[investor_add];
        
        payment=investor.total_return;
        
        //uint256 date= investor.date_of_maturity;
        require(block.timestamp>=investor.date_of_maturity, "Didn't reach the maturity yet");
        investor_return.amount_paid=payment;
        investor_return.date_of_payment=block.timestamp;
        address payable investor_pay=payable(investor_add);
        require(msg.value==investor.total_return," No enough");
        investor_pay.transfer(msg.value);
        investor.total_bond_purchased=0;
        investorlist_paid.push(investor_add);
        emit show2(investor_return.amount_paid,investor.date_of_maturity,investor_add);
        return true;
     }
     
     
     // return future value to investor after maturity who bought bonds from other investors
     function return_to_new_investor (address investor_add) public payable the_issuer returns(bool) {
         
        PaymentHistory storage investor_return= payment_info[investor_add];
        InvestorBondData storage investor= n_time_investors_info[investor_add];
        
        payment=investor.total_return;
        
        require(block.timestamp>=investor.date_of_maturity, "Didn't reach the maturity yet");
        investor_return.amount_paid=payment;
        investor_return.date_of_payment=block.timestamp;
        address payable investor_pay=payable(investor_add);
        require(msg.value==investor.total_return," No enough");
        investor_pay.transfer(msg.value);
        investor.total_bond_purchased=0;
        investorlist_paid.push(investor_add);
        emit show2(investor_return.amount_paid,investor.date_of_maturity,investor_add);
        return true;
     }
     
    // to check the bond quantity of investors who bought bonds from issuer
    function balanceOf(address account_add) public view returns(uint){
        InvestorBondData storage investor = investors_info[account_add];
        
        return investor.total_bond_purchased;
    }
    
    // to check the bond quantity of investors who bought bonds from other investor
    function balanceOf_new(address account_add) public view returns(uint){
        InvestorBondData storage investor = n_time_investors_info[account_add];
        
        return investor.total_bond_purchased;
    }
    
    // for math multiplications
    function multiply(uint a, uint b, uint c) internal pure returns(uint256){
        if (a==0){
            return 0;
        }
        else {
            uint256 d=a*(b**c);
            return d;
        }
    }

    // for math additions
    function additive(uint256 a,uint256 b) internal pure returns(uint256){
        uint256 c= a+b;
        return c;
    }

    //for math divisions
    function division(uint256 a, uint256 b) internal pure returns(uint256){
        uint256 c= a/b;
        return c;
    }
    
    
    // for calculating future value of a zero coupon bond
    function ZCB_calculation(uint256 a, uint256 b,uint256 d) internal pure returns(uint256){
            
            uint256 c= (a*((100+b)**d))/(100**d);
            return c;
     }
    
    modifier the_issuer(){
        require(msg.sender==_issuer,"Only for Issure to use");
        _;
    }
   
   
     ////////////////////////////////////////////////////////////////////////////////////////////////


    // related with ERC20 token convention 
   //1st part, investor will approve quantity of bonds for new investor
    function approve_new_investor(address old_inv_add,address new_inv_add,uint256 bond_to_sell,uint256 time_left) public returns(bool){
        InvestorBondData storage investor=investors_info[old_inv_add];
        InvestorExchange storage temp_investor=investors_info_temp[new_inv_add];
       
        require(investor.total_bond_purchased>=bond_to_sell, "You did not buy this much bond");    
        
        uint256 used_time=in_seconds-time_left;  //// need to give bigger value maturity time
        uint256 left_price=multiply(bond_to_sell,wei_for_each_token,uint256(1));
        
        temp_investor.wei_exchange = ZCB_calculation(left_price,coupon_rate,used_time); 
        temp_investor.bond_exchange=bond_to_sell;
        temp_investor.investor_for_sell=msg.sender;
        temp_investor.investor_for_buy=new_inv_add;
        emit show3(temp_investor.wei_exchange);
        return true;
        
    }
    
       // 2rd part, new investor can check quantity of bond allocated for him/her from  investor who want to sell
   function allowance(address old_inv_add,address new_inv_add)public view returns(uint256,uint256){
        InvestorExchange storage temp_investor=investors_info_temp[new_inv_add];
        require(temp_investor.investor_for_sell==old_inv_add,"no Match found");
        return (temp_investor.bond_exchange,temp_investor.wei_exchange);
   }
    
    // 3rd part, new investor will approve the total price of bond for old investor  
     function approve_old_investor(address new_inv_add, uint256 amount) public returns(bool ){
        
        InvestorExchange storage new_investor=investors_info_temp[new_inv_add];
        new_investor.wei_exchange=amount;
        emit show3(new_investor.wei_exchange);
        return true;
        
    }
   
    // 4th part new investor will exchange bond for ether with old investor, this function should called buy new investor
    function transfer_bond(address old_inv_add,address new_inv_add,uint256 bond_amount,uint256 time_left) public payable {

        InvestorBondData storage investor=investors_info[old_inv_add];
        InvestorBondData storage investor_new=n_time_investors_info[new_inv_add];
        InvestorExchange storage new_investor=investors_info_temp[new_inv_add];
        
        if(approve_new_investor(old_inv_add,new_inv_add,bond_amount,time_left)==true && approve_old_investor(old_inv_add,new_investor.wei_exchange)==true){
            address payable receiver=payable(old_inv_add);
            require(msg.value==new_investor.wei_exchange,"Transacted amount is not sufficient");/////
            receiver.transfer(msg.value);
            uint256 used_time=in_seconds-time_left;  //// need to give bigger value maturity time in term of year
            uint256 left_price=multiply(bond_amount,wei_for_each_token,uint256(1));
            investor.total_bond_purchased-=bond_amount;
            if(investor.total_bond_purchased==0){
                investor.total_return=0;    
            }
            else{
            
            investor.total_face_value=multiply(investor.total_bond_purchased,wei_for_each_token,uint256(1)); //decreased face value of old investor
            uint256 decreased_face_value=multiply(investor.total_bond_purchased,wei_for_each_token,uint256(1));
            investor.total_return= ZCB_calculation(decreased_face_value,coupon_rate,in_seconds);
            investorlist.push(msg.sender);
            }
            
            investor_new.total_bond_purchased=bond_amount;
            investor_new.total_return=ZCB_calculation(left_price,coupon_rate,in_seconds);
            investor_new.date_of_issue=investor.date_of_issue;
            investor_new.date_of_maturity=investor.date_of_maturity;
            investor_new.investor_address=new_inv_add;
            investor_new.total_face_value=ZCB_calculation(left_price,coupon_rate,used_time);
            
            emit show(investor_new.total_bond_purchased,investor_new.total_face_value,investor_new.date_of_issue,investor_new.date_of_maturity,investor_new.total_return);
            emit show(investor.total_bond_purchased,investor.total_face_value,investor.date_of_issue,investor.date_of_maturity,investor.total_return);
            
        }
    }
}
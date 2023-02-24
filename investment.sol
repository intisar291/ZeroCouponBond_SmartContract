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

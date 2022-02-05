//SPDX-License-Identifier:GPL-3.0

pragma solidity 0.8.0;

contract crowdfunding{

    mapping(address=>uint)public contributers;
    address public admin;
    uint public noofcontributers;
    uint public raisedamount;
    uint public minimumcontributions;
    uint public goal;
    uint public deadline;

    // events to emit
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    constructor(uint _goal,uint _deadline){
        admin=msg.sender;
        goal=_goal;
        deadline=_deadline+block.timestamp;
        minimumcontributions=100 wei;
    }

    function contribute()public payable {
        require(block.timestamp<deadline,"The deadline has passed");
        require(msg.value>=minimumcontributions,"Minimum contribution not met");

        if(contributers[msg.sender]==0){
            noofcontributers++;
        }
        contributers[msg.sender]+=msg.value;
        raisedamount+=msg.value;
        emit ContributeEvent(msg.sender, msg.value);
    }

    receive()payable external{
        contribute();
    }

    function getbalance()public view returns(uint){
        return address(this).balance;
    }

    //refund if goal was not reached within the deadline
    function getrefund()public{
        require(block.timestamp>=deadline && raisedamount<goal);
        require(contributers[msg.sender]>0);

        address payable recipient=payable(msg.sender);
        uint value=contributers[msg.sender];
        recipient.transfer(value);
    }

    // Spending Request
    struct Request{
        string des;
        address payable recipient;
        uint value;
        bool completed;
        uint noofvoters;
        mapping(address=>bool)voters;
    }

    // mapping of spending requests
    mapping(uint=>Request)public requests;
    uint public numrequest;

    modifier onlyowner(){
        require(msg.sender==admin,"You are not the owner");
        _;
    }

    

    

    function createspendingrequest(string memory _des,address payable _recipient,uint _value)public onlyowner{

        Request storage newrequest=requests[numrequest];
        numrequest;

        newrequest.des=_des;
        newrequest.recipient=_recipient;
        newrequest.value=_value;
        newrequest.completed=false;
        newrequest.noofvoters=0;
        emit CreateRequestEvent(_des, _recipient, _value);

    }

    function voterequest(uint _requestno)public{
        require(contributers[msg.sender]>0,"You must be a contributer");
        Request storage thisrequest=requests[_requestno];
        require(thisrequest.voters[msg.sender] == false,"Already Voted");
        thisrequest.voters[msg.sender]=true;
        thisrequest.noofvoters++;
    }


    function makepayment(uint _requestno)public onlyowner{
        require(raisedamount>=goal);
        Request storage thisrequest=requests[_requestno];
        require(thisrequest.completed==false,"The request has already completed");
        require(thisrequest.noofvoters>noofcontributers/2,"Needs more than 50%");

        thisrequest.recipient.transfer(thisrequest.value);
        thisrequest.completed=true;
        emit MakePaymentEvent(thisrequest.recipient, thisrequest.value);
    }





}
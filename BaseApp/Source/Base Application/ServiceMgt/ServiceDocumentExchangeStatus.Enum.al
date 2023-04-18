enum 712 "Service Document Exchange Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Not Sent") { Caption = 'Not Sent'; }
    value(1; "Sent to Document Exchange Service") { Caption = 'Sent to Document Exchange Service'; }
    value(2; "Delivered to Recipient") { Caption = 'Delivered to Recipient'; }
    value(3; "Delivery Failed") { Caption = 'Delivery Failed'; }
    value(4; "Pending Connection to Recipient") { Caption = 'Pending Connection to Recipient'; }
}
query 760 "Trailing Sales Order Qry"
{
    Caption = 'Trailing Sales Order Qry';

    elements
    {
        dataitem(Sales_Header; "Sales Header")
        {
            DataItemTableFilter = "Document Type" = CONST(Order);
            filter(ShipmentDate; "Shipment Date")
            {
            }
            filter(Status; Status)
            {
            }
            filter(DocumentDate; "Document Date")
            {
            }
            column(CurrencyCode; "Currency Code")
            {
            }
            dataitem(Sales_Line; "Sales Line")
            {
                DataItemLink = "Document Type" = Sales_Header."Document Type", "Document No." = Sales_Header."No.";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = Amount = FILTER(<> 0);
                column(Amount; Amount)
                {
                    Method = Sum;
                }
            }
        }
    }
}


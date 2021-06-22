query 5002 "Locations from items Purch"
{
    Caption = 'Locations from items Purch';

    elements
    {
        dataitem(Purchase_Line; "Purchase Line")
        {
            DataItemTableFilter = "Document Type" = CONST(Order), Type = CONST(Item), "Location Code" = FILTER(<> ''), "No." = FILTER(<> ''), Quantity = FILTER(<> 0);
            column(Document_No; "Document No.")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            dataitem(Location; Location)
            {
                DataItemLink = Code = Purchase_Line."Location Code";
                DataItemTableFilter = "Use As In-Transit" = CONST(false);
                column(Require_Put_away; "Require Put-away")
                {
                }
                column(Require_Receive; "Require Receive")
                {
                }
            }
        }
    }
}


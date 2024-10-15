namespace Microsoft.Inventory.Item;

using Microsoft.Manufacturing.Document;

query 9152 "My Items"
{
    Caption = 'My Items';

    elements
    {
        dataitem(My_Item; "My Item")
        {
            filter(User_ID; "User ID")
            {
            }
            column(Item_No; "Item No.")
            {
            }
            dataitem(Prod_Order_Line; "Prod. Order Line")
            {
                DataItemLink = "Item No." = My_Item."Item No.";
                filter(Date_Filter; "Date Filter")
                {
                }
                column(Status; Status)
                {
                }
                column(Remaining_Quantity; "Remaining Quantity")
                {
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
        SetRange(User_ID, UserId);
    end;
}


page 9091 "Item Planning FactBox"
{
    Caption = 'Item Details - Planning';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = Planning;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the item.';

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field("Reordering Policy"; "Reordering Policy")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the reordering policy that is used to calculate the lot size per planning period (time bucket).';
            }
            field("Reorder Point"; "Reorder Point")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a stock quantity that sets the inventory below the level that you must replenish the item.';
            }
            field("Reorder Quantity"; "Reorder Quantity")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a standard lot size quantity to be used for all order proposals.';
            }
            field("Maximum Inventory"; "Maximum Inventory")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a quantity that you want to use as a maximum inventory level.';
            }
            field("Overflow Level"; "Overflow Level")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a quantity you allow projected inventory to exceed the reorder point, before the system suggests to decrease supply orders.';
            }
            field("Time Bucket"; "Time Bucket")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a time period that defines the recurring planning horizon used with Fixed Reorder Qty. or Maximum Qty. reordering policies.';
            }
            field("Lot Accumulation Period"; "Lot Accumulation Period")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a period in which multiple demands are accumulated into one supply order when you use the Lot-for-Lot reordering policy.';
            }
            field("Rescheduling Period"; "Rescheduling Period")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a period within which any suggestion to change a supply date always consists of a Reschedule action and never a Cancel + New action.';
            }
            field("Safety Lead Time"; "Safety Lead Time")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a date formula to indicate a safety lead time that can be used as a buffer period for production and other delays.';
            }
            field("Safety Stock Quantity"; "Safety Stock Quantity")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a quantity of stock to have in inventory to protect against supply-and-demand fluctuations during replenishment lead time.';
            }
            field("Minimum Order Quantity"; "Minimum Order Quantity")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a minimum allowable quantity for an item order proposal.';
            }
            field("Maximum Order Quantity"; "Maximum Order Quantity")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a maximum allowable quantity for an item order proposal.';
            }
            field("Order Multiple"; "Order Multiple")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a parameter used by the planning system to modify the quantity of planned supply orders.';
            }
            field("Dampener Period"; "Dampener Period")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders.';
            }
            field("Dampener Quantity"; "Dampener Quantity")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies a dampener quantity to block insignificant change suggestions for an existing supply, if the change quantity is lower than the dampener quantity.';
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Item Card", Rec);
    end;
}


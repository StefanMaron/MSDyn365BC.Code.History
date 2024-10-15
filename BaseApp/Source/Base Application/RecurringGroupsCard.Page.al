page 15000300 "Recurring Groups Card"
{
    Caption = 'Recurring Groups Card';
    PageType = Card;
    SourceTable = "Recurring Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code to identify the recurring group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description to identify the recurring group.';
                }
                field("Date formula"; "Date formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the time interval between orders.';
                }
                field("Create only the latest"; "Create only the latest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to only create the latest recurring order, if the recurring group interval has been exceeded.';
                }
                field("Starting date"; "Starting date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date of the recurring group.';
                }
                field("Closing date"; "Closing date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date of the recurring group.';
                }
            }
            group(Update)
            {
                Caption = 'Update';
                field("Update Document Date"; "Update Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the document date will be updated.';
                }
                field("Document Date Formula"; "Document Date Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the document date on the order.';
                }
                field("Delivery Date Formula"; "Delivery Date Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the delivery date on the order.';
                }
                field("Update Price"; "Update Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how prices will be updated on new orders.';
                }
                field("Update Number"; "Update Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to manage the quantity specified on the original order.';
                }
            }
        }
    }

    actions
    {
    }
}


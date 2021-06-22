page 99000958 "Order Promising Setup"
{
    AdditionalSearchTerms = 'calculate delivery,capable to promise,ctp,available to promise,atp';
    ApplicationArea = OrderPromising;
    Caption = 'Order Promising Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Order Promising Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Offset (Time)"; "Offset (Time)")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the period of time to wait before issuing a new purchase order, production order, or transfer order.';
                }
                field("Order Promising Nos."; "Order Promising Nos.")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the code that identifies the number series that you select for order promising.';
                }
                field("Order Promising Template"; "Order Promising Template")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the name of the requisition worksheet template that you select for order promising.';
                }
                field("Order Promising Worksheet"; "Order Promising Worksheet")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the name of the requisition worksheet that you select for order promising.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}


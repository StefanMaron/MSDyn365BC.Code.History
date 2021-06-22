page 6635 "Return Reasons"
{
    ApplicationArea = SalesReturnOrder;
    Caption = 'Return Reasons';
    PageType = List;
    SourceTable = "Return Reason";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the description of the return reason.';
                }
                field("Default Location Code"; "Default Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the location where items that are returned for the reason in question are always placed.';
                }
                field("Inventory Value Zero"; "Inventory Value Zero")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies that items that are returned for the reason in question do not increase the inventory value.';
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
}


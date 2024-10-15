page 17390 "Staff List Archives"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Archived Staff Lists';
    CardPageID = "Staff List Archive";
    Editable = false;
    PageType = List;
    SourceTable = "Staff List Archive";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Staff List Date"; "Staff List Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Staff Positions"; "Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Out-of-Staff Positions"; "Out-of-Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("HR Manager No."; "HR Manager No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Chief Accountant No."; "Chief Accountant No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}


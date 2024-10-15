page 14918 "Payment Order Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Order Codes';
    PageType = List;
    SourceTable = "Payment Order Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Reason Document No."; "Reason Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Document Type"; "Reason Document Type")
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


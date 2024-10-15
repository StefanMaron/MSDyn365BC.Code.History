page 32000005 "Payment Method Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Method Codes';
    PageType = List;
    SourceTable = "Foreign Payment Types";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code to identify the payment term.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the terms.';
                }
                field(Banks; Banks)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank name for the payment type.';
                }
            }
        }
    }

    actions
    {
    }
}


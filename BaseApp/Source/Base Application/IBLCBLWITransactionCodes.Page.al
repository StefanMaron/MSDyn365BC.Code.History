page 2000002 "IBLC/BLWI Transaction Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'IBLC/BLWI Transaction Codes';
    PageType = List;
    SourceTable = "IBLC/BLWI Transaction Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction Code"; "Transaction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the transaction code.';
                }
            }
        }
    }

    actions
    {
    }
}


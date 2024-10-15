page 11023 "VAT Cipher Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Cipher Codes';
    PageType = List;
    SourceTable = "VAT Cipher Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT cipher code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT cipher code.';
                }
            }
        }
    }

    actions
    {
    }
}


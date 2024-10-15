page 12140 "VAT Identifier"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Identifier';
    PageType = List;
    SourceTable = "VAT Identifier";
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
                    ApplicationArea = All;
                    ToolTip = 'Specifies a VAT identifier code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the VAT identifier.';
                }
                field("Subject to VAT Plafond"; Rec."Subject to VAT Plafond")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT code is subject to a VAT exemption ceiling.';
                }
            }
        }
    }

    actions
    {
    }
}


namespace Microsoft.Bank.Setup;

page 1240 "SWIFT Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SWIFT Codes';
    PageType = List;
    SourceTable = "SWIFT Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank for the corresponding SWIFT code.';
                }
            }
        }
    }

    actions
    {
    }
}


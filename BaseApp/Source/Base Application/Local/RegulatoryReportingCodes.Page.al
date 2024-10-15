page 10607 "Regulatory Reporting Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Regulatory Reporting Codes';
    PageType = ListPlus;
    SourceTable = "Regulatory Reporting Code";
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
                    ToolTip = 'Specifies a code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
            }
        }
    }

    actions
    {
    }
}


page 10745 "Operation Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Operation Codes';
    PageType = List;
    SourceTable = "Operation Code";
    UsageCategory = Tasks;

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
                    ToolTip = 'Specifies an operation code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for an operation code.';
                }
            }
        }
    }

    actions
    {
    }
}


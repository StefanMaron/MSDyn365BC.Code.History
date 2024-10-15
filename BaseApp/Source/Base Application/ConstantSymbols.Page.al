page 11703 "Constant Symbols"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Constant Symbols';
    PageType = List;
    SourceTable = "Constant Symbol";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220002)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for a constant symbol.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the constant symbol.';
                }
            }
        }
    }

    actions
    {
    }
}


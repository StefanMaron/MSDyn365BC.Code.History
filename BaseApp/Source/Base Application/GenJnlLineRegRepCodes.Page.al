page 10608 "Gen. Jnl. Line Reg. Rep. Codes"
{
    Caption = 'Gen. Jnl. Line Reg. Rep. Codes';
    PageType = List;
    SourceTable = "Gen. Jnl. Line Reg. Rep. Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Reg. Code"; "Reg. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration code.';
                }
                field("Reg. Code Description"; "Reg. Code Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the registration code.';
                }
            }
        }
    }

    actions
    {
    }
}


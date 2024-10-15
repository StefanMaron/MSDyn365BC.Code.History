page 12101 "Interest on Arrears"
{
    Caption = 'Interest on Arrears';
    PageType = List;
    SourceTable = "Interest on Arrears";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the finance charge term code.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a starting date for each interest on arrear.';
                }
                field("Interest Rate"; Rec."Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage the program should use to calculate interest on arrear.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the interest.';
                }
            }
        }
    }

    actions
    {
    }
}


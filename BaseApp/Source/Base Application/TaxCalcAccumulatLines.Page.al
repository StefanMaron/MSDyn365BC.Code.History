page 17323 "Tax Calc. Accumulat. Lines"
{
    Caption = 'Tax Calc. Accumulat. Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Calc. Accumulation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Register No."; "Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the register number associated with the tax calculation accumulation. ';
                }
                field("Template Line Code"; "Template Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the template line code associated with the tax calculation accumulation. ';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax calculation accumulation. ';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the tax calculation accumulation. ';

                    trigger OnDrillDown()
                    begin
                        DrillDownAmount;
                    end;
                }
            }
        }
    }

    actions
    {
    }
}


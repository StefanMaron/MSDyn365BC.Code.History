page 736 "VAT Return Period FactBox"
{
    Caption = 'Additional Information';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Return Period";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(WarningText; WarningText)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Style = Unfavorable;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the warning text that is displayed for an open or overdue obligation.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        WarningText := CheckOpenOrOverdue();
    end;

    var
        WarningText: Text;
}


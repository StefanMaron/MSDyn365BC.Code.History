page 1394 "Trial Balance Setup"
{
    Caption = 'Trial Balance Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Trial Balance Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Account Schedule Name"; "Account Schedule Name")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the account schedule to use to calculate the results that display in the Trial Balance chart.';
                }
                field("Column Layout Name"; "Column Layout Name")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the column layout to use to determine how columns display in the Trial Balance chart.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}


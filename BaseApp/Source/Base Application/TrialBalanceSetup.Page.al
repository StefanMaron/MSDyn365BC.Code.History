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
            group(Step0)
            {
                Caption = '';
                group(Control1)
                {
                    InstructionalText = 'Note that the trial balance page shows a maximum of 9 rows because it is intended to show a simplified version of the G/L Trial Balance chart.';
                    ShowCaption = false;
                }
            }
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


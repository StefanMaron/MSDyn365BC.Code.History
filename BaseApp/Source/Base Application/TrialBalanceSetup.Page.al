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
                    InstructionalText = 'The Trial Balance page shows a simplified version of the Trial Balance chart. It shows the first nine rows from the account schedule, and the first two columns defined for the column layout in reverse order. The second column is on the left, and the first column is on the right. You can set the order of the columns on the Column Layouts page.';
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


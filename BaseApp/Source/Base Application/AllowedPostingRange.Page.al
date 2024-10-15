page 10819 "Allowed Posting Range"
{
    Caption = 'Allowed Posting Range';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "General Ledger Setup";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Posting Allowed From"; "Posting Allowed From")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Allowed From';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the starting date of the allowed posting range.';
                }
                field(PostingAllowedTo; CalcDate('<-1D>', "Posting Allowed To"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Allowed To';
                    Editable = false;
                    ToolTip = 'Specifies the ending date of the allowed posting range. The program automatically calculates and updates the contents of the field based on the  ending date of the last fiscal year that is not fiscally closed.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("Posting Allowed To");
    end;
}


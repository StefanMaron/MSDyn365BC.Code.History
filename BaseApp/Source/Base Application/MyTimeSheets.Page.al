page 9155 "My Time Sheets"
{
    Caption = 'My Time Sheets';
    PageType = ListPart;
    SourceTable = "My Time Sheets";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Time Sheet No."; "Time Sheet No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the time sheet.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the assignment.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the assignment.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any comments about the assignment.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    EditTimeSheet;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetTimeSheet;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(TimeSheetHeader);
    end;

    trigger OnOpenPage()
    begin
        SetRange("User ID", UserId);
    end;

    var
        TimeSheetHeader: Record "Time Sheet Header";

    local procedure GetTimeSheet()
    begin
        Clear(TimeSheetHeader);

        if TimeSheetHeader.Get("Time Sheet No.") then begin
            "Time Sheet No." := TimeSheetHeader."No.";
            "Start Date" := TimeSheetHeader."Starting Date";
            "End Date" := TimeSheetHeader."Ending Date";
            Comment := TimeSheetHeader.Comment;
        end;
    end;

    local procedure EditTimeSheet()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        TimeSheetMgt.SetTimeSheetNo("Time Sheet No.", TimeSheetLine);
        PAGE.Run(PAGE::"Time Sheet", TimeSheetLine);
    end;
}


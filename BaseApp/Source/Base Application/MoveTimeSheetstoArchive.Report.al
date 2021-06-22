report 953 "Move Time Sheets to Archive"
{
    Caption = 'Move Time Sheets to Archive';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Time Sheet Header"; "Time Sheet Header")
        {
            RequestFilterFields = "No.", "Starting Date";

            trigger OnAfterGetRecord()
            begin
                Counter := Counter + 1;
                Window.Update(1, "No.");
                Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
                TimeSheetMgt.MoveTimeSheetToArchive("Time Sheet Header");
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;
                Message(Text002, Counter);
            end;

            trigger OnPreDataItem()
            begin
                OnBeforePreDataItemTimesheetHeader("Time Sheet Header");

                CounterTotal := Count;
                Window.Open(Text001);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Window: Dialog;
        Counter: Integer;
        Text001: Label 'Moving time sheets to archive  #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 time sheets have been moved to the archive.';
        CounterTotal: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreDataItemTimesheetHeader(var TimeSheetHeader: Record "Time Sheet Header")
    begin
    end;
}


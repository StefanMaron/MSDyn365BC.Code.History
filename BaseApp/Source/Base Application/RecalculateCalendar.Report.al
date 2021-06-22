report 99001047 "Recalculate Calendar"
{
    Caption = 'Recalculate Calendar';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Calendar Entry"; "Calendar Entry")
        {
            DataItemTableView = SORTING("Capacity Type", "No.", Date, "Starting Time", "Ending Time", "Work Shift Code");
            RequestFilterFields = "Capacity Type", "No.", Date;

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "Capacity Type");
                Window.Update(2, "No.");
                Window.Update(3, Date);

                if (CalendarEntry2.Date <> 0D) and
                   (CalendarEntry2.Date <> Date)
                then
                    HandleAbsence;
                CalendarEntry2 := "Calendar Entry";
                Validate("No.");
                Validate("Ending Time");
                Modify;
            end;

            trigger OnPostDataItem()
            begin
                HandleAbsence;
                Window.Close;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000 +
                  '#1########## #2########## \' +
                  Text001);
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
        Text000: Label 'Recalculating Schedule for\\';
        Text001: Label 'For #3###### ';
        CalendarEntry2: Record "Calendar Entry";
        Window: Dialog;

    local procedure HandleAbsence()
    var
        CalAbsentEntry: Record "Calendar Absence Entry";
        CalAbsenceMgt: Codeunit "Calendar Absence Management";
    begin
        CalAbsentEntry.SetRange("Capacity Type", CalendarEntry2."Capacity Type");
        CalAbsentEntry.SetRange("No.", CalendarEntry2."No.");
        CalAbsentEntry.SetRange(Date, CalendarEntry2.Date);
        CalAbsentEntry.SetRange(Updated, false);
        while CalAbsentEntry.FindFirst do
            CalAbsenceMgt.UpdateAbsence(CalAbsentEntry);
    end;
}


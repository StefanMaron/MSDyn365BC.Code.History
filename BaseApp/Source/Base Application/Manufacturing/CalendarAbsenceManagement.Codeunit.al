codeunit 99000759 "Calendar Absence Management"
{

    trigger OnRun()
    begin
    end;

    var
        Remove: Boolean;

    procedure UpdateAbsence(var CalAbsentEntry: Record "Calendar Absence Entry")
    var
        CalendarEntry: Record "Calendar Entry";
        CalendarEntry2: Record "Calendar Entry";
        CalendarEntry3: Record "Calendar Entry";
        AbsenceStartingDateTime: DateTime;
        Finished: Boolean;
    begin
        with CalAbsentEntry do begin
            AbsenceStartingDateTime := "Starting Date-Time";
            CalendarEntry.SetCurrentKey("Capacity Type", "No.", "Starting Date-Time");
            CalendarEntry.SetRange("Capacity Type", "Capacity Type");
            CalendarEntry.SetRange("No.", "No.");
            CalendarEntry.SetFilter("Starting Date-Time", '<%1', "Ending Date-Time");
            CalendarEntry.SetFilter("Ending Date-Time", '>%1', "Starting Date-Time");
            if Remove then
                CalendarEntry.SetFilter("Absence Capacity", '>%1', 0);
            if CalendarEntry.Find('-') then
                repeat
                    Finished := false;
                    CalendarEntry2 := CalendarEntry;
                    CalendarEntry3 := CalendarEntry;
                    CalendarEntry.Delete();
                    if CalendarEntry."Starting Date-Time" < "Starting Date-Time" then begin
                        CalendarEntry2.Validate("Ending Date-Time", "Starting Date-Time");
                        CalendarEntry2.Insert();
                    end else
                        "Starting Date-Time" := CalendarEntry."Starting Date-Time";

                    if Remove then
                        if CalendarEntry2."Absence Capacity" < Capacity then
                            CalendarEntry2."Absence Capacity" := 0
                        else
                            CalendarEntry2."Absence Capacity" := CalendarEntry2."Absence Capacity" - Capacity
                    else
                        if CalendarEntry2.Capacity > Capacity then
                            CalendarEntry2."Absence Capacity" := Capacity
                        else
                            CalendarEntry2."Absence Capacity" := CalendarEntry2.Capacity;

                    if CalendarEntry."Ending Date-Time" < "Ending Date-Time" then begin
                        CalendarEntry2.Validate("Ending Date-Time", CalendarEntry."Ending Date-Time");
                        CalendarEntry2.Validate("Starting Date-Time", "Starting Date-Time");
                        CalendarEntry2.Insert();
                        CalendarEntry := CalendarEntry2;
                        "Starting Date-Time" := CalendarEntry."Ending Date-Time";
                    end else begin
                        CalendarEntry2.Validate("Ending Date-Time", "Ending Date-Time");
                        CalendarEntry2.Validate("Starting Date-Time", "Starting Date-Time");
                        CalendarEntry2.Insert();
                        if CalendarEntry3."Ending Date-Time" > "Ending Date-Time" then begin
                            CalendarEntry3.Validate("Starting Date-Time", "Ending Date-Time");
                            CalendarEntry3.Insert();
                            CalendarEntry := CalendarEntry3;
                        end;
                        Finished := true;
                    end;

                until (CalendarEntry.Next() = 0) or Finished;
        end;

        CalAbsentEntry."Starting Date-Time" := AbsenceStartingDateTime;
        CalAbsentEntry.Updated := not Remove;

        if not Remove then
            CalAbsentEntry.Modify();

        GatherEntries(CalendarEntry3);

        OnAfterUpdateAbsence(CalAbsentEntry);
    end;

    procedure RemoveAbsence(var CalAbsentEntry: Record "Calendar Absence Entry")
    begin
        if not CalAbsentEntry.Updated then
            exit;
        Remove := true;
        UpdateAbsence(CalAbsentEntry);
        Remove := false;
    end;

    local procedure GatherEntries(CalendarEntry: Record "Calendar Entry")
    var
        CalendarEntry2: Record "Calendar Entry";
    begin
        with CalendarEntry do begin
            CalendarEntry2.SetCurrentKey("Capacity Type", "No.", "Starting Date-Time");
            CalendarEntry2.SetRange("Capacity Type", "Capacity Type");
            CalendarEntry2.SetRange("No.", "No.");
            CalendarEntry2.SetRange(Date, Date);
            if not CalendarEntry2.Find('-') then
                exit;

            CalendarEntry := CalendarEntry2;
            if CalendarEntry2.Next() = 0 then
                exit;

            repeat
                if (Efficiency = CalendarEntry2.Efficiency) and
                   (Capacity = CalendarEntry2.Capacity) and
                   ("Absence Efficiency" = CalendarEntry2."Absence Efficiency") and
                   ("Absence Capacity" = CalendarEntry2."Absence Capacity") and
                   (Date = CalendarEntry2.Date) and
                   ("Work Shift Code" = CalendarEntry2."Work Shift Code") and
                   ("Ending Date-Time" = CalendarEntry2."Starting Date-Time")
                then begin
                    CalendarEntry2.Delete();
                    Delete();
                    CalendarEntry2.Validate("Starting Date-Time", "Starting Date-Time");
                    CalendarEntry2.Insert();
                end;
                CalendarEntry := CalendarEntry2;
            until CalendarEntry2.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAbsence(var CalendarAbsenceEntry: Record "Calendar Absence Entry")
    begin
    end;
}


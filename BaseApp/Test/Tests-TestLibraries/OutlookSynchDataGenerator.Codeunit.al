codeunit 132461 "Outlook Synch Data Generator"
{

    trigger OnRun()
    begin
        PopulateTaskMeetings(10000, 'AH', '', 0, 20, WorkDate, WorkDate + 5, 100000T, 235959T, 0, 120, 'Massive Test Tasks');
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        ProgressMsg: Label '#1###### of #2####### complete...';
        CompleteMsg: Label 'Completed.';

    [Scope('OnPrem')]
    procedure PopulateTaskMeetings("Count": Integer; SalesPersonFilter: Text; ContactFilter: Text; ContactNoBegin: Integer; ContactNoEnd: Integer; StartDateBegin: Date; StartDateEnd: Date; StartTimeBegin: Time; StartTimeEnd: Time; DurationMinBegin: Integer; DurationMinEnd: Integer; DescriptionHdr: Text)
    var
        Salesperson: Record "Salesperson/Purchaser";
        ProgressWindow: Dialog;
        SelectedDate: Date;
        SelectedTime: Time;
        Duration: Duration;
        Description: Text;
        i: Integer;
    begin
        Salesperson.SetFilter(Code, SalesPersonFilter);
        if Salesperson.Count = 0 then
            exit;

        i := 1;
        ProgressWindow.Open(ProgressMsg, i, Count);

        while i <= Count do begin
            SelectRandomSalesperson(Salesperson);
            SelectedDate := SelectRandomDate(StartDateBegin, StartDateEnd);
            SelectedTime := SelectRandomTime(StartTimeBegin, StartTimeEnd);
            Description := StrSubstNo('%1 %2', DescriptionHdr, i);
            Duration := SelectRandomDuration(DurationMinBegin, DurationMinEnd);

            InsertTask(Salesperson.Code, SelectedDate, Description, SelectedTime, Duration, ContactFilter, ContactNoBegin, ContactNoEnd);

            i := i + 1;

            if i mod 50 = 0 then
                ProgressWindow.Update;
        end;

        Message(CompleteMsg);
    end;

    local procedure InsertTask(SalespersonCode: Code[20]; StartDate: Date; Description: Text; StartTime: Time; Duration: Duration; ContactFilter: Text; ContactCountBegin: Integer; ContactCountEnd: Integer)
    var
        Task: Record "To-do";
        Contact: Record Contact;
        Attendee: Record Attendee;
        InteractionTemplate: Record "Interaction Template";
        TempEndDateTime: DateTime;
        EndDate: Date;
        EndTime: Time;
        OrganizerTask: Code[20];
        ContactNo: Integer;
        AttendeeLineNo: Integer;
    begin
        TempEndDateTime := CreateDateTime(StartDate, StartTime) + Duration;
        EndDate := DT2Date(TempEndDateTime);
        EndTime := DT2Time(TempEndDateTime);

        InteractionTemplate.Get('MEETINV');

        // Insert organizer's line
        InitTask(Task, InteractionTemplate, SalespersonCode, StartDate,
          CopyStr(Description, 1, MaxStrLen(Task.Description)), StartTime, Duration, EndDate, EndTime);
        Task."System To-do Type" := Task."System To-do Type"::Organizer;

        // Insert contact lines,if any
        ContactNo := ContactCountBegin + LibraryRandom.RandInt(ContactCountEnd - ContactCountBegin) - 1;

        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("No.", ContactFilter);
        if ContactNo > Contact.Count then
            ContactNo := Contact.Count();

        Task.Insert(true);
        OrganizerTask := Task."No.";
        Task.Modify(true);

        Attendee.Init();
        Attendee.CreateAttendee(
          Attendee, Task."No.", 10000, Attendee."Attendance Type"::"To-do Organizer",
          Attendee."Attendee Type"::Salesperson, SalespersonCode, true);

        while ContactNo > 0 do begin
            SelectRandomContact(Contact);

            InitTask(Task, InteractionTemplate, SalespersonCode, StartDate,
              CopyStr(Description, 1, MaxStrLen(Task.Description)), StartTime, Duration, EndDate, EndTime);
            Task."System To-do Type" := Task."System To-do Type"::"Contact Attendee";
            Task."Organizer To-do No." := OrganizerTask;
            Task.Insert(true);

            if Attendee.FindLast then
                AttendeeLineNo := Attendee."Line No." + 10000
            else
                AttendeeLineNo := 10000;

            Attendee.Init();
            Attendee.CreateAttendee(
              Attendee, OrganizerTask, AttendeeLineNo, Attendee."Attendance Type"::Required,
              Attendee."Attendee Type"::Contact, Contact."No.", Contact."E-Mail" <> '');

            ContactNo := ContactNo - 1;
        end;
    end;

    local procedure InitTask(var Task: Record "To-do"; InteractionTemplate: Record "Interaction Template"; SalespersonCode: Code[20]; StartDate: Date; Description: Text; StartTime: Time; Duration: Duration; EndDate: Date; EndTime: Time)
    begin
        Task.Init();
        Task."No." := '';
        Task."Salesperson Code" := SalespersonCode;
        Task.Type := Task.Type::Meeting;
        Task.Date := StartDate;
        Task.Description := CopyStr(Description, 1, MaxStrLen(Task.Description));
        Task."Start Time" := StartTime;
        Task.Duration := Duration;
        Task."Ending Date" := EndDate;
        Task."Ending Time" := EndTime;
        Task."Interaction Template Code" := InteractionTemplate.Code;
        Task.Subject := InteractionTemplate.Description;
    end;

    local procedure SelectRandomSalesperson(var Salesperson: Record "Salesperson/Purchaser")
    var
        Rnd: Integer;
    begin
        Salesperson.Find('-');
        Rnd := LibraryRandom.RandInt(Salesperson.Count);
        repeat
            Rnd := Rnd - 1;
        until (Salesperson.Next = 0) or (Rnd = 0);
    end;

    local procedure SelectRandomContact(var Contact: Record Contact)
    var
        Rnd: Integer;
    begin
        Contact.Find('-');
        Rnd := LibraryRandom.RandInt(Contact.Count);
        repeat
            Rnd := Rnd - 1;
        until (Contact.Next = 0) or (Rnd = 0);
    end;

    local procedure SelectRandomDate(StartDate: Date; EndDate: Date): Date
    var
        Rnd: Integer;
    begin
        if EndDate >= StartDate then begin
            Rnd := LibraryRandom.RandInt(EndDate - StartDate) - 1;
            exit(StartDate + Rnd)
        end;
        exit(StartDate);
    end;

    local procedure SelectRandomTime(StartTime: Time; EndTime: Time): Time
    var
        Rnd: Integer;
    begin
        if EndTime >= StartTime then begin
            Rnd := LibraryRandom.RandInt(EndTime - StartTime) - 1;
            exit(StartTime + Rnd);
        end;
        exit(StartTime);
    end;

    local procedure SelectRandomDuration(DurationMinBegin: Integer; DurationMinEnd: Integer): Duration
    var
        Rnd: Integer;
    begin
        if DurationMinEnd >= DurationMinBegin then begin
            Rnd := LibraryRandom.RandInt(DurationMinBegin - DurationMinEnd) - 1;
            exit((DurationMinBegin + Rnd) * 60000);
        end;
        exit(DurationMinBegin);
    end;
}


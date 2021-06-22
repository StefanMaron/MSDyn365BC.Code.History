table 1513 "Notification Schedule"
{
    Caption = 'Notification Schedule';
    DrillDownPageID = "Notification Schedule";
    LookupPageID = "Notification Schedule";
    ReplicateData = false;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(2; "Notification Type"; Option)
        {
            Caption = 'Notification Type';
            OptionCaption = 'New Record,Approval,Overdue';
            OptionMembers = "New Record",Approval,Overdue;
        }
        field(3; Recurrence; Option)
        {
            Caption = 'Recurrence';
            InitValue = Instantly;
            OptionCaption = 'Instantly,Daily,Weekly,Monthly';
            OptionMembers = Instantly,Daily,Weekly,Monthly;
        }
        field(4; Time; Time)
        {
            Caption = 'Time';
            InitValue = 120000T;
        }
        field(5; "Daily Frequency"; Option)
        {
            Caption = 'Daily Frequency';
            InitValue = Weekday;
            OptionCaption = 'Weekday,Daily';
            OptionMembers = Weekday,Daily;

            trigger OnValidate()
            begin
                UpdateDailyFrequency;
            end;
        }
        field(6; Monday; Boolean)
        {
            Caption = 'Monday';
            InitValue = true;
        }
        field(7; Tuesday; Boolean)
        {
            Caption = 'Tuesday';
            InitValue = true;
        }
        field(8; Wednesday; Boolean)
        {
            Caption = 'Wednesday';
            InitValue = true;
        }
        field(9; Thursday; Boolean)
        {
            Caption = 'Thursday';
            InitValue = true;
        }
        field(10; Friday; Boolean)
        {
            Caption = 'Friday';
            InitValue = true;
        }
        field(11; Saturday; Boolean)
        {
            Caption = 'Saturday';
        }
        field(12; Sunday; Boolean)
        {
            Caption = 'Sunday';
        }
        field(13; "Date of Month"; Integer)
        {
            Caption = 'Date of Month';
            MaxValue = 31;
            MinValue = 1;
        }
        field(14; "Monthly Notification Date"; Option)
        {
            Caption = 'Monthly Notification Date';
            OptionCaption = 'First Workday,Last Workday,Custom';
            OptionMembers = "First Workday","Last Workday",Custom;
        }
        field(15; "Last Scheduled Job"; Guid)
        {
            Caption = 'Last Scheduled Job';
            TableRelation = "Job Queue Entry";
        }
    }

    keys
    {
        key(Key1; "User ID", "Notification Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get("Last Scheduled Job") then begin
            JobQueueEntry.Delete(true);
            ScheduleNow;
        end;
    end;

    trigger OnModify()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get("Last Scheduled Job") then begin
            JobQueueEntry.Delete(true);
            Schedule;
        end;
    end;

    var
        NotifyNowDescriptionTxt: Label 'Instant Notification Job';
        NoWritePermissionsErr: Label 'You are not allowed to send notifications. Ask your system administrator to give you permission to do so. Specifically, you need the Write permission for the Sent Notification Entry table.';
        NotifyNowLbl: Label 'NOTIFYNOW', Locked = true;
        NotifyLaterLbl: Label 'NOTIFYLTR', Locked = true;

    procedure NewRecord(NewUserID: Code[50]; NewNotificationType: Option)
    begin
        Init;
        "User ID" := NewUserID;
        "Notification Type" := NewNotificationType;

        Insert;
    end;

    local procedure UpdateDailyFrequency()
    begin
        Monday := true;
        Tuesday := true;
        Wednesday := true;
        Thursday := true;
        Friday := true;
        Saturday := "Daily Frequency" <> "Daily Frequency"::Weekday;
        Sunday := "Daily Frequency" <> "Daily Frequency"::Weekday;
    end;

    local procedure GetFirstWorkdateOfMonth(CurrentDate: Date): Date
    var
        Day: Option ,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
    begin
        if Date2DWY(CalcDate('<-CM>', CurrentDate), 1) in [Day::Saturday, Day::Sunday] then
            exit(CalcDate('<-CM+WD1>', CurrentDate));

        exit(CalcDate('<-CM>', CurrentDate))
    end;

    local procedure GetScheduledFirstWorkdateOfMonth(CurrentDateTime: DateTime; ScheduledTime: Time) ScheduledDateTime: DateTime
    var
        CurrentDate: Date;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        ScheduledDateTime := CreateDateTime(GetFirstWorkdateOfMonth(CurrentDate), ScheduledTime);

        if ScheduledDateTime < CurrentDateTime then
            ScheduledDateTime := CreateDateTime(GetFirstWorkdateOfMonth(CalcDate('<+1M>', CurrentDate)), ScheduledTime);
    end;

    local procedure GetLastWorkdateOfMonth(CurrentDate: Date): Date
    var
        Day: Option ,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
    begin
        if Date2DWY(CalcDate('<+CM>', CurrentDate), 1) in [Day::Saturday, Day::Sunday] then
            exit(CalcDate('<+CM-WD5>', CurrentDate));

        exit(CalcDate('<+CM>', CurrentDate))
    end;

    local procedure GetScheduledLastWorkdateOfMonth(CurrentDateTime: DateTime; ScheduledTime: Time) ScheduledDateTime: DateTime
    var
        CurrentDate: Date;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        ScheduledDateTime := CreateDateTime(GetLastWorkdateOfMonth(CurrentDate), ScheduledTime);

        if ScheduledDateTime < CurrentDateTime then
            ScheduledDateTime := CreateDateTime(GetLastWorkdateOfMonth(CalcDate('<+1M>', CurrentDate)), ScheduledTime);
    end;

    local procedure GetLastDateOfMonth(CurrentDate: Date): Date
    begin
        exit(CalcDate('<+CM>', CurrentDate))
    end;

    local procedure GetScheduledCustomWorkdateOfMonth(CurrentDateTime: DateTime; ScheduledTime: Time; ScheduledDay: Integer): DateTime
    var
        CurrentDate: Date;
        CurrentTime: Time;
        CurrentDay: Integer;
        CurrentMonth: Integer;
        CurrentYear: Integer;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        CurrentTime := DT2Time(CurrentDateTime);
        CurrentDay := Date2DMY(CurrentDate, 1);
        CurrentMonth := Date2DMY(CurrentDate, 2);
        CurrentYear := Date2DMY(CurrentDate, 3);

        if (ScheduledDay = CurrentDay) and (CurrentTime < ScheduledTime) then
            exit(CreateDateTime(DMY2Date(ScheduledDay, CurrentMonth, CurrentYear), ScheduledTime));

        if ScheduledDay <= CurrentDay then begin
            CurrentDate := CalcDate('<+1M>', CurrentDate);
            CurrentMonth := Date2DMY(CurrentDate, 2);
            CurrentYear := Date2DMY(CurrentDate, 3);
        end;

        CurrentDate := GetLastDateOfMonth(CurrentDate);
        if ScheduledDay > Date2DMY(CurrentDate, 1) then
            exit(CreateDateTime(CurrentDate, ScheduledTime));
        exit(CreateDateTime(DMY2Date(ScheduledDay, CurrentMonth, CurrentYear), ScheduledTime))
    end;

    local procedure GetScheduledWeekDay(CurrentDateTime: DateTime; ScheduledTime: Time): DateTime
    var
        CurrentDate: Date;
        CurrentTime: Time;
        WeekDays: array[7] of Boolean;
        Idx: Integer;
        NextWeekDayIdx: Integer;
        CurrWeekDay: Integer;
        NextWeekDay: Integer;
    begin
        CurrentDate := DT2Date(CurrentDateTime);
        CurrentTime := DT2Time(CurrentDateTime);

        CurrWeekDay := Date2DWY(CurrentDate, 1);
        NextWeekDay := CurrWeekDay;

        WeekDays[1] := Monday;
        WeekDays[2] := Tuesday;
        WeekDays[3] := Wednesday;
        WeekDays[4] := Thursday;
        WeekDays[5] := Friday;
        WeekDays[6] := Saturday;
        WeekDays[7] := Sunday;

        if WeekDays[CurrWeekDay] and (CurrentTime < ScheduledTime) then
            exit(CreateDateTime(CurrentDate, ScheduledTime));

        for Idx := 0 to 6 do begin
            NextWeekDayIdx := ((CurrWeekDay + Idx) mod 7) + 1;
            if WeekDays[NextWeekDayIdx] then begin
                NextWeekDay := NextWeekDayIdx;
                break;
            end;
        end;

        exit(CreateDateTime(CalcDate(StrSubstNo('<+WD%1>', NextWeekDay), CurrentDate), ScheduledTime));
    end;

    procedure CalculateExecutionTime(DateTime: DateTime): DateTime
    begin
        case Recurrence of
            Recurrence::Instantly:
                exit(CurrentDateTime);
            Recurrence::Daily,
          Recurrence::Weekly:
                exit(GetScheduledWeekDay(DateTime, Time));
            Recurrence::Monthly:
                case "Monthly Notification Date" of
                    "Monthly Notification Date"::"First Workday":
                        exit(GetScheduledFirstWorkdateOfMonth(DateTime, Time));
                    "Monthly Notification Date"::"Last Workday":
                        exit(GetScheduledLastWorkdateOfMonth(DateTime, Time));
                    "Monthly Notification Date"::Custom:
                        exit(GetScheduledCustomWorkdateOfMonth(DateTime, Time, "Date of Month"));
                end;
        end;
    end;

    local procedure Schedule()
    begin
        if Recurrence = Recurrence::Instantly then
            ScheduleNow
        else
            ScheduleForLater
    end;

    local procedure CheckSentNotificationEntryPermissions()
    var
        DummySentNotificationEntry: Record "Sent Notification Entry";
    begin
        if not DummySentNotificationEntry.WritePermission() then
            Error(NoWritePermissionsErr);
    end;

    procedure ScheduleNotification(NotificationEntry: Record "Notification Entry")
    begin
        // Try to get a schedule if none exist use the default record values
        if Get(NotificationEntry."Recipient User ID", NotificationEntry.Type) then;

        Schedule;
    end;

    local procedure OneMinuteFromNow(): DateTime
    begin
        exit(CurrentDateTime + 60000);
    end;

    local procedure ScheduleNow()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
    begin
        CheckSentNotificationEntryPermissions();
        if JobQueueEntry.ReuseExistingJobFromCatagory(NotifyNowLbl, OneMinuteFromNow()) then
            exit;

        JobQueueCategory.InsertRec(NotifyNowLbl, NotifyNowDescriptionTxt);
        JobQueueEntry.ScheduleJobQueueEntryForLater(
          CODEUNIT::"Notification Entry Dispatcher", OneMinuteFromNow, NotifyNowLbl, '');
    end;

    local procedure ScheduleForLater()
    var
        JobQueueEntry: Record "Job Queue Entry";
        NotificationEntry: Record "Notification Entry";
        ExcetutionDateTime: DateTime;
    begin
        CheckSentNotificationEntryPermissions();
        ExcetutionDateTime := CalculateExecutionTime(CurrentDateTime);
        if JobQueueEntry.ReuseExistingJobFromID("Last Scheduled Job", ExcetutionDateTime) then
            exit;

        NotificationEntry.SetRange("Recipient User ID", "User ID");
        NotificationEntry.SetRange(Type, "Notification Type");
        JobQueueEntry.ScheduleJobQueueEntryForLater(
          CODEUNIT::"Notification Entry Dispatcher", ExcetutionDateTime, NotifyLaterLbl, NotificationEntry.GetView);
        "Last Scheduled Job" := JobQueueEntry.ID;
        Modify
    end;
}


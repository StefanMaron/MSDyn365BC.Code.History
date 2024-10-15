table 2160 "Calendar Event"
{
    Caption = 'Calendar Event';
    Permissions = TableData "Calendar Event" = rimd;
    ReplicateData = false;
    ObsoleteReason = 'Invoicing';
#if not CLEAN24
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#endif
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Scheduled Date"; Date)
        {
            Caption = 'Scheduled Date';
#if not CLEAN24
            trigger OnValidate()
            begin
                CheckIfArchived();
            end;
#endif
        }
        field(3; Archived; Boolean)
        {
            Caption = 'Archived';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
#if not CLEAN24
            trigger OnValidate()
            begin
                CheckIfArchived();
            end;
#endif
        }
        field(5; "Object ID to Run"; Integer)
        {
            Caption = 'Object ID to Run';
#if not CLEAN24
            trigger OnValidate()
            begin
                CheckIfArchived();
            end;
#endif
        }
        field(6; "Record ID to Process"; RecordID)
        {
            Caption = 'Record ID to Process';
            DataClassification = CustomerContent;
#if not CLEAN24
            trigger OnValidate()
            begin
                CheckIfArchived();
            end;
#endif
        }
        field(7; State; Option)
        {
            Caption = 'State';
            OptionCaption = 'Queued,In Progress,Completed,Failed,On Hold';
            OptionMembers = Queued,"In Progress",Completed,Failed,"On Hold";
        }
        field(8; Result; Text[250])
        {
            Caption = 'Result';
        }
        field(9; User; Code[50])
        {
            Caption = 'User';
            DataClassification = EndUserIdentifiableInformation;
#if not CLEAN24
            trigger OnValidate()
            begin
                CheckIfArchived();
            end;
#endif
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'User,System';
            OptionMembers = User,System;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Scheduled Date", Archived, User)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Scheduled Date", Description, State)
        {
        }
    }

#if not CLEAN24
    trigger OnDelete()
    var
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CheckIfArchived();

        Archived := true;
        Modify();

        CalendarEventMangement.DescheduleCalendarEvent(Rec);
    end;

    trigger OnInsert()
    begin
        Schedule();
    end;

    trigger OnModify()
    begin
        Schedule();
    end;

    var
        AlreadyExecutedErr: Label 'This calendar entry has already been executed and cannot be modified.';

    local procedure Schedule()
    var
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        if (State <> State::Queued) or Archived then
            exit;

        // Validate entries
        TestField("Scheduled Date");
        TestField(Description);
        TestField("Object ID to Run");
        TestField(Archived, false);

        User := UserId;

        CalendarEventMangement.CreateOrUpdateJobQueueEntry(Rec)
    end;

    local procedure CheckIfArchived()
    begin
        if Archived then
            Error(AlreadyExecutedErr);
    end;
#endif
}


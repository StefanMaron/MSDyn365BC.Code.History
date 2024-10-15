table 31124 "EET Entry Status"
{
    Caption = 'EET Entry Status';
#if CLEAN18
    ObsoleteState = Removed;
#else
    DrillDownPageID = "EET Entry Status Log";
    LookupPageID = "EET Entry Status Log";
    ObsoleteState = Pending;
#endif    
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(5; "EET Entry No."; Integer)
        {
            Caption = 'EET Entry No.';
#if not CLEAN18
            TableRelation = "EET Entry";
#endif
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';

            trigger OnLookup()
            var
                ErrorMessage: Record "Error Message";
            begin
                ErrorMessage.SetContext(Rec);
                ErrorMessage.ShowErrorMessages(false);
            end;
        }
        field(20; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Created,Send Pending,Sent,Failure,Success,Success with Warnings,Sent to Verification,Verified,Verified with Warnings';
            OptionMembers = Created,"Send Pending",Sent,Failure,Success,"Success with Warnings","Sent to Verification",Verified,"Verified with Warnings";
        }
        field(25; "Change Datetime"; DateTime)
        {
            Caption = 'Change Datetime';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "EET Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ClearErrorMessages;
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    local procedure ClearErrorMessages()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Context Record ID", RecordId);
        ErrorMessage.DeleteAll();
    end;
}


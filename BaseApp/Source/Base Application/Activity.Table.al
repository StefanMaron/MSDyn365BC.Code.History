table 5081 Activity
{
    Caption = 'Activity';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Activity List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ActivityStep: Record "Activity Step";
    begin
        ActivityStep.SetRange("Activity Code", Code);
        ActivityStep.DeleteAll();
    end;

    procedure IncludesMeeting(ActivityCode: Code[10]): Boolean
    var
        ActivityStep: Record "Activity Step";
    begin
        with ActivityStep do begin
            SetCurrentKey("Activity Code", Type);
            SetRange("Activity Code", ActivityCode);
            SetRange(Type, Type::Meeting);
            exit(FindFirst);
        end;
    end;
}


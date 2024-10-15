table 31044 "FA History Entry"
{
    Caption = 'FA History Entry';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '21.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = 'Location,Responsible Employee';
            OptionMembers = Location,"Responsible Employee";
        }
        field(3; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            Editable = false;
            TableRelation = "Fixed Asset"."No.";
        }
        field(4; "Old Value"; Code[20])
        {
            Caption = 'Old Value';
            Editable = false;
            TableRelation = if (Type = const(Location)) "FA Location".Code
            else
            if (Type = const("Responsible Employee")) Employee."No.";
        }
        field(5; "New Value"; Code[20])
        {
            Caption = 'New Value';
            Editable = false;
            TableRelation = if (Type = const(Location)) "FA Location".Code
            else
            if (Type = const("Responsible Employee")) Employee."No.";
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(7; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            Editable = false;
        }
        field(8; Disposal; Boolean)
        {
            Caption = 'Disposal';
            Editable = false;
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            Editable = false;
        }
        field(10; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "FA No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}

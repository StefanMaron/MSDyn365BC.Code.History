table 5334 "CRM Option Mapping"
{
    Caption = 'CRM Option Mapping';

    fields
    {
        field(1; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Option Value"; Integer)
        {
            Caption = 'Option Value';
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(4; "Integration Table ID"; Integer)
        {
            Caption = 'Integration Table ID';
        }
        field(5; "Integration Field ID"; Integer)
        {
            Caption = 'Integration Field ID';
        }
        field(6; "Option Value Caption"; Text[250])
        {
            Caption = 'Option Value Caption';
        }
    }

    keys
    {
        key(Key1; "Record ID")
        {
            Clustered = true;
        }
        key(Key2; "Integration Table ID", "Integration Field ID", "Option Value")
        {
        }
    }

    fieldgroups
    {
    }

    procedure FindRecordID(IntegrationTableID: Integer; IntegrationFieldID: Integer; OptionValue: Integer): Boolean
    begin
        Reset;
        SetRange("Integration Table ID", IntegrationTableID);
        SetRange("Integration Field ID", IntegrationFieldID);
        SetRange("Option Value", OptionValue);
        exit(FindFirst);
    end;

    procedure GetRecordKeyValue(): Text
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecordRef: RecordRef;
    begin
        RecordRef.Get("Record ID");
        KeyRef := RecordRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        exit(Format(FieldRef.Value));
    end;
}


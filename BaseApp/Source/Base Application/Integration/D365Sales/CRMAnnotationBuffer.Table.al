table 5391 "CRM Annotation Buffer"
{
    Caption = 'CRM Annotation Buffer';

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Related Table ID"; Integer)
        {
            Caption = 'Related Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Related Record ID"; RecordID)
        {
            Caption = 'Related Record ID';
            DataClassification = CustomerContent;
        }
        field(4; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(5; "Change Type"; Option)
        {
            Caption = 'Change Type';
            DataClassification = SystemMetadata;
            OptionCaption = ',Created,Deleted';
            OptionMembers = ,Created,Deleted;
        }
        field(6; "Change DateTime"; DateTime)
        {
            Caption = 'Change DateTime';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


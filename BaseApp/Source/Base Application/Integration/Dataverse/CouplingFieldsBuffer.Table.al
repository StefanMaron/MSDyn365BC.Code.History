table 5327 "Coupling Fields Buffer"
{
    Caption = 'Coupling Field Buffer';
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Field Name"; Text[50])
        {
            Caption = 'Field Name';
            DataClassification = SystemMetadata;
        }
        field(2; "Mapped Field Name"; Text[50])
        {
            Caption = 'Mapped Field Name';
            DataClassification = SystemMetadata;
        }
        field(3; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(4; "Integration Value"; Text[250])
        {
            Caption = 'Integration Value';
            DataClassification = SystemMetadata;
        }
        field(6; Direction; Option)
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(8; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Field Name", "Mapped Field Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


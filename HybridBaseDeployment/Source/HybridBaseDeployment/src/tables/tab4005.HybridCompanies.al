table 4005 "Hybrid Company"
{
    DataPerCompany = false;
    ReplicateData = false;

    // We must prohibit extending this table since it is not populated by the application.
    Extensible = false;

    fields
    {
        field(1; "Name"; Text[50])
        {
            Description = 'The SQL-friendly name of a company';
            DataClassification = SystemMetadata;
        }
        field(2; "Display Name"; Text[250])
        {
            Description = 'The display name for the company';
            DataClassification = SystemMetadata;
        }
        field(3; "Replicate"; Boolean)
        {
            Description = 'Indicates whether to replicate the company data';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Name")
        {
            Clustered = true;
        }
    }

    procedure SetSelected(SelectAll: Boolean)
    begin
        ModifyAll(Replicate, SelectAll);
    end;
}
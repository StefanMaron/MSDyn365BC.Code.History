table 6309 "Power BI Service Status Setup"
{
    // // Singleton table for tracking across companies whether the Power BI service for deploying
    // // OOB reports appears to currently be accessible or not, based on the Retry After times
    // // received when uploading reports.

    Caption = 'Power BI Service Status Setup';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
            Description = 'Just a key value for SQL.';
        }
        field(2; "Retry After"; DateTime)
        {
            Caption = 'Retry After';
            DataClassification = CustomerContent;
            Description = 'Indicates when the PBI service should be available again.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Count > 1 then
            Error(SingletonErr);
    end;

    var
        SingletonErr: Label 'There should be only one record for Power BI Service Status Setup.';
}


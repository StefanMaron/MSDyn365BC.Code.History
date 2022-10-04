table 1263 "No. Series Tenant"
{
    Caption = 'No. Series Tenant';
    DataPerCompany = false;
    Permissions = TableData "No. Series Tenant" = rimd;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; "Last Used number"; Code[10])
        {
            Caption = 'Last Used number';
            DataClassification = SystemMetadata;
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

    [Scope('OnPrem')]
    procedure InitNoSeries(NoSeriesCode: Code[10]; NoSeriesDescription: Text[50]; LastUsedNo: Code[10])
    var
        NoSeriesTenant: Record "No. Series Tenant";
    begin
        NoSeriesTenant.Validate(Code, NoSeriesCode);
        NoSeriesTenant.Validate(Description, NoSeriesDescription);
        NoSeriesTenant.Validate("Last Used number", LastUsedNo);
        NoSeriesTenant.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetNextAvailableCode() NextAvailableCode: Code[20]
    begin
        NextAvailableCode := IncStr(Code + "Last Used number");
        Validate("Last Used number", IncStr("Last Used number"));
        Modify();
    end;
}


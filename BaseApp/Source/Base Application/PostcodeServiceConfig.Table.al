table 9091 "Postcode Service Config"
{
    Caption = 'Postcode Service Config';
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; ServiceKey; Text[250])
        {
            Caption = 'ServiceKey';
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

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

    [Scope('OnPrem')]
    procedure SaveServiceKey(ServiceKeyText: Text)
    begin
        if ServiceKey = '' then
            ServiceKey := CreateGuid();

        IsolatedStorageManagement.Set(ServiceKey, ServiceKeyText, DATASCOPE::Company);
        Modify();
    end;

    [Scope('OnPrem')]
    procedure GetServiceKey(): Text
    var
        Value: Text;
        ServiceKeyGUID: Guid;
    begin
        if ServiceKey <> '' then
            Evaluate(ServiceKeyGUID, ServiceKey);

        if not IsNullGuid(ServiceKeyGUID) then
            if IsolatedStorageManagement.Get(ServiceKey, DATASCOPE::Company, Value) then
                exit(Value);
    end;
}


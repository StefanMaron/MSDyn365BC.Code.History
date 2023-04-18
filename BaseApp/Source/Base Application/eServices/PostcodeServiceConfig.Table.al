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

    procedure SaveServiceKey(ServiceKeyText: Text)
    begin
        Rec.ServiceKey := CopyStr(ServiceKeyText, 1, MaxStrLen(Rec.ServiceKey));
        Rec.Modify();
    end;

    procedure GetServiceKey(): Text
    begin
        exit(Rec.ServiceKey);
    end;
}


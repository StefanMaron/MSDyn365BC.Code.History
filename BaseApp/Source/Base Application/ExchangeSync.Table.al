table 6700 "Exchange Sync"
{
    Caption = 'Exchange Sync';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(3; "Exchange Service URI"; Text[250])
        {
            Caption = 'Exchange Service URI';
            DataClassification = SystemMetadata;
        }
        field(4; "Exchange Account Password Key"; Guid)
        {
            Caption = 'Exchange Account Password Key';
        }
        field(5; "Last Sync Date Time"; DateTime)
        {
            Caption = 'Last Sync Date Time';
            Editable = false;
        }
        field(7; "Folder ID"; Text[30])
        {
            Caption = 'Folder ID';
        }
        field(9; "Filter"; BLOB)
        {
            Caption = 'Filter';
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePassword("Exchange Account Password Key");
    end;

    var
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

    [Scope('OnPrem')]
    procedure SetExchangeAccountPassword(PasswordText: Text)
    begin
        PasswordText := DelChr(PasswordText, '=', ' ');
        if PasswordText <> '' then
            CheckEncryption;

        if IsNullGuid("Exchange Account Password Key") then
            "Exchange Account Password Key" := CreateGuid;

        IsolatedStorageManagement.Set("Exchange Account Password Key", PasswordText, DATASCOPE::Company);
    end;

    procedure GetExchangeEndpoint() Endpoint: Text[250]
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
    begin
        Endpoint := "Exchange Service URI";
        if Endpoint = '' then
            Endpoint := CopyStr(ExchangeWebServicesServer.GetEndpoint, 1, 250);
    end;

    local procedure CheckEncryption()
    begin
        if not EncryptionEnabled then
            if Confirm(EncryptionIsNotActivatedQst) then
                PAGE.Run(PAGE::"Data Encryption Management");
    end;

    [Scope('OnPrem')]
    local procedure DeletePassword(PasswordKey: Guid)
    begin
        IsolatedStorageManagement.Delete(PasswordKey, DATASCOPE::Company);
    end;

    procedure SaveFilter(FilterText: Text)
    var
        WriteStream: OutStream;
    begin
        Clear(Filter);
        Filter.CreateOutStream(WriteStream);
        WriteStream.WriteText(FilterText);
    end;

    procedure GetSavedFilter() FilterText: Text
    var
        ReadStream: InStream;
    begin
        CalcFields(Filter);
        Filter.CreateInStream(ReadStream);
        ReadStream.ReadText(FilterText);
    end;

    procedure DeleteActivityLog()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange("Record ID", RecordId);
        ActivityLog.DeleteAll();
    end;
}


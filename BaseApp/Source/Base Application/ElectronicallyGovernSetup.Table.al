table 11761 "Electronically Govern. Setup"
{
    Caption = 'Electronically Govern. Setup';
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(30; "Proxy Server"; Text[30])
        {
            Caption = 'Proxy Server';
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(31; "Proxy User"; Text[30])
        {
            Caption = 'Proxy User';
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(32; "Proxy Password"; Text[30])
        {
            Caption = 'Proxy Password';
            ExtendedDatatype = Masked;
            ObsoleteReason = 'Moved to Service Password';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(33; "Proxy Password Key"; Guid)
        {
            Caption = 'Proxy Password Key';
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(80; UncertaintyPayerWebService; Text[250])
        {
            Caption = 'UncertaintyPayerWebService';
            ExtendedDatatype = URL;
            InitValue = 'http://adisrws.mfcr.cz/adistc/axis2/services/rozhraniCRPDPH.rozhraniCRPDPHSOAP';
        }
        field(81; "Public Bank Acc.Chck.Star.Date"; Date)
        {
            Caption = 'Public Bank Acc.Chck.Star.Date';
        }
        field(82; "Public Bank Acc.Check Limit"; Decimal)
        {
            BlankZero = true;
            Caption = 'Public Bank Acc.Check Limit';
            MinValue = 0;
        }
        field(85; "Unc.Payer Request Record Limit"; Integer)
        {
            Caption = 'Unc.Payer Request Record Limit';
            InitValue = 99;
            MinValue = 0;
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

    trigger OnDelete()
    begin
        DeletePassword;
    end;

    [Obsolete('The functionality of Communication using Proxy server will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure SavePassword(PasswordText: Text)
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        PasswordKey: Text;
    begin
        if IsNullGuid("Proxy Password Key") or not IsolatedStorageManagement.Contains("Proxy Password Key", DATASCOPE::Company) then begin
            PasswordKey := Format(CreateGuid);
            "Proxy Password Key" := PasswordKey;
        end;
        IsolatedStorageManagement.Set(PasswordKey, PasswordText, DATASCOPE::Company)
    end;

    [Obsolete('The functionality of Communication using Proxy server will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure GetPassword(): Text
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        PasswordText: Text;
    begin
        if not IsNullGuid("Proxy Password Key") then
            if IsolatedStorageManagement.Get("Proxy Password Key", DATASCOPE::Company, PasswordText) then
                exit(PasswordText);
        exit('');
    end;

    [Obsolete('The functionality of Communication using Proxy server will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    local procedure DeletePassword()
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if IsolatedStorageManagement.Contains("Proxy Password Key", DATASCOPE::Company) then
            IsolatedStorageManagement.Delete("Proxy Password Key", DATASCOPE::Company)
    end;

    [Obsolete('The functionality of Communication using Proxy server will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure HasPassword(): Boolean
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        PasswordText: Text;
    begin
        if not IsolatedStorageManagement.Get("Proxy Password Key", DATASCOPE::Company, PasswordText) then
            exit(false);
        exit(PasswordText <> '');
    end;
}


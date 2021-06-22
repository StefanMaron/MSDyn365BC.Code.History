table 409 "SMTP Mail Setup"
{
    Caption = 'SMTP Mail Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "SMTP Server"; Text[250])
        {
            Caption = 'SMTP Server';
        }
        field(3; Authentication; Option)
        {
            Caption = 'Authentication';
            OptionCaption = 'Anonymous,NTLM,Basic';
            OptionMembers = Anonymous,NTLM,Basic;

            trigger OnValidate()
            begin
                if Authentication <> Authentication::Basic then begin
                    "User ID" := '';
                    SetPassword('');
                end;

                if Authentication = Authentication::Anonymous then
                    "Allow Sender Substitution" := true;
            end;
        }
        field(4; "User ID"; Text[250])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                "User ID" := DelChr("User ID", '<>', ' ');
                if "User ID" = '' then
                    exit;
                TestField(Authentication, Authentication::Basic);
            end;
        }
        field(6; "SMTP Server Port"; Integer)
        {
            Caption = 'SMTP Server Port';
            InitValue = 25;
        }
        field(7; "Secure Connection"; Boolean)
        {
            Caption = 'Secure Connection';
            InitValue = false;
        }
        field(8; "Password Key"; Guid)
        {
            Caption = 'Password Key';
        }
        field(9; "Send As"; Text[250])
        {
            Caption = 'Send As';
        }
        field(10; "Allow Sender Substitution"; Boolean)
        {
            Caption = 'Allow Sender Substitution';
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

    /// <summary>
    /// Checks if SMTP Mail Setup record has been initialized.
    /// </summary>
    /// <returns>True if there is an SMTP Mail Setup record.</returns>
    procedure HasSetup(): Boolean
    begin
        exit(not IsEmpty());
    end;

    /// <summary>
    /// Checks if SMTP Mail Setup record has been initialized and initialize it if it has not.
    /// </summary>
    /// <returns>True if SMTP has been setup with an SMTP Server.</returns>
    procedure GetSetup(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        if not Get then begin
            if not WritePermission then begin
                MailManagement.GetSMTPCredentials(Rec);
                exit("SMTP Server" <> '');
            end;
            Init;
            Insert;
        end;

        if "SMTP Server" = '' then
            MailManagement.GetSMTPCredentials(Rec);

        exit("SMTP Server" <> '');
    end;

    [NonDebuggable]
    procedure SetPassword(NewPassword: Text)
    begin
        if IsNullGuid("Password Key") then
            "Password Key" := CreateGuid;

        IsolatedStorageManagement.Set("Password Key", NewPassword, DATASCOPE::Company);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetPassword(): Text
    var
        Value: Text;
    begin
        IsolatedStorageManagement.Get("Password Key", DATASCOPE::Company, Value);
        exit(Value);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure HasPassword(): Boolean
    begin
        exit(GetPassword() <> '');
    end;

    [Scope('OnPrem')]
    procedure RemovePassword()
    begin
        IsolatedStorageManagement.Delete("Password Key", DATASCOPE::Company);
        Clear("Password Key");
    end;

    procedure GetSender(): Text[250]
    begin
        if "Send As" = '' then
            "Send As" := "User ID";

        exit("Send As");
    end;

    procedure GetConnectionString(): Text[250]
    begin
        if GetSender = "User ID" then
            exit("User ID");

        exit(CopyStr(StrSubstNo('%1\%2', "User ID", "Send As"), 1, MaxStrLen("User ID")));
    end;

    procedure SplitUserIdAndSendAs(ConnectionString: Text[250])
    var
        MailManagement: Codeunit "Mail Management";
        AtLocation: Integer;
        SlashLocation: Integer;
    begin
        ConnectionString := DelChr(ConnectionString);
        if (ConnectionString = '') or MailManagement.CheckValidEmailAddress(ConnectionString) then begin
            "User ID" := ConnectionString;
            "Send As" := ConnectionString;
            exit;
        end;

        AtLocation := StrPos(ConnectionString, '@');

        if AtLocation > 0 then begin
            SlashLocation := StrPos(ConnectionString, '\');
            if SlashLocation > AtLocation then begin
                "User ID" := CopyStr(ConnectionString, 1, SlashLocation - 1);
                "Send As" := CopyStr(ConnectionString, SlashLocation + 1);
                if MailManagement.CheckValidEmailAddress("User ID") and MailManagement.CheckValidEmailAddress("Send As") then
                    exit;
            end;
        end;

        "User ID" := ConnectionString;
        "Send As" := ConnectionString;
    end;
}


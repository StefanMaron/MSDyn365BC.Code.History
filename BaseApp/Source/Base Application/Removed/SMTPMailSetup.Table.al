namespace System.Email;

table 409 "SMTP Mail Setup"
{
    Caption = 'SMTP Mail Setup';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to "Email - SMTP" app. Use SMTP connector to create SMTP accounts. Email accounts can be configured from "Email Accouts" page from "System Application".';
    ObsoleteTag = '20.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

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
            OptionCaption = 'Anonymous,NTLM,Basic,OAuth 2.0';
            OptionMembers = Anonymous,NTLM,Basic,OAuth2;
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

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "Send As" <> '' then
                    MailManagement.CheckValidEmailAddress("Send As");
            end;
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
}

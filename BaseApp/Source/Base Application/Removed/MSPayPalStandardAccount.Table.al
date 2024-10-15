table 7860 "MS- PayPal Standard Account"
{
    Caption = 'MS- PayPal Standard Account';
    ObsoleteReason = 'This table is no longer used by any user.';
    ObsoleteState = Removed;
    Permissions = TableData "Webhook Subscription" = rimd;
    ObsoleteTag = '15.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            NotBlank = true;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(5; "Always Include on Documents"; Boolean)
        {
            Caption = 'Always Include on Documents';
        }
        field(8; "Terms of Service"; Text[250])
        {
            Caption = 'Terms of Service';
            ExtendedDatatype = URL;
        }
        field(10; "Account ID"; Text[250])
        {
            Caption = 'Account ID';
        }
        field(12; "Target URL"; BLOB)
        {
            Caption = 'Target URL';
            SubType = Bitmap;
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

    procedure GetTargetURL(): Text
    var
        InStream: InStream;
        TargetURL: Text;
    begin
        TargetURL := '';
        CalcFields("Target URL");
        if "Target URL".HasValue() then begin
            "Target URL".CreateInStream(InStream);
            InStream.Read(TargetURL);
        end;
        exit(TargetURL);
    end;

    procedure SetTargetURL(TargetURL: Text)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        OutStream: OutStream;
    begin
        WebRequestHelper.IsValidUri(TargetURL);
        WebRequestHelper.IsHttpUrl(TargetURL);
        WebRequestHelper.IsSecureHttpUrl(TargetURL);

        "Target URL".CreateOutStream(OutStream);
        OutStream.Write(TargetURL);
        Modify();
    end;

    [Scope('OnPrem')]
    procedure HideAllDialogs()
    begin
    end;
}


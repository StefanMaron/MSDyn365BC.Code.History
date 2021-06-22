table 870 "Social Listening Setup"
{
    Caption = 'Social Engagement Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Solution ID"; Text[250])
        {
            Caption = 'Solution ID';
            Editable = false;

            trigger OnValidate()
            begin
                if "Solution ID" = '' then begin
                    Validate("Show on Items", false);
                    Validate("Show on Customers", false);
                    Validate("Show on Vendors", false);
                end;
            end;
        }
        field(3; "Show on Items"; Boolean)
        {
            Caption = 'Show on Items';

            trigger OnValidate()
            begin
                if "Show on Items" then begin
                    TestField("Social Listening URL");
                    TestField("Accept License Agreement");
                    TestField("Solution ID");
                end;
            end;
        }
        field(4; "Show on Customers"; Boolean)
        {
            Caption = 'Show on Customers';

            trigger OnValidate()
            begin
                if "Show on Customers" then begin
                    TestField("Social Listening URL");
                    TestField("Accept License Agreement");
                    TestField("Solution ID");
                end;
            end;
        }
        field(5; "Show on Vendors"; Boolean)
        {
            Caption = 'Show on Vendors';

            trigger OnValidate()
            begin
                if "Show on Vendors" then begin
                    TestField("Social Listening URL");
                    TestField("Accept License Agreement");
                    TestField("Solution ID");
                end;
            end;
        }
        field(6; "Accept License Agreement"; Boolean)
        {
            Caption = 'Accept License Agreement';

            trigger OnValidate()
            begin
                if not "Accept License Agreement" then begin
                    Validate("Show on Items", false);
                    Validate("Show on Customers", false);
                    Validate("Show on Vendors", false);
                end;
            end;
        }
        field(7; "Terms of Use URL"; Text[250])
        {
            Caption = 'Terms of Use URL';
            ExtendedDatatype = URL;
            NotBlank = true;
        }
        field(8; "Signup URL"; Text[250])
        {
            Caption = 'Signup URL';
            ExtendedDatatype = URL;
            NotBlank = true;
        }
        field(9; "Social Listening URL"; Text[250])
        {
            Caption = 'Social Engagement URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            begin
                if "Social Listening URL" = '' then begin
                    Validate("Solution ID", '');
                    exit;
                end;

                if StrPos("Social Listening URL", 'https://') <> 1 then
                    Error(MustStartWithErr, FieldCaption("Social Listening URL"));
                if StrPos("Social Listening URL", '/app/') = 0 then
                    Error(MustContainSolutionIDErr, FieldCaption("Social Listening URL"));

                Validate("Solution ID", SocialListeningMgt.ConvertURLToID("Social Listening URL", '/app/'));
            end;
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
        if "Signup URL" = '' then
            "Signup URL" := SocialListeningMgt.GetSignupURL;
        if "Terms of Use URL" = '' then
            "Terms of Use URL" := SocialListeningMgt.GetTermsOfUseURL;
    end;

    var
        SocialListeningMgt: Codeunit "Social Listening Management";
        MustStartWithErr: Label 'The %1 must start with ''https://''.';
        MustContainSolutionIDErr: Label 'The %1 must contain the Solution ID.';
}


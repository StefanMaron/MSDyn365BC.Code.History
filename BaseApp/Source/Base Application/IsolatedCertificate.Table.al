table 1262 "Isolated Certificate"
{
    Caption = 'Isolated Certificate';
    DataPerCompany = false;
    LookupPageID = "Certificate List";
    Permissions = TableData "Isolated Certificate" = rimd,
                  TableData "No. Series Tenant" = rimd;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            Editable = false;
        }
        field(2; Scope; Option)
        {
            Caption = 'Available To';
            InitValue = Company;
            NotBlank = true;
            OptionCaption = ',Company,User,Company and User';
            OptionMembers = ,Company,User,CompanyAndUser;
        }
        field(3; Password; Text[50])
        {
            Caption = 'Password';
            ExtendedDatatype = Masked;
        }
        field(4; "Expiry Date"; DateTime)
        {
            Caption = 'Expiry Date';
            Editable = false;
        }
        field(5; "Has Private Key"; Boolean)
        {
            Caption = 'Has Private Key';
            Editable = false;
        }
        field(6; Name; Text[50])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(7; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(8; "Company ID"; Text[30])
        {
            Caption = 'Company ID';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(10; ThumbPrint; Text[50])
        {
            Caption = 'ThumbPrint';
            Editable = false;
        }
        field(13; "Issued By"; Text[250])
        {
            Caption = 'Issued By';
            Editable = false;
        }
        field(14; "Issued To"; Text[250])
        {
            Caption = 'Issued To';
            Editable = false;
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
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    begin
        CertificateManagement.DeleteCertAndPasswordFromIsolatedStorage(Rec);
    end;

    trigger OnInsert()
    begin
        Code := GetNextAvailableCode;
        if ExistsInIsolatedStorage then
            Error(CertCodeExistsErr);
    end;

    var
        CertCodeTxt: Label 'CERT', Locked = true;
        CertStartCodeNumberTxt: Label '0000000000', Locked = true;
        CertCodeExistsErr: Label 'This Cert code is being already used in Isolated storage.';
        CertNoSeriesDescriptionTxt: Label 'Certificates No. Series';
        CertificateManagement: Codeunit "Certificate Management";

    [Scope('OnPrem')]
    procedure IsCertificateExpired(): Boolean
    begin
        if ThumbPrint <> '' then
            exit("Expiry Date" < CurrentDateTime);
    end;

    local procedure GetNextAvailableCode(): Code[20]
    var
        NoSeriesTenant: Record "No. Series Tenant";
    begin
        if not NoSeriesTenant.Get(CertCodeTxt) then begin
            NoSeriesTenant.InitNoSeries(CertCodeTxt, CertNoSeriesDescriptionTxt, CertStartCodeNumberTxt);
            NoSeriesTenant.Get(CertCodeTxt);
        end;
        exit(NoSeriesTenant.GetNextAvailableCode);
    end;

    [Scope('OnPrem')]
    procedure SetScope()
    var
        User: Record User;
    begin
        User.Get(UserSecurityId);
        case Scope of
            Scope::Company:
                Validate("Company ID", CompanyName);
            Scope::User:
                Validate("User ID", User."User Name");
            Scope::CompanyAndUser:
                begin
                    Validate("Company ID", CompanyName);
                    Validate("User ID", User."User Name");
                end;
        end;
        Modify;
    end;

    local procedure ExistsInIsolatedStorage(): Boolean
    begin
        exit(ISOLATEDSTORAGE.Contains(Code, CertificateManagement.GetCertDataScope(Rec)));
    end;
}


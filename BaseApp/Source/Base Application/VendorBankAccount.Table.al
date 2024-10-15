table 288 "Vendor Bank Account"
{
    Caption = 'Vendor Bank Account';
    DataCaptionFields = "Vendor No.", "Code", Name;
    DrillDownPageID = "Vendor Bank Account List";
    LookupPageID = "Vendor Bank Account List";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(5; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(6; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(7; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(10; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(11; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(12; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(13; "Bank Branch No."; Text[60])
        {
            Caption = 'Bank Branch No.';
        }
        field(14; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            begin
                if "Country/Region Code" = '' then
                    ValidateAccountNo;
            end;
        }
        field(15; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(17; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(18; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(19; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(20; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(21; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(22; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(23; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(24; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(25; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(1211; "Bank Clearing Code"; Text[50])
        {
            Caption = 'Bank Clearing Code';
        }
        field(1212; "Bank Clearing Standard"; Text[50])
        {
            Caption = 'Bank Clearing Standard';
            TableRelation = "Bank Clearing Standard";
        }
        field(12400; BIC; Code[9])
        {
            Caption = 'BIC';
            TableRelation = "Bank Directory";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if BankDir.Get(BIC) then begin
                    "Bank Corresp. Account No." := BankDir."Corr. Account No.";
                    if Name = '' then
                        Name := CopyStr(BankDir."Full Name", 1, MaxStrLen(Name));
                    if StrLen(Name) < StrLen(BankDir."Full Name") then
                        "Name 2" := CopyStr(BankDir."Full Name", StrLen(Name) + 1, MaxStrLen("Name 2"));
                    if Address = '' then
                        Address := CopyStr(BankDir.Address, 1, MaxStrLen(Address));
                    if StrLen(Address) < StrLen(BankDir.Address) then
                        "Address 2" := CopyStr(BankDir.Address, StrLen(Address) + 1, MaxStrLen("Address 2"));
                    if "Phone No." = '' then
                        "Phone No." := CopyStr(BankDir.Telephone, 1, MaxStrLen("Phone No."));
                    City := BankDir."Area Name";
                    "Abbr. City" := LowerCase(CopyStr(Format(BankDir."Area Type"), 1, 1));
                end;
            end;
        }
        field(12401; "Abbr. City"; Text[1])
        {
            Caption = 'Abbr. City';
        }
        field(12402; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(12403; "Personal Account No."; Text[20])
        {
            Caption = 'Personal Account No.';
        }
        field(12404; "Def. Payment Purpose"; Text[250])
        {
            Caption = 'Def. Payment Purpose';
        }
        field(12410; "Bank Corresp. Account No."; Code[20])
        {
            Caption = 'Bank Corresp. Account No.';

            trigger OnValidate()
            begin
                if "Bank Corresp. Account No." <> '' then begin
                    BankDir.Reset();
                    BankDir.SetCurrentKey("Corr. Account No.");
                    BankDir.SetRange("Corr. Account No.", "Bank Corresp. Account No.");
                    if BankDir.Find('-') then
                        if BIC = '' then
                            Validate(BIC, BankDir.BIC)
                        else
                            if BIC <> BankDir.BIC then
                                if Confirm(Text12400, true, BankDir."Corr. Account No.", BankDir.BIC, BankDir."Short Name") then
                                    Validate(BIC, BankDir.BIC)
                end;

                if "Country/Region Code" = '' then
                    ValidateAccountNo;
            end;
        }
        field(12411; "Bank Card No."; Code[16])
        {
            Caption = 'Bank Card No.';
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Name, "Phone No.", Contact)
        {
        }
    }

    trigger OnDelete()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", "Vendor No.");
        VendorLedgerEntry.SetRange("Recipient Bank Account", Code);
        VendorLedgerEntry.SetRange(Open, true);
        if not VendorLedgerEntry.IsEmpty then
            Error(BankAccDeleteErr);
        if Vendor.Get("Vendor No.") and (Vendor."Preferred Bank Account Code" = Code) then begin
            Vendor."Preferred Bank Account Code" := '';
            Vendor.Modify();
        end;
    end;

    var
        PostCode: Record "Post Code";
        BankDir: Record "Bank Directory";
        Text12400: Label 'Corr. Account %1 corresponds to the bank %2 %3\Do you agree?';
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a Bank Account No. or an IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';

    [Scope('OnPrem')]
    procedure ValidateAccountNo()
    begin
        case CurrFieldNo of
            FieldNo("Bank Account No."):
                if StrLen("Bank Account No.") > 20 then
                    FieldError("Bank Account No.");
            FieldNo("Transit No."):
                if StrLen("Transit No.") > 20 then
                    FieldError("Transit No.");
        end;
    end;

    procedure GetBankAccountNoWithCheck() AccountNo: Text
    begin
        AccountNo := GetBankAccountNo;
        if AccountNo = '' then
            Error(BankAccIdentifierIsEmptyErr);
    end;

    procedure GetBankAccountNo(): Text
    begin
        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;
}


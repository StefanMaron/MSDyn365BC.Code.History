table 11762 "Registration Country/Region"
{
    Caption = 'Registration Country/Region';
    LookupPageID = "Registration Country/Region";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    fields
    {
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Customer,Vendor,Contact,Company Information';
            OptionMembers = Customer,Vendor,Contact,"Company Information";
        }
        field(10; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST(Contact)) Contact;
        }
        field(15; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region" WHERE("EU Country/Region Code" = FILTER(<> ''));
        }
        field(20; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            begin
                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." <> xRec."VAT Registration No." then
                    VATRegistrationValidation;
            end;
        }
        field(25; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if ("Account Type" = "Account Type"::"Company Information") and ("Account No." = '') then
                    TestField("VAT Bus. Posting Group", '');
            end;
        }
        field(30; "Currency Code (Local)"; Code[10])
        {
            Caption = 'Currency Code (Local)';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"Company Information") and ("Account No." <> '') then
                    TestField("Currency Code (Local)", '');
            end;
        }
        field(35; "VAT Rounding Type"; Option)
        {
            Caption = 'VAT Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(40; "Rounding VAT"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rounding VAT';
            InitValue = 1;

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"Company Information") and ("Account No." <> '') then
                    TestField("Rounding VAT", 0);
            end;
        }
        field(50; "Intrastat Export Object Type"; Option)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object Type';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit,XMLPort';
            OptionMembers = ,,,"Report",,"Codeunit","XMLPort";

            trigger OnValidate()
            begin
                if "Intrastat Export Object Type" <> 0 then
                    TestField("Account Type", "Account Type"::"Company Information");

                if "Intrastat Export Object Type" <> xRec."Intrastat Export Object Type" then
                    "Intrastat Export Object No." := 0;
            end;
        }
        field(52; "Intrastat Export Object No."; Integer)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FIELD("Intrastat Export Object Type"));

            trigger OnLookup()
            begin
                LookupObjectNo("Intrastat Export Object Type", "Intrastat Export Object No.");
                Validate("Intrastat Export Object No.");
            end;

            trigger OnValidate()
            begin
                if "Intrastat Export Object No." <> 0 then
                    TestField("Account Type", "Account Type"::"Company Information");
            end;
        }
        field(60; "Intrastat Exch.Rate Mandatory"; Boolean)
        {
            Caption = 'Intrastat Exch.Rate Mandatory';
        }
        field(80; "VIES Decl. Exp. Obj. Type"; Option)
        {
            BlankZero = true;
            Caption = 'VIES Decl. Exp. Obj. Type';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit';
            OptionMembers = ,,,"Report",,"Codeunit";

            trigger OnValidate()
            begin
                if xRec."VIES Decl. Exp. Obj. Type" <> "VIES Decl. Exp. Obj. Type" then
                    Validate("VIES Decl. Exp. Obj. No.", 0);
            end;
        }
        field(82; "VIES Decl. Exp. Obj. No."; Integer)
        {
            BlankZero = true;
            Caption = 'VIES Decl. Exp. Obj. No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = field("VIES Decl. Exp. Obj. Type"));

            trigger OnLookup()
            begin
                LookupObjectNo("VIES Decl. Exp. Obj. Type", "VIES Decl. Exp. Obj. No.");
                Validate("VIES Decl. Exp. Obj. No.");
            end;

            trigger OnValidate()
            begin
                CalcFields("VIES Decl. Exp. Obj. Name");
            end;
        }
        field(84; "VIES Decl. Exp. Obj. Name"; Text[250])
        {
            CalcFormula = lookup (AllObjWithCaption."Object Caption" where(
                "Object Type" = field("VIES Decl. Exp. Obj. Type"),
                "Object ID" = field("VIES Decl. Exp. Obj. No.")));
            Caption = 'VIES Decl. Exp. Obj. Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(86; "VIES Declaration Report No."; Integer)
        {
            Caption = 'VIES Declaration Report No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));

            trigger OnValidate()
            begin
                CalcFields("VIES Declaration Report Name");
            end;
        }
        field(87; "VIES Declaration Report Name"; Text[250])
        {
            CalcFormula = lookup (AllObjWithCaption."Object Caption" where(
                "Object Type" = const(Report),
                "Object ID" = field("VIES Decl. Exp. Obj. No.")));
            Caption = 'VIES Declaration Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Account Type", "Account No.", "Country/Region Code")
        {
            Clustered = true;
        }
        key(Key2; "VAT Registration No.")
        {
        }
    }

    fieldgroups
    {
    }

    local procedure LookupObjectNo(ObjectType: Option; var ObjectNo: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        if AllObjWithCaption.Get(ObjectType, ObjectNo) then
            Objects.SetRecord(AllObjWithCaption);

        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", ObjectType);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode(true);
        if Objects.RunModal() = Action::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            ObjectNo := AllObjWithCaption."Object ID";
        end else
            Error('');
    end;

    local procedure VATRegistrationValidation()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ApplicableCountryCode: Code[10];
    begin
        if not VATRegistrationNoFormat.Test("VAT Registration No.", "Country/Region Code", "Account No.", GetTableIDFromAccountType) then
            exit;
        VATRegistrationLogMgt.LogRegistrationCountryRegion(Rec);
        if ("Country/Region Code" = '') and (VATRegistrationNoFormat."Country/Region Code" = '') then
            exit;
        ApplicableCountryCode := "Country/Region Code";
        if ApplicableCountryCode = '' then
            ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";
        if VATRegNoSrvConfig.VATRegNoSrvIsEnabled then
            VATRegistrationLogMgt.CheckVATRegNoWithVIES(Rec, "Account No.", "Account Type", ApplicableCountryCode);
    end;

    local procedure GetTableIDFromAccountType(): Integer
    begin
        case "Account Type" of
            "Account Type"::Customer:
                exit(DATABASE::Customer);
            "Account Type"::Vendor:
                exit(DATABASE::Vendor);
            "Account Type"::Contact:
                exit(DATABASE::Contact);
            "Account Type"::"Company Information":
                exit(DATABASE::"Company Information");
        end;
    end;

    procedure VerifyFromVIES()
    begin
        VATRegistrationValidation;
    end;
}


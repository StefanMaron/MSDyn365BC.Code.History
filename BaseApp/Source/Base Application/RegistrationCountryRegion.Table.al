table 11762 "Registration Country/Region"
{
    Caption = 'Registration Country/Region';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of VAT Registration in Other Countries has been removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

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
        }
        field(25; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(30; "Currency Code (Local)"; Code[10])
        {
            Caption = 'Currency Code (Local)';
            TableRelation = Currency;
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
        }
        field(50; "Intrastat Export Object Type"; Option)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object Type';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit,XMLPort';
            OptionMembers = ,,,"Report",,"Codeunit","XMLPort";
        }
        field(52; "Intrastat Export Object No."; Integer)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FIELD("Intrastat Export Object Type"));
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
        }
        field(82; "VIES Decl. Exp. Obj. No."; Integer)
        {
            BlankZero = true;
            Caption = 'VIES Decl. Exp. Obj. No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = field("VIES Decl. Exp. Obj. Type"));
        }
        field(84; "VIES Decl. Exp. Obj. Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where(
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
        }
        field(87; "VIES Declaration Report Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where(
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
}

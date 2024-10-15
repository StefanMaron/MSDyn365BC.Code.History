table 31094 "Reverse Charge Line"
{
    Caption = 'Reverse Charge Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Reverse Charge No."; Code[20])
        {
            Caption = 'Reverse Charge No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = ' ,Invoice,Cr. Memo';
            OptionMembers = " ",Invoice,"Cr. Memo";
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            Editable = false;
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(15; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item,Resource,Fixed Asset,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        }
        field(16; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Item)) Item
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF (Type = CONST("Charge (Item)")) "Item Charge";
        }
        field(17; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Commodity Code"; Code[10])
        {
            Caption = 'Commodity Code';
            TableRelation = Commodity;
        }
        field(25; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(26; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(30; "VAT Base Amount (LCY)"; Decimal)
        {
            Caption = 'VAT Base Amount (LCY)';
        }
        field(35; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(40; "Document Quantity"; Decimal)
        {
            Caption = 'Document Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(41; "Document Unit of Measure Code"; Code[10])
        {
            Caption = 'Document Unit of Measure Code';
            Editable = false;
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Resource)) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."))
            ELSE
            "Unit of Measure";
        }
        field(45; "Document Tariff No."; Code[20])
        {
            Caption = 'Document Tariff No.';
            Editable = false;
            TableRelation = "Tariff Number";
        }
    }

    keys
    {
        key(Key1; "Reverse Charge No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "VAT Base Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetVATRegNo() VATRegNo: Code[20]
    var
        Country: Record "Country/Region";
    begin
        VATRegNo := "VAT Registration No.";

        if "Country/Region Code" <> '' then begin
            Country.Get("Country/Region Code");
            if CopyStr("VAT Registration No.", 1, StrLen(Country."EU Country/Region Code")) = Country."EU Country/Region Code" then
                VATRegNo := CopyStr("VAT Registration No.", StrLen(Country."EU Country/Region Code") + 1);
        end;
    end;
}


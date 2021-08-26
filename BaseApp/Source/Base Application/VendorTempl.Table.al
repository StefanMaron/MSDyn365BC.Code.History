table 1383 "Vendor Templ."
{
    Caption = 'Vendor Template';

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';

            trigger OnLookup()
            var
                PostCode: Record "Post Code";
                CityText: Text;
                CountyText: Text;
            begin
                PostCode.LookupPostCode(CityText, "Post Code", CountyText, "Country/Region Code");
                City := CopyStr(CityText, 1, MaxStrLen(City));
                County := CopyStr(CountyText, 1, MaxStrLen(County));
            end;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(21; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(28; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";
        }
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(33; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
            TableRelation = Vendor;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
                CityText: Text;
                CountyText: Text;
            begin
                PostCode.CheckClearPostCodeCityCounty(CityText, "Post Code", CountyText, "Country/Region Code", xRec."Country/Region Code");
                City := CopyStr(CityText, 1, MaxStrLen(City));
                County := CopyStr(CountyText, 1, MaxStrLen(County));
            end;
        }
        field(39; Blocked; Enum "Vendor Blocked")
        {
            Caption = 'Blocked';
        }
        field(45; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(80; "Application Method"; Enum "Application Method")
        {
            Caption = 'Application Method';
        }
        field(82; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';

            trigger OnLookup()
            var
                PostCode: Record "Post Code";
                CityText: Text;
                CountyText: Text;
            begin
                PostCode.LookupPostCode(CityText, "Post Code", CountyText, "Country/Region Code");
                City := CopyStr(CityText, 1, MaxStrLen(City));
                County := CopyStr(CountyText, 1, MaxStrLen(County));
            end;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(116; "Block Payment Tolerance"; Boolean)
        {
            Caption = 'Block Payment Tolerance';
        }
        field(132; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
        }
        field(5050; "Contact Type"; Enum "Contact Type")
        {
            Caption = 'Contact Type';
        }
        field(5701; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(7601; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            TableRelation = "Document Sending Profile".Code;
        }
        field(7602; "Validate EU Vat Reg. No."; Boolean)
        {
            Caption = 'Validate EU Vat Reg. No.';
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        DefaultDimension.SetRange("No.", Code);
        DefaultDimension.DeleteAll();
    end;

    trigger OnRename()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.RenameDefaultDim(Database::"Vendor Templ.", xRec.Code, Code);
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(Database::"Vendor Templ.", Code, FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    procedure CopyFromTemplate(SourceVendorTempl: Record "Vendor Templ.")
    begin
        CopyTemplate(SourceVendorTempl);
        CopyDimensions(SourceVendorTempl);
    end;

    local procedure CopyTemplate(SourceVendorTempl: Record "Vendor Templ.")
    var
        SavedVendorTempl: Record "Vendor Templ.";
    begin
        SavedVendorTempl := Rec;
        TransferFields(SourceVendorTempl, false);
        Code := SavedVendorTempl.Code;
        Description := SavedVendorTempl.Description;
        Modify();
    end;

    local procedure CopyDimensions(SourceVendorTempl: Record "Vendor Templ.")
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        DestDefaultDimension.SetRange("No.", Code);
        DestDefaultDimension.DeleteAll(true);

        SourceDefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        SourceDefaultDimension.SetRange("No.", SourceVendorTempl.Code);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::"Vendor Templ.");
                DestDefaultDimension.Validate("No.", Code);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if DestDefaultDimension.Insert(true) then;
            until SourceDefaultDimension.Next() = 0;
    end;
}


table 5800 "Item Charge"
{
    Caption = 'Item Charge';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Item Charges";
    LookupPageID = "Item Charges";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
            end;
        }
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(4; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(5; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(6; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(7; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(8; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(31060; "Incl. in Intrastat Amount"; Boolean)
        {
            Caption = 'Incl. in Intrastat Amount';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';

            trigger OnValidate()
            begin
                if "Incl. in Intrastat Amount" then begin
                    CheckIncludeIntrastat;
                    TestField("Incl. in Intrastat Stat. Value", false);
                end;
            end;
        }
        field(31061; "Incl. in Intrastat Stat. Value"; Boolean)
        {
            Caption = 'Incl. in Intrastat Stat. Value';
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';

            trigger OnValidate()
            begin
                if "Incl. in Intrastat Stat. Value" then begin
                    CheckIncludeIntrastat;
                    TestField("Incl. in Intrastat Amount", false);
                end;
            end;
        }
        field(31070; "Use Ledger Entry Dimensions"; Boolean)
        {
            Caption = 'Use Ledger Entry Dimensions';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31071; "Sales Only"; Boolean)
        {
            Caption = 'Sales Only';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31072; "Purchase Only"; Boolean)
        {
            Caption = 'Purchase Only';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31073; "Disable Receipt Lines"; Boolean)
        {
            Caption = 'Disable Receipt Lines';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31074; "Disable Transfer Receipt Lines"; Boolean)
        {
            Caption = 'Disable Transfer Receipt Lines';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31075; "Disable Return Schipment Lines"; Boolean)
        {
            Caption = 'Disable Return Schipment Lines';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31076; "Disable Sales Schipment Lines"; Boolean)
        {
            Caption = 'Disable Sales Schipment Lines';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31077; "Disable Return Receipt Lines"; Boolean)
        {
            Caption = 'Disable Return Receipt Lines';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31078; "Assigment on Receive/Shipment"; Boolean)
        {
            Caption = 'Assigment on Receive/Shipment';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "Gen. Prod. Posting Group")
        {
        }
        key(Key4; Description)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(DATABASE::"Item Charge", "No.");
    end;

    trigger OnModify()
    begin
        DimMgt.UpdateDefaultDim(
          DATABASE::"Item Charge", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::"Charge (Item)", xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::"Charge (Item)", xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::"Item Charge", xRec."No.", "No.");
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Item Charge", "No.", FieldNumber, ShortcutDimCode);
            Modify;
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ItemCharge: Record "Item Charge"; xItemCharge: Record "Item Charge"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ItemCharge: Record "Item Charge"; xItemCharge: Record "Item Charge"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    procedure CheckIncludeIntrastat()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        // NAVCZ
        StatReportingSetup.Get();
        StatReportingSetup.TestField("No Item Charges in Intrastat", false);
    end;
}


table 5105 "Customer Template"
{
    Caption = 'Customer Template';
#if not CLEAN18
    DrillDownPageID = "Customer Template List";
    LookupPageID = "Customer Template List";
#endif
    ReplicateData = true;
    ObsoleteReason = 'Deprecate mini and customer templates. Use table "Customer Templ." instead and for extensions.';
#if not CLEAN18
    ObsoleteState = Pending;
    ObsoleteTag = '18.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));
#if not CLEAN18
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
#endif
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));
#if not CLEAN18
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
#endif
        }
        field(21; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(23; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(33; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
            TableRelation = Customer;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                Cust: Record Customer;
            begin
                if PAGE.RunModal(0, Cust) = ACTION::LookupOK then
                    "Invoice Disc. Code" := Cust."Invoice Disc. Code";
            end;
        }
        field(34; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(82; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
#if not CLEAN18
            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
#endif
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(5050; "Contact Type"; Enum "Contact Type")
        {
            Caption = 'Contact Type';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
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
        fieldgroup(DropDown; "Code", Description, "Country/Region Code", "Customer Posting Group")
        {
        }
    }

#if not CLEAN18
    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(DATABASE::"Customer Template", Code);
    end;

    trigger OnInsert()
    begin
        DimMgt.UpdateDefaultDim(
          DATABASE::"Customer Template", Code,
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        "Invoice Disc. Code" := Code;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Customer Template", xRec.Code, Code);
    end;

    var
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        DimMgt: Codeunit DimensionManagement;

    [Obsolete('Will be removed with other functionality related to "old" templates. Replaced by new templates.', '18.0')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Customer Template", Code, FieldNumber, ShortcutDimCode);
            Modify;
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [Obsolete('Will be removed with other functionality related to "old" templates. Replaced by new templates.', '18.0')]
    [Scope('OnPrem')]
    procedure CopyTemplate(var SourceCustomerTemplate: Record "Customer Template")
    begin
        TransferFields(SourceCustomerTemplate, false);
        Modify(true);
    end;

    [Obsolete('Will be removed with other functionality related to "old" templates. Replaced by new templates.', '18.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var CustomerTemplate: Record "Customer Template"; var xCustomerTemplate: Record "Customer Template"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [Obsolete('Will be removed with other functionality related to "old" templates. Replaced by new templates.', '18.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var CustomerTemplate: Record "Customer Template"; var xCustomerTemplate: Record "Customer Template"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
#endif
}


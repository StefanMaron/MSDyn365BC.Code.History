table 152 "Resource Group"
{
    Caption = 'Resource Group';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Resource Groups";
    LookupPageID = "Resource Groups";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(22; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(23; Capacity; Decimal)
        {
            CalcFormula = Sum("Res. Capacity Entry".Capacity WHERE("Resource Group No." = FIELD("No."),
                                                                    Date = FIELD("Date Filter")));
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(24; "Qty. on Order (Job)"; Decimal)
        {
            CalcFormula = Sum("Job Planning Line"."Quantity (Base)" WHERE(Status = CONST(Order),
                                                                           "Schedule Line" = CONST(true),
                                                                           Type = CONST(Resource),
                                                                           "Resource Group No." = FIELD("No."),
                                                                           "Planning Date" = FIELD("Date Filter")));
            Caption = 'Qty. on Order (Job)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Qty. Quoted (Job)"; Decimal)
        {
            CalcFormula = Sum("Job Planning Line"."Quantity (Base)" WHERE(Status = CONST(Quote),
                                                                           "Schedule Line" = CONST(true),
                                                                           Type = CONST(Resource),
                                                                           "Resource Group No." = FIELD("No."),
                                                                           "Planning Date" = FIELD("Date Filter")));
            Caption = 'Qty. Quoted (Job)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
        }
        field(27; "Usage (Qty.)"; Decimal)
        {
            CalcFormula = Sum("Res. Ledger Entry".Quantity WHERE("Entry Type" = CONST(Usage),
                                                                  Chargeable = FIELD("Chargeable Filter"),
                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Filter"),
                                                                  "Resource Group No." = FIELD("No."),
                                                                  "Posting Date" = FIELD("Date Filter")));
            Caption = 'Usage (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Usage (Cost)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = Sum("Res. Ledger Entry"."Total Cost" WHERE("Entry Type" = CONST(Usage),
                                                                      Chargeable = FIELD("Chargeable Filter"),
                                                                      "Unit of Measure Code" = FIELD("Unit of Measure Filter"),
                                                                      "Resource Group No." = FIELD("No."),
                                                                      "Posting Date" = FIELD("Date Filter")));
            Caption = 'Usage (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Usage (Price)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Res. Ledger Entry"."Total Price" WHERE("Entry Type" = CONST(Usage),
                                                                       Chargeable = FIELD("Chargeable Filter"),
                                                                       "Unit of Measure Code" = FIELD("Unit of Measure Filter"),
                                                                       "Resource Group No." = FIELD("No."),
                                                                       "Posting Date" = FIELD("Date Filter")));
            Caption = 'Usage (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Sales (Qty.)"; Decimal)
        {
            CalcFormula = - Sum("Res. Ledger Entry".Quantity WHERE("Entry Type" = CONST(Sale),
                                                                   "Resource Group No." = FIELD("No."),
                                                                   "Unit of Measure Code" = FIELD("Unit of Measure Filter"),
                                                                   "Posting Date" = FIELD("Date Filter")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Sales (Cost)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = - Sum("Res. Ledger Entry"."Total Cost" WHERE("Entry Type" = CONST(Sale),
                                                                       "Resource Group No." = FIELD("No."),
                                                                       "Unit of Measure Code" = FIELD("Unit of Measure Filter"),
                                                                       "Posting Date" = FIELD("Date Filter")));
            Caption = 'Sales (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Sales (Price)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Res. Ledger Entry"."Total Price" WHERE("Entry Type" = CONST(Sale),
                                                                        "Resource Group No." = FIELD("No."),
                                                                        "Unit of Measure Code" = FIELD("Unit of Measure Filter"),
                                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Sales (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Chargeable Filter"; Boolean)
        {
            Caption = 'Chargeable Filter';
            FieldClass = FlowFilter;
        }
        field(34; "Global Dimension 1 Code"; Code[20])
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
        field(35; "Global Dimension 2 Code"; Code[20])
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
        field(36; "No. of Resources Assigned"; Integer)
        {
            CalcFormula = Count(Resource WHERE("Resource Group No." = FIELD("No.")));
            Caption = 'No. of Resources Assigned';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5900; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = Sum("Service Order Allocation"."Allocated Hours" WHERE(Posted = CONST(false),
                                                                                  "Resource Group No." = FIELD("No."),
                                                                                  "Allocation Date" = FIELD("Date Filter"),
                                                                                  Status = CONST(Active)));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ResCapacityEntry.SetCurrentKey("Resource Group No.");
        ResCapacityEntry.SetRange("Resource Group No.", "No.");
        ResCapacityEntry.DeleteAll();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Resource Group");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::"Resource Group", "No.");
    end;

    trigger OnInsert()
    begin
        DimMgt.UpdateDefaultDim(
          DATABASE::"Resource Group", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnRename()
    var
        PriceListLine: Record "Price List Line";
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Resource Group", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Resource Group", xRec."No.", "No.");
        PriceListLine.RenameNo(PriceListLine."Asset Type"::"Resource Group", xRec."No.", "No.")
    end;

    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        CommentLine: Record "Comment Line";
        DimMgt: Codeunit DimensionManagement;

    local procedure AsPriceAsset(var PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type")
    begin
        PriceAsset.Init();
        PriceAsset."Price Type" := PriceType;
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::"Resource Group";
        PriceAsset."Asset No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        AsPriceAsset(PriceAsset, PriceType);
        PriceUXManagement.ShowPriceListLines(PriceAsset, PriceType, AmountType);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Resource Group", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ResourceGroup: Record "Resource Group"; xResourceGroup: Record "Resource Group"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ResourceGroup: Record "Resource Group"; xResourceGroup: Record "Resource Group"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}


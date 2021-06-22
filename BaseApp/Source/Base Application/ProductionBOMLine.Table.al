table 99000772 "Production BOM Line"
{
    Caption = 'Production BOM Line';

    fields
    {
        field(1; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            NotBlank = true;
            TableRelation = "Production BOM Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
            TableRelation = "Production BOM Version"."Version Code" WHERE("Production BOM No." = FIELD("Production BOM No."));
        }
        field(10; Type; Enum "Production BOM Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                TestStatus;

                xRec.Type := Type;

                Init;
                Type := xRec.Type;
            end;
        }
        field(11; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Item)) Item WHERE(Type = FILTER(Inventory | "Non-Inventory"))
            ELSE
            IF (Type = CONST("Production BOM")) "Production BOM Header";

            trigger OnValidate()
            begin
                TestField(Type);

                TestStatus;

                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            Description := Item.Description;
                            Item.TestField("Base Unit of Measure");
                            "Unit of Measure Code" := Item."Base Unit of Measure";
                            "Scrap %" := Item."Scrap %";
                            if "No." <> xRec."No." then
                                "Variant Code" := '';
                            OnValidateNoOnAfterAssignItemFields(Rec, Item, xRec, CurrFieldNo);
                        end;
                    Type::"Production BOM":
                        begin
                            ProdBOMHeader.Get("No.");
                            ProdBOMHeader.TestField("Unit of Measure Code");
                            Description := ProdBOMHeader.Description;
                            "Unit of Measure Code" := ProdBOMHeader."Unit of Measure Code";
                            OnValidateNoOnAfterAssignProdBOMFields(Rec, ProdBOMHeader, xRec, CurrFieldNo);
                        end;
                end;

                OnAfterValidateNo(Rec);
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST("Production BOM")) "Unit of Measure";

            trigger OnValidate()
            begin
                TestField("No.");
                if xRec."Unit of Measure Code" <> "Unit of Measure Code" then
                    TestField(Type, Type::Item);
            end;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(15; Position; Code[10])
        {
            Caption = 'Position';
        }
        field(16; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
        }
        field(17; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
        }
        field(18; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';

            trigger OnValidate()
            begin
                TestField("No.");
            end;
        }
        field(19; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            TableRelation = "Routing Link";

            trigger OnValidate()
            begin
                if "Routing Link Code" <> '' then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                end;
            end;
        }
        field(20; "Scrap %"; Decimal)
        {
            BlankNumbers = BlankNeg;
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;

            trigger OnValidate()
            begin
                TestField("No.");
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            begin
                if "Variant Code" = '' then
                    exit;
                TestField(Type, Type::Item);
                TestField("No.");
                ItemVariant.Get("No.", "Variant Code");
                Description := ItemVariant.Description;
            end;
        }
        field(22; Comment; Boolean)
        {
            CalcFormula = Exist ("Production BOM Comment Line" WHERE("Production BOM No." = FIELD("Production BOM No."),
                                                                     "Version Code" = FIELD("Version Code"),
                                                                     "BOM Line No." = FIELD("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField("No.");

                if "Starting Date" > 0D then
                    Validate("Ending Date");
            end;
        }
        field(29; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                TestField("No.");

                if ("Ending Date" > 0D) and
                   ("Starting Date" > 0D) and
                   ("Starting Date" > "Ending Date")
                then
                    Error(
                      Text000,
                      FieldCaption("Ending Date"),
                      FieldCaption("Starting Date"));
            end;
        }
        field(40; Length; Decimal)
        {
            Caption = 'Length';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(41; Width; Decimal)
        {
            Caption = 'Width';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(42; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(43; Depth; Decimal)
        {
            Caption = 'Depth';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(44; "Calculation Formula"; Enum "Quantity Calculation Formula")
        {
            Caption = 'Calculation Formula';

            trigger OnValidate()
            begin
                TestField("No.");

                case "Calculation Formula" of
                    "Calculation Formula"::" ":
                        Quantity := "Quantity per";
                    "Calculation Formula"::Length:
                        Quantity := Round(Length * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::"Length * Width":
                        Quantity := Round(Length * Width * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::"Length * Width * Depth":
                        Quantity := Round(Length * Width * Depth * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::Weight:
                        Quantity := Round(Weight * "Quantity per", UOMMgt.QtyRndPrecision);
                    else
                        OnValidateCalculationFormulaEnumExtension(Rec);
                end;
            end;
        }
        field(45; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
    }

    keys
    {
        key(Key1; "Production BOM No.", "Version Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Type, "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ProdBOMComment: Record "Production BOM Comment Line";
        PlanningAssignment: Record "Planning Assignment";
    begin
        if Type <> Type::" " then begin
            TestStatus;
            case Type of
                Type::Item:
                    PlanningAssignment.AssignPlannedOrders("No.", false);
                Type::"Production BOM":
                    PlanningAssignment.OldBom("No.");
                else
                    OnDeleteOnCaseTypeElse(Rec);
            end;
        end;

        ProdBOMComment.SetRange("Production BOM No.", "Production BOM No.");
        ProdBOMComment.SetRange("BOM Line No.", "Line No.");
        ProdBOMComment.SetRange("Version Code", "Version Code");
        ProdBOMComment.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestStatus;
    end;

    trigger OnModify()
    begin
        if Type <> Type::" " then
            TestStatus;
    end;

    var
        Text000: Label '%1 must be later than %2.';
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ItemVariant: Record "Item Variant";
        BOMVersionUOMErr: Label 'The Unit of Measure Code %1 for Item %2 does not exist. Identification fields and values: Production BOM No. = %3, Version Code = %4.', Comment = '%1=UOM Code;%2=Item No.;%3=Production BOM No.;%4=Version Code';
        BOMHeaderUOMErr: Label 'The Unit of Measure Code %1 for Item %2 does not exist. Identification fields and values: Production BOM No. = %3.', Comment = '%1=UOM Code;%2=Item No.;%3=Production BOM No.';
        BOMLineUOMErr: Label 'The Unit of Measure Code %1 for Item %2 does not exist. Identification fields and values: Production BOM No. = %3, Version Code = %4, Line No. = %5.', Comment = '%1=UOM Code;%2=Item No.;%3=Production BOM No.;%4=Version Code;%5=Line No.';
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure TestStatus()
    var
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if IsTemporary then
            exit;

        if "Version Code" = '' then begin
            ProdBOMHeader.Get("Production BOM No.");
            if ProdBOMHeader.Status = ProdBOMHeader.Status::Certified then
                ProdBOMHeader.FieldError(Status);
        end else begin
            ProdBOMVersion.Get("Production BOM No.", "Version Code");
            if ProdBOMVersion.Status = ProdBOMVersion.Status::Certified then
                ProdBOMVersion.FieldError(Status);
        end;

        OnAfterTestStatus(Rec, ProdBOMHeader, ProdBOMVersion);
    end;

    procedure GetQtyPerUnitOfMeasure(): Decimal
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if Type = Type::Item then begin
            Item.Get("No.");
            exit(
              UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"));
        end;
        exit(1);
    end;

    procedure GetBOMHeaderQtyPerUOM(Item: Record Item): Decimal
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if "Production BOM No." = '' then
            exit(1);

        if "Version Code" <> '' then begin
            ProdBOMVersion.Get("Production BOM No.", "Version Code");
            if not ItemUnitOfMeasure.Get(Item."No.", ProdBOMVersion."Unit of Measure Code") then
                Error(BOMVersionUOMErr, ProdBOMVersion."Unit of Measure Code", Item."No.", "Production BOM No.", "Version Code");
            exit(UOMMgt.GetQtyPerUnitOfMeasure(Item, ProdBOMVersion."Unit of Measure Code"));
        end;

        ProdBOMHeader.Get("Production BOM No.");
        if not ItemUnitOfMeasure.Get(Item."No.", ProdBOMHeader."Unit of Measure Code") then
            Error(BOMHeaderUOMErr, ProdBOMHeader."Unit of Measure Code", Item."No.", "Production BOM No.");
        exit(UOMMgt.GetQtyPerUnitOfMeasure(Item, ProdBOMHeader."Unit of Measure Code"));
    end;

    procedure GetBOMLineQtyPerUOM(Item: Record Item): Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if "No." = '' then
            exit(1);

        if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
            Error(BOMLineUOMErr, "Unit of Measure Code", Item."No.", "Production BOM No.", "Version Code", "Line No.");
        exit(UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatus(ProductionBOMLine: Record "Production BOM Line"; ProductionBOMHeader: Record "Production BOM Header"; ProductionBOMVersion: Record "Production BOM Version")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNo(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnCaseTypeElse(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCalculationFormulaEnumExtension(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterAssignItemFields(var ProductionBOMLine: Record "Production BOM Line"; Item: Record Item; var xProductionBOMLine: Record "Production BOM Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterAssignProdBOMFields(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMHeader: Record "Production BOM Header"; var xProductionBOMLine: Record "Production BOM Line"; CallingFieldNo: Integer)
    begin
    end;
}


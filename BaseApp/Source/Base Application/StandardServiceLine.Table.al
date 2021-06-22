table 5997 "Standard Service Line"
{
    Caption = 'Standard Service Line';

    fields
    {
        field(1; "Standard Service Code"; Code[10])
        {
            Caption = 'Standard Service Code';
            Editable = false;
            TableRelation = "Standard Service Code";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; Type; Enum "Service Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                OldType: Integer;
            begin
                OldType := Type;
                Init;
                Type := OldType;
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST(Item)) Item WHERE(Blocked = CONST(false))
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST(Cost)) "Service Cost"
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account";

            trigger OnValidate()
            var
                StdTxt: Record "Standard Text";
                GLAcc: Record "G/L Account";
                Item: Record Item;
                Res: Record Resource;
                ServCost: Record "Service Cost";
            begin
                if "No." <> xRec."No." then begin
                    Quantity := 0;
                    "Amount Excl. VAT" := 0;
                    "Unit of Measure Code" := '';
                    Description := '';
                    if "No." = '' then
                        exit;
                    StdServCode.Get("Standard Service Code");
                    case Type of
                        Type::" ":
                            begin
                                StdTxt.Get("No.");
                                Description := StdTxt.Description;
                            end;
                        Type::Item:
                            begin
                                Item.Get("No.");
                                Item.TestField(Blocked, false);
                                if Item.Type = Item.Type::Inventory then
                                    Item.TestField("Inventory Posting Group");
                                Item.TestField("Gen. Prod. Posting Group");
                                Description := Item.Description;
                                "Unit of Measure Code" := Item."Sales Unit of Measure";
                                "Variant Code" := '';
                            end;
                        Type::Resource:
                            begin
                                Res.Get("No.");
                                Res.CheckResourcePrivacyBlocked(false);
                                Res.TestField(Blocked, false);
                                Res.TestField("Gen. Prod. Posting Group");
                                Description := Res.Name;
                                "Unit of Measure Code" := Res."Base Unit of Measure";
                            end;
                        Type::Cost:
                            begin
                                ServCost.Get("No.");
                                GLAcc.Get(ServCost."Account No.");
                                GLAcc.TestField("Gen. Prod. Posting Group");
                                Description := ServCost.Description;
                                Quantity := ServCost."Default Quantity";
                                "Unit of Measure Code" := ServCost."Unit of Measure Code";
                            end;
                        Type::"G/L Account":
                            begin
                                GLAcc.Get("No.");
                                GLAcc.CheckGLAcc;
                                GLAcc.TestField("Direct Posting", true);
                                Description := GLAcc.Name;
                            end;
                    end;
                end;

                CreateDim(DimMgt.TypeToTableID5(Type), "No.");
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Quantity; Decimal)
        {
            BlankZero = true;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField(Type);
                TestField("No.");
                if Quantity < 0 then
                    FieldError(Quantity, Text002);
            end;
        }
        field(7; "Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrency;
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Amount Excl. VAT';

            trigger OnValidate()
            begin
                if Type <> Type::"G/L Account" then
                    FieldError(Type, StrSubstNo(Text001, Type));
            end;
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            "Unit of Measure";

            trigger OnValidate()
            begin
                TestField(Type);
            end;
        }
        field(9; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(10; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        Item.Get("No.");
                        Description := Item.Description;
                    end;
                    exit;
                end;

                TestField(Type, Type::Item);
                ItemVariant.Get("No.", "Variant Code");
                Description := ItemVariant.Description;
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Standard Service Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        StdServCode.Get("Standard Service Code");
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        StdServCode: Record "Standard Service Code";
        DimMgt: Codeunit DimensionManagement;
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'must not be %1';
        Text002: Label 'must be positive';

    procedure EmptyLine(): Boolean
    begin
        exit(("No." = '') and (Quantity = 0))
    end;

    procedure InsertLine(): Boolean
    begin
        exit((Type = Type::" ") or not EmptyLine);
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if StdServCode.Get("Standard Service Code") then
            exit(StdServCode."Currency Code");
        exit('');
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        Modify;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();

        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var StandardServiceLine: Record "Standard Service Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var StandardServiceLine: Record "Standard Service Line"; var xStandardServiceLine: Record "Standard Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var StandardServiceLine: Record "Standard Service Line"; var xStandardServiceLine: Record "Standard Service Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}


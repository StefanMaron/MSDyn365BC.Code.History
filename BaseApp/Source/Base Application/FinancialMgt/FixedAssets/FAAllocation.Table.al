table 5615 "FA Allocation"
{
    Caption = 'FA Allocation';
    DrillDownPageID = "FA Allocations";
    LookupPageID = "FA Allocations";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "FA Posting Group";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                if "Account No." = '' then
                    exit;
                GLAcc.Get("Account No.");
                GLAcc.CheckGLAcc();
                if "Allocation Type".AsInteger() < "Allocation Type"::Gain.AsInteger() then
                    GLAcc.TestField("Direct Posting");
                Description := GLAcc.Name;
            end;
        }
        field(5; "Global Dimension 1 Code"; Code[20])
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
        field(6; "Global Dimension 2 Code"; Code[20])
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
        field(7; "Allocation %"; Decimal)
        {
            Caption = 'Allocation %';
            DecimalPlaces = 1 : 1;
            MaxValue = 100;
            MinValue = 0;
        }
        field(8; "Allocation Type"; Enum "FA Allocation Type")
        {
            Caption = 'Allocation Type';
        }
        field(9; "Account Name"; Text[100])
        {
            CalcFormula = Lookup("G/L Account".Name WHERE("No." = FIELD("Account No.")));
            Caption = 'Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Code", "Allocation Type", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Allocation Type", "Code")
        {
            SumIndexFields = "Allocation %";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Dimension Set ID" := 0;
        "Global Dimension 1 Code" := '';
        "Global Dimension 2 Code" := '';
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        GLAcc: Record "G/L Account";
        DimMgt: Codeunit DimensionManagement;

        Text000: Label 'You cannot rename a %1.';

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', Code, "Allocation Type", "Line No."),
            "Global Dimension 1 Code", "Global Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var FAAllocation: Record "FA Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var FAAllocation: Record "FA Allocation"; var xFAAllocation: Record "FA Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var FAAllocation: Record "FA Allocation"; var xFAAllocation: Record "FA Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}


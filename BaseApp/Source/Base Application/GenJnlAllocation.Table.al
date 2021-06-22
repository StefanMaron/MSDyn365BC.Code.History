table 221 "Gen. Jnl. Allocation"
{
    Caption = 'Gen. Jnl. Allocation';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
            TableRelation = "Gen. Journal Line"."Line No." WHERE("Journal Template Name" = FIELD("Journal Template Name"),
                                                                  "Journal Batch Name" = FIELD("Journal Batch Name"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                if "Account No." = '' then begin
                    GLAcc.Init();
                    CreateDim(DATABASE::"G/L Account", "Account No.");
                end else begin
                    GLAcc.Get("Account No.");
                    GLAcc.CheckGLAcc;
                    GLAcc.TestField("Direct Posting", true);
                end;
                "Account Name" := GLAcc.Name;

                if CopyVATSetupToJnlLines() then begin
                    "Gen. Posting Type" := GLAcc."Gen. Posting Type";
                    "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
                    "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
                    "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
                    "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
                    Validate("VAT Prod. Posting Group");
                end;

                CreateDim(DATABASE::"G/L Account", "Account No.");
            end;
        }
        field(6; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify;
            end;
        }
        field(7; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify;
            end;
        }
        field(8; "Allocation Quantity"; Decimal)
        {
            Caption = 'Allocation Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Allocation Quantity" = 0 then begin
                    "Allocation %" := 0;
                    Amount := 0;
                end;
                UpdateAllocations(GenJnlLine);
            end;
        }
        field(9; "Allocation %"; Decimal)
        {
            Caption = 'Allocation %';
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                "Allocation Quantity" := 0;
                if "Allocation %" = 0 then
                    Amount := 0;
                UpdateAllocations(GenJnlLine);
            end;
        }
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if ("Allocation Quantity" <> 0) or ("Allocation %" <> 0) then begin
                    "Allocation Quantity" := 0;
                    "Allocation %" := 0;
                    UpdateAllocations(GenJnlLine);
                end else begin
                    Validate("VAT Prod. Posting Group");
                    Modify;
                    UpdateJnlBalance(GenJnlLine);
                end;
            end;
        }
        field(11; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(12; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(13; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(14; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(15; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(16; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(17; "Account Name"; Text[100])
        {
            CalcFormula = Lookup ("G/L Account".Name WHERE("No." = FIELD("Account No.")));
            Caption = 'Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(19; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(20; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(21; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(22; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                GenJnlLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.");
                CheckVAT(GenJnlLine);
                UpdateVAT(GenJnlLine);
            end;
        }
        field(24; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            Editable = false;
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
        key(Key1; "Journal Template Name", "Journal Batch Name", "Journal Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Validate(Amount, 0);
    end;

    trigger OnInsert()
    begin
        LockTable();
        GenJnlLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.");

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        Text000: Label '%1 cannot be used in allocations when they are completed on the general journal line.';
        GLAcc: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        DimMgt: Codeunit DimensionManagement;

    local procedure CopyVATSetupToJnlLines(): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if ("Journal Template Name" <> '') and ("Journal Batch Name" <> '') then
            if GenJournalBatch.Get("Journal Template Name", "Journal Batch Name") then
                exit(GenJournalBatch."Copy VAT Setup to Jnl. Lines");

        exit(true);
    end;

    procedure UpdateAllocations(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        GenJnlAlloc2: Record "Gen. Jnl. Allocation";
        FromAllocations: Boolean;
        TotalQty: Decimal;
        TotalPct: Decimal;
        TotalPctRnded: Decimal;
        TotalAmountLCY: Decimal;
        TotalAmountLCY2: Decimal;
        TotalAmountLCYRnded: Decimal;
        TotalAmountLCYRnded2: Decimal;
        UpdateGenJnlLine: Boolean;
    begin
        if "Line No." <> 0 then begin
            FromAllocations := true;
            GenJnlAlloc.UpdateVAT(GenJnlLine);
            Modify;
            GenJnlLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.");
            CheckVAT(GenJnlLine);
        end;

        GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine."Line No.");
        if FromAllocations then
            UpdateGenJnlLine := true
        else
            if not GenJnlAlloc.IsEmpty then begin
                GenJnlAlloc.LockTable();
                UpdateGenJnlLine := true;
            end;

        if GenJnlAlloc.FindSet then
            repeat
                if (GenJnlAlloc."Allocation Quantity" <> 0) or (GenJnlAlloc."Allocation %" <> 0) then begin
                    if not FromAllocations then
                        GenJnlAlloc.CheckVAT(GenJnlLine);
                    if GenJnlAlloc."Allocation Quantity" = 0 then begin
                        TotalAmountLCY2 := TotalAmountLCY2 - GenJnlLine."Amount (LCY)" * GenJnlAlloc."Allocation %" / 100;
                        GenJnlAlloc.Amount := Round(TotalAmountLCY2) - TotalAmountLCYRnded2;
                        TotalAmountLCYRnded2 := TotalAmountLCYRnded2 + GenJnlAlloc.Amount;
                    end else begin
                        if TotalQty = 0 then begin
                            GenJnlAlloc2.Copy(GenJnlAlloc);
                            GenJnlAlloc2.SetFilter("Allocation Quantity", '<>0');
                            GenJnlAlloc2.CalcSums("Allocation Quantity");
                            TotalQty := GenJnlAlloc2."Allocation Quantity";
                            if TotalQty = 0 then
                                TotalQty := 1;
                        end;
                        TotalPct := TotalPct + GenJnlAlloc."Allocation Quantity" / TotalQty * 100;
                        GenJnlAlloc."Allocation %" := Round(TotalPct, 0.01) - TotalPctRnded;
                        TotalPctRnded := TotalPctRnded + GenJnlAlloc."Allocation %";
                        TotalAmountLCY := TotalAmountLCY - GenJnlLine."Amount (LCY)" * GenJnlAlloc."Allocation Quantity" / TotalQty;
                        GenJnlAlloc.Amount := Round(TotalAmountLCY) - TotalAmountLCYRnded;
                        TotalAmountLCYRnded := TotalAmountLCYRnded + GenJnlAlloc.Amount;
                    end;
                    GenJnlAlloc.UpdateVAT(GenJnlLine);
                    GenJnlAlloc.Modify();
                end;
            until GenJnlAlloc.Next = 0;

        if UpdateGenJnlLine then
            UpdateJnlBalance(GenJnlLine);

        if FromAllocations then
            Find;
    end;

    procedure UpdateAllocationsAddCurr(var GenJnlLine: Record "Gen. Journal Line"; AddCurrAmount: Decimal)
    var
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        GenJnlAlloc2: Record "Gen. Jnl. Allocation";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        TotalQty: Decimal;
        TotalPct: Decimal;
        TotalPctRnded: Decimal;
        TotalAmountAddCurr: Decimal;
        TotalAmountAddCurr2: Decimal;
        TotalAmountAddCurrRnded: Decimal;
        TotalAmountAddCurrRnded2: Decimal;
    begin
        GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine."Line No.");
        GenJnlAlloc.LockTable();
        if GenJnlAlloc.FindSet then begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            repeat
                if (GenJnlAlloc."Allocation Quantity" <> 0) or (GenJnlAlloc."Allocation %" <> 0) then begin
                    if GenJnlAlloc."Allocation Quantity" = 0 then begin
                        TotalAmountAddCurr2 :=
                          TotalAmountAddCurr2 - AddCurrAmount * GenJnlAlloc."Allocation %" / 100;
                        GenJnlAlloc."Additional-Currency Amount" :=
                          Round(TotalAmountAddCurr2, Currency."Amount Rounding Precision") -
                          TotalAmountAddCurrRnded2;
                        TotalAmountAddCurrRnded2 :=
                          TotalAmountAddCurrRnded2 + GenJnlAlloc."Additional-Currency Amount";
                    end else begin
                        if TotalQty = 0 then begin
                            GenJnlAlloc2.Copy(GenJnlAlloc);
                            GenJnlAlloc2.SetFilter("Allocation Quantity", '<>0');
                            repeat
                                TotalQty := TotalQty + GenJnlAlloc2."Allocation Quantity";
                            until GenJnlAlloc2.Next = 0;
                            if TotalQty = 0 then
                                TotalQty := 1;
                        end;
                        TotalPct := TotalPct + GenJnlAlloc."Allocation Quantity" / TotalQty * 100;
                        GenJnlAlloc."Allocation %" := Round(TotalPct, 0.01) - TotalPctRnded;
                        TotalPctRnded := TotalPctRnded + GenJnlAlloc."Allocation %";
                        TotalAmountAddCurr :=
                          TotalAmountAddCurr -
                          AddCurrAmount * GenJnlAlloc."Allocation Quantity" / TotalQty;
                        GenJnlAlloc."Additional-Currency Amount" :=
                          Round(TotalAmountAddCurr, Currency."Amount Rounding Precision") -
                          TotalAmountAddCurrRnded;
                        TotalAmountAddCurrRnded :=
                          TotalAmountAddCurrRnded + GenJnlAlloc."Additional-Currency Amount";
                    end;
                    GenJnlAlloc.Modify();
                end;
            until GenJnlAlloc.Next = 0;
        end;
    end;

    local procedure UpdateJnlBalance(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.CalcFields("Allocated Amt. (LCY)");
        if GenJnlLine."Bal. Account No." = '' then
            GenJnlLine."Balance (LCY)" := GenJnlLine."Amount (LCY)" + GenJnlLine."Allocated Amt. (LCY)"
        else
            GenJnlLine."Balance (LCY)" := GenJnlLine."Allocated Amt. (LCY)";
        GenJnlLine.Modify();
    end;

    procedure CheckVAT(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if ("Gen. Posting Type" <> 0) and (GenJnlLine."Gen. Posting Type" <> 0) then
            Error(
              Text000,
              GenJnlLine.FieldCaption("Gen. Posting Type"));
    end;

    procedure UpdateVAT(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2.CopyFromGenJnlAllocation(Rec);
        GenJnlLine2."Posting Date" := GenJnlLine."Posting Date";
        GenJnlLine2.Validate("VAT Prod. Posting Group");
        Amount := GenJnlLine2."Amount (LCY)";
        "VAT Calculation Type" := GenJnlLine2."VAT Calculation Type";
        "VAT Amount" := GenJnlLine2."VAT Amount";
        "VAT %" := GenJnlLine2."VAT %";
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        GenJnlLine3: Record "Gen. Journal Line";
    begin
        GenJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlLine3.SetRange("Line No.", "Journal Line No.");
        if GenJnlLine3.FindFirst then
            exit(GenJnlLine3."Currency Code");

        exit('');
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(Rec, CurrFieldNo, TableID, No, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
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

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID",
            StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Journal Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var FieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var xGenJnlAllocation: Record "Gen. Jnl. Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var xGenJnlAllocation: Record "Gen. Jnl. Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}


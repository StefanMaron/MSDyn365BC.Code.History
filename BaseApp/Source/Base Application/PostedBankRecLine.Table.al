table 10124 "Posted Bank Rec. Line"
{
    Caption = 'Posted Bank Rec. Line';
    DrillDownPageID = "Posted Bank Rec. Lines";
    LookupPageID = "Posted Bank Rec. Lines";

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Posted Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Record Type"; Option)
        {
            Caption = 'Record Type';
            OptionCaption = 'Check,Deposit,Adjustment';
            OptionMembers = Check,Deposit,Adjustment;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(9; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(12; Cleared; Boolean)
        {
            Caption = 'Cleared';
        }
        field(13; "Cleared Amount"; Decimal)
        {
            Caption = 'Cleared Amount';
        }
        field(14; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(15; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(17; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(18; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(19; "Bank Ledger Entry No."; Integer)
        {
            Caption = 'Bank Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
        }
        field(20; "Check Ledger Entry No."; Integer)
        {
            Caption = 'Check Ledger Entry No.';
            TableRelation = "Check Ledger Entry"."Entry No.";
        }
        field(21; "Adj. Source Record ID"; Option)
        {
            Caption = 'Adj. Source Record ID';
            OptionCaption = 'Check,Deposit,Adjustment';
            OptionMembers = Check,Deposit,Adjustment;
        }
        field(22; "Adj. Source Document No."; Code[20])
        {
            Caption = 'Adj. Source Document No.';
        }
        field(23; "Adj. No. Series"; Code[20])
        {
            Caption = 'Adj. No. Series';
            TableRelation = "No. Series";
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(27; Positive; Boolean)
        {
            Caption = 'Positive';
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
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Record Type", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Statement No.", "Record Type", Cleared)
        {
            SumIndexFields = Amount, "Cleared Amount";
        }
        key(Key3; "Bank Account No.", "Statement No.", "Record Type", Positive)
        {
            SumIndexFields = Amount;
        }
        key(Key4; "Bank Account No.", "Statement No.", "Posting Date", "Document Type", "Document No.", "External Document No.")
        {
        }
        key(Key5; "Bank Account No.", "Statement No.", "Record Type", "Bal. Account Type", "Bal. Account No.", Positive)
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Bank Account No.", "Statement No.", "Record Type", "Account Type", Positive, "Account No.")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        BankRecCommentLine.SetRange("Table Name", BankRecCommentLine."Table Name"::"Bank Rec.");
        BankRecCommentLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecCommentLine.SetRange("No.", "Statement No.");
        BankRecCommentLine.SetRange("Line No.", "Line No.");
        BankRecCommentLine.DeleteAll();
    end;

    var
        BankRecCommentLine: Record "Bank Comment Line";
        DimMgt: Codeunit DimensionManagement;

#if not CLEAN20
    [Obsolete('Replaced by CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]', '20.0')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;

        IsHandled := false;
        OnCreateDimOnAfterSetTableIDs(Rec, TableID, No, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimMgt.GetDefaultDimID(TableID, No, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;
#endif

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN20
        RunEventOnCreateDimOnAfterSetTableIDs(DefaultDimSource, IsHandled);
#endif
        OnBeforeCreateDim(Rec, DefaultDimSource, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimMgt.GetDefaultDimID(DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

#if not CLEAN20
    local procedure RunEventOnCreateDimOnAfterSetTableIDs(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        DimArrayConversionHelper.CreateDimTableIDs(Rec, DefaultDimSource, TableID, No);
        OnCreateDimOnAfterSetTableIDs(Rec, TableID, No, IsHandled);
        DimArrayConversionHelper.CreateDefaultDimSourcesFromDimArray(Database::"Posted Bank Rec. Line", DefaultDimSource, TableID, No);
    end;

    [Obsolete('Replaced by OnBeforeCreateDim()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnAfterSetTableIDs(var PostedBankAccRecLine: Record "Posted Bank Rec. Line"; TableID: array[10] of Integer; No: array[10] of Code[20]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var PostedBankAccRecLine: Record "Posted Bank Rec. Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var PostedBankAccRecLine: Record "Posted Bank Rec. Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var PostedBankAccRecLine: Record "Posted Bank Rec. Line")
    begin
    end;
}


table 11307 "G/L Entry Application Buffer"
{
    Caption = 'G/L Entry Application Buffer';
    DrillDownPageID = "General Ledger Entries";
    LookupPageID = "General Ledger Entries";
    Permissions = TableData "G/L Entry" = rimd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
            DataClassification = SystemMetadata;
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(10; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = SystemMetadata;
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
        field(17; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = SystemMetadata;
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = SystemMetadata;
            TableRelation = "Source Code";
        }
        field(29; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = SystemMetadata;
        }
        field(30; "Prior-Year Entry"; Boolean)
        {
            Caption = 'Prior-Year Entry';
            DataClassification = SystemMetadata;
        }
        field(41; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        field(42; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(43; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            DataClassification = SystemMetadata;
        }
        field(45; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            DataClassification = SystemMetadata;
            TableRelation = "Business Unit";
        }
        field(46; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
        field(47; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = SystemMetadata;
            TableRelation = "Reason Code";
        }
        field(48; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(49; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        field(50; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        field(51; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = SystemMetadata;
        }
        field(52; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        field(53; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(54; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(55; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
            DataClassification = SystemMetadata;
        }
        field(56; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(57; "Source Type"; Option)
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(58; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = SystemMetadata;
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Source Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(59; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = SystemMetadata;
            TableRelation = "No. Series";
        }
        field(60; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        field(61; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        field(62; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        field(63; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        field(64; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(65; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(68; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(69; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(70; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(71; "Close Income Statement Dim. ID"; Integer)
        {
            Caption = 'Close Income Statement Dim. ID';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(5400; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = SystemMetadata;
        }
        field(5600; "FA Entry Type"; Option)
        {
            Caption = 'FA Entry Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Fixed Asset,Maintenance';
            OptionMembers = " ","Fixed Asset",Maintenance;
        }
        field(5601; "FA Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = IF ("FA Entry Type" = CONST("Fixed Asset")) "FA Ledger Entry"
            ELSE
            IF ("FA Entry Type" = CONST(Maintenance)) "Maintenance Ledger Entry";
        }
        field(11300; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Template";
        }
        field(11301; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(11302; "Remaining Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(11303; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            DataClassification = SystemMetadata;
        }
        field(11304; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
            DataClassification = SystemMetadata;
        }
        field(11305; "Closed by Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
            DataClassification = SystemMetadata;
        }
        field(11306; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "G/L Account No.", "Posting Date", "Entry No.", Open)
        {
        }
        key(Key3; "Applies-to ID")
        {
        }
        key(Key4; "Closed by Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;
        AnotherUserModifiedTheRecordErr: Label 'Another user has modified the record for this %1 after you retrieved it from the database.', Comment = '%1 table caption';

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimManagement: Codeunit DimensionManagement;
    begin
        "Dimension Set ID" := DimManagement.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Entry No.", "G/L Account No."),
            "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure GetAppliedEntries(var TempGLEntryApplicationBuffer: Record "G/L Entry Application Buffer" temporary; OrgGLEntry: Record "G/L Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        if OrgGLEntry."Closed by Entry No." <> 0 then begin
            GLEntry.Get(OrgGLEntry."Closed by Entry No.");
            TempGLEntryApplicationBuffer.TransferFields(GLEntry);
            TempGLEntryApplicationBuffer.Insert();
        end else begin
            GLEntry.SetCurrentKey("Closed by Entry No.");
            GLEntry.SetRange("Closed by Entry No.", OrgGLEntry."Entry No.");
            if GLEntry.FindSet() then
                repeat
                    if GLEntry."Entry No." <> OrgGLEntry."Entry No." then begin
                        TempGLEntryApplicationBuffer.TransferFields(GLEntry);
                        TempGLEntryApplicationBuffer.Insert();
                    end;
                until GLEntry.Next() = 0;
        end;
    end;

    procedure Apply(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer")
    var
        GLEntry: Record "G/L Entry";
        AppliedAmount: Decimal;
        TotalAppliedAmount: Decimal;
        BaseEntryNo: Integer;
    begin
        GLEntryApplicationBuffer.TestField("Applies-to ID");
        BaseEntryNo := GLEntryApplicationBuffer."Entry No.";

        RealEntryChanged(GLEntryApplicationBuffer, GLEntry);

        GLEntryApplicationBuffer.SetRange("Applies-to ID", GLEntryApplicationBuffer."Applies-to ID");
        GLEntryApplicationBuffer.SetFilter("Entry No.", '<> %1', GLEntryApplicationBuffer."Entry No.");
        if GLEntryApplicationBuffer.FindSet() then begin
            repeat
                GLEntryApplicationBuffer.TestField("G/L Account No.", GLEntryApplicationBuffer."G/L Account No.");
                GLEntryApplicationBuffer.TestField(Open, true);
                AppliedAmount := -GLEntryApplicationBuffer."Remaining Amount";
                TotalAppliedAmount := TotalAppliedAmount + AppliedAmount;
                RealEntryChanged(GLEntryApplicationBuffer, GLEntry);
                OnApplyOnBeforeUpdateTables(Rec, GLEntryApplicationBuffer, GLEntry, AppliedAmount, TotalAppliedAmount, BaseEntryNo);
                UpdateTempTable(GLEntryApplicationBuffer, 0, false, BaseEntryNo, "Posting Date", -AppliedAmount, '');
                UpdateRealTable(GLEntry, 0, false, BaseEntryNo, "Posting Date", -AppliedAmount, '');
            until GLEntryApplicationBuffer.Next() = 0;
        end else
            exit;

        // Update entry where cursor is on
        // Update real Table
        GLEntry.Get(BaseEntryNo);
        UpdateRealTable(
          GLEntry, GLEntry."Remaining Amount" - TotalAppliedAmount,
          (GLEntry."Remaining Amount" - TotalAppliedAmount) <> 0, 0, 0D, 0, '');

        // Update Temporary Table
        with GLEntryApplicationBuffer do begin
            Get(BaseEntryNo);
            UpdateTempTable(
              GLEntryApplicationBuffer, "Remaining Amount" - TotalAppliedAmount,
              ("Remaining Amount" - TotalAppliedAmount) <> 0, 0, 0D, 0, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure Undo(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer")
    var
        OrgGLEntry: Record "G/L Entry";
        GLEntry: Record "G/L Entry";
        UndoGLEntry: Record "G/L Entry";
        BaseEntryNo: Integer;
    begin
        // 'Real' G/L Entry changed whilst undoing ?
        RealEntryChanged(GLEntryApplicationBuffer, GLEntry);

        with GLEntryApplicationBuffer do begin
            Reset();

            if "Closed by Entry No." <> 0 then begin
                OrgGLEntry.Get("Closed by Entry No.");
                OrgGLEntry.TestField("Closed by Entry No.", 0);
            end else
                OrgGLEntry.Get("Entry No.");
            BaseEntryNo := OrgGLEntry."Entry No.";

            UndoGLEntry.SetCurrentKey("Closed by Entry No.");
            UndoGLEntry.SetRange("Closed by Entry No.", OrgGLEntry."Entry No.");
            if UndoGLEntry.FindSet() then
                repeat
                    RealEntryChanged(GLEntryApplicationBuffer, GLEntry);
                    if Get(UndoGLEntry."Entry No.") then
                        UpdateTempTable(GLEntryApplicationBuffer, "Closed by Amount", true, 0, 0D, 0, '');
                    UpdateRealTable(UndoGLEntry, UndoGLEntry."Closed by Amount", true, 0, 0D, 0, '');
                until UndoGLEntry.Next() = 0;

            GLEntry.Get(BaseEntryNo);
            UpdateRealTable(GLEntry, GLEntry.Amount, true, 0, 0D, 0, '');
            if Get(BaseEntryNo) then
                UpdateTempTable(GLEntryApplicationBuffer, Amount, true, 0, 0D, 0, '');

            SetRange("Closed by Entry No.");
            SetCurrentKey("G/L Account No.", "Posting Date", "Entry No.", Open);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateTempTable(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; RemainingAmt: Decimal; IsOpen: Boolean; ClosedbyEntryNo: Integer; ClosedbyDate: Date; ClosedbyAmt: Decimal; AppliesToID: Code[20])
    begin
        // Update Temporary Table
        with GLEntryApplicationBuffer do begin
            "Remaining Amount" := RemainingAmt;
            Open := IsOpen;
            "Closed by Entry No." := ClosedbyEntryNo;
            "Closed at Date" := ClosedbyDate;
            "Closed by Amount" := ClosedbyAmt;
            "Applies-to ID" := AppliesToID;
            Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateRealTable(GLEntry: Record "G/L Entry"; RemainingAmt: Decimal; IsOpen: Boolean; ClosedbyEntryNo: Integer; ClosedbyDate: Date; ClosedbyAmt: Decimal; AppliesToID: Code[20])
    begin
        // Update Temporary Table
        GLEntry."Remaining Amount" := RemainingAmt;
        GLEntry.Open := IsOpen;
        GLEntry."Closed by Entry No." := ClosedbyEntryNo;
        GLEntry."Closed at Date" := ClosedbyDate;
        GLEntry."Closed by Amount" := ClosedbyAmt;
        GLEntry."Applies-to ID" := AppliesToID;
        GLEntry.Modify();
    end;

    [Scope('OnPrem')]
    procedure RealEntryChanged(GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; var GlEntry: Record "G/L Entry")
    begin
        // 'Real' G/L Entry changed whilst application ?
        GlEntry.Get(GLEntryApplicationBuffer."Entry No.");
        if (GlEntry."Remaining Amount" <> GLEntryApplicationBuffer."Remaining Amount") or
           (GlEntry.Open <> GLEntryApplicationBuffer.Open) or
           (GlEntry."Closed by Entry No." <> GLEntryApplicationBuffer."Closed by Entry No.") or
           (GlEntry."Closed at Date" <> GLEntryApplicationBuffer."Closed at Date") or
           (GlEntry."Closed by Amount" <> GLEntryApplicationBuffer."Closed by Amount")
        then
            Error(AnotherUserModifiedTheRecordErr, TableCaption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforeUpdateTables(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; var OrigGLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; GLEntry: Record "G/L Entry"; AppliedAmount: Decimal; TotalAppliedAmount: Decimal; BaseEntryNo: Integer)
    begin
    end;
}


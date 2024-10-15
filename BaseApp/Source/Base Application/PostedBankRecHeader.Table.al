table 10123 "Posted Bank Rec. Header"
{
    Caption = 'Posted Bank Rec. Header';
    DrillDownPageID = "Posted Bank Rec. List";
    LookupPageID = "Posted Bank Rec. List";

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
        }
        field(3; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
        }
        field(4; "Statement Balance"; Decimal)
        {
            Caption = 'Statement Balance';
        }
        field(5; "G/L Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'G/L Balance ($)';
            Editable = false;
        }
        field(6; "Positive Adjustments"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Adjustment),
                                                                    Positive = CONST(true),
                                                                    "Account Type" = CONST("Bank Account"),
                                                                    "Account No." = FIELD("Bank Account No.")));
            Caption = 'Positive Adjustments';
            FieldClass = FlowField;
        }
        field(7; "Negative Adjustments"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Adjustment),
                                                                    Positive = CONST(false),
                                                                    "Account Type" = CONST("Bank Account"),
                                                                    "Account No." = FIELD("Bank Account No.")));
            Caption = 'Negative Adjustments';
            FieldClass = FlowField;
        }
        field(8; "Outstanding Deposits"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Deposit),
                                                                    Cleared = CONST(false)));
            Caption = 'Outstanding Deposits';
            FieldClass = FlowField;
        }
        field(9; "Outstanding Checks"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Check),
                                                                    Cleared = CONST(false)));
            Caption = 'Outstanding Checks';
            FieldClass = FlowField;
        }
        field(10; "Date Created"; Date)
        {
            Caption = 'Date Created';
        }
        field(11; "Time Created"; Time)
        {
            Caption = 'Time Created';
        }
        field(12; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(14; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(16; "Cleared With./Chks. Per Stmnt."; Decimal)
        {
            Caption = 'Cleared With./Chks. Per Stmnt.';
        }
        field(17; "Cleared Inc./Dpsts. Per Stmnt."; Decimal)
        {
            Caption = 'Cleared Inc./Dpsts. Per Stmnt.';
        }
        field(19; "Total Cleared Checks"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line"."Cleared Amount" WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                              "Statement No." = FIELD("Statement No."),
                                                                              "Record Type" = CONST(Check),
                                                                              Cleared = CONST(true)));
            Caption = 'Total Cleared Checks';
            FieldClass = FlowField;
        }
        field(20; "Total Cleared Deposits"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line"."Cleared Amount" WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                              "Statement No." = FIELD("Statement No."),
                                                                              "Record Type" = CONST(Deposit),
                                                                              Cleared = CONST(true)));
            Caption = 'Total Cleared Deposits';
            FieldClass = FlowField;
        }
        field(21; "Total Adjustments"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Adjustment)));
            Caption = 'Total Adjustments';
            FieldClass = FlowField;
        }
        field(22; "G/L Bank Account No."; Code[20])
        {
            Caption = 'G/L Bank Account No.';
            Editable = false;
            TableRelation = "G/L Account";
        }
        field(23; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(24; Comment; Boolean)
        {
            CalcFormula = Exist("Bank Comment Line" WHERE("Table Name" = CONST("Posted Bank Rec."),
                                                           "Bank Account No." = FIELD("Bank Account No."),
                                                           "No." = FIELD("Statement No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(26; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(27; "G/L Balance"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'G/L Balance';
            Editable = false;
        }
        field(28; "Total Balanced Adjustments"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Adjustment),
                                                                    "Bal. Account No." = FILTER(<> '')));
            Caption = 'Total Balanced Adjustments';
            FieldClass = FlowField;
        }
        field(29; "Positive Bal. Adjustments"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Adjustment),
                                                                    Positive = CONST(true),
                                                                    "Bal. Account No." = FIELD("Bank Account No."),
                                                                    "Bal. Account Type" = CONST("Bank Account")));
            Caption = 'Positive Bal. Adjustments';
            FieldClass = FlowField;
        }
        field(30; "Negative Bal. Adjustments"; Decimal)
        {
            CalcFormula = Sum("Posted Bank Rec. Line".Amount WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                    "Statement No." = FIELD("Statement No."),
                                                                    "Record Type" = CONST(Adjustment),
                                                                    Positive = CONST(false),
                                                                    "Bal. Account No." = FIELD("Bank Account No."),
                                                                    "Bal. Account Type" = CONST("Bank Account")));
            Caption = 'Negative Bal. Adjustments';
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim;
            end;
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PostedBankRecDelete.Run(Rec);
    end;

    var
#if not CLEAN20
        PostedBankRecHdr: Record "Posted Bank Rec. Header";
#endif
        PostedBankRecLines: Record "Posted Bank Rec. Line";
        PostedBankRecDelete: Codeunit "Posted Bank Rec.-Delete";
        DimMgt: Codeunit DimensionManagement;
        Text001: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    procedure PrintRecords(ShowRequestForm: Boolean)
    begin
#if not CLEAN20
        PostedBankRecHdr.Copy(Rec);
        Report.RunModal(Report::"Bank Reconciliation", ShowRequestForm, false, PostedBankRecHdr);
#endif
    end;

    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Statement Date", "Statement No.");
        NavigateForm.Run();
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Bank Account No.", "Statement No."));
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if PostedBankRecLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure PostedBankRecLinesExist(): Boolean
    begin
        PostedBankRecLines.Reset();
        PostedBankRecLines.SetRange("Bank Account No.", "Bank Account No.");
        PostedBankRecLines.SetRange("Statement No.", "Statement No.");
        exit(PostedBankRecLines.FindFirst);
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text001) then
            exit;

        PostedBankRecLines.Reset();
        PostedBankRecLines.SetRange("Bank Account No.", "Bank Account No.");
        PostedBankRecLines.SetRange("Statement No.", "Statement No.");
        PostedBankRecLines.LockTable();
        if PostedBankRecLines.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(PostedBankRecLines."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if PostedBankRecLines."Dimension Set ID" <> NewDimSetID then begin
                    PostedBankRecLines."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      PostedBankRecLines."Dimension Set ID", PostedBankRecLines."Shortcut Dimension 1 Code",
                      PostedBankRecLines."Shortcut Dimension 2 Code");
                    OnUpdateAllLineDimOnBeforePostedBankRecLinesModify(PostedBankRecLines);
                    PostedBankRecLines.Modify();
                end;
            until PostedBankRecLines.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforePostedBankRecLinesModify(var PostedBankRecLines: Record "Posted Bank Rec. Line")
    begin
    end;
}


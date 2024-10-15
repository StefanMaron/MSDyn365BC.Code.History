// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

table 10120 "Bank Rec. Header"
{
    Caption = 'Bank Rec. Header';
    Permissions = TableData "Bank Account" = rm;
    DataCaptionFields = "Bank Account No.", "Statement No.", "Statement Date";
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;
            TableRelation = "Bank Account";

            trigger OnValidate()
            begin
                BankAccount.Get("Bank Account No.");
                BankAcctPostingGrp.Get(BankAccount."Bank Acc. Posting Group");
                "G/L Bank Account No." := BankAcctPostingGrp."G/L Account No.";
                Validate("Currency Code", BankAccount."Currency Code");
            end;
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';

            trigger OnValidate()
            begin
                CalculateBalance();
            end;
        }
        field(3; "Statement Date"; Date)
        {
            Caption = 'Statement Date';

            trigger OnValidate()
            begin
                Validate("Currency Code");
                CalculateBalance();
            end;
        }
        field(4; "Statement Balance"; Decimal)
        {
            Caption = 'Statement Balance';
        }
        field(5; "G/L Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("G/L Bank Account No."),
                                                        "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'G/L Balance ($)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Positive Adjustments"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Adjustment),
                                                             Positive = const(true),
                                                             "Account Type" = const("Bank Account"),
                                                             "Account No." = field("Bank Account No.")));
            Caption = 'Positive Adjustments';
            FieldClass = FlowField;
        }
        field(7; "Negative Adjustments"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Adjustment),
                                                             Positive = const(false),
                                                             "Account Type" = const("Bank Account"),
                                                             "Account No." = field("Bank Account No.")));
            Caption = 'Negative Adjustments';
            FieldClass = FlowField;
        }
        field(8; "Outstanding Deposits"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Deposit),
                                                             Cleared = const(false)));
            Caption = 'Outstanding Deposits';
            FieldClass = FlowField;
        }
        field(9; "Outstanding Checks"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Check),
                                                             Cleared = const(false)));
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
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> '' then begin
                    Currency.Get("Currency Code");
                    if "Statement Date" = 0D then
                        "Statement Date" := WorkDate();
                    "Currency Factor" := CurrExchRate.ExchangeRate("Statement Date", "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");
            end;
        }
        field(14; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text002, FieldCaption("Currency Code")));
            end;
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
            CalcFormula = sum("Bank Rec. Line"."Cleared Amount" where("Bank Account No." = field("Bank Account No."),
                                                                       "Statement No." = field("Statement No."),
                                                                       "Record Type" = const(Check),
                                                                       Cleared = const(true)));
            Caption = 'Total Cleared Checks';
            FieldClass = FlowField;
        }
        field(20; "Total Cleared Deposits"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line"."Cleared Amount" where("Bank Account No." = field("Bank Account No."),
                                                                       "Statement No." = field("Statement No."),
                                                                       "Record Type" = const(Deposit),
                                                                       Cleared = const(true)));
            Caption = 'Total Cleared Deposits';
            FieldClass = FlowField;
        }
        field(21; "Total Adjustments"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Adjustment)));
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
            CalcFormula = exist("Bank Comment Line" where("Table Name" = const("Bank Rec."),
                                                           "Bank Account No." = field("Bank Account No."),
                                                           "No." = field("Statement No.")));
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
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Adjustment),
                                                             "Bal. Account No." = filter(<> '')));
            Caption = 'Total Balanced Adjustments';
            FieldClass = FlowField;
        }
        field(29; "Positive Bal. Adjustments"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Adjustment),
                                                             Positive = const(true),
                                                             "Bal. Account No." = field("Bank Account No."),
                                                             "Bal. Account Type" = const("Bank Account")));
            Caption = 'Positive Bal. Adjustments';
            FieldClass = FlowField;
        }
        field(30; "Negative Bal. Adjustments"; Decimal)
        {
            CalcFormula = sum("Bank Rec. Line".Amount where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             "Record Type" = const(Adjustment),
                                                             Positive = const(false),
                                                             "Bal. Account No." = field("Bank Account No."),
                                                             "Bal. Account Type" = const("Bank Account")));
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
                Rec.ShowDocDim();
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
        BankRecLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecLine.SetRange("Statement No.", "Statement No.");
        BankRecLine.DeleteAll(true);

        BankRecCommentLine.SetRange("Table Name", BankRecCommentLine."Table Name"::"Bank Rec.");
        BankRecCommentLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecCommentLine.SetRange("No.", "Statement No.");
        BankRecCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "Statement Date" = 0D then
            "Statement Date" := WorkDate();

        if "Statement No." = '' then
            Validate("Statement No.", GetStatementNo());

        "Date Created" := WorkDate();
        "Time Created" := Time;
        "Created By" := UserId();
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecCommentLine: Record "Bank Comment Line";
        BankAccount: Record "Bank Account";
        BankAcctPostingGrp: Record "Bank Account Posting Group";
        Currency: Record Currency;
        Text002: Label 'cannot be specified without %1';
        CurrExchRate: Record "Currency Exchange Rate";
        Text003: Label 'You cannot rename a %1.';
        Text004: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        DimMgt: Codeunit DimensionManagement;

    procedure GetStatementNo(): Code[20]
    begin
        BankAccount.Get("Bank Account No.");
        BankAccount.TestField("Last Statement No.");
        BankAccount."Last Statement No." := IncStr(BankAccount."Last Statement No.");
        BankAccount.Modify(true);
        exit(BankAccount."Last Statement No.");
    end;

    procedure CalculateBalance()
    var
        GLEntry: Record "G/L Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateBalance(Rec, IsHandled);
        if IsHandled then
            exit;

        SetFilter("Date Filter", '%1..%2', 0D, "Statement Date");
        CalcFields("G/L Balance (LCY)");
        if "Currency Code" = '' then
            "G/L Balance" := "G/L Balance (LCY)"
        else
            if "G/L Balance (LCY)" = 0 then
                "G/L Balance" := 0
            else begin
                "G/L Balance" := 0;
                GLEntry.Reset();
                GLEntry.SetFilter("G/L Account No.", "G/L Bank Account No.");
                GLEntry.SetFilter("Posting Date", '%1..%2', 0D, "Statement Date");
                if GLEntry.FindSet() then begin
                    Currency.Get("Currency Code");
                    repeat
                        if BankAccLedgEntry.Get(GLEntry."Entry No.") then begin
                            if "Currency Code" <> BankAccLedgEntry."Currency Code" then begin
                                if BankAccLedgEntry."Currency Code" <> '' then
                                    "G/L Balance" += Round(CurrExchRate.ExchangeAmtFCYToFCY("Statement Date",
                                          BankAccLedgEntry."Currency Code",
                                          "Currency Code",
                                          BankAccLedgEntry.Amount),
                                        Currency."Amount Rounding Precision")
                                else
                                    "G/L Balance" += Round(CurrExchRate.ExchangeAmtLCYToFCY("Statement Date",
                                          "Currency Code",
                                          BankAccLedgEntry.Amount,
                                          "Currency Factor"),
                                        Currency."Amount Rounding Precision");
                            end else
                                "G/L Balance" += BankAccLedgEntry.Amount;
                        end else
                            "G/L Balance" += Round(CurrExchRate.ExchangeAmtLCYToFCY("Statement Date",
                                  "Currency Code",
                                  GLEntry.Amount,
                                  "Currency Factor"),
                                Currency."Amount Rounding Precision");

                    until GLEntry.Next() = 0;
                end;
            end;
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
            Modify();
            if BankRecLineExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure BankRecLineExist(): Boolean
    begin
        BankRecLine.Reset();
        BankRecLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecLine.SetRange("Statement No.", "Statement No.");
        exit(BankRecLine.FindFirst())
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text004) then
            exit;

        BankRecLine.Reset();
        BankRecLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecLine.SetRange("Statement No.", "Statement No.");
        BankRecLine.LockTable();
        if BankRecLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(BankRecLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if BankRecLine."Dimension Set ID" <> NewDimSetID then begin
                    BankRecLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      BankRecLine."Dimension Set ID", BankRecLine."Shortcut Dimension 1 Code", BankRecLine."Shortcut Dimension 2 Code");
                    OnUpdateAllLineDimOnBeforeBankRecLineModify(BankRecLine);
                    BankRecLine.Modify();
                end;
            until BankRecLine.Next() = 0;
    end;

    procedure InsertRec(BankAccountNo: Code[20])
    begin
        Init();
        Validate("Bank Account No.", BankAccountNo);
        Insert(true);
    end;

    procedure CalculateEndingBalance() Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateEndingBalance(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CalcFields("Outstanding Deposits", "Outstanding Checks");
        exit(("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateBalance(var BankRecHeader: Record "Bank Rec. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateEndingBalance(var BankRecHeader: Record "Bank Rec. Header"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeBankRecLineModify(var BankRecLine: Record "Bank Rec. Line")
    begin
    end;
}


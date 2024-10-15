﻿namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Security.User;
using Microsoft;

table 379 "Detailed Cust. Ledg. Entry"
{
    Caption = 'Detailed Cust. Ledg. Entry';
    DataCaptionFields = "Customer No.";
    DrillDownPageID = "Detailed Cust. Ledg. Entries";
    LookupPageID = "Detailed Cust. Ledg. Entries";
    Permissions = TableData "Detailed Cust. Ledg. Entry" = m;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(3; "Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(12; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(13; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(14; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(15; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(16; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(17; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(18; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
        }
        field(19; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
        }
        field(20; "Initial Entry Due Date"; Date)
        {
            Caption = 'Initial Entry Due Date';
        }
        field(21; "Initial Entry Global Dim. 1"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(22; "Initial Entry Global Dim. 2"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(24; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(25; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(29; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(30; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(31; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(35; "Initial Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Initial Document Type';
        }
        field(36; "Applied Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Applied Cust. Ledger Entry No.';
        }
        field(37; Unapplied; Boolean)
        {
            Caption = 'Unapplied';
        }
        field(38; "Unapplied by Entry No."; Integer)
        {
            Caption = 'Unapplied by Entry No.';
            TableRelation = "Detailed Cust. Ledg. Entry";
        }
        field(39; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
        }
        field(40; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';
        }
        field(41; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            Editable = false;
            TableRelation = "Tax Jurisdiction";
        }
        field(42; "Application No."; Integer)
        {
            Caption = 'Application No.';
            Editable = false;
        }
        field(43; "Ledger Entry Amount"; Boolean)
        {
            Caption = 'Ledger Entry Amount';
            Editable = false;
        }
        field(44; "Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        field(45; "Exch. Rate Adjmt. Reg. No."; Integer)
        {
            Caption = 'Exch. Rate Adjmt. Reg. No.';
            Editable = false;
            TableRelation = "Exch. Rate Adjmt. Reg.";
        }
        field(10700; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
        }
        field(7000001; "Document Situation"; Enum "ES Document Situation")
        {
            Caption = 'Document Situation';
        }
        field(7000002; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
        }
        field(7000003; "Document Status"; Enum "ES Document Status")
        {
            Caption = 'Document Status';
        }
        field(7000004; "Excluded from calculation"; Boolean)
        {
            Caption = 'Excluded from calculation';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Cust. Ledger Entry No.", "Posting Date")
        {
        }
        key(Key3; "Cust. Ledger Entry No.", "Entry Type", "Posting Date")
        {
        }
        key(Key4; "Ledger Entry Amount", "Cust. Ledger Entry No.", "Posting Date", "Excluded from calculation")
        {
            IncludedFields = Amount, "Amount (LCY)", "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)";
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with "Key17" for better peformance.';
            ObsoleteTag = '18.0';
        }
        key(Key5; "Initial Document Type", "Entry Type", "Customer No.", "Currency Code", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2", "Posting Date")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key6; "Customer No.", "Currency Code", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2", "Initial Entry Due Date", "Posting Date")
        {
            SumIndexFields = Amount, "Amount (LCY)";
            MaintainSQLIndex = false;
            MaintainSiftIndex = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with "Key15" for better peformance.';
            ObsoleteTag = '18.0';
        }
        key(Key7; "Document No.", "Document Type", "Posting Date")
        {
        }
        key(Key8; "Applied Cust. Ledger Entry No.", "Entry Type")
        {
        }
        key(Key9; "Transaction No.", "Customer No.", "Entry Type")
        {
        }
        key(Key10; "Application No.", "Customer No.", "Entry Type")
        {
        }
        key(Key11; "Customer No.", "Entry Type", "Posting Date", "Initial Document Type")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key12; "Document Type")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key13; "Initial Document Type", "Initial Entry Due Date")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key14; "Customer No.", "Initial Entry Due Date")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key15; "Customer No.", "Currency Code", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2", "Initial Entry Due Date", "Posting Date", "Excluded from calculation")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key17; "Cust. Ledger Entry No.", "Posting Date", "Ledger Entry Amount", "Excluded from calculation")
        {
            IncludedFields = Amount, "Amount (LCY)", "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Cust. Ledger Entry No.", "Customer No.", "Posting Date", "Document Type", "Document No.")
        {
        }
    }

    trigger OnInsert()
    begin
        SetLedgerEntryAmount();
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure UpdateDebitCredit(Correction: Boolean)
    begin
        if ((Amount > 0) or ("Amount (LCY)" > 0)) and not Correction or
           ((Amount < 0) or ("Amount (LCY)" < 0)) and Correction
        then begin
            "Debit Amount" := Amount;
            "Credit Amount" := 0;
            "Debit Amount (LCY)" := "Amount (LCY)";
            "Credit Amount (LCY)" := 0;
        end else begin
            "Debit Amount" := 0;
            "Credit Amount" := -Amount;
            "Debit Amount (LCY)" := 0;
            "Credit Amount (LCY)" := -"Amount (LCY)";
        end;

        OnAfterUpdateDebitCredit(Rec, Correction);
    end;

    procedure SetZeroTransNo(TransactionNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationNo: Integer;
    begin
        DetailedCustLedgEntry.SetCurrentKey("Transaction No.");
        DetailedCustLedgEntry.SetRange("Transaction No.", TransactionNo);
        if DetailedCustLedgEntry.FindSet(true) then begin
            ApplicationNo := DetailedCustLedgEntry."Entry No.";
            repeat
                DetailedCustLedgEntry."Transaction No." := 0;
                DetailedCustLedgEntry."Application No." := ApplicationNo;
                OnSetZeroTransNoOnBeforeDetailedCustLedgEntryModify(DetailedCustLedgEntry);
                DetailedCustLedgEntry.Modify();
            until DetailedCustLedgEntry.Next() = 0;
        end;
    end;

    local procedure SetLedgerEntryAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLedgerEntryAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        "Ledger Entry Amount" :=
            not ("Entry Type" in ["Entry Type"::Application, "Entry Type"::"Appln. Rounding", "Entry Type"::Redrawal,
                                  "Entry Type"::Rejection]);
    end;

    procedure GetUnrealizedGainLossAmount(EntryNo: Integer): Decimal
    begin
        SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        SetRange("Cust. Ledger Entry No.", EntryNo);
        SetRange("Entry Type", "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
        CalcSums("Amount (LCY)");
        exit("Amount (LCY)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLedgerEntryAmount(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDebitCredit(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; Correction: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetZeroTransNoOnBeforeDetailedCustLedgEntryModify(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;
}


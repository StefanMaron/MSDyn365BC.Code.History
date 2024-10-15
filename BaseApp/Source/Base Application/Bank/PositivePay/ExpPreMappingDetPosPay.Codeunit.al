namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using System.IO;

codeunit 1704 "Exp. Pre-Mapping Det Pos. Pay"
{
    Permissions = TableData "Positive Pay Detail" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckLedgerEntryView: Text;
        LineNo: Integer;
    begin
        OnGetFiltersBeforePreparingPosPayDetails(CheckLedgerEntryView);
        CheckLedgerEntry.SetView(CheckLedgerEntryView);
        CheckLedgerEntry.SetRange("Data Exch. Entry No.", Rec."Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, Rec."Entry No.", LineNo);

        // Reset filters and set it on the Data Exch. Voided Entry No.
        CheckLedgerEntry.Reset();
        CheckLedgerEntry.SetView(CheckLedgerEntryView);
        CheckLedgerEntry.SetRange("Data Exch. Voided Entry No.", Rec."Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, Rec."Entry No.", LineNo);
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Preprocessing line no. #1######.';
#pragma warning restore AA0470

    local procedure PreparePosPayDetails(var CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; var LineNo: Integer)
    var
        Window: Dialog;
    begin
        if CheckLedgerEntry.FindSet() then begin
            Window.Open(ProgressMsg);
            repeat
                LineNo += 1;
                Window.Update(1, LineNo);
                PreparePosPayDetail(CheckLedgerEntry, DataExchangeEntryNo, LineNo);
            until CheckLedgerEntry.Next() = 0;
            Window.Close();
        end;
    end;

    local procedure PreparePosPayDetail(CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; LineNo: Integer)
    var
        BankAccount: Record "Bank Account";
        PosPayDetail: Record "Positive Pay Detail";
    begin
        BankAccount.Get(CheckLedgerEntry."Bank Account No.");

        PosPayDetail.Init();
        PosPayDetail."Data Exch. Entry No." := DataExchangeEntryNo;
        PosPayDetail."Entry No." := LineNo;
        PosPayDetail."Account Number" := BankAccount."Bank Account No.";
        if DataExchangeEntryNo = CheckLedgerEntry."Data Exch. Voided Entry No." then begin
            // V for Void legend
            PosPayDetail."Record Type Code" := 'V';
            PosPayDetail."Void Check Indicator" := 'V';
        end else begin
            // O for Open legend
            PosPayDetail."Record Type Code" := 'O';
            PosPayDetail."Void Check Indicator" := '';
        end;
        PosPayDetail."Check Number" := CheckLedgerEntry."Check No.";
        PosPayDetail.Amount := CheckLedgerEntry.Amount;
        PosPayDetail.Payee := CheckLedgerEntry.Description;
        PosPayDetail."Issue Date" := CheckLedgerEntry."Check Date";
        if BankAccount."Currency Code" <> '' then
            PosPayDetail."Currency Code" := BankAccount."Currency Code";

        OnPreparePosPayDetailOnBeforeInsert(CheckLedgerEntry, PosPayDetail);
        PosPayDetail.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFiltersBeforePreparingPosPayDetails(var CheckLedgerEntryView: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreparePosPayDetailOnBeforeInsert(CheckLedgerEntry: Record "Check Ledger Entry"; var PositivePayDetail: Record "Positive Pay Detail")
    begin
    end;
}


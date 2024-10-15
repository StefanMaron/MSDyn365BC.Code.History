namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.Check;
using System.IO;

codeunit 1710 "Exp. User Feedback Pos. Pay"
{
    Permissions = TableData "Check Ledger Entry" = rimd,
                  TableData "Positive Pay Entry" = rimd,
                  TableData "Positive Pay Entry Detail" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        PositivePayEntry: Record "Positive Pay Entry";
        BankAccNo: Code[20];
        LastUpdateDateTime: DateTime;
    begin
        // Update the CheckLedgerEntry for the Data Exch. Entry No. as exported successfully
        CheckLedgerEntry.SetRange("Data Exch. Entry No.", Rec."Entry No.");
        CheckLedgerEntry.SetRange("Positive Pay Exported", false);
        CheckLedgerEntry.SetFilter(
          "Entry Status", '%1|%2|>%3',
          CheckLedgerEntry."Entry Status"::Printed,
          CheckLedgerEntry."Entry Status"::Posted,
          CheckLedgerEntry."Entry Status"::"Test Print");
        if CheckLedgerEntry.FindFirst() then
            BankAccNo := CheckLedgerEntry."Bank Account No.";
        CheckLedgerEntry.ModifyAll("Positive Pay Exported", true, true);

        // Update the CheckLedgerEntry for the Data Exch. Voided Entry No. for Checks as exported successfully
        CheckLedgerEntry.SetRange("Data Exch. Entry No.");
        CheckLedgerEntry.SetRange("Data Exch. Voided Entry No.", Rec."Entry No.");
        CheckLedgerEntry.SetFilter(
          "Entry Status", '%1|%2|%3',
          CheckLedgerEntry."Entry Status"::Voided,
          CheckLedgerEntry."Entry Status"::"Financially Voided",
          CheckLedgerEntry."Entry Status"::"Test Print");
        // Only populate the BankAcct if there were no open checks found in case there are no voids
        if BankAccNo = '' then
            if CheckLedgerEntry.FindFirst() then
                BankAccNo := CheckLedgerEntry."Bank Account No.";
        CheckLedgerEntry.ModifyAll("Positive Pay Exported", true, true);

        if BankAccNo <> '' then
            LastUpdateDateTime := GetLastUploadDateTime(BankAccNo);

        // Initialize Pos. Pay Enties
        PositivePayEntry.Init();
        PositivePayEntry.Validate("Bank Account No.", BankAccNo);
        PositivePayEntry."Last Upload Date" := DT2Date(LastUpdateDateTime);
        PositivePayEntry."Last Upload Time" := DT2Time(LastUpdateDateTime);

        // Retrieve the range of exported data and move Pos. Pay Entry Detail tables
        CreatePosPayEntryDetail(PositivePayEntry, Rec."Entry No.", BankAccNo);

        Rec.CalcFields("File Content");
        PositivePayEntry."Exported File" := Rec."File Content";
        PositivePayEntry.Insert();
    end;

    local procedure GetLastUploadDateTime(BankAccNo: Code[20]): DateTime
    var
        PositivePayEntry: Record "Positive Pay Entry";
    begin
        // Retrieve the Last Updated Date and Time to set in the new record
        PositivePayEntry.SetRange("Bank Account No.", BankAccNo);
        if PositivePayEntry.FindLast() then
            exit(PositivePayEntry."Upload Date-Time");
    end;

    local procedure CreatePosPayEntryDetail(var PositivePayEntry: Record "Positive Pay Entry"; EntryNo: Integer; BankAccNo: Code[20])
    var
        PositivePayEntryDetail: Record "Positive Pay Entry Detail";
        PositivePayDetail: Record "Positive Pay Detail";
    begin
        PositivePayDetail.SetRange("Data Exch. Entry No.", EntryNo);
        if PositivePayDetail.FindSet() then
            repeat
                PositivePayEntryDetail.Init();
                PositivePayEntryDetail."Upload Date-Time" := PositivePayEntry."Upload Date-Time";
                PositivePayEntryDetail.CopyFromPosPayEntryDetail(PositivePayDetail, BankAccNo);
                if PositivePayEntryDetail."Document Type" = PositivePayEntryDetail."Document Type"::CHECK then begin
                    PositivePayEntry."Number of Checks" += 1;
                    PositivePayEntry."Check Amount" += PositivePayEntryDetail.Amount;
                end else begin
                    PositivePayEntry."Number of Voids" += 1;
                    PositivePayEntry."Void Amount" += PositivePayEntryDetail.Amount;
                end;
                PositivePayEntry."Number of Uploads" += 1;
                PositivePayEntryDetail.Insert();
            until PositivePayDetail.Next() = 0;
    end;
}


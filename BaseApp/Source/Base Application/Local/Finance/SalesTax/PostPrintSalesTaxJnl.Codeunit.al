// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 10101 "Post- Print Sales Tax Jnl"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GenJnlLine.Copy(Rec);
        Code();
        Rec.Copy(GenJnlLine);
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GLReg: Record "G/L Register";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        ManageSalesTaxJournal: Codeunit "Manage Sales Tax Journal";
        TempJnlBatchName: Code[10];
        Text000: Label 'cannot be filtered when posting recurring journals.', Comment = 'Posting Date cannot be filtered when posting recurring journals.';
        Text001: Label 'Do you want to post the journal lines and print the report(s)?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';

    procedure "Code"()
    begin
        with GenJnlLine do begin
            GenJnlTemplate.Get("Journal Template Name");
            if GenJnlTemplate."Force Posting Report" or
               (GenJnlTemplate."Cust. Receipt Report ID" = 0) and (GenJnlTemplate."Vendor Receipt Report ID" = 0)
            then
                GenJnlTemplate.TestField("Posting Report ID");
            if GenJnlTemplate.Recurring and (GetFilter("Posting Date") <> '') then
                FieldError("Posting Date", Text000);

            if not Confirm(Text001, false) then
                exit;

            TempJnlBatchName := "Journal Batch Name";

            ManageSalesTaxJournal.PostToVAT(GenJnlLine);
            ManageSalesTaxJournal.CreateGenJnlLines(GenJnlLine);
            GenJnlPostBatch.Run(GenJnlLine);

            if GLReg.Get("Line No.") then begin
                if GenJnlTemplate."Cust. Receipt Report ID" <> 0 then begin
                    CustLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
                    REPORT.Run(GenJnlTemplate."Cust. Receipt Report ID", false, false, CustLedgEntry);
                end;
                if GenJnlTemplate."Vendor Receipt Report ID" <> 0 then begin
                    VendLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
                    REPORT.Run(GenJnlTemplate."Vendor Receipt Report ID", false, false, VendLedgEntry);
                end;
                if GenJnlTemplate."Posting Report ID" <> 0 then begin
                    GLReg.SetRecFilter();
                    REPORT.Run(GenJnlTemplate."Posting Report ID", false, false, GLReg);
                end;
            end;

            if "Line No." = 0 then
                Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text003)
                else
                    Message(
                      Text004,
                      "Journal Batch Name");

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                Reset();
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                FilterGroup(0);
                "Line No." := 1;
            end;
        end;
    end;
}


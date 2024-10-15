// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

codeunit 10250 "Bulk Vendor Remit Reporting"
{

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        PreviewModeNoExportMsg: Label 'Preview mode is enabled for one or more reports. File export is not possible for any data.';
        VendRemittanceReportSelectionErr: Label 'You must add at least one Vendor Remittance report to the report selection.';
        BankPaymentType: Enum "Bank Payment Type";

    procedure RunWithRecord(var GenJournalLine: Record "Gen. Journal Line")
    var
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineRecRef: RecordRef;
        GenJournalLineFieldName: Text;
        JoinDatabaseNumber: Integer;
        JoinDatabaseFieldName: Text;
    begin
        GenJournalLine.SetFilter("Check Exported", '=FALSE');

        GenJournalLineRecRef.GetTable(GenJournalLine);
        GenJournalLineRecRef.SetView(GenJournalLine.GetView());

        GenJournalLine.Find('-');
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch.OnCheckGenJournalLineExportRestrictions();

        // Based on the types of the accounts, set up the report layout joins appropriate.
        case GenJournalLine."Bal. Account Type" of
            GenJournalLine."Bal. Account Type"::Vendor:
                begin
                    GenJournalLineFieldName := GenJournalLine.FieldName("Bal. Account No.");
                    JoinDatabaseNumber := DATABASE::Vendor;
                    JoinDatabaseFieldName := Vendor.FieldName("No.");
                end;
            GenJournalLine."Bal. Account Type"::Customer:
                begin
                    GenJournalLineFieldName := GenJournalLine.FieldName("Bal. Account No.");
                    JoinDatabaseNumber := DATABASE::Customer;
                    JoinDatabaseFieldName := Customer.FieldName("No.");
                end;
            GenJournalLine."Bal. Account Type"::"Bank Account":
                case GenJournalLine."Account Type" of
                    GenJournalLine."Account Type"::Customer:
                        begin
                            GenJournalLineFieldName := GenJournalLine.FieldName("Account No.");
                            JoinDatabaseNumber := DATABASE::Customer;
                            JoinDatabaseFieldName := Customer.FieldName("No.");
                        end;
                    GenJournalLine."Account Type"::Vendor:
                        begin
                            GenJournalLineFieldName := GenJournalLine.FieldName("Account No.");
                            JoinDatabaseNumber := DATABASE::Vendor;
                            JoinDatabaseFieldName := Vendor.FieldName("No.");
                        end;
                end;
            else
                GenJournalLine.FieldError("Bal. Account No.");
        end;

        BankPaymentType := GenJournalLine."Bank Payment Type";

        CheckReportSelectionsExists();

        // Set up data, request pages, etc.
        CustomLayoutReporting.InitializeReportData(
          ReportSelections.Usage::"V.Remittance", GenJournalLineRecRef,
          GenJournalLineFieldName, JoinDatabaseNumber, JoinDatabaseFieldName, false);

        if not PreviewModeSelected() then
            UpdateDocNo(GenJournalLineRecRef)
        else
            ClearDocNoPreview(GenJournalLineRecRef);

        // Run reports
        CustomLayoutReporting.SetRunReportOncePerFilter(true);
        CustomLayoutReporting.SetOutputFileBaseName('Remittance Advice');
        CustomLayoutReporting.ProcessReport();

        // Export to file if we don't have anything in preview mode
        if not PreviewModeSelected() then
            SetExportReportOptionsAndExport(GenJournalLineRecRef);
    end;

    local procedure PreviewModeSelected(): Boolean
    var
        ReportSelections: Record "Report Selections";
        ReportOutputType: Integer;
        PreviewMode: Boolean;
        FirstLoop: Boolean;
    begin
        // Check to see if any of the associated reports are in 'preview' mode:
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");

        FirstLoop := true;
        if ReportSelections.Find('-') then
            repeat
                ReportOutputType := CustomLayoutReporting.GetOutputOption(ReportSelections."Report ID");
                // We don't need to test for mixed preview and non-preview in the first loop
                if FirstLoop then begin
                    FirstLoop := false;
                    PreviewMode := (ReportOutputType = CustomLayoutReporting.GetPreviewOption())
                end else
                    // If we have mixed preview and non-preview, then display a message that we're not going to export to file
                    if (PreviewMode and (ReportOutputType <> CustomLayoutReporting.GetPreviewOption())) or
                       (not PreviewMode and (ReportOutputType = CustomLayoutReporting.GetPreviewOption()))
                    then begin
                        Message(PreviewModeNoExportMsg);
                        PreviewMode := true;
                    end;
            until ReportSelections.Next() = 0;

        exit(PreviewMode);
    end;

    local procedure SetExportReportOptionsAndExport(var GenJournalLineRecRef: RecordRef)
    var
        ReportSelections: Record "Report Selections";
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        BankAccountNo: Code[20];
        GenJournalLineBankAccount: Code[20];
        OptionText: Text;
        OptionCode: Code[20];
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        if ReportSelections.Find('-') then
            repeat
                // Ensure that the report has valid request parameters before trying to access them and run the export
                if CustomLayoutReporting.HasRequestParameterData(ReportSelections."Report ID") then begin
                    // Get the same options from the user-selected options for this export report run
                    // Items in the request page XML use the 'Source' as their name
                    OptionText :=
                      CustomLayoutReporting.GetOptionValueFromRequestPageForReport(ReportSelections."Report ID", 'BankAccount."No."');
                    OptionCode := CopyStr(OptionText, 1, 20);
                    Evaluate(BankAccountNo, OptionCode);
                    if GenJournalLineRecRef.FindFirst() then begin
                        repeat
                            GenJournalLineRecRef.SetTable(GenJournalLine);
                            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account" then
                                GenJournalLineBankAccount := GenJournalLine."Account No."
                            else
                                GenJournalLineBankAccount := GenJournalLine."Bal. Account No.";

                            if ProcessLine(GenJournalLine) and (BankAccountNo = GenJournalLineBankAccount) then begin
                                CreateEFTRecord(EFTExport, GenJournalLine, BankAccountNo);
                                UpdateCheckInfoForGenLedgLine(GenJournalLine, EFTExport);

                                CreateCreditTransferRegister(BankAccountNo, GenJournalLine."Bal. Account No.", BankPaymentType);
                            end;
                        until GenJournalLineRecRef.Next() = 0;
                    end;
                end;
            until ReportSelections.Next() = 0;
    end;

    local procedure CheckReportSelectionsExists()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        ReportSelections.SetFilter("Report ID", '<>0');
        if not ReportSelections.FindFirst() then
            Error(VendRemittanceReportSelectionErr);
    end;

    local procedure CreateEFTRecord(var EFTExport: Record "EFT Export"; GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    begin
        EFTExport.Init();
        EFTExport."Journal Template Name" := GenJournalLine."Journal Template Name";
        EFTExport."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        EFTExport."Line No." := GenJournalLine."Line No.";
        EFTExport."Sequence No." := GetNextSequenceNo();

        EFTExport."Bank Account No." := BankAccountNo;
        EFTExport."Bank Payment Type" := GenJournalLine."Bank Payment Type";
        EFTExport."Transaction Code" := GenJournalLine."Transaction Code";
        EFTExport."Document Type" := GenJournalLine."Document Type";
        EFTExport."Posting Date" := GenJournalLine."Posting Date";
        EFTExport."Account Type" := GenJournalLine."Account Type";
        EFTExport."Account No." := GenJournalLine."Account No.";
        EFTExport."Applies-to ID" := GenJournalLine."Applies-to ID";
        EFTExport."Document No." := GenJournalLine."Document No.";
        EFTExport.Description := GenJournalLine.Description;
        EFTExport."Currency Code" := GenJournalLine."Currency Code";
        EFTExport."Bal. Account No." := GenJournalLine."Bal. Account No.";
        EFTExport."Bal. Account Type" := GenJournalLine."Bal. Account Type";
        EFTExport."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type";
        EFTExport."Applies-to Doc. No." := GenJournalLine."Applies-to Doc. No.";
        EFTExport."Check Exported" := true;
        EFTExport."Check Printed" := true;
        EFTExport."Exported to Payment File" := true;
        EFTExport."Amount (LCY)" := GenJournalLine."Amount (LCY)";
        EFTExport."Foreign Exchange Reference" := GenJournalLine."Foreign Exchange Reference";
        EFTExport."Foreign Exchange Indicator" := GenJournalLine."Foreign Exchange Indicator";
        EFTExport."Foreign Exchange Ref.Indicator" := GenJournalLine."Foreign Exchange Ref.Indicator";
        EFTExport."Country/Region Code" := GenJournalLine."Country/Region Code";
        EFTExport."Source Code" := GenJournalLine."Source Code";
        EFTExport."Company Entry Description" := GenJournalLine."Company Entry Description";
        EFTExport."Transaction Type Code" := GenJournalLine."Transaction Type Code";
        EFTExport."Payment Related Information 1" := GenJournalLine."Payment Related Information 1";
        EFTExport."Payment Related Information 2" := GenJournalLine."Payment Related Information 2";
        EFTExport."Gateway Operator OFAC Scr.Inc" := GenJournalLine."Gateway Operator OFAC Scr.Inc";
        EFTExport."Secondary OFAC Scr.Indicator" := GenJournalLine."Secondary OFAC Scr.Indicator";
        EFTExport."Origin. DFI ID Qualifier" := GenJournalLine."Origin. DFI ID Qualifier";
        EFTExport."Receiv. DFI ID Qualifier" := GenJournalLine."Receiv. DFI ID Qualifier";
        EFTExport."Document Date" := GenJournalLine."Document Date";
        EFTExport."Document No." := GenJournalLine."Document No.";
        EFTExport."External Document No." := GenJournalLine."External Document No.";
        EFTExport."Payment Reference" := GenJournalLine."Payment Reference";

        EFTExport.Insert();
    end;

    local procedure UpdateCheckInfoForGenLedgLine(var GenJournalLine: Record "Gen. Journal Line"; EFTExport: Record "EFT Export")
    begin
        GenJournalLine."Check Printed" := true;
        GenJournalLine."Check Exported" := true;
        GenJournalLine."Exported to Payment File" := true;
        GenJournalLine."EFT Export Sequence No." := EFTExport."Sequence No.";

        GenJournalLine.Modify();
    end;

    local procedure UpdateDocNo(var GenJournalLineRecRef: RecordRef)
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        BankAccountNo: Code[20];
        GenJournalLineBankAccount: Code[20];
        OptionText: Text;
        OptionCode: Code[20];
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        if ReportSelections.Find('-') then begin
            repeat
                if CustomLayoutReporting.HasRequestParameterData(ReportSelections."Report ID") then begin
                    // Get the same options from the user-selected options for this export report run
                    // Items in the request page XML use the 'Source' as their name
                    OptionText :=
                      CustomLayoutReporting.GetOptionValueFromRequestPageForReport(ReportSelections."Report ID", 'BankAccount."No."');
                    OptionCode := CopyStr(OptionText, 1, 20);
                    Evaluate(BankAccountNo, OptionCode);

                    if GenJournalLineRecRef.FindFirst() then begin
                        repeat
                            GenJournalLineRecRef.SetTable(GenJournalLine);
                            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account" then
                                GenJournalLineBankAccount := GenJournalLine."Account No."
                            else
                                GenJournalLineBankAccount := GenJournalLine."Bal. Account No.";

                            if ProcessLine(GenJournalLine) and (BankAccountNo = GenJournalLineBankAccount) then
                                UpdateDocNoForGenLedgLine(GenJournalLine, BankAccountNo);
                        until GenJournalLineRecRef.Next() = 0;
                    end;
                end;
            until ReportSelections.Next() = 0;
        end;
    end;

    local procedure UpdateDocNoForGenLedgLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount."Last Remittance Advice No." := IncStr(BankAccount."Last Remittance Advice No.");
        BankAccount.Modify();

        GenJournalLine."Document No." := BankAccount."Last Remittance Advice No.";

        GenJournalLine.Modify();

        InsertIntoCheckLedger(GenJournalLine, BankAccountNo);
    end;

    local procedure InsertIntoCheckLedger(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccount: Record "Bank Account";
        CheckManagement: Codeunit CheckManagement;
        BankAccountIs: Option Acnt,BalAcnt;
    begin
        OnBeforeInsertIntoCheckLedger(GenJournalLine);
        BankAccount.Get(BankAccountNo);

        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account" then
            BankAccountIs := BankAccountIs::Acnt
        else
            BankAccountIs := BankAccountIs::BalAcnt;

        CheckLedgerEntry.Init();
        CheckLedgerEntry."Bank Account No." := BankAccount."No.";
        CheckLedgerEntry."Posting Date" := GenJournalLine."Document Date";
        CheckLedgerEntry."Document Type" := GenJournalLine."Document Type";
        CheckLedgerEntry."Document No." := GenJournalLine."Document No.";
        CheckLedgerEntry.Description := GenJournalLine.Description;
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Electronic Payment";
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Exported;
        CheckLedgerEntry."Check Date" := GenJournalLine."Document Date";
        CheckLedgerEntry."Check No." := GenJournalLine."Document No.";

        if BankAccountIs = BankAccountIs::Acnt then begin
            CheckLedgerEntry."Bal. Account Type" := GenJournalLine."Bal. Account Type";
            CheckLedgerEntry."Bal. Account No." := GenJournalLine."Bal. Account No.";
            CheckLedgerEntry.Amount := -GenJournalLine.Amount;
        end else begin
            CheckLedgerEntry."Bal. Account Type" := GenJournalLine."Account Type";
            CheckLedgerEntry."Bal. Account No." := GenJournalLine."Account No.";
            CheckLedgerEntry.Amount := GenJournalLine.Amount;
        end;
        CheckManagement.InsertCheck(CheckLedgerEntry, GenJournalLine.RecordId);
    end;

    local procedure CreateCreditTransferRegister(BankAccountNo: Code[20]; BalAccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CreditTransferRegister: Record "Credit Transfer Register";
        DataExchDef: Record "Data Exch. Def";
        BankAccount: Record "Bank Account";
        NewIdentifier: Code[20];
        PaymentExportDirection: Integer;
    begin
        BankAccount.Get(BankAccountNo);

        if BankPaymentType = "Bank Payment Type"::"Electronic Payment" then
            BankExportImportSetup.Get(BankAccount."Payment Export Format")
        else
            if BankPaymentType = "Bank Payment Type"::"Electronic Payment-IAT" then
                BankExportImportSetup.Get(BankAccount."EFT Export Code");

        PaymentExportDirection := BankExportImportSetup.Direction;
        if PaymentExportDirection <> 3 then // Export-EFT
            if BankAccount."Payment Export Format" <> '' then begin
                DataExchDef.Get(BankAccount."Payment Export Format");
                NewIdentifier := DataExchDef.Code;
            end else
                NewIdentifier := '';

        CreditTransferRegister.CreateNew(NewIdentifier, BalAccountNo);
        Commit();
    end;

    local procedure GetNextSequenceNo(): Integer
    var
        EFTExport: Record "EFT Export";
    begin
        EFTExport.SetCurrentKey("Sequence No.");
        EFTExport.SetRange("Sequence No.");
        if EFTExport.FindLast() then
            exit(EFTExport."Sequence No." + 1);

        exit(1);
    end;

    [Scope('OnPrem')]
    procedure ProcessLine(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        ExportNewLines: Boolean;
    begin
        ExportNewLines := false;
        if GenJournalLine."Amount (LCY)" <> 0 then
            if ((GenJournalLine."Bank Payment Type" = GenJournalLine."Bank Payment Type"::"Electronic Payment") or
                (GenJournalLine."Bank Payment Type" = GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT")) and
               (GenJournalLine."Check Exported" = false)
            then
                ExportNewLines := true;

        exit(ExportNewLines);
    end;

    local procedure ClearDocNoPreview(var GenJournalLineRecRef: RecordRef)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if GenJournalLineRecRef.FindFirst() then begin
            repeat
                GenJournalLineRecRef.SetTable(GenJournalLine);

                if ProcessLine(GenJournalLine) then begin
                    GenJournalLine."Document No." := '';
                    GenJournalLine.Modify();
                    OnClearDocNoPreviewOnAfterGenJournalLineModify(GenJournalLine);
                end;
            until GenJournalLineRecRef.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertIntoCheckLedger(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearDocNoPreviewOnAfterGenJournalLineModify(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139610 SendRemittanceAdvice
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance Advice] [Email]
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailVerifyModalPageHandler')]
    procedure SendRemittanceAdviceFromPaymentJournal()
    var
        CustomReportSelection: Record "Custom Report Selection";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Send remittance advice report to vendor by email from Payment Journal
        Initialize();

        // [GIVEN] Vendor with email
        // [GIVEN] Payment journal line
        // [GIVEN] Custom report selection 
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."E-Mail" := LibraryUtility.GenerateRandomEmail();
        Vendor.Modify(true);
        CreateVendorRemittanceReportSelection(CustomReportSelection.Usage::"V.Remittance", Vendor."No.");
        CreateGenJnlLine(GenJournalLine, Vendor."No.");
        // [WHEN] Open Payment Journal and invoke "Send Remittance Advice" action
        LibraryVariableStorage.Enqueue(Vendor."E-Mail");
        SendFromPaymentJournal(GenJournalLine);
        // [THEN] Email Dialog opened and "To:" = "Email"
        // Verified in EmailVerifyModalPageHandler handler
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailVerifyModalPageHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntry()
    var
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Send remittance advice report to vendor by email from Payment Journal
        Initialize();

        // [GIVEN] Vendor with email
        // [GIVEN] Vendor Ledger Entry
        // [GIVEN] Custom report selection 
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."E-Mail" := LibraryUtility.GenerateRandomEmail();
        Vendor.Modify(true);
        CreateVendorRemittanceReportSelection(CustomReportSelection.Usage::"P.V.Remit.", Vendor."No.");
        MockVendorLedgerEntry(Vendor."No.");
        // [WHEN] Open Vendor Ledger Entries and invoke "Send Remittance Advice" action
        LibraryVariableStorage.Enqueue(Vendor."E-Mail");
        SendFromVendorLedgerEntry(Vendor."No.");
        // [THEN] Email Dialog opened and "To:" = "Email"
        // Verified in EmailVerifyModalPageHandler handler
    end;

    local procedure Initialize()
    var
        LibraryAzureKVMockMgmt: Codeunit 131021;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::SendRemittanceAdvice);
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
		LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::SendRemittanceAdvice);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::SendRemittanceAdvice);
    end;

    local procedure CreateVendorRemittanceReportSelection(ReportSelectionUsage: Option; VendorNo: Code[20])
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        CustomReportSelection.DeleteAll();

        CustomReportSelection.Init();
        CustomReportSelection."Source Type" := 23;
        CustomReportSelection."Source No." := VendorNo;
        CustomReportSelection.Usage := ReportSelectionUsage;
        CASE CustomReportSelection.Usage OF
            CustomReportSelection.Usage::"V.Remittance":
                CustomReportSelection."Report ID" := REPORT::"Remittance Advice - Journal";
            CustomReportSelection.Usage::"P.V.Remit.":
                CustomReportSelection."Report ID" := REPORT::"Remittance Advice - Entries";
        END;
        CustomReportSelection."Use for Email Attachment" := TRUE;
        CustomReportSelection.INSERT();
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        SourceCode: Record "Source Code";
    begin
        GenJournalTemplate.DeleteAll();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Type := GenJournalTemplate.Type::General;
        LibraryERM.CreateSourceCode(SourceCode);
        GenJournalTemplate."Source Code" := SourceCode.Code;
        GenJournalTemplate.Modify(true);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Type := GenJournalTemplate.Type::Payments;
        LibraryERM.CreateSourceCode(SourceCode);
        GenJournalTemplate."Source Code" := SourceCode.Code;
        GenJournalTemplate."Page ID" := 256;
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
            VendorNo, 100);
    end;

    local procedure MockVendorLedgerEntry(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LastEntryNo: Integer;
    begin
        VendorLedgerEntry.FindLast();
        LastEntryNo := VendorLedgerEntry."Entry No.";
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LastEntryNo + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Payment;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendorLedgerEntry.Insert();
    end;

    local procedure SendFromPaymentJournal(GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.SendRemittanceAdvice.Invoke();
        PaymentJournal.Close();
    end;

    local procedure SendFromVendorLedgerEntry(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntry.SETRANGE("Vendor No.", VendorNo);
        VendorLedgerEntry.SETRANGE("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FINDFIRST();
        VendorLedgerEntries.OPENEDIT();
        VendorLedgerEntries.GOTORECORD(VendorLedgerEntry);
        VendorLedgerEntries.SendRemittanceAdvice.INVOKE();
        VendorLedgerEntries.CLOSE();
    end;

    [ModalPageHandler]
    procedure SelectSendingOptionHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        SelectSendingOptions."E-Mail".SETVALUE(DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        SelectSendingOptions.Disk.SETVALUE(DocumentSendingProfile.Disk::PDF);
        SelectSendingOptions.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EmailVerifyModalPageHandler(var EmailDialog: TestPage "Email Dialog")
    begin
        EmailDialog.SendTo.AssertEquals(LibraryVariableStorage.DequeueText());
    end;
}
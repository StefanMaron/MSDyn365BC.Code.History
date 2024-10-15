// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139610 SendRemittanceAdvice
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWorkflow: Codeunit "Library - Workflow";
        IsInitialized: Boolean;
        ModalCount: Integer;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance Advice] [Email]
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "Confirm Default", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = empty; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromPaymentJournal(true, 2, 4, 2, 2);

        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "Confirm Default", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromPaymentJournal(false, 2, 4, 2, 2);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "Confirm Default", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromPaymentJournal(true, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "Confirm Default", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = '; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromPaymentJournal(false, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromPaymentJournal(true, 2, 4, 2, 2);

        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromPaymentJournal(false, 2, 4, 2, 2);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromPaymentJournal(true, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRemittanceAdviceFromPaymentJournalInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Payment Journal when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromPaymentJournal(false, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    local procedure SendRemittanceAdviceFromPaymentJournal(RunJQ: Boolean; InvoicesCount: Integer; JQCount: Integer; VendorCount: Integer; EmailCount: Integer)
    var
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: Page "Payment Journal";
        VendorNo: Text;
        VendorNos, VendorEmails : List of [Text];
        Count: Integer;
        StrBuilder: TextBuilder;
    begin
        // [GIVEN] Customers with email
        for Count := 1 to VendorCount do begin
            CreateVendorWithEmail(Vendor);
            VendorNos.Add(Vendor."No.");
            VendorEmails.Add(Vendor."E-Mail");
            CreateVendorRemittanceReportSelection(Enum::"Report Selection Usage"::"V.Remittance".AsInteger(), Vendor."No.");
        end;

        // [GIVEN] General Journal Lines for above customers
        for Count := 1 to VendorCount do begin
            VendorNos.Get(Count, VendorNo);
            Vendor.Get(VendorNo);
            CreateMultipleGeneralJournalLineForVendor(Vendor, 'GL0001', InvoicesCount);
            StrBuilder.Append(VendorNo + '|');
        end;
        GenJournalLine.SetRange("Document No.", 'GL0001');
        GenJournalLine.SetFilter("Account No.", StrBuilder.ToText().TrimEnd('|'));
        GenJournalLine.FindSet();
        Assert.RecordCount(GenJournalLine, InvoicesCount * VendorCount);

        repeat
            GenJournalLine.Mark(true);
        until GenJournalLine.Next() = 0;

        // [WHEN] Send General Journal lines
        PaymentJournal.SendVendorRecords(GenJournalLine);

        if RunJQ then begin
            // [THEN] "Document-Mailing" JQ will be created
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Document-Mailing");
            Assert.IsTrue(JobQueueEntry.FindSet(), 'No job queue entry for document-mailing found');
            Assert.RecordCount(JobQueueEntry, JQCount);

            // [WHEN] The "Document-Mailing" JQ will run and send the email
            repeat
                Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
            until JobQueueEntry.Next() = 0;
        end;

        ValidateAfterSending(VendorEmails, JQCount, EmailCount);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntryInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "ConfirmDefault", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromVendorLedgerEntry(true, 2, 4, 2, 2);

        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRAFromVendorLedgerEntryInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "ConfirmDefault", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromVendorLedgerEntry(false, 2, 4, 2, 2);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntryInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "ConfirmDefault", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromVendorLedgerEntry(true, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntryInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "ConfirmDefault", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendRemittanceAdviceFromVendorLedgerEntry(false, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntryInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromVendorLedgerEntry(true, 2, 4, 2, 2);

        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntryInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings))", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromVendorLedgerEntry(false, 2, 4, 2, 2);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntryInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromVendorLedgerEntry(true, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntryInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Remittance Advice from Vendor Ledger Entries when Select sending options = "UseDefaultProfile", Document Sending Profile has E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = ''; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, '', true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendRemittanceAdviceFromVendorLedgerEntry(false, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    local procedure SendRemittanceAdviceFromVendorLedgerEntry(RunJQ: Boolean; InvoicesCount: Integer; JQCount: Integer; VendorCount: Integer; EmailCount: Integer)
    var
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: Page "Vendor Ledger Entries";
        VendorNo: Text;
        VendorNos, VendorEmails : List of [Text];
        Count: Integer;
        StrBuilder: TextBuilder;
    begin
        // [GIVEN] Vendors with email
        for Count := 1 to VendorCount do begin
            CreateVendorWithEmail(Vendor);
            VendorNos.Add(Vendor."No.");
            VendorEmails.Add(Vendor."E-Mail");
            CreateVendorRemittanceReportSelection(Enum::"Report Selection Usage"::"P.V.Remit.".AsInteger(), Vendor."No.");
        end;

        // [GIVEN] Vendor Ledger Entries for above Vendors
        for Count := 1 to VendorCount do begin
            VendorNos.Get(Count, VendorNo);
            Vendor.Get(VendorNo);
            CreateMultipleVendorLedgerEntriesForVendor(Vendor, 'GL0001', InvoicesCount);
            StrBuilder.Append(VendorNo + '|');
        end;
        VendorLedgerEntry.SetRange("Document No.", 'GL0001');
        VendorLedgerEntry.SetFilter("Vendor No.", StrBuilder.ToText().TrimEnd('|'));
        VendorLedgerEntry.FindSet();
        Assert.RecordCount(VendorLedgerEntry, InvoicesCount * VendorCount);

        // [WHEN] Send Vendor Ledger Entries
        VendorLedgerEntries.SendVendorRecords(VendorLedgerEntry);

        if RunJQ then begin
            // [THEN] "Document-Mailing" JQ will be created
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Document-Mailing");
            Assert.IsTrue(JobQueueEntry.FindSet(), 'No job queue entry for document-mailing found');
            Assert.RecordCount(JobQueueEntry, JQCount);

            // [WHEN] The "Document-Mailing" JQ will run and send the email
            repeat
                Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
            until JobQueueEntry.Next() = 0;
        end;

        ValidateAfterSending(VendorEmails, JQCount, EmailCount);
    end;

    local procedure ValidateAfterSending(Emails: List of [Text]; TotalEmailCount: Integer; PerEntityEmailCount: Integer)
    var
        EmailOutbox: Record "Email Outbox";
        SentEmail: Record "Sent Email";
        EmailMessage: Codeunit "Email Message";
        RecipientsCount: Dictionary of [Text, Integer];
        Email: Text;
        Count: Integer;
    begin
        // [THEN] One email should have been sent to the above created customer
        Assert.RecordCount(EmailOutbox, 0);
        Assert.RecordCount(SentEmail, TotalEmailCount);

        // [THEN] Email sent is only sent to customer
        SentEmail.FindSet();
        repeat
            EmailMessage.Get(SentEmail.GetMessageId());
            Email := ValidateOnlyOneToRecipientAndGetRecipient(EmailMessage);
            if not RecipientsCount.Get(Email, Count) then
                Count := 0;
            RecipientsCount.Set(Email, Count + 1);

            // [THEN] Email only has one attachment and is pdf
            ValidateEmailAttachmentsOnlyPdf(EmailMessage, 1);
        until SentEmail.Next() = 0;

        foreach Email in RecipientsCount.Keys() do begin
            Assert.IsTrue(Emails.Contains(Email), 'Email was sent to someone unexpected');
            Assert.AreEqual(PerEntityEmailCount, RecipientsCount.Get(Email), 'The number of emails sent to recipient do not match');
        end;
    end;

    local procedure CreateMultipleGeneralJournalLineForVendor(Vendor: Record Vendor; DocNo: Code[20]; GeneralJournalLineCount: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        No: Integer;
    begin
        for No := 1 to GeneralJournalLineCount do begin
            CreateGenJnlLine(GenJournalLine, Vendor."No.");
            GenJournalLine."Document No." := DocNo;
            GenJournalLine.Modify();
        end;
    end;

    local procedure CreateMultipleVendorLedgerEntriesForVendor(Vendor: Record Vendor; DocNo: Code[20]; VendorLedgerEntryCount: Integer)
    var
        No: Integer;
    begin
        for No := 1 to VendorLedgerEntryCount do
            MockVendorLedgerEntry(Vendor."No.", DocNo);
    end;

    local procedure ValidateOnlyOneToRecipientAndGetRecipient(var EmailMessage: Codeunit "Email Message"): Text
    var
        Recipients: List of [Text];
        Recipient: Text;
    begin
        // Validate "Cc" recipients
        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::"Cc", Recipients);
        Assert.AreEqual(0, Recipients.Count(), 'Email was sent to a Cc recipient');

        // Validate "Bcc" recipients
        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::"Bcc", Recipients);
        Assert.AreEqual(0, Recipients.Count(), 'Email was sent to a Bcc recipient');

        // Validate "To" recipients
        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::"To", Recipients);

        Assert.AreEqual(1, Recipients.Count(), 'More than one recipient');
        Recipients.Get(1, Recipient);
        exit(Recipient);
    end;

    local procedure ValidateEmailAttachmentsOnlyPdf(var EmailMessage: Codeunit "Email Message"; Count: Integer)
    var
        AttachmentCount: Integer;
    begin
        Assert.IsTrue(EmailMessage.Attachments_First(), 'No email attachments');
        repeat
            AttachmentCount += 1;
            Assert.IsSubstring(EmailMessage.Attachments_GetName(), '.pdf');
        until EmailMessage.Attachments_Next() = 0;
        Assert.AreEqual(AttachmentCount, Count, 'More than one email attachment found');
    end;

    local procedure CreateVendorWithEmail(var Vendor: Record Vendor) Email: Text[80]
    begin
        Email := LibraryUtility.GenerateRandomEmail();

        LibraryPurchase.CreateVendorWithAddress(Vendor);
        Vendor."E-Mail" := Email;
        Vendor.Modify();
    end;

    local procedure SetupDefaultEmailSendingProfile(EmailType: Option; EmailAttachment: Enum "Document Sending Profile Attachment Type"; EmailFormatCode: Code[20]; CombineEmails: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.DeleteAll();

        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Printer := DocumentSendingProfile.Printer::No;
        DocumentSendingProfile."E-Mail" := EmailType;
        DocumentSendingProfile."E-Mail Attachment" := EmailAttachment;
        DocumentSendingProfile."E-Mail Format" := EmailFormatCode;
        DocumentSendingProfile."Combine Email Documents" := CombineEmails;
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Insert();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    procedure SendRemittanceAdviceFromPaymentJournal()
    begin
        SendRemittanceAdviceFromPaymentJournalInternal();
    end;

    procedure SendRemittanceAdviceFromPaymentJournalInternal()
    var
        CustomReportSelection: Record "Custom Report Selection";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        LibraryWorkflow: Codeunit "Library - Workflow";
    begin
        // [SCENARIO 339846] Send remittance advice report to vendor by email from Payment Journal using customized Document Sending Profile
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

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
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    procedure SendRemittanceAdviceFromVendorLedgerEntry()
    begin
        SendRemittanceAdviceFromVendorLedgerEntryInternal();
    end;

    procedure SendRemittanceAdviceFromVendorLedgerEntryInternal()
    var
        CustomReportSelection: Record "Custom Report Selection";
        Vendor: Record Vendor;
        LibraryWorkflow: Codeunit "Library - Workflow";
    begin
        // [SCENARIO 339846] Send remittance advice report to vendor by email from Payment Journal using customized Document Sending Profile
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Vendor with email
        // [GIVEN] Vendor Ledger Entry
        // [GIVEN] Custom report selection 
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."E-Mail" := LibraryUtility.GenerateRandomEmail();
        Vendor.Modify(true);
        CreateVendorRemittanceReportSelection(CustomReportSelection.Usage::"P.V.Remit.", Vendor."No.");
        MockVendorLedgerEntry(Vendor."No.", '');
        // [WHEN] Open Vendor Ledger Entries and invoke "Send Remittance Advice" action
        LibraryVariableStorage.Enqueue(Vendor."E-Mail");
        SendFromVendorLedgerEntry(Vendor."No.");
        // [THEN] Email Dialog opened and "To:" = "Email"
    end;

    local procedure Initialize()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        EmailOutbox: Record "Email Outbox";
        SentEmail: Record "Sent Email";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::SendRemittanceAdvice);
        LibraryVariableStorage.Clear();
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();
        GenJournalLine.DeleteAll();
        EmailOutbox.DeleteAll();
        SentEmail.DeleteAll();
        ModalCount := 0;
        ResetDefaultDocumentSendingProfile();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::SendRemittanceAdvice);
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');
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

        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportSelectionUsage);
        ReportSelections.Validate("Report ID", CustomReportSelection."Report ID");
        ReportSelections.Validate("Use for Email Attachment", true);
        ReportSelections.Insert();
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

    local procedure MockVendorLedgerEntry(VendorNo: Code[20]; DocNo: Code[20])
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
        VendorLedgerEntry."Document No." := DocNo;
        if DocNo = '' then
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

    local procedure ResetDefaultDocumentSendingProfile()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        with DocumentSendingProfile do begin
            SetRange(Default, true);
            DeleteAll();

            Validate(Default, true);
            Validate(Description, LibraryUtility.GenerateGUID());
            Validate(Disk, Disk::No);
            Validate(Printer, Printer::No);
            Validate("E-Mail", "E-Mail"::No);
            Validate("Electronic Document", "Electronic Document"::No);
            Insert();
        end;
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
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.ToField.AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionsStrMenuHandler(MenuOptions: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    procedure SelectSendingOptionsOKModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
        ModalCount += 1;
    end;

    [ModalPageHandler]
    procedure EmailEditorSendModalPageHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.Send.Invoke();
    end;
}

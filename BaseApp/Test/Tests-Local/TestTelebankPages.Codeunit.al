codeunit 144022 "Test Telebank Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPaymentJournalBE: Codeunit "Library - Payment Journal BE";
        PmtJnlBatchesPageCaption: Text;
        BankAccountCodeFilter: Text[30];

    [Test]
    [Scope('OnPrem')]
    procedure ElectronicBankingSetupOnOpen()
    var
        ElectronicBankingSetup: Record "Electronic Banking Setup";
        ElectronicBankingSetupCard: TestPage "Electronic Banking Setup";
    begin
        // Init
        if ElectronicBankingSetup.Get() then
            ElectronicBankingSetup.Delete();

        // Execute
        ElectronicBankingSetupCard.OpenEdit;
        ElectronicBankingSetupCard.Close();

        // Verify
        ElectronicBankingSetup.Get();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EBPaymentJournalOnOpen1()
    var
        EBPaymentJournal: TestPage "EB Payment Journal";
    begin
        // Execute
        EBPaymentJournal.OpenEdit;

        // Verify
        Assert.AreEqual('', Format(EBPaymentJournal.ExportProtocolCode), '');
        Assert.AreEqual('', Format(EBPaymentJournal.BankAccountCodeFilter), '');

        // Cleanup
        EBPaymentJournal.Close();
    end;

    [Test]
    [HandlerFunctions('EBPaymentJournalTemplateHandler,EBPaymentJournalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EBPaymentJournalOnOpen2()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJournalLine: Record "Payment Journal Line";
        EBPaymentJournalBatches: TestPage "EB Payment Journal Batches";
    begin
        // Init
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);
        LibraryPaymentJournalBE.InitPmtJournalLine(PaymentJnlTemplate, PaymJournalBatch, PaymentJournalLine);

        // Exercise
        EBPaymentJournalBatches.OpenView;
        EBPaymentJournalBatches.FILTER.SetFilter(Name, PaymJournalBatch.Name);
        EBPaymentJournalBatches.First;
        EBPaymentJournalBatches."Edit Journal".Invoke;
        EBPaymentJournalBatches.Close();

        // Verify: Page 2000001 opens - caught by page handler.
    end;

    [Test]
    [HandlerFunctions('BankAccountListHandler')]
    [Scope('OnPrem')]
    procedure EBPaymentJournalOpen()
    var
        EBPaymentJournal: TestPage "EB Payment Journal";
    begin
        // Execute
        EBPaymentJournal.OpenEdit;
        EBPaymentJournal.BankAccountCodeFilter.Lookup;
        // Verify
        Assert.AreEqual('', Format(EBPaymentJournal.ExportProtocolCode), '');
        Assert.AreEqual(BankAccountCodeFilter, DelChr(Format(EBPaymentJournal.BankAccountCodeFilter), '<>', ''''), '');

        // Cleanup
        EBPaymentJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EBPaymentJournalNew()
    var
        EBPaymentJournal: TestPage "EB Payment Journal";
    begin
        // Init
        EBPaymentJournal.OpenEdit;

        // Exercise
        if EBPaymentJournal.Last then;
        EBPaymentJournal.New;

        // Verify
        Assert.AreEqual('', Format(EBPaymentJournal."Account No."), '');

        // Cleanup
        EBPaymentJournal.Close();
    end;

    [Test]
    [HandlerFunctions('EBPaymentJournalTemplateHandler,EBPaymentJournalBatchHandler,DimensionSetHandler,VendorEntriesHandler,RequestPage2000019Handler,VendorCardHandler')]
    [Scope('OnPrem')]
    procedure EBPaymentJournalEditRec()
    var
        Vendor: Record Vendor;
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJournalLine: Record "Payment Journal Line";
        ExportProtocol: Record "Export Protocol";
        EBPaymentJournal: TestPage "EB Payment Journal";
    begin
        // Init
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);
        LibraryPaymentJournalBE.InitPmtJournalLine(PaymentJnlTemplate, PaymJournalBatch, PaymentJournalLine);
        ExportProtocol.Init();
        ExportProtocol.Code := CopyStr(CreateGuid, 1, MaxStrLen(ExportProtocol.Code));
        ExportProtocol.Description := ExportProtocol.Code;
        ExportProtocol."Export Object Type" := ExportProtocol."Export Object Type"::Report;
        ExportProtocol.Insert();
        Commit();
        Vendor.FindFirst();
        EBPaymentJournal.OpenEdit;
        EBPaymentJournal.CurrentJnlBatchName.Lookup;
        EBPaymentJournal.CurrentJnlBatchName.SetValue(PaymJournalBatch.Name);
        EBPaymentJournal.ExportProtocolCode.SetValue(ExportProtocol.Code);

        // Exercise
        if EBPaymentJournal.Last then;
        EBPaymentJournal.New;
        EBPaymentJournal."Posting Date".SetValue(WorkDate());
        EBPaymentJournal."Account Type".SetValue(PaymentJournalLine."Account Type"::Vendor);
        EBPaymentJournal."Account No.".SetValue(Vendor."No.");
        EBPaymentJournal.New;
        EBPaymentJournal."Posting Date".SetValue(WorkDate());
        EBPaymentJournal."Account Type".SetValue(PaymentJournalLine."Account Type"::Vendor);
        EBPaymentJournal."Account No.".SetValue(Vendor."No.");
        Commit();

        // Verify: Verify that the correct pages are opened and handled by handler functions.
        EBPaymentJournal.Dimensions.Invoke;
        EBPaymentJournal.Card.Invoke;
        EBPaymentJournal.LedgerEntries.Invoke;
        Commit();
        EBPaymentJournal.SuggestVendorPayments.Invoke;
        asserterror EBPaymentJournal.CheckPaymentLines.Invoke;

        // Cleanup
        EBPaymentJournal.Close();
        PaymentJournalLine.DeleteAll();
        PaymJournalBatch.Delete();
        PaymentJnlTemplate.Delete();
        ExportProtocol.Delete();
    end;

    [Test]
    [HandlerFunctions('EBPaymentJournalBatchHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EBPaymentJournalBatches()
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        EBPaymentJournalBatches: Page "EB Payment Journal Batches";
    begin
        // Init
        LibraryPaymentJournalBE.CreateTemplate(PaymentJnlTemplate);
        LibraryPaymentJournalBE.CreateBatch(PaymentJnlTemplate, PaymJournalBatch);
        PmtJnlBatchesPageCaption := '';

        // Exercise
        EBPaymentJournalBatches.SetTableView(PaymJournalBatch);
        EBPaymentJournalBatches.RunModal();

        // Verify: Page 2000003 opens - caught by page handler.
        Assert.AreEqual(
          StrSubstNo(
            'Edit - %1 - %2 %3',
            EBPaymentJournalBatches.Caption,
            PaymentJnlTemplate.Name, PaymentJnlTemplate.Description),
          PmtJnlBatchesPageCaption, '');
    end;

    [Test]
    [HandlerFunctions('DomiciliationJournalBatchesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DomiciliationJournalBatches()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalBatches: Page "Domiciliation Journal Batches";
    begin
        // Init
        LibraryPaymentJournalBE.CreateDomTemplate(DomiciliationJournalTemplate);
        LibraryPaymentJournalBE.CreateDomBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        PmtJnlBatchesPageCaption := '';

        // Exercise
        DomiciliationJournalBatches.SetTableView(DomiciliationJournalBatch);
        DomiciliationJournalBatches.RunModal();

        // Verify: Page 2000021 opens - caught by page handler.
        Assert.AreEqual(
          StrSubstNo(
            'Edit - %1 - %2 %3',
            DomiciliationJournalBatches.Caption,
            DomiciliationJournalTemplate.Name, DomiciliationJournalTemplate.Description),
          PmtJnlBatchesPageCaption, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DomiciliationJournalOnOpen1()
    var
        DomiciliationJournal: TestPage "Domiciliation Journal";
    begin
        // Verify that it opens directly
        DomiciliationJournal.OpenEdit;
        // Cleanup
        DomiciliationJournal.Close();
    end;

    [Test]
    [HandlerFunctions('DomiciliationJournalTemplateHandler,DomiciliationJournalHandler')]
    [Scope('OnPrem')]
    procedure DomiciliationJournalOnOpen2()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalBatches: TestPage "Domiciliation Journal Batches";
    begin
        // Init
        LibraryPaymentJournalBE.CreateDomTemplate(DomiciliationJournalTemplate);
        LibraryPaymentJournalBE.CreateDomBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        Commit();

        // Exercise
        DomiciliationJournalBatches.OpenView;
        DomiciliationJournalBatches.FILTER.SetFilter(Name, DomiciliationJournalBatch.Name);
        DomiciliationJournalBatches.First;
        DomiciliationJournalBatches."Edit Journal".Invoke;
        DomiciliationJournalBatches.Close();

        // Verify: Page 2000022 opens - caught by page handler.

        // Cleanup
        DomiciliationJournalTemplate.Delete();
        DomiciliationJournalBatch.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DomiciliationJournalNew()
    var
        DomiciliationJournal: TestPage "Domiciliation Journal";
    begin
        // Init
        DomiciliationJournal.OpenEdit;

        // Exercise
        if DomiciliationJournal.Last then;
        DomiciliationJournal.New;

        // Verify
        Assert.AreEqual('', Format(DomiciliationJournal."Customer No."), '');

        // Cleanup
        DomiciliationJournal.Close();
    end;

    [Test]
    [HandlerFunctions('DomiciliationJournalTemplateHandler,DomiciliationJournalBatchesLookUpHandler,DimensionSetHandler,CustomerCardHandler,CustomerEntriesHandler,RequestPage2000039Handler')]
    [Scope('OnPrem')]
    procedure DomiciliationJournalEditRec()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        DomiciliationJournal: TestPage "Domiciliation Journal";
    begin
        // Init
        LibraryPaymentJournalBE.CreateDomTemplate(DomiciliationJournalTemplate);
        LibraryPaymentJournalBE.CreateDomBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        LibraryPaymentJournalBE.InitDomJournalLine(DomiciliationJournalTemplate, DomiciliationJournalBatch, DomiciliationJournalLine);
        Commit();
        Customer.FindFirst();
        BankAccount.FindSet();
        DomiciliationJournal.OpenEdit;
        DomiciliationJournal.CurrentJnlBatchName.Lookup;
        DomiciliationJournal.CurrentJnlBatchName.SetValue(DomiciliationJournalBatch.Name);

        // Exercise
        if DomiciliationJournal.Last then;
        DomiciliationJournal.New;
        DomiciliationJournal."Posting Date".SetValue(WorkDate());
        DomiciliationJournal."Customer No.".SetValue(Customer."No.");
        DomiciliationJournal."Bank Account No.".SetValue(BankAccount."No.");
        DomiciliationJournal.New;
        DomiciliationJournal."Posting Date".SetValue(WorkDate());
        DomiciliationJournal."Customer No.".SetValue(Customer."No.");
        DomiciliationJournal."Bank Account No.".SetValue(BankAccount."No.");
        BankAccount.Next();
        DomiciliationJournal."Bank Account No.".SetValue(BankAccount."No.");
        DomiciliationJournal.Previous;
        Commit();

        // Verify: Verify that the correct pages are opened and handled by handler functions.
        Assert.AreEqual(BankAccount."No.", DomiciliationJournal."Bank Account No.".Value, '');
        DomiciliationJournal.Dimensions.Invoke;
        DomiciliationJournal.Card.Invoke;
        DomiciliationJournal.LedgerEntries.Invoke;
        Commit();
        DomiciliationJournal.SuggestDomiciliations.Invoke;

        // Cleanup
        DomiciliationJournal.Close();
        DomiciliationJournalLine.DeleteAll();
        DomiciliationJournalBatch.Delete();
        DomiciliationJournalTemplate.Delete();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountListHandler(var BankAccountList: TestPage "Bank Account List")
    begin
        BankAccountList.First;
        BankAccountCodeFilter := BankAccountList."No.".Value;
        BankAccountList.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EBPaymentJournalHandler(var EBPaymentJournal: TestPage "EB Payment Journal")
    begin
        EBPaymentJournal.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EBPaymentJournalBatchHandler(var EBPaymentJournalBatches: TestPage "EB Payment Journal Batches")
    begin
        PmtJnlBatchesPageCaption := EBPaymentJournalBatches.Caption;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EBPaymentJournalTemplateHandler(var EBPaymentJournalTemplates: TestPage "EB Payment Journal Templates")
    begin
        EBPaymentJournalTemplates.First;
        EBPaymentJournalTemplates.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DomiciliationJournalHandler(var DomiciliationJournal: TestPage "Domiciliation Journal")
    begin
        DomiciliationJournal.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DomiciliationJournalBatchesHandler(var DomiciliationJournalBatches: TestPage "Domiciliation Journal Batches")
    begin
        PmtJnlBatchesPageCaption := DomiciliationJournalBatches.Caption;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DomiciliationJournalBatchesLookUpHandler(var DomiciliationJournalBatches: TestPage "Domiciliation Journal Batches")
    begin
        DomiciliationJournalBatches.First;
        DomiciliationJournalBatches.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DomiciliationJournalTemplateHandler(var DomicilJournalTemplates: TestPage "Domicil. Journal Templates")
    begin
        DomicilJournalTemplates.First;
        DomicilJournalTemplates.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardHandler(var CustomerCard: TestPage "Customer Card")
    begin
        CustomerCard.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerEntriesHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustomerLedgerEntries.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorCardHandler(var VendorCard: TestPage "Vendor Card")
    begin
        VendorCard.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorEntriesHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPage2000019Handler(var SuggestVendorPaymentsEB: TestRequestPage "Suggest Vendor Payments EB")
    begin
        SuggestVendorPaymentsEB.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPage2000039Handler(var Suggestdomicilations: TestRequestPage "Suggest domicilations")
    begin
        Suggestdomicilations.Cancel.Invoke;
    end;
}


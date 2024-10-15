codeunit 144018 "Test Telebank Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalTemplateOnInsert()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Setup
        SourceCodeSetup.Init();
        if not SourceCodeSetup.Get() then
            SourceCodeSetup.Insert();
        SourceCodeSetup."Payment Journal" := CopyStr(CreateGuid(), 1, MaxStrLen(SourceCodeSetup."Payment Journal"));
        SourceCodeSetup.Modify();

        with PaymentJournalTemplate do begin
            Init();
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));

            // Exercise
            Insert(true);

            // Validate
            TestField("Source Code", SourceCodeSetup."Payment Journal");
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalTemplateOnDelete()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymentJournalTemplate.Delete(true);

        // Verify
        Assert.AreEqual(0, PaymentJnlLine.Count, '');
        Assert.AreEqual(0, PaymJnlBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalTemplateSourceCode()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        SourceCode: Record "Source Code";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);
        LibraryERM.CreateSourceCode(SourceCode);
        // Exercise
        PaymentJournalTemplate.Validate("Source Code", SourceCode.Code);

        // Verify
        PaymentJnlLine.SetRange("Source Code", PaymentJournalTemplate."Source Code");
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalBatchOnInsert()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);

        // Exercise
        with PaymJnlBatch do begin
            Init();
            "Journal Template Name" := PaymentJournalTemplate.Name;
            SetRange("Journal Template Name", "Journal Template Name");
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));
            Insert(true);
        end;

        // Verify
        Assert.AreEqual(PaymentJournalTemplate."Reason Code", PaymJnlBatch."Reason Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalBatchOnDelete()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymJnlBatch.Delete(true);

        // Verify
        Assert.AreEqual(0, PaymentJnlLine.Count, '');
        Assert.AreEqual(0, PaymJnlBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalBatchOnRename()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymJnlBatch.Rename('', PaymJnlBatch.Name);

        // Verify
        Assert.AreEqual(0, PaymentJnlLine.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalLineDim()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        DimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);
        DimValue.FindFirst();
        DefaultDimension.Init();
        DefaultDimension."Table ID" := DATABASE::Vendor;
        DefaultDimension."No." := Vendor."No.";
        DefaultDimension."Dimension Code" := DimValue."Dimension Code";
        DefaultDimension."Dimension Value Code" := DimValue.Code;
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Insert(true);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine.Validate("Account No.", Vendor."No.");

        // intermediate result
        ValidateJournalLineDim(PaymentJnlLine, DefaultDimension);

        // Exercise, continued
        PaymentJnlLine.Validate("Bank Account", BankAccount."No.");

        // Verify
        ValidateJournalLineDim(PaymentJnlLine, DefaultDimension);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalTemplateOnInsert()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Setup
        SourceCodeSetup.Init();
        if not SourceCodeSetup.Get() then
            SourceCodeSetup.Insert();
        SourceCodeSetup."Domiciliation Journal" := CopyStr(CreateGuid(), 1, MaxStrLen(SourceCodeSetup."Domiciliation Journal"));
        SourceCodeSetup.Modify();

        with DomiciliationJournalTemplate do begin
            Init();
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));

            // Exercise
            Insert(true);

            // Validate
            TestField("Source Code", SourceCodeSetup."Domiciliation Journal");
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalTemplateOnDelete()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);

        // Validate setup
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(1, DomiciliationJournalBatch.Count, '');

        // Exercise
        DomiciliationJournalTemplate.Delete(true);

        // Verify
        Assert.AreEqual(0, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(0, DomiciliationJournalBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalTemplateSourceCode()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        SourceCode: Record "Source Code";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);
        LibraryERM.CreateSourceCode(SourceCode);
        // Exercise
        DomiciliationJournalTemplate.Validate("Source Code", SourceCode.Code);

        // Verify
        DomiciliationJournalLine.SetRange("Source Code", DomiciliationJournalTemplate."Source Code");
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalBatchOnInsert()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);

        // Exercise
        with DomiciliationJournalBatch do begin
            Init();
            "Journal Template Name" := DomiciliationJournalTemplate.Name;
            SetRange("Journal Template Name", "Journal Template Name");
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));
            Insert(true);
        end;

        // Verify
        Assert.AreEqual(DomiciliationJournalTemplate."Reason Code", DomiciliationJournalBatch."Reason Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalBatchOnDelete()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);

        // Validate setup
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(1, DomiciliationJournalBatch.Count, '');

        // Exercise
        DomiciliationJournalBatch.Delete(true);

        // Verify
        Assert.AreEqual(0, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(0, DomiciliationJournalBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalBatchOnRename()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);

        // Validate setup
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(1, DomiciliationJournalBatch.Count, '');

        // Exercise
        DomiciliationJournalBatch.Rename('', DomiciliationJournalBatch.Name);

        // Verify
        Assert.AreEqual(0, DomiciliationJournalLine.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableCODAStatementLineApplicationStatus()
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        // Init
        CODAStatementLine.Init();
        CODAStatementLine."Account No." := 'X';
        CODAStatementLine."Application Status" := CODAStatementLine."Application Status"::"Partly applied";
        CODAStatementLine.Validate("Account No.", '');

        // Validation
        CODAStatementLine.TestField("Application Status", CODAStatementLine."Application Status"::" ");
    end;

    local procedure CreatePaymentJournalTemplate(var PaymentJournalTemplate: Record "Payment Journal Template")
    begin
        with PaymentJournalTemplate do begin
            Init();
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));
            Insert();
        end;
    end;

    local procedure CreatePaymentJournalBatch(PaymentJournalTemplate: Record "Payment Journal Template"; var PaymJnlBatch: Record "Paym. Journal Batch")
    begin
        with PaymJnlBatch do begin
            Init();
            "Journal Template Name" := PaymentJournalTemplate.Name;
            SetRange("Journal Template Name", "Journal Template Name");
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));
            Insert();
        end;
    end;

    local procedure CreatePaymentJournalLine(PaymJnlBatch: Record "Paym. Journal Batch"; var PaymentJnlLine: Record "Payment Journal Line")
    begin
        with PaymentJnlLine do begin
            "Journal Template Name" := PaymJnlBatch."Journal Template Name";
            "Journal Batch Name" := PaymJnlBatch.Name;
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            if FindLast() then;
            "Line No." += 10000;
            Init();
            Insert();
        end;
    end;

    local procedure CreateDomiciliationJournalTemplate(var DomiciliationJournalTemplate: Record "Domiciliation Journal Template")
    begin
        with DomiciliationJournalTemplate do begin
            Init();
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));
            Insert();
        end;
    end;

    local procedure CreateDomiciliationJournalBatch(DomiciliationJournalTemplate: Record "Domiciliation Journal Template"; var DomiciliationJournalBatch: Record "Domiciliation Journal Batch")
    begin
        with DomiciliationJournalBatch do begin
            Init();
            "Journal Template Name" := DomiciliationJournalTemplate.Name;
            SetRange("Journal Template Name", "Journal Template Name");
            Name := CopyStr(CreateGuid(), 1, MaxStrLen(Name));
            Insert();
        end;
    end;

    local procedure CreateDomiciliationJournalLine(DomiciliationJournalBatch: Record "Domiciliation Journal Batch"; var DomiciliationJournalLine: Record "Domiciliation Journal Line")
    begin
        with DomiciliationJournalLine do begin
            "Journal Template Name" := DomiciliationJournalBatch."Journal Template Name";
            "Journal Batch Name" := DomiciliationJournalBatch.Name;
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            if FindLast() then;
            "Line No." += 10000;
            Init();
            Insert();
        end;
    end;

    local procedure ValidateJournalLineDim(var PaymentJnlLine: Record "Payment Journal Line"; var DefaultDimension: Record "Default Dimension")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        PaymentJnlLine.TestField("Dimension Set ID");
        DimensionManagement.GetDimensionSet(TempDimSetEntry, PaymentJnlLine."Dimension Set ID");
        Assert.AreEqual(1, TempDimSetEntry.Count, '');
        TempDimSetEntry.FindFirst();
        Assert.AreEqual(DefaultDimension."Dimension Code", TempDimSetEntry."Dimension Code", '');
        Assert.AreEqual(DefaultDimension."Dimension Value Code", TempDimSetEntry."Dimension Value Code", '');
    end;
}


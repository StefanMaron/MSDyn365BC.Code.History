codeunit 144020 "Test Telebank Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Message1PrefixTxt: Label 'Message1:%1';
        ReferencePrefixTxt: Label 'Reference:%1';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";

    [HandlerFunctions('HandleDomiciliationJournalTestReport')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DomiciliationJournalReportTest()
    var
        DomiciliationCustomer: Record Customer;
        DomiciliationBankAccount: Record "Bank Account";
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        BankAccountNo: Text[12];
        TotalAmount: Decimal;
        MonthCounter: Integer;
    begin
        // Setup
        LibraryERM.CreateBankAccount(DomiciliationBankAccount);
        DomiciliationBankAccount.Validate("No.", '000000000097');
        DomiciliationBankAccount.Validate(Name, DomiciliationBankAccount."No.");
        DomiciliationBankAccount.Insert();

        LibrarySales.CreateCustomer(DomiciliationCustomer);
        BankAccountNo := DelStr(DomiciliationBankAccount."No.", 13);
        DomiciliationCustomer.Validate("Domiciliation No.", BankAccountNo);
        DomiciliationCustomer.Modify();
        DomiciliationJournalTemplate.Validate("Bank Account No.", BankAccountNo);

        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLines(DomiciliationJournalBatch, DomiciliationBankAccount, DomiciliationCustomer);

        // Execution
        REPORT.Run(REPORT::"Domiciliation Journal - Test", true, false, DomiciliationJournalBatch);

        // Validation
        LibraryReportDataset.LoadDataSetFile;

        for MonthCounter := 1 to 12 do begin
            LibraryReportDataset.AssertElementWithValueExists(
              'Message1_DomiciliationJnlLine', StrSubstNo(Message1PrefixTxt, MonthCounter));
            LibraryReportDataset.AssertElementWithValueExists(
              'Amount_DomiciliationJnlLine', MonthCounter * 1000);
            LibraryReportDataset.AssertElementWithValueExists(
              'PmtDiscPossible_DomiciliationJnlLine', MonthCounter * 100);
            LibraryReportDataset.AssertElementWithValueExists(
              'PostingDateFormatted_DomiciliationJnlLine', Format(DMY2Date(1, MonthCounter, Date2DMY(WorkDate(), 3))));
            LibraryReportDataset.AssertElementWithValueExists(
              'Reference_DomiciliationJnlLine', StrSubstNo(ReferencePrefixTxt, MonthCounter));

            TotalAmount += MonthCounter * 1000;
            LibraryReportDataset.AssertElementWithValueExists('TotalAmount', TotalAmount);
            LibraryReportDataset.GetNextRow;
        end;
    end;

    local procedure CreateDomiciliationJournalTemplate(var DomiciliationJournalTemplate: Record "Domiciliation Journal Template")
    begin
        with DomiciliationJournalTemplate do begin
            Validate(Name, CopyStr(CreateGuid, 1, MaxStrLen(Name)));
            Insert();
        end;
    end;

    local procedure CreateDomiciliationJournalBatch(DomiciliationJournalTemplate: Record "Domiciliation Journal Template"; var DomiciliationJournalBatch: Record "Domiciliation Journal Batch")
    begin
        with DomiciliationJournalBatch do begin
            Validate("Journal Template Name", DomiciliationJournalTemplate.Name);
            SetRange("Journal Template Name", "Journal Template Name");
            Validate(Name, CopyStr(CreateGuid, 1, MaxStrLen(Name)));
            Insert();
        end;
    end;

    local procedure CreateDomiciliationJournalLines(DomiciliationJournalBatch: Record "Domiciliation Journal Batch"; DomiciliationBankAccount: Record "Bank Account"; DomiciliationCustomer: Record Customer)
    var
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        MonthCounter: Integer;
    begin
        for MonthCounter := 1 to 12 do
            with DomiciliationJournalLine do begin
                Init();
                Validate("Customer No.", DomiciliationCustomer."No.");
                Validate("Bank Account No.", DomiciliationBankAccount."No.");
                Validate("Message 1", StrSubstNo(Message1PrefixTxt, MonthCounter));
                Validate(Amount, MonthCounter * 1000);
                Validate("Posting Date", DMY2Date(1, MonthCounter, Date2DMY(WorkDate(), 3)));
                Validate("Pmt. Disc. Possible", MonthCounter * 100);
                Validate("Pmt. Discount Date", DMY2Date(1, MonthCounter, Date2DMY(WorkDate(), 3)));
                Validate(Reference, StrSubstNo(ReferencePrefixTxt, MonthCounter));
                Validate("Journal Template Name", DomiciliationJournalBatch."Journal Template Name");
                Validate("Journal Batch Name", DomiciliationJournalBatch.Name);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                Validate("Line No.", Amount);
                Insert();
            end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure HandleDomiciliationJournalTestReport(var RequestPage: TestRequestPage "Domiciliation Journal - Test")
    begin
        RequestPage.ShowDim.SetValue(true);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}


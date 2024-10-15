#if not CLEAN22
codeunit 144023 "SE Feature Bugs"
{
    // 1. Test to verify Gen. Journal Line after Suggest Vendor Payment with Always Including Credit Memo as True.
    // 2. Test to verify Gen. Journal Line after Suggest Vendor Payment with Always Including Credit Memo as False.
    // 3. Test to verify Amount on Issued Fin. Charge Memo Statistics page after issue Finance Charge Memo.
    // 
    // Covers Test Cases for WI - 351052
    // -----------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -----------------------------------------------------------------------------
    // SuggestVendorPaymentWithAlwaysInclCrMemoTrue
    // SuggestVendorPaymentWithAlwaysInclCrMemoFalse                          154018
    // 
    // Covers Test Cases for WI - 351205
    // -----------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -----------------------------------------------------------------------------
    // IssuedFinanceChargeMemoStatistics                                      269302

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryRandom: Codeunit "Library - Random";
        RecordEmptyMsg: Label 'Record Must be Empty.';
        IncorrectPeriodStartDateErr: Label 'Incorrect period start date';
        IncorrectPeriodEndDateErr: Label 'Incorrect period end date';
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithAlwaysInclCrMemoTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test to verify Gen. Journal Line after Suggest Vendor Payment with Always Including Credit Memo as True.

        // Setup and Exercise.
        SuggestVendorPaymentAfterPostPurchDoc(PurchaseLine, true);  // AlwaysInclCreditMemo as True.

        // Verify.
        VerifyGenJournalLine(
          GenJournalLine."Applies-to Doc. Type"::Invoice, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Amount Including VAT");
        VerifyGenJournalLine(
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", -PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithAlwaysInclCrMemoFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test to verify Gen. Journal Line after Suggest Vendor Payment with Always Including Credit Memo as False.

        // Setup and Exercise.
        SuggestVendorPaymentAfterPostPurchDoc(PurchaseLine, false);  // AlwaysInclCreditMemo as False.

        // Verify.
        VerifyNoGenJournalLineExist(GenJournalLine."Applies-to Doc. Type"::Invoice, PurchaseLine."Buy-from Vendor No.");
        VerifyNoGenJournalLineExist(GenJournalLine."Applies-to Doc. Type"::Payment, PurchaseLine."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('CreateFinanceChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssuedFinanceChargeMemoStatistics()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoStat: TestPage "Issued Fin. Charge Memo Stat.";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        FinChrgMemoTotal: Decimal;
    begin
        // Test to verify Amount on Issued Fin. Charge Memo Statistics page after issue Finance Charge Memo.

        // Setup: Create and post Sales Order. Create Finance Charge Memos.
        Initialize();
        CreateFinanceChargeTerms(FinanceChargeTerms);
        CustomerNo := CreateCustomerWithFinanceChargeTerms(FinanceChargeTerms.Code);
        DocumentNo := CreateAndPostSalesOrder(CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo);  // Enqueue for CreateFinanceChargeMemosRequestPageHandler.
        CreateAndIssueFinanceChargeMemos(CustomerNo);
        FinChrgMemoTotal :=
          CalculateFinanceChargeMemoTotal(CustomerNo, DocumentNo, FinanceChargeTerms."Interest Period (Days)");
        IssuedFinChargeMemoHeader.SetRange("Customer No.", CustomerNo);
        IssuedFinChargeMemoStat.Trap;

        // Exercise.
        OpenIssuedFinChargeMemoStatisticsPage(CustomerNo);

        // Verify.
        IssuedFinChargeMemoStat.FinChrgMemoTotal.AssertEquals(FinChrgMemoTotal);
    end;

    [Test]
    [HandlerFunctions('SIEExportRPH')]
    [Scope('OnPrem')]
    procedure SIE_Export_TRANS_Format()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        ExpectedLine: Text;
    begin
        // [FEATURE] [SIE Import/Export]
        // [SCENARIO 363105] SIE Export writes GLEntry's posting date to #TRANS  section
        Initialize();

        // [GIVEN] Post General Journal Line with Date = "D", GLAccount "ACC", Amount = "AMT"
        CreatePostGenJnlLineWithBalAcc(GenJournalLine);
        Commit();

        // [WHEN] Run SIE Export report
        FileName := RunSIEExport(GenJournalLine."Account No.", WorkDate(), WorkDate());

        // [THEN] Exported file containes #TRANS line with Date = "D", GLAccount = "ACC", Amount = "AMT"
        ExpectedLine :=
          StrSubstNo('  #TRANS  %1  {}  %2  %3',
            GenJournalLine."Account No.", FormatAmount(GenJournalLine.Amount), FormatDate(WorkDate()));
        Assert.ExpectedMessage(
          ExpectedLine,
          LibraryTextFileValidation.FindLineWithValue(FileName, 1, StrLen(ExpectedLine), ExpectedLine));
    end;

    [Test]
    [HandlerFunctions('SIEExportRPH')]
    [Scope('OnPrem')]
    procedure SIEExportAccPeriodLessThanYear()
    var
        StartDate: Date;
        EndDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [SIE Export]
        // [SCENARIO 378125] SIE Export writes accounting period ending date to #RAR section
        Initialize();

        // [GIVEN] Create fiscal year with period less than calendar year
        CreateNextFiscalYear(LibraryRandom.RandIntInRange(5, 10), StartDate, EndDate);
        Commit();

        // [WHEN] Run SIE Export report
        FileName := RunSIEExport('', StartDate, EndDate);

        // [THEN] Exported file containes #RAR line for current fiscal year (#RAR  0) with proper starting and ending dates
        VerifyLinePeriod(FileName, '#RAR  0', StartDate, EndDate);
    end;

    [Test]
    [HandlerFunctions('SIEExportRPH')]
    [Scope('OnPrem')]
    procedure SIEExportPrevAccPeriodLessThanYear()
    var
        PrevFYStartDate: Date;
        PrevFYEndDate: Date;
        LastFYStartDate: Date;
        LastFYEndDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [SIE Export]
        // [SCENARIO 378125] SIE Export writes previous accounting period ending date to #RAR section
        Initialize();

        // [GIVEN] Create 2 fiscal years with period less than calendar year
        CreateNextFiscalYear(LibraryRandom.RandIntInRange(5, 10), PrevFYStartDate, PrevFYEndDate);
        CreateNextFiscalYear(LibraryRandom.RandIntInRange(5, 10), LastFYStartDate, LastFYEndDate);
        Commit();

        // [WHEN] Run SIE Export report
        FileName := RunSIEExport('', LastFYStartDate, LastFYEndDate);

        // [THEN] Exported file containes #RAR line for previous fiscal year (#RAR  -1) with proper starting and ending dates
        VerifyLinePeriod(FileName, '#RAR  -1', PrevFYStartDate, PrevFYEndDate);
    end;

    [Test]
    [HandlerFunctions('SIEExportRPH,SIEImportRPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure SIEImportGLAccountFieldsValidateInGJLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        SIEImport: Report "SIE Import";
        FileName: Text;
    begin
        // [FEATURE] [SIE Import/Export]
        // [SCENARIO 309471] SIE Import validates VAT and Posting fields from GLAccount posted in documents having spaces in No.
        Initialize();

        // [GIVEN] Post General Journal Line with GLAccount "Acc"
        CreatePostGenJnlLineWithBalAcc(GenJournalLine);
        Commit();

        // [GIVEN] Exported file saved on the server
        FileName := RunSIEExport(GenJournalLine."Account No.", WorkDate(), WorkDate());

        // [GIVEN] Add VAT and Posting setup to the 'Acc'
        ModifyGLAccountWithVatSetup(GenJournalLine."Account No.");

        // [GIVEN] Gen. Journal Template "GJT" and Gen. Journal Batch "GJB"
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [WHEN] Run SIE Import with "GJT" and "GJB"
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        Commit();
        SIEImport.UseRequestPage(true);
        SIEImport.InitializeRequest(FileName);
        SIEImport.RunModal();

        // [THEN] VAT and Posting fields on imported Gen. Journal Line are the same as on GLAccount
        VerifyImportedGenJnlLine(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('SIEExportYearRequestPageHandler,SIEImportInsertGLAccountRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SIEImportEmptyGLAccountNo()
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccountNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [SIE Import]
        // [SCENARIO 372202] Run SIE Import on file that contains #KONTO line with empty No and Name.
        Initialize();
        CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] SIE file, that contains two #KONTO lines.
        // [GIVEN] First #KONTO line is with alphanumeric No = "GLNO" and Name = "GLNAME": #KONTO  1GU00000000000000000  "1GU00000000000000000".
        // [GIVEN] Second #KONTO line is with spaces in place of No and Name: #KONTO        .
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        Commit();
        FileName := RunSIEExport(GLAccountNo, WorkDate(), WorkDate());
        AddLineWithEmptyKONTONoAndName(FileName);

        // [GIVEN] G/L Account with No "GLNO" does not exist.
        GLAccount.Get(GLAccountNo);
        GLAccount.Delete();

        // [WHEN] Run SIE Import report on this SIE file with option Insert G/L Account set.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        Commit();
        RunSIEImport(FileName);

        // [THEN] G/L Account "GLNO" is created. G/L Account with empty No is not created.
        GLAccount.Get(GLAccountNo);
        asserterror GLAccount.Get();
        Assert.ExpectedError('The G/L Account does not exist.');
        Assert.ExpectedErrorCode('DB:RecordNotFound');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SIEExportRPH,SIEImportRPH,MessageHandler')]
    procedure VATDateWhenRunSIEImport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        PostingDate: Date;
    begin
        // [FEATURE] [Import]
        // [SCENARIO 463175] VAT Reporting Date in General Journal when run SIE Import.
        Initialize();

        // [GIVEN] Posted General Journal Line with Posting Date "D1".
        PostingDate := LibraryRandom.RandDateFromInRange(WorkDate(), 1, 5);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Commit();

        // [GIVEN] Exported SIE file.
        FileName := RunSIEExport(GenJournalLine."Account No.", PostingDate, PostingDate);

        // [GIVEN] General Journal Template "T" and General Journal Batch "B".
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [WHEN] Run SIE Import to General Journal with template "T" and batch "B".
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        Commit();
        RunSIEImport(FileName);

        // [THEN] General Journal Line is created. Posting Date, Document Date, VAT Registration Date are equal to "D1".
        VerifyDatesOnGenJournalLine(
            GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Account No.", PostingDate, PostingDate, PostingDate);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure AddLineWithEmptyKONTONoAndName(FileName: Text)
    var
        SIEFile: File;
        CR: Char;
        LF: Char;
    begin
        CR := 13;
        LF := 10;
        SIEFile.WriteMode(true);
        SIEFile.Open(FileName);
        SIEFile.Seek(SIEFile.Len);
        SIEFile.Write('#KONTO        ' + Format(CR) + Format(LF));
        SIEFile.Close();
    end;

    local procedure CalculateFinanceChargeMemoTotal(CustomerNo: Code[20]; DocumentNo: Code[20]; InterestPeriod: Integer) FinanceChargeMemoAmount: Decimal
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        DaysOverdue: Integer;
    begin
        IssuedFinChargeMemoHeader.SetRange("Customer No.", CustomerNo);
        IssuedFinChargeMemoHeader.FindFirst();
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        IssuedFinChargeMemoLine.SetRange("Document No.", DocumentNo);
        IssuedFinChargeMemoLine.FindFirst();
        DaysOverdue := IssuedFinChargeMemoHeader."Due Date" - IssuedFinChargeMemoLine."Due Date";
        FinanceChargeMemoAmount :=
          Round(IssuedFinChargeMemoLine."Remaining Amount" * (DaysOverdue / InterestPeriod) *
            (IssuedFinChargeMemoLine."Interest Rate" / 100), LibraryERM.GetInvoiceRoundingPrecisionLCY);
    end;

    local procedure CreateAndIssueFinanceChargeMemos(CustomerNo: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        REPORT.Run(REPORT::"Create Finance Charge Memos");  // Opens CreateFinanceChargeMemosRequestPageHandler.
        FinanceChargeMemoHeader.SetRange("Customer No.", CustomerNo);
        FinanceChargeMemoHeader.FindFirst();
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PaymentTermsCode: Code[10]; VendorNo: Code[20]; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Terms Code", PaymentTermsCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
    end;

    local procedure CreateAndPostSalesOrder(CustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure CreateCustomerWithFinanceChargeTerms(FinChargeTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
    end;

    local procedure CreatePostGenJnlLineWithBalAcc(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, LibraryRandom.RandDec(1000, 2));

        // TFS334845: The SIE export file cannot be used if the customer has a space character in a document number.
        GenJournalLine."Document No." := CopyStr(LibraryUtility.GenerateGUID + ' A A', 1, MaxStrLen(GenJournalLine."Document No."));
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        VATPostingSetup.SetFilter("VAT Calculation Type", '<>%1', VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.FindFirst();
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateFinanceChargeTerms(var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandDec(10, 2));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(30));
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateNextFiscalYear(NumberOfMonth: Integer; var StartDate: Date; var EndDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        CreateFiscalYear: Report "Create Fiscal Year";
        PeriodLength: DateFormula;
    begin
        StartDate := GetNextFiscalYearStartDate;
        Evaluate(PeriodLength, '<1M>');
        CreateFiscalYear.InitializeRequest(NumberOfMonth, PeriodLength, StartDate);
        CreateFiscalYear.UseRequestPage(false);
        CreateFiscalYear.Run();

        EndDate := AccountingPeriod.GetFiscalYearEndDate(StartDate);
    end;

    local procedure ModifyGLAccountWithVatSetup(GLAccountNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        LibraryERM.UpdateGLAccountWithPostingSetup(GLAccount, "General Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
    end;

    local procedure GetNextFiscalYearStartDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if AccountingPeriod.FindLast() then
            exit(AccountingPeriod."Starting Date");

        exit(CalcDate('<-CY>', WorkDate()));
    end;

    local procedure OpenIssuedFinChargeMemoStatisticsPage(CustomerNo: Code[20])
    var
        IssuedFinChargeMemoList: TestPage "Issued Fin. Charge Memo List";
    begin
        IssuedFinChargeMemoList.OpenEdit;
        IssuedFinChargeMemoList.FILTER.SetFilter("Customer No.", CustomerNo);
        IssuedFinChargeMemoList.Statistics.Invoke;
        IssuedFinChargeMemoList.Close();
    end;

    local procedure RunSuggestVendorPaymentsReport(GenJournalLine: Record "Gen. Journal Line"; No: Code[20])
    var
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        Vendor.SetRange("No.", No);
        Clear(SuggestVendorPayments);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.SetTableView(Vendor);
        Commit();  // Commit Required.
        SuggestVendorPayments.Run();
    end;

    local procedure RunSIEExport(GLAccountNo: Code[20]; StartDate: Date; EndDate: Date) FileName: Text
    var
        GLAccount: Record "G/L Account";
        SIEExport: Report "SIE Export";
        FileMgt: Codeunit "File Management";
    begin
        FileName := FileMgt.ServerTempFileName('');
        GLAccount.SetRange("No.", GLAccountNo);
        GLAccount.SetRange("Date Filter", StartDate, EndDate);
        SIEExport.UseRequestPage(true);
        SIEExport.SetTableView(GLAccount);
        SIEExport.InitializeRequest(FileName);
        SIEExport.RunModal();
    end;

    local procedure RunSIEImport(FileName: Text)
    var
        SIEImport: Report "SIE Import";
    begin
        SIEImport.UseRequestPage(true);
        SIEImport.InitializeRequest(FileName);
        SIEImport.RunModal();
    end;

    local procedure SuggestVendorPaymentAfterPostPurchDoc(var PurchaseLine: Record "Purchase Line"; AlwaysInclCreditMemo: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        // Setup: Create and post Purchase Invoice and Purchase Credit Memo.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PaymentTerms.Code, Vendor."No.", CreateGLAccount,
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));  // Take random Quantity and Direct Unit Cost.
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PaymentTerms.Code, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");
        CreateGeneralJournalLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(AlwaysInclCreditMemo);  // Enqueue for SuggestVendorPaymentsRequestPageHandler.

        // Exercise.
        RunSuggestVendorPaymentsReport(GenJournalLine, PurchaseLine."Buy-from Vendor No.");  // Opens SuggestVendorPaymentsRequestPageHandler.
    end;

    local procedure FormatAmount(Amount: Decimal): Text[30]
    begin
        exit(ConvertStr(Format(Amount, 0, '<Sign><Integer><decimal>'), ',', '.'));
    end;

    local procedure FormatDate(Date: Date): Text[30]
    begin
        exit(Format(Date, 8, '<Year4><month,2><day,2>'));
    end;

    local procedure VerifyGenJournalLine(AppliesToDocType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField(Amount, Amount);
    end;

    local procedure VerifyNoGenJournalLineExist(AppliesToDocType: Enum "Gen. Journal Document Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        Assert.IsTrue(GenJournalLine.IsEmpty, RecordEmptyMsg);
    end;

    local procedure VerifyLinePeriod(FileName: Text; PeriodSubstring: Code[10]; ExpectedStartDate: Date; ExpectedEndDate: Date)
    var
        LineText: Text;
        ExpectedStartDateAsText: Text;
        ExpectedEndDateAsText: Text;
    begin
        ExpectedStartDateAsText := FormatDate(ExpectedStartDate);
        ExpectedEndDateAsText := FormatDate(ExpectedEndDate);
        LineText := LibraryTextFileValidation.FindLineContainingValue(FileName, 1, 1000, PeriodSubstring);
        Assert.AreEqual(ExpectedStartDateAsText, CopyStr(LineText, StrLen(PeriodSubstring) + 3, 8), IncorrectPeriodStartDateErr);
        Assert.AreEqual(ExpectedEndDateAsText, CopyStr(LineText, StrLen(PeriodSubstring) + 15, 8), IncorrectPeriodEndDateErr);
    end;

    local procedure VerifyImportedGenJnlLine(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10]; GLAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Gen. Posting Type", GLAccount."Gen. Posting Type");
        GenJournalLine.TestField("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        GenJournalLine.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GenJournalLine.TestField("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenJournalLine.TestField("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
    end;

    local procedure VerifyDatesOnGenJournalLine(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10]; GLAccountNo: Code[20]; PostingDate: Date; DocumentDate: Date; VATDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.SetRange("Account No.", GLAccountNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", PostingDate);
        GenJournalLine.TestField("Document Date", DocumentDate);
        GenJournalLine.TestField("VAT Reporting Date", VATDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateFinanceChargeMemosRequestPageHandler(var CreateFinanceChargeMemos: TestRequestPage "Create Finance Charge Memos")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CreateFinanceChargeMemos.DocumentDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        CreateFinanceChargeMemos.Customer.SetFilter("No.", No);
        CreateFinanceChargeMemos.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        AlwaysInclCreditMemo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysInclCreditMemo);
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.AlwaysInclCreditMemo.SetValue(AlwaysInclCreditMemo);
        SuggestVendorPayments.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SIEExportRPH(var SIEExport: TestRequestPage "SIE Export")
    var
        ExportType: Option "1. Year - End Balances","2. Periodic Balances","3. Object Balances","4. Transactions";
    begin
        SIEExport.ExportType.SetValue(ExportType::"4. Transactions");
        SIEExport.FiscalYear.SetValue(Date2DMY(WorkDate(), 3));
        SIEExport.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SIEExportYearRequestPageHandler(var SIEExport: TestRequestPage "SIE Export")
    var
        ExportType: Option "1. Year - End Balances","2. Periodic Balances","3. Object Balances","4. Transactions";
    begin
        SIEExport.ExportType.SetValue(ExportType::"1. Year - End Balances");
        SIEExport.FiscalYear.SetValue(Date2DMY(WorkDate(), 3));
        SIEExport.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SIEImportRPH(var SIEImport: TestRequestPage "SIE Import")
    begin
        SIEImport."GenJnlLine.""Journal Template Name""".SetValue(LibraryVariableStorage.DequeueText);
        SIEImport."GenJnlLine.""Journal Batch Name""".SetValue(LibraryVariableStorage.DequeueText);
        SIEImport.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SIEImportInsertGLAccountRequestPageHandler(var SIEImport: TestRequestPage "SIE Import")
    begin
        SIEImport."GenJnlLine.""Journal Template Name""".SetValue(LibraryVariableStorage.DequeueText());  // Gen. Journal Template
        SIEImport."GenJnlLine.""Journal Batch Name""".SetValue(LibraryVariableStorage.DequeueText());  // Gen. Journal Batch
        SIEImport.InsertNewAccount.SetValue(true);  // Insert G/L Account
        SIEImport.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

#endif
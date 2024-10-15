codeunit 144110 "Cash Desk Reports"
{
    // Test Cases for Cash Desk Reports
    // 1. Check that Receipt Cash Document Report is correctly printed.
    // 2. Check that Withdrawal Cash Document Report is correctly printed.
    // 3. Check that correct Amounts are present on Receipt Cash Document Report after posting Receipt Cash Document.
    // 4. Check that correct Amounts are present on Withdrawal Cash Document Report after posting Withdrawal Cash Document.
    // 5. Check that correct Amounts are present on Receipt Cash Desk Book Report after posting Receipt Cash Document.

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCashDesk: Codeunit "Library - Cash Desk";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageReceiptCashDocHandler')]
    [Scope('OnPrem')]
    procedure PrintingReceiptCashDocument()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Check that Receipt Cash Document Report is correctly printed.
        PrintingCashDocument(CashDocHdr."Cash Document Type"::Receipt);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageWithdrawalCashDocHandler')]
    [Scope('OnPrem')]
    procedure PrintingWithdrawalCashDocument()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Check that Withdrawal Cash Document Report is correctly printed.
        PrintingCashDocument(CashDocHdr."Cash Document Type"::Withdrawal);
    end;

    local procedure PrintingCashDocument(CashDocType: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
    begin
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Cash Document
        CreateCashDocument(CashDocHdr, CashDocLn, CashDocType, BankAcc."No.");
        Commit;

        // 2.Exercise: Print Cash Document
        PrintCashDocument(CashDocHdr);

        // 3.Verify:
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_CashDocumentHeader', CashDocHdr."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_CashDocumentHeader', CashDocHdr."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountIncludingVAT_CashDocumentLine', CashDocLn."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPagePostedReceiptCashDocHandler')]
    [Scope('OnPrem')]
    procedure PrintingPostedReceiptCashDocument()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Check that correct Amounts are present on Receipt Cash Document Report after posting Receipt Cash Document.
        PrintingPostedCashDocument(CashDocHdr."Cash Document Type"::Receipt);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPagePostedWithdrawalCashDocHandler')]
    [Scope('OnPrem')]
    procedure PrintingPostedWithdrawalCashDocument()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Check that correct Amounts are present on Withdrawal Cash Document Report after posting Withdrawal Cash Document.
        PrintingPostedCashDocument(CashDocHdr."Cash Document Type"::Withdrawal);
    end;

    local procedure PrintingPostedCashDocument(CashDocType: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
    begin
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Receipt Cash Document
        CreateCashDocument(CashDocHdr, CashDocLn, CashDocType, BankAcc."No.");

        // Post Cash Document
        PostCashDocument(CashDocHdr);
        PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
        PostedCashDocHdr.FindFirst;

        // 2.Exercise: Print Posted Cash Document
        PrintPostedCashDocument(PostedCashDocHdr);

        // 3.Verify:
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_PostedCashDocumentHeader', PostedCashDocHdr."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_PostedCashDocumentHeader', PostedCashDocHdr."No."));
        case CashDocType of
            CashDocHdr."Cash Document Type"::Receipt:
                begin
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmount_GLEntry', CashDocLn.Amount);
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('CreditAmount_GLEntry', CashDocLn.Amount);
                end;
            CashDocHdr."Cash Document Type"::Withdrawal:
                begin
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('CreditAmount_GLEntry', CashDocLn.Amount);
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('DebitAmount_GLEntry', CashDocLn.Amount);
                end;
        end;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageCashDeskBookHandler')]
    [Scope('OnPrem')]
    procedure PrintingCashDeskBook()
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        CashDeskEvent: Record "Cash Desk Event";
    begin
        // Check that correct Amount is present on Receipt Cash Desk Book Report after posting Receipt Cash Document.
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Withdrawal Cash Document
        LibraryCashDesk.CreateCashDeskEvent(
          CashDeskEvent, BankAcc."No.", CashDocHdr."Cash Document Type"::Withdrawal,
          CashDeskEvent."Account Type"::"G/L Account", GetNewGLAccountNo(true));
        LibraryCashDesk.CreateCashDocumentHeader(CashDocHdr, CashDocHdr."Cash Document Type"::Withdrawal, BankAcc."No.");

        // Create Withdrawal Cash Document Line 1
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocLn, CashDocHdr, CashDeskEvent.Code, LibraryRandom.RandInt(Round(BankAcc."Cash Receipt Limit", 1, '<')));

        // Create Withdrawal Cash Document Line 2
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocLn, CashDocHdr, CashDeskEvent.Code, LibraryRandom.RandInt(Round(BankAcc."Cash Receipt Limit", 1, '<')));

        // Post Cash Document
        PostCashDocument(CashDocHdr);

        // Create Withdrawal Cash Document
        Clear(CashDocHdr);
        Clear(CashDocLn);
        CreateCashDocumentWithFixedAsset(CashDocHdr, CashDocLn, CashDocHdr."Cash Document Type"::Withdrawal, BankAcc."No.");

        // Post Cash Document
        PostCashDocument(CashDocHdr);

        // 2.Exercise:
        LibraryVariableStorage.Enqueue(BankAcc."No."); // Cash Desk No.
        LibraryVariableStorage.Enqueue(CalcDate('<-1d>', WorkDate)); // Starting Date
        LibraryVariableStorage.Enqueue(CalcDate('<1d>', WorkDate)); // Closing Date
        PrintCashDeskBook;

        // 3.Verify:
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Bank_Account_No', BankAcc."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Bank_Account_No', BankAcc."No."));

        PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
        PostedCashDocHdr.FindSet;
        PostedCashDocHdr.CalcFields("Amount Including VAT");

        LibraryReportDataset.AssertCurrentRowValueEquals('Variables_Payment', PostedCashDocHdr."Amount Including VAT");

        PostedCashDocHdr.Next;
        PostedCashDocHdr.CalcFields("Amount Including VAT");

        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Variables_Payment', PostedCashDocHdr."Amount Including VAT");
    end;

    local procedure CreateCashDesk(var BankAcc: Record "Bank Account")
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
        RoundingMethod: Record "Rounding Method";
        CashDeskUser: Record "Cash Desk User";
    begin
        CreateBankAccountPostingGroup(BankAccPostingGroup, GetNewGLAccountNo(false));
        CreateRoundingMethod(RoundingMethod);
        CreateCashDeskBase(BankAcc, BankAccPostingGroup.Code, RoundingMethod.Code);
        CreateCashDeskUser(CashDeskUser, BankAcc."No.");
    end;

    local procedure CreateCashDeskBase(var BankAcc: Record "Bank Account"; BankAccPostingGroupCode: Code[20]; RoundingMethodCode: Code[10])
    begin
        LibraryCashDesk.CreateCashDesk(BankAcc);
        BankAcc."Confirm Inserting of Document" := true;
        BankAcc."Bank Acc. Posting Group" := BankAccPostingGroupCode;
        BankAcc."Debit Rounding Account" := GetNewGLAccountNo(false);
        BankAcc."Credit Rounding Account" := GetNewGLAccountNo(false);
        BankAcc."Rounding Method Code" := RoundingMethodCode;
        BankAcc."Cash Receipt Limit" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Cash Withdrawal Limit" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Max. Balance" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Min. Balance" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Cash Document Receipt Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc."Cash Document Withdrawal Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc.Modify(true);
    end;

    local procedure CreateCashDeskEvent(var CashDeskEvent: Record "Cash Desk Event"; CashDeskNo: Code[20]; CashDocType: Option; AccountType: Option)
    var
        AccountNo: Code[20];
    begin
        case AccountType of
            CashDeskEvent."Account Type"::"G/L Account":
                AccountNo := GetNewGLAccountNo(false);
        end;

        LibraryCashDesk.CreateCashDeskEvent(CashDeskEvent, CashDeskNo, CashDocType, AccountType, AccountNo);
    end;

    local procedure CreateCashDeskUser(var CashDeskUser: Record "Cash Desk User"; CashDeskNo: Code[20])
    begin
        LibraryCashDesk.CreateCashDeskUser(CashDeskUser, CashDeskNo, true, true, true);
    end;

    local procedure CreateBankAccountPostingGroup(var BankAccPostingGroup: Record "Bank Account Posting Group"; GLAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccPostingGroup);
        BankAccPostingGroup."G/L Account No." := GLAccountNo;
        BankAccPostingGroup.Modify(true);
    end;

    local procedure CreateRoundingMethod(var RoundingMethod: Record "Rounding Method")
    begin
        LibraryCashDesk.CreateRoundingMethod(RoundingMethod);
        RoundingMethod."Minimum Amount" := 0;
        RoundingMethod."Amount Added Before" := 0;
        RoundingMethod.Type := RoundingMethod.Type::Nearest;
        RoundingMethod.Precision := 1;
        RoundingMethod."Amount Added After" := 0;
        RoundingMethod.Modify(true);
    end;

    local procedure CreateCashDocument(var CashDocHdr: Record "Cash Document Header"; var CashDocLn: Record "Cash Document Line"; CashDocType: Option; CashDeskNo: Code[20])
    var
        BankAcc: Record "Bank Account";
        CashDeskEvent: Record "Cash Desk Event";
    begin
        CreateCashDeskEvent(CashDeskEvent, CashDeskNo, CashDocType, CashDeskEvent."Account Type"::"G/L Account");
        BankAcc.Get(CashDeskNo);

        LibraryCashDesk.CreateCashDocumentHeader(CashDocHdr, CashDocType, CashDeskNo);
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocLn, CashDocHdr, CashDeskEvent.Code, LibraryRandom.RandInt(Round(BankAcc."Cash Receipt Limit", 1, '<')));
    end;

    local procedure CreateCashDocumentWithFixedAsset(var CashDocHdr: Record "Cash Document Header"; var CashDocLn: Record "Cash Document Line"; CashDocType: Option; CashDeskNo: Code[20])
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get(CashDeskNo);

        LibraryCashDesk.CreateCashDocumentHeader(CashDocHdr, CashDocType, CashDeskNo);
        LibraryCashDesk.CreateCashDocumentLine(
          CashDocLn, CashDocHdr, CashDocLn."Account Type"::"Fixed Asset",
          GetNewFixedAssetNo, LibraryRandom.RandInt(Round(BankAcc."Cash Receipt Limit", 1, '<')));
        CashDocLn.Validate("FA Posting Type", CashDocLn."FA Posting Type"::"Acquisition Cost");
        CashDocLn.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; WithVATPostingSetup: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
    begin
        if not WithVATPostingSetup then
            LibraryERM.CreateGLAccount(GLAccount)
        else begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
            GLAccount.Get(GLAccountNo);
        end;
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateDepreciationBook(DepreciationBook);
        CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Default FA Depreciation Book", true);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup."Acquisition Cost Account" := GetExistGLAccountNo;
        FAPostingGroup."Accum. Depreciation Account" := GetExistGLAccountNo;
        FAPostingGroup."Acq. Cost Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Accum. Depr. Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Gains Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Losses Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Maintenance Expense Account" := GetExistGLAccountNo;
        FAPostingGroup."Depreciation Expense Acc." := GetExistGLAccountNo;
        FAPostingGroup.Modify(true);
    end;

    local procedure CreateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.FindGLAccount(GLAccount);
    end;

    local procedure GetExistGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure GetNewGLAccountNo(WithVATPostingSetup: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount, WithVATPostingSetup);
        exit(GLAccount."No.");
    end;

    local procedure GetNewFixedAssetNo(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFixedAsset(FixedAsset);
        exit(FixedAsset."No.");
    end;

    local procedure PostCashDocument(var CashDocHdr: Record "Cash Document Header")
    begin
        LibraryCashDesk.PostCashDocument(CashDocHdr);
    end;

    local procedure PrintCashDocument(var CashDocHdr: Record "Cash Document Header")
    begin
        LibraryCashDesk.PrintCashDocument(CashDocHdr, true);
    end;

    local procedure PrintPostedCashDocument(var PostedCashDocHdr: Record "Posted Cash Document Header")
    begin
        LibraryCashDesk.PrintPostedCashDocument(PostedCashDocHdr, true);
    end;

    local procedure PrintCashDeskBook()
    begin
        LibraryCashDesk.PrintCashDeskBook(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageReceiptCashDocHandler(var ReceiptCashDocument: TestRequestPage "Receipt Cash Document")
    begin
        ReceiptCashDocument.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageWithdrawalCashDocHandler(var WithdrawalCashDocument: TestRequestPage "Withdrawal Cash Document")
    begin
        WithdrawalCashDocument.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPagePostedReceiptCashDocHandler(var PostedReceiptCashDoc: TestRequestPage "Posted Receipt Cash Doc.")
    begin
        PostedReceiptCashDoc.PrintAccountingSheet.SetValue(true);
        PostedReceiptCashDoc.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPagePostedWithdrawalCashDocHandler(var PostedWithdrawalCashDoc: TestRequestPage "Posted Withdrawal Cash Doc.")
    begin
        PostedWithdrawalCashDoc.PrintAccountingSheet.SetValue(true);
        PostedWithdrawalCashDoc.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageCashDeskBookHandler(var CashDeskBook: TestRequestPage "Cash Desk Book")
    var
        CashDeskNo: Variant;
        StartingDate: Variant;
        ClosingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashDeskNo);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(ClosingDate);
        CashDeskBook.CashDeskNo.SetValue(CashDeskNo);
        CashDeskBook.StartDate.SetValue(StartingDate);
        CashDeskBook.EndDate.SetValue(ClosingDate);
        CashDeskBook.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}


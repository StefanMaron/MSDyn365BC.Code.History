codeunit 145001 "Credits Reports"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryCredit: Codeunit "Library - Credit";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateCreditsSetup;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('RequestPageCreditHandler')]
    [Scope('OnPrem')]
    procedure PrintingCreditWithCustLedgEntries()
    begin
        PrintingCredit(0);
    end;

    [Test]
    [HandlerFunctions('RequestPageCreditHandler')]
    [Scope('OnPrem')]
    procedure PrintingCreditWithVendLedgEntries()
    begin
        PrintingCredit(1);
    end;

    local procedure PrintingCredit(SourceType: Option)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CreditHeader: Record "Credit Header";
        CreditLine1: Record "Credit Line";
        CreditLine2: Record "Credit Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // 1. Setup:
        Initialize;

        CreateCreditHeader(CreditHeader);

        case SourceType of
            CreditLine1."Source Type"::Customer:
                begin
                    FindCustomerLedgerEntryForInvoice(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                    FindCustomerLedgerEntryForCrMemo(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                end;
            CreditLine1."Source Type"::Vendor:
                begin
                    FindVendorLedgerEntryForInvoice(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                    FindVendorLedgerEntryForCrMemo(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                end;
        end;

        if Abs(CreditLine1."Amount (LCY)") > Abs(CreditLine2."Amount (LCY)") then
            LibraryCredit.UpdateCreditLine(CreditLine1, -CreditLine2."Amount (LCY)")
        else
            LibraryCredit.UpdateCreditLine(CreditLine2, -CreditLine1."Amount (LCY)");

        // 2. Exercise:

        PrintCredit(CreditHeader);

        // 3. Verify:

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Credit_Header_No_', CreditHeader."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Credit_Header_No_', CreditHeader."No."));

        case SourceType of
            CreditLine1."Source Type"::Customer:
                begin
                    LibraryReportDataset.AssertCurrentRowValueEquals('Credit_Line_Amount', CreditLine1.Amount);
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('Credit_Line_Amount', CreditLine2.Amount);
                end;
            CreditLine1."Source Type"::Vendor:
                begin
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('Amount', CreditLine2.Amount);
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('Amount', CreditLine1.Amount);
                end;
        end;

        // 4. Teardown

        CreditHeader.SetRecFilter;
        CreditHeader.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('RequestPagePostedCreditHandler')]
    [Scope('OnPrem')]
    procedure PrintingPostedCreditWithCustLedgEntries()
    begin
        PrintingPostedCredit(0);
    end;

    [Test]
    [HandlerFunctions('RequestPagePostedCreditHandler')]
    [Scope('OnPrem')]
    procedure PrintingPostedCreditWithVendLedgEntries()
    begin
        PrintingPostedCredit(1);
    end;

    local procedure PrintingPostedCredit(SourceType: Option)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CreditHeader: Record "Credit Header";
        CreditLine1: Record "Credit Line";
        CreditLine2: Record "Credit Line";
        PostedCreditHeader: Record "Posted Credit Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // 1. Setup:
        Initialize;

        CreateCreditHeader(CreditHeader);

        case SourceType of
            CreditLine1."Source Type"::Customer:
                begin
                    FindCustomerLedgerEntryForInvoice(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                    FindCustomerLedgerEntryForCrMemo(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                end;
            CreditLine1."Source Type"::Vendor:
                begin
                    FindVendorLedgerEntryForInvoice(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                    FindVendorLedgerEntryForCrMemo(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                end;
        end;

        if Abs(CreditLine1."Amount (LCY)") > Abs(CreditLine2."Amount (LCY)") then
            LibraryCredit.UpdateCreditLine(CreditLine1, -CreditLine2."Amount (LCY)")
        else
            LibraryCredit.UpdateCreditLine(CreditLine2, -CreditLine1."Amount (LCY)");

        PostCredit(CreditHeader);
        PostedCreditHeader.Get(CreditHeader."No.");

        // 2. Exercise:

        PrintPostedCredit(PostedCreditHeader);

        // 3. Verify:

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Posted_Credit_Header_No_', PostedCreditHeader."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Posted_Credit_Header_No_', PostedCreditHeader."No."));

        case SourceType of
            CreditLine1."Source Type"::Customer:
                begin
                    LibraryReportDataset.AssertCurrentRowValueEquals('Posted_Credit_Line_Amount', CreditLine1.Amount);
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('Posted_Credit_Line_Amount', CreditLine2.Amount);
                end;
            CreditLine1."Source Type"::Vendor:
                begin
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('Amount', CreditLine2.Amount);
                    LibraryReportDataset.GetNextRow;
                    LibraryReportDataset.AssertCurrentRowValueEquals('Amount', CreditLine1.Amount);
                end;
        end;

        // 4. Teardown

        PostedCreditHeader.SetRecFilter;
        PostedCreditHeader.DeleteAll(true);
    end;

    local procedure CreateCreditHeader(var CreditHeader: Record "Credit Header")
    begin
        LibraryCredit.CreateCreditHeader(CreditHeader, LibrarySales.CreateCustomerNo);
    end;

    local procedure CreateCreditLine(var CreditLine: Record "Credit Line"; CreditHeader: Record "Credit Header"; SourceType: Option; SourceEntryNo: Integer)
    begin
        LibraryCredit.CreateCreditLine(CreditLine, CreditHeader, SourceType, SourceEntryNo);
    end;

    local procedure FindCustomerLedgerEntryForInvoice(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        LibraryCredit.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice);
    end;

    local procedure FindCustomerLedgerEntryForCrMemo(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        LibraryCredit.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::"Credit Memo");
    end;

    local procedure FindVendorLedgerEntryForInvoice(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        LibraryCredit.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice);
    end;

    local procedure FindVendorLedgerEntryForCrMemo(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        LibraryCredit.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo");
    end;

    local procedure PostCredit(var CreditHeader: Record "Credit Header")
    begin
        LibraryCredit.RunPostCredit(CreditHeader);
    end;

    local procedure PrintCredit(var CreditHeader: Record "Credit Header")
    begin
        Commit();
        LibraryCredit.RunPrintCredit(CreditHeader, true);
    end;

    local procedure PrintPostedCredit(var PostedCreditHeader: Record "Posted Credit Header")
    begin
        Commit();
        LibraryCredit.RunPrintPostedCredit(PostedCreditHeader, true);
    end;

    local procedure UpdateCreditsSetup()
    var
        CreditsSetup: Record "Credits Setup";
    begin
        CreditsSetup.Get();
        CreditsSetup."Credit Nos." := LibraryERM.CreateNoSeriesCode;
        CreditsSetup."Credit Bal. Account No." := LibraryERM.CreateGLAccountNo;
        CreditsSetup."Credit Proposal By" := CreditsSetup."Credit Proposal By"::"Registration No.";
        CreditsSetup."Max. Rounding Amount" := 1;
        CreditsSetup."Debit Rounding Account" := LibraryERM.CreateGLAccountNo;
        CreditsSetup."Credit Rounding Account" := LibraryERM.CreateGLAccountNo;
        CreditsSetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageCreditHandler(var Credit: TestRequestPage Credit)
    begin
        Credit.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPagePostedCreditHandler(var PostedCredit: TestRequestPage "Posted Credit")
    begin
        PostedCredit.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}


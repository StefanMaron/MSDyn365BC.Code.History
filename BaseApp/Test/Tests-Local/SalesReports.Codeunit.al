#if not CLEAN17
codeunit 145010 "Sales Reports"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
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

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('RequestPageSalesCrMemoHandler')]
    [Scope('OnPrem')]
    procedure PrintingInternalCorrectionDocument()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::"Credit Memo");
        SalesHdr.Validate("Credit Memo Type", SalesHdr."Credit Memo Type"::"Internal Correction");
        SalesHdr.Modify();

        PostedDocumentNo := PostSalesDocument(SalesHdr);

        // 2. Exercise
        PrintCreditMemo(PostedDocumentNo);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesCrMemoHeader', PostedDocumentNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_SalesCrMemoHeader', PostedDocumentNo));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'CreditMemoType_SalesCrMemoHeader', Format(SalesHdr."Credit Memo Type"::"Internal Correction", 0, '<Number>'));
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option)
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLn, SalesHdr, SalesLn.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandDec(10000, 2));
        SalesLn.Validate(Description, SalesHdr."No.");
        SalesLn.Modify(true);
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;

    local procedure PrintCreditMemo(DocumentNo: Code[20])
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHdr.Get(DocumentNo);
        SalesCrMemoHdr.SetRecFilter;
        REPORT.Run(REPORT::"Sales - Credit Memo CZ", true, false, SalesCrMemoHdr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageSalesCrMemoHandler(var SalesCreditMemoCZ: TestRequestPage "Sales - Credit Memo CZ")
    begin
        SalesCreditMemoCZ.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

#endif
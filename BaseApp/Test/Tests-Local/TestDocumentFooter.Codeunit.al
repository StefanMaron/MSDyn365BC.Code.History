#if not CLEAN17
codeunit 145003 "Test Document Footer"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.

        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('RequestPageSalesInvoiceHandler')]
    [Scope('OnPrem')]
    procedure TestDocumentFooterSalesInvoice()
    var
        DocumentFooter: Record "Document Footer";
        SalesHdr: Record "Sales Header";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesLn: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CreateDocumentFooter(DocumentFooter, 'CSY');
        CreateSalesInvoice(SalesHdr, SalesLn);

        PostedDocNo := PostSalesDocument(SalesHdr);

        SalesInvHdr.Get(PostedDocNo);

        // 2. Exercise
        REPORT.Run(REPORT::"Sales - Invoice CZ", true, false, SalesInvHdr);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesInvoiceHeader', SalesInvHdr."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_SalesInvoiceHeader', SalesInvHdr."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocFooterText', DocumentFooter."Footer Text");
    end;

    [Test]
    [HandlerFunctions('RequestPageSalesCrMemoHandler')]
    [Scope('OnPrem')]
    procedure TestDocumentFooterSalesCrMemo()
    var
        DocumentFooter: Record "Document Footer";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CreateDocumentFooter(DocumentFooter, 'CSY');
        CreateSalesCrMemo(SalesHdr, SalesLn);

        PostedDocNo := PostSalesDocument(SalesHdr);

        SalesCrMemoHdr.Get(PostedDocNo);

        // 2. Exercise
        REPORT.Run(REPORT::"Sales - Credit Memo CZ", true, false, SalesCrMemoHdr);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesCrMemoHeader', SalesCrMemoHdr."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_SalesCrMemoHeader', SalesCrMemoHdr."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocFooterText', DocumentFooter."Footer Text");
    end;

    [Test]
    [HandlerFunctions('RequestPageSalesQuoteHandler')]
    [Scope('OnPrem')]
    procedure TestDocumentFooterSalesQuote()
    var
        DocumentFooter: Record "Document Footer";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
    begin
        // 1. Setup
        Initialize;

        CreateDocumentFooter(DocumentFooter, 'CSY');
        CreateSalesQuote(SalesHdr, SalesLn);

        // 2. Exercise
        Commit();
        REPORT.Run(REPORT::"Sales - Quote CZ", true, false, SalesHdr);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesHeader', SalesHdr."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_SalesHeader', SalesHdr."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocFooterText', DocumentFooter."Footer Text");
    end;

    local procedure CreateDocumentFooter(var DocumentFooter: Record "Document Footer"; LanguageCode: Code[10])
    begin
        if DocumentFooter.Get(LanguageCode) then
            exit;

        DocumentFooter.Init();
        DocumentFooter."Language Code" := LanguageCode;
        DocumentFooter."Footer Text" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DocumentFooter."Footer Text")),
            1, MaxStrLen(DocumentFooter."Footer Text"));
        DocumentFooter.Insert(true);
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; LineType: Option; LineNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, CustomerNo);
        SalesHdr."Language Code" := 'CSY';
        SalesHdr.Modify(true);

        LibrarySales.CreateSalesLine(SalesLn, SalesHdr, LineType, LineNo, 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLn.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    begin
        CreateSalesDocument(
          SalesHdr, SalesLn, SalesHdr."Document Type"::Invoice, LibrarySales.CreateCustomerNo,
          SalesLn.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup);
    end;

    local procedure CreateSalesCrMemo(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    begin
        CreateSalesDocument(
          SalesHdr, SalesLn, SalesHdr."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo,
          SalesLn.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup);
    end;

    local procedure CreateSalesQuote(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    begin
        CreateSalesDocument(
          SalesHdr, SalesLn, SalesHdr."Document Type"::Quote, LibrarySales.CreateCustomerNo,
          SalesLn.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup);
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageSalesInvoiceHandler(var SalesInvoiceCZ: TestRequestPage "Sales - Invoice CZ")
    begin
        SalesInvoiceCZ.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageSalesCrMemoHandler(var SalesCreditMemoCZ: TestRequestPage "Sales - Credit Memo CZ")
    begin
        SalesCreditMemoCZ.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageSalesQuoteHandler(var SalesQuoteCZ: TestRequestPage "Sales - Quote CZ")
    begin
        SalesQuoteCZ.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

#endif
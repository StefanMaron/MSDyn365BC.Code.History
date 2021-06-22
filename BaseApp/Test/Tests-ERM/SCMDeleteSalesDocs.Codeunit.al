codeunit 137208 "SCM Delete Sales Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Print Documents] [Sales]
        isInitialized := false;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        FilePath: Text[1024];

    [Normal]
    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Delete Sales Docs");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Delete Sales Docs");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        CompanyInformation.Get;
        CompanyInformation."Bank Account No." := 'A';
        CompanyInformation.Modify;
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Delete Sales Docs");
    end;

    [Test]
    [HandlerFunctions('SalesShipReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedShipment()
    begin
        DeletePostedDoc(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('SalesInvReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedInvoice()
    begin
        DeletePostedDoc(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('RetRcptReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedRetReceipt()
    begin
        DeletePostedDoc(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('CrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedCrMemo()
    begin
        DeletePostedDoc(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Normal]
    local procedure DeletePostedDoc(DocumentType: Option)
    begin
        // Setup: Create Sales Document and Post.
        Initialize;
        CreateSalesDocument(SalesHeader, DocumentType);
        LibrarySales.SetAllowDocumentDeletionBeforeDate(SalesHeader."Posting Date" + 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Re-print and delete the posted document.
        FilePath := TemporaryPath + SalesHeader."No." + '.pdf';
        PrintDocument(SalesHeader);

        // Verify: No document lines remain in the database.
        VerifyLinesAreDeleted(SalesHeader, DocumentType);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        Counter: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");

        // Create a sales document with 2 lines.
        for Counter := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        end;
    end;

    [Normal]
    local procedure PrintDocument(SalesHeader: Record "Sales Header")
    var
        NoPrinted: Integer;
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                begin
                    SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
                    SalesShipmentHeader.FindFirst;
                    NoPrinted := SalesShipmentHeader."No. Printed";
                    SalesShipmentHeader.PrintRecords(false);
                    SalesShipmentHeader.Get(SalesShipmentHeader."No.");
                    NoPrinted := SalesShipmentHeader."No. Printed" - NoPrinted;
                    SalesShipmentHeader.Delete(true);
                end;
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
                    SalesInvoiceHeader.FindFirst;
                    NoPrinted := SalesInvoiceHeader."No. Printed";
                    SalesInvoiceHeader.PrintRecords(false);
                    SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
                    NoPrinted := SalesInvoiceHeader."No. Printed" - NoPrinted;
                    SalesInvoiceHeader.Delete(true);
                end;
            SalesHeader."Document Type"::"Return Order":
                begin
                    ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
                    ReturnReceiptHeader.FindFirst;
                    NoPrinted := ReturnReceiptHeader."No. Printed";
                    ReturnReceiptHeader.PrintRecords(false);
                    ReturnReceiptHeader.Get(ReturnReceiptHeader."No.");
                    NoPrinted := ReturnReceiptHeader."No. Printed" - NoPrinted;
                    ReturnReceiptHeader.Delete(true);
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
                    SalesCrMemoHeader.FindFirst;
                    NoPrinted := SalesCrMemoHeader."No. Printed";
                    SalesCrMemoHeader.PrintRecords(false);
                    SalesCrMemoHeader.Get(SalesCrMemoHeader."No.");
                    NoPrinted := SalesCrMemoHeader."No. Printed" - NoPrinted;
                    SalesCrMemoHeader.Delete(true);
                end;
        end;
        Assert.AreEqual(1, NoPrinted, 'No. printed was not incremented for ' + SalesHeader."No.");
    end;

    [Normal]
    local procedure VerifyLinesAreDeleted(SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // Verify there are no related document lines remaining in the database for the given doc. no.
        case DocumentType of
            SalesHeader."Document Type"::Order:
                begin
                    SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
                    Assert.IsTrue(SalesShipmentLine.IsEmpty, 'Not all shipment lines were deleted.');
                end;
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesInvoiceLine.SetRange("Document No.", SalesHeader."No.");
                    Assert.IsTrue(SalesInvoiceLine.IsEmpty, 'Not all invoice lines were deleted.');
                end;
            SalesHeader."Document Type"::"Return Order":
                begin
                    ReturnReceiptLine.SetRange("Return Order No.", SalesHeader."No.");
                    Assert.IsTrue(ReturnReceiptLine.IsEmpty, 'Not all receipt lines were deleted.');
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoLine.SetRange("Document No.", SalesHeader."No.");
                    Assert.IsTrue(SalesCrMemoLine.IsEmpty, 'Not all cr. memo lines were deleted.');
                end;
        end;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesShipReportHandler(var SalesShipment: Report "Sales - Shipment")
    begin
        SalesShipment.SetTableView(SalesShipmentHeader);
        SalesShipment.SaveAsPdf(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure RetRcptReportHandler(var SalesReturnReceipt: Report "Sales - Return Receipt")
    begin
        SalesReturnReceipt.SetTableView(ReturnReceiptHeader);
        SalesReturnReceipt.SaveAsPdf(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesInvReportHandler(var StandardSalesInvoice: Report "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SetTableView(SalesInvoiceHeader);
        StandardSalesInvoice.SaveAsPdf(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure CrMemoReportHandler(var StandardSalesCreditMemo: Report "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemo.SetTableView(SalesCrMemoHeader);
        StandardSalesCreditMemo.SaveAsPdf(FilePath);
    end;
}


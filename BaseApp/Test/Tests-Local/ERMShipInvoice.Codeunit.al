codeunit 144062 "ERM Ship Invoice"
{
    // 1. Test to Verify Sales - Invoice report after Post Sales Invoice Header using Get Shipment Line.
    // 
    // Covers Test Cases for WI - 343619
    // --------------------------------------------------------------------------------
    // Test Function Name                                                        TFS ID
    // --------------------------------------------------------------------------------
    // SalesInvoiceIncludeShipmentNo                                      152602,152143

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ShipmentNoCap: Label 'Shipment No. %1:';

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler,SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceIncludeShipmentNo()
    var
        Customer: Record Customer;
        PostedShipmentNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // Test to Verify Sales - Invoice report after Post Sales Invoice Header using Get Shipment Line.

        // Setup: Create Customer, create and post Sales Order, create Sales Invoice and Get Shipment Line.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        PostedShipmentNo := CreateAndShipSalesOrder(Customer."No.");
        LibraryVariableStorage.Enqueue(PostedShipmentNo);  // Enqueue for GetShipmentLinesPageHandler.
        PostedInvoiceNo := CreateAndPostSalesInvoiceUsingGetShipmentLine(Customer."No.");

        // Exercise.
        RunSalesInvoiceReport(PostedInvoiceNo);

        // Verify: Verify values of No1_SalesInvHdr and Desc_SalesInvLine on report Sales - Invoice.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('No1_SalesInvHdr', PostedInvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists('Desc_SalesInvLine', StrSubstNo(ShipmentNoCap, PostedShipmentNo));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateAndShipSalesOrder(CustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Take random Unit Price.
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post as Ship.
    end;

    local procedure CreateAndPostSalesInvoiceUsingGetShipmentLine(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));  // Post as Invoice.
    end;

    local procedure RunSalesInvoiceReport(No: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: Report "Sales - Invoice";
    begin
        Clear(SalesInvoice);
        SalesInvoiceHeader.SetRange("No.", No);
        SalesInvoice.SetTableView(SalesInvoiceHeader);
        SalesInvoice.Run;  // Open SalesInvoiceRequestPageHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        GetShipmentLines.FILTER.SetFilter("Document No.", DocumentNo);
        GetShipmentLines.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoice.IncludeShipmentNo.SetValue(true);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}


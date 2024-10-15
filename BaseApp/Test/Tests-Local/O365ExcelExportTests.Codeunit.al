codeunit 138915 "O365 Excel Export Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing]
    end;

    var
        ExcelBuffer: Record "Excel Buffer";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        O365ExportInvoicesEmail: Codeunit "O365 Export Invoices + Email";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        GSTAmountTxt: Label 'GST Amount';
        PSTAmountTxt: Label 'PST Amount';
        HSTAmountTxt: Label 'HST Amount';
        TaxableCodeTxt: Label 'TAXABLE';
        InvoiceNotFoundTxt: Label 'Invoice No %1 does not exist in the file.';

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyGSTExportedAlberta()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServerFileName: Text;
        GSTColumnNo: Integer;
        PSTColumnNo: Integer;
        HSTColumnNo: Integer;
        InvoiceRowNo: Integer;
    begin
        Initialize();

        CreateAndPostNewInvoice(SalesInvoiceHeader, 'AB', 1000);

        ServerFileName := O365ExportInvoicesEmail.ExportInvoicesToExcel(WorkDate(), WorkDate());

        LibraryReportValidation.OpenBookAsExcel(ServerFileName);

        ExcelBuffer.SetRange("Cell Value as Text", GSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'GST column not found');
        GSTColumnNo := ExcelBuffer."Column No.";

        ExcelBuffer.SetRange("Cell Value as Text", SalesInvoiceHeader."No.");
        Assert.IsTrue(ExcelBuffer.FindFirst, StrSubstNo(InvoiceNotFoundTxt, SalesInvoiceHeader."No."));
        InvoiceRowNo := ExcelBuffer."Row No.";

        ExcelBuffer.Get(InvoiceRowNo, GSTColumnNo);
        Assert.AreEqual(Format(50), ExcelBuffer."Cell Value as Text", 'GST amount does not match.');

        ExcelBuffer.SetRange("Cell Value as Text", PSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'PST column not found');
        PSTColumnNo := ExcelBuffer."Column No.";

        Assert.IsFalse(ExcelBuffer.Get(InvoiceRowNo, PSTColumnNo), 'PST amount exists in the file');

        ExcelBuffer.SetRange("Cell Value as Text", HSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'HST column not found');
        HSTColumnNo := ExcelBuffer."Column No.";

        Assert.IsFalse(ExcelBuffer.Get(InvoiceRowNo, HSTColumnNo), 'HST amount exists in the file');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyHSTExportedOntario()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServerFileName: Text;
        GSTColumnNo: Integer;
        PSTColumnNo: Integer;
        HSTColumnNo: Integer;
        InvoiceRowNo: Integer;
    begin
        Initialize();

        CreateAndPostNewInvoice(SalesInvoiceHeader, 'ON', 1000);

        ServerFileName := O365ExportInvoicesEmail.ExportInvoicesToExcel(WorkDate(), WorkDate());

        LibraryReportValidation.OpenBookAsExcel(ServerFileName);

        ExcelBuffer.SetRange("Cell Value as Text", HSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'HST column not found');
        HSTColumnNo := ExcelBuffer."Column No.";

        ExcelBuffer.SetRange("Cell Value as Text", SalesInvoiceHeader."No.");
        Assert.IsTrue(ExcelBuffer.FindFirst, StrSubstNo(InvoiceNotFoundTxt, SalesInvoiceHeader."No."));
        InvoiceRowNo := ExcelBuffer."Row No.";

        ExcelBuffer.Get(InvoiceRowNo, HSTColumnNo);
        Assert.AreEqual(Format(130), ExcelBuffer."Cell Value as Text", 'HST amount does not match.');

        ExcelBuffer.SetRange("Cell Value as Text", PSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'PST column not found');
        PSTColumnNo := ExcelBuffer."Column No.";

        Assert.IsFalse(ExcelBuffer.Get(InvoiceRowNo, PSTColumnNo), 'PST amount exists in the file');

        ExcelBuffer.SetRange("Cell Value as Text", GSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'GST column not found');
        GSTColumnNo := ExcelBuffer."Column No.";

        Assert.IsFalse(ExcelBuffer.Get(InvoiceRowNo, GSTColumnNo), 'GST amount exists in the file');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGSTAndPSTExportedManitoba()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServerFileName: Text;
        GSTColumnNo: Integer;
        PSTColumnNo: Integer;
        HSTColumnNo: Integer;
        InvoiceRowNo: Integer;
    begin
        Initialize();

        CreateAndPostNewInvoice(SalesInvoiceHeader, 'MB', 1000);

        ServerFileName := O365ExportInvoicesEmail.ExportInvoicesToExcel(WorkDate(), WorkDate());

        LibraryReportValidation.OpenBookAsExcel(ServerFileName);

        ExcelBuffer.SetRange("Cell Value as Text", GSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'GST column not found');
        GSTColumnNo := ExcelBuffer."Column No.";

        ExcelBuffer.SetRange("Cell Value as Text", SalesInvoiceHeader."No.");
        Assert.IsTrue(ExcelBuffer.FindFirst, StrSubstNo(InvoiceNotFoundTxt, SalesInvoiceHeader."No."));
        InvoiceRowNo := ExcelBuffer."Row No.";

        ExcelBuffer.Get(InvoiceRowNo, GSTColumnNo);
        Assert.AreEqual(Format(50), ExcelBuffer."Cell Value as Text", 'GST amount does not match.');

        ExcelBuffer.SetRange("Cell Value as Text", PSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'PST column not found');
        PSTColumnNo := ExcelBuffer."Column No.";

        ExcelBuffer.Get(InvoiceRowNo, PSTColumnNo);
        Assert.AreEqual(Format(80), ExcelBuffer."Cell Value as Text", 'PST amount does not match.');

        ExcelBuffer.SetRange("Cell Value as Text", HSTAmountTxt);
        Assert.IsTrue(ExcelBuffer.FindFirst, 'HST column not found');
        HSTColumnNo := ExcelBuffer."Column No.";

        Assert.IsFalse(ExcelBuffer.Get(InvoiceRowNo, HSTColumnNo), 'HST amount exists in the file');
    end;

    local procedure Initialize()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Item: Record Item;
        Customer: Record Customer;
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        LibraryVariableStorage.Clear();
        SalesInvoiceHeader.DeleteAll();
        Item.DeleteAll();
        Customer.DeleteAll();

        if not O365C2GraphEventSettings.Get() then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();
    end;

    local procedure CreateCustomerWithTaxAreaCode(var Customer: Record Customer; CustomersTaxAreaCode: Code[20])
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", CustomersTaxAreaCode);
        Customer."Tax Liable" := true;
        Customer.Modify();
    end;

    local procedure CreateTaxableItem(var Item: Record Item; ItemUnitPrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item.Validate("Tax Group Code", TaxableCodeTxt);
        Item.Validate("Unit Price", ItemUnitPrice);
        Item.Modify();
    end;

    local procedure CreateAndPostNewInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustomersTaxAreaCode: Code[20]; ItemUnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateCustomerWithTaxAreaCode(Customer, CustomersTaxAreaCode);
        CreateTaxableItem(Item, ItemUnitPrice);

        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        LibrarySmallBusiness.PostSalesInvoice(SalesHeader);
        SalesInvoiceHeader.FindFirst();
    end;
}


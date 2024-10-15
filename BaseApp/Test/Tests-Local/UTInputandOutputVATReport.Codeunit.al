codeunit 141073 "UT Input and Output VAT Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AddressCap: Label 'Address';
        BaseAmtGoodsCap: Label 'BaseAmtgoods';
        BaseAmtServicesCap: Label 'BaseAmtServices';
        BillToPayToNoCap: Label 'VAT_Entry__Bill_to_Pay_to_No__';
        TINCap: Label 'TIN';
        VATGoodsCap: Label 'VATGoods';
        VATServicesCap: Label 'VATServices';

    [Test]
    [HandlerFunctions('VATReportCustomerRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryCrMemoVATReportCustomer()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28028 VAT Report - Customer with Document Type as Credit Memo.
        VATReportCustomerWithDocumentType(VATGoodsCap, BaseAmtGoodsCap, VATEntry."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('VATReportCustomerRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryInvoiceVATReportCustomer()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28028 VAT Report - Customer with Document Type as Invoice.
        VATReportCustomerWithDocumentType(VATGoodsCap, BaseAmtGoodsCap, VATEntry."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('VATReportCustomerRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryPaymentVATReportCustomer()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28028 VAT Report - Customer with Document Type as Payment.
        VATReportCustomerWithDocumentType(VATServicesCap, BaseAmtServicesCap, VATEntry."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('VATReportCustomerRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryRefundVATReportCustomer()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28028 VAT Report - Customer with Document Type as Refund.
        VATReportCustomerWithDocumentType(VATServicesCap, BaseAmtServicesCap, VATEntry."Document Type"::Refund);
    end;

    local procedure VATReportCustomerWithDocumentType(AmountCaption: Text[20]; BaseCaption: Text[20]; DocumentType: Option)
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
    begin
        // Setup.
        Initialize;
        CreateCustomer(Customer);
        CreateVATEntry(VATEntry, Customer."No.", DocumentType, VATEntry.Type::Sale);
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue value for VATReportCustomerRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Report - Customer");

        // Verify.
        VerifyXMLValuesOnVATReport(VATEntry, Customer.Address, Customer."VAT Registration No.", AmountCaption, BaseCaption);
    end;

    [Test]
    [HandlerFunctions('VATReportVendorRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryCreditMemoVATReportVendor()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28027 VAT Report - Vendor with Document Type as Credit Memo.
        VATReportVendorWithDocumentType(VATGoodsCap, BaseAmtGoodsCap, VATEntry."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('VATReportVendorRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryInvoiceVATReportVendor()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28027 VAT Report - Vendor with Document Type as Invoice.
        VATReportVendorWithDocumentType(VATGoodsCap, BaseAmtGoodsCap, VATEntry."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('VATReportVendorRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryPaymentVATReportVendor()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28027 VAT Report - Vendor with Document Type as Payment.
        VATReportVendorWithDocumentType(VATServicesCap, BaseAmtServicesCap, VATEntry."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('VATReportVendorRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryRefundVATReportVendor()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate VAT Entry - OnAfterGetRecord Trigger of Report - 28027 VAT Report - Vendor with Document Type as Refund.
        VATReportVendorWithDocumentType(VATServicesCap, BaseAmtServicesCap, VATEntry."Document Type"::Refund);
    end;

    local procedure VATReportVendorWithDocumentType(AmountCaption: Text[20]; BaseCaption: Text[20]; DocumentType: Option)
    var
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
    begin
        // Setup.
        Initialize;
        CreateVendor(Vendor);
        CreateVATEntry(VATEntry, Vendor."No.", DocumentType, VATEntry.Type::Purchase);
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for VATReportVendorRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Report - Vendor");

        // Verify.
        VerifyXMLValuesOnVATReport(VATEntry, Vendor.Address, Vendor."VAT Registration No.", AmountCaption, BaseCaption);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer.Address := LibraryUTUtility.GetNewCode;
        Customer."VAT Registration No." := LibraryUTUtility.GetNewCode;
        Customer.Insert();
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; BillToPayToNo: Code[20]; DocumentType: Option; Type: Option)
    begin
        VATEntry.Type := Type;
        VATEntry."Document Type" := DocumentType;
        VATEntry."Bill-to/Pay-to No." := BillToPayToNo;
        VATEntry.Base := LibraryRandom.RandDec(100, 2);
        VATEntry.Amount := VATEntry.Base;
        VATEntry.Insert();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor.Address := LibraryUTUtility.GetNewCode;
        Vendor."VAT Registration No." := LibraryUTUtility.GetNewCode;
        Vendor.Insert();
    end;

    local procedure VerifyXMLValuesOnVATReport(VATEntry: Record "VAT Entry"; Address: Code[20]; VATRegistrationNo: Code[20]; AmountCaption: Text[20]; BaseCaption: Text[20])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(BillToPayToNoCap, VATEntry."Bill-to/Pay-to No.");
        LibraryReportDataset.AssertElementWithValueExists(TINCap, VATRegistrationNo);
        LibraryReportDataset.AssertElementWithValueExists(AddressCap, Address);
        LibraryReportDataset.AssertElementWithValueExists(BaseCaption, VATEntry.Base);
        LibraryReportDataset.AssertElementWithValueExists(AmountCaption, VATEntry.Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATReportCustomerRequestPageHandler(var VATReportCustomer: TestRequestPage "VAT Report - Customer")
    var
        BillToPayToNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BillToPayToNo);
        VATReportCustomer."VAT Entry".SetFilter("Bill-to/Pay-to No.", BillToPayToNo);
        VATReportCustomer.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATReportVendorRequestPageHandler(var VATReportVendor: TestRequestPage "VAT Report - Vendor")
    var
        BillToPayToNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BillToPayToNo);
        VATReportVendor."VAT Entry".SetFilter("Bill-to/Pay-to No.", BillToPayToNo);
        VATReportVendor.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}


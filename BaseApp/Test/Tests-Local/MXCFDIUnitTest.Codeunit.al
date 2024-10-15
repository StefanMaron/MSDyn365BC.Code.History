codeunit 144000 "MX CFDI Unit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CFDI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        PACCodeDeleteError: Label 'You cannot delete the code %1 because it is used in the %2 window.';
        PACWebServiceDetailError: Label 'PAC Web Service Details count is incorrect.';
        EDocAction: Option "Request Stamp",Send,Cancel;
        EDocStatus: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error";
        EDocStatusError: Label 'You cannot choose the action %1 when the document status is %2.';
        ExpectedError: Label 'Error message was different than expected.';
        NoRelationDocumentsExistErr: Label 'No relation documents specified for the replacement of previous CFDIs.';

    [Test]
    [Scope('OnPrem')]
    procedure DeletePACServiceSelectedInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check that error comes when the PAC code setup is deleted defined on General Ledger Setup.

        // Setup : Create new PAC Setup with unique PAC Code and update that in General Ledger Setup.
        Initialize;
        CreatePACSetup(PACWebService);
        UpdateGLSetupPACCode(GeneralLedgerSetup, PACWebService.Code, true);

        // Exercise : Delete the new PAC code setup created.
        asserterror PACWebService.Delete(true);

        // Verify : Error comes when PAC code on GL Setup is deleted.
        if StrPos(GetLastErrorText, StrSubstNo(PACCodeDeleteError, PACWebService.Code, GeneralLedgerSetup.TableCaption)) = 0 then
            Error(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePACServiceNotInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: array[2] of Record "PAC Web Service";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if value on General Ledger Setup is updated with new PAC code created after deletion of other PAC code.

        // Setup : Create 2 new PAC Setups with unique PAC Code and update General Ledger Setup with 2nd new PAC code.
        Initialize;
        CreatePACSetup(PACWebService[1]);
        CreatePACSetup(PACWebService[2]);
        UpdateGLSetupPACCode(GeneralLedgerSetup, PACWebService[2].Code, true);

        // Exercise : Delete the 1st PAC code created.
        PACWebService[1].Delete(true);

        // Verify : value on General Ledger Setup is equal to 2nd new PAC code created
        GeneralLedgerSetup.TestField("PAC Code", PACWebService[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePACSubTables()
    var
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        PACCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check PAC Web Service details is deleted on deletion of related PAC code.

        // Setup : Create new PAC Setup with unique PAC Code
        Initialize;
        CreatePACSetup(PACWebService);
        PACCode := PACWebService.Code;
        CreateMultiplePACDetails(PACWebService.Code);

        // Exercise : Delete the PAC Setup created.
        PACWebService.Delete(true);

        // Verify : Check that PAC Web Service details is deleted.
        PACWebServiceDetail.SetRange("PAC Code", PACCode);
        Assert.IsTrue(PACWebServiceDetail.IsEmpty, PACWebServiceDetailError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenamePACServiceSelectedInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check GL setup is renamed when the PAC code attached is renamed.

        // Setup : Create new PAC Setup with unique PAC Code
        Initialize;
        CreatePACSetup(PACWebService);
        UpdateGLSetupPACCode(GeneralLedgerSetup, PACWebService.Code, true);

        // Exercise : Rename the PAC Setup created with random value.
        PACWebService.Rename(LibraryUtility.GenerateRandomCode(PACWebService.FieldNo(Code), DATABASE::"PAC Web Service"));

        // Verify : General Ledger Setup is renamed with new PAC code.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("PAC Code", PACWebService.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenamePACSubTables()
    var
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        PACWebServiceDetailCount: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check PAC Web Service details is renamed on renaming of related PAC code.

        // Setup : Create new PAC Setup with unique PAC Code
        Initialize;
        CreatePACSetup(PACWebService);
        CreateMultiplePACDetails(PACWebService.Code);

        // Exercise : Rename the PAC Setup created.
        PACWebServiceDetail.SetRange("PAC Code", PACWebService.Code);
        PACWebServiceDetailCount := PACWebServiceDetail.Count();
        PACWebService.Rename(LibraryUtility.GenerateRandomCode(PACWebService.FieldNo(Code), DATABASE::"PAC Web Service"));

        // Verify : PAC Web Service details is renamed
        PACWebServiceDetail.SetRange("PAC Code", PACWebService.Code);
        Assert.AreEqual(PACWebServiceDetailCount, PACWebServiceDetail.Count, PACWebServiceDetailError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePACInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if value of Environment code on General Ledger Setup is updated to Disabled when the PAC code is made balnk.

        // Setup : Create new PAC Setup with unique PAC Code
        Initialize;
        CreatePACSetup(PACWebService);

        // Exercise : Update General Ledger Setup with new PAC code and set Environment code to Test,then make PAC code blank on GL Setup.
        UpdateGLSetupPACCode(GeneralLedgerSetup, PACWebService.Code, false);
        GeneralLedgerSetup.Validate("PAC Environment", GeneralLedgerSetup."PAC Environment"::Test);
        UpdateGLSetupPACCode(GeneralLedgerSetup, '', false);

        // Verify : Value of Environment code on General Ledger Setup is updated to Disabled
        GeneralLedgerSetup.TestField("PAC Environment", GeneralLedgerSetup."PAC Environment"::Disabled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestStampStampReceived()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Stamp Received and EDocAction = Request Stamp

        TestEInvoiceMgmtforEdocStatus(EDocAction::"Request Stamp", EDocStatus::"Stamp Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestStampSent()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Sent and EDocAction = Request Stamp

        TestEInvoiceMgmtforEdocStatus(EDocAction::"Request Stamp", EDocStatus::Sent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestStampCancelError()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Cancel Error and EDocAction = Request Stamp

        TestEInvoiceMgmtforEdocStatus(EDocAction::"Request Stamp", EDocStatus::"Cancel Error");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendBlank()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = '' and EDocAction = Send

        TestEInvoiceMgmtforEdocStatus(EDocAction::Send, EDocStatus::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendCanceled()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Canceled Received and EDocAction = Send

        TestEInvoiceMgmtforEdocStatus(EDocAction::Send, EDocStatus::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendStampRequestError()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Stamp Request Error Received and EDocAction = Send

        TestEInvoiceMgmtforEdocStatus(EDocAction::Send, EDocStatus::"Stamp Request Error");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendCancelError()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Cancel Error  and EDocAction = Send

        TestEInvoiceMgmtforEdocStatus(EDocAction::Send, EDocStatus::"Cancel Error");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestStampCanceled()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Canceled and EDocAction = Request Stamp

        TestEInvoiceMgmtforEdocStatus(EDocAction::"Request Stamp", EDocStatus::Canceled);
    end;

    local procedure TestEInvoiceMgmtforEdocStatus("Action": Option "Request Stamp",Send,Cancel; Status: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error")
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // Setup
        Initialize;

        // Exercise
        asserterror EInvoiceMgt.EDocActionValidation(Action, Status);

        // Verify
        if StrPos(GetLastErrorText, StrSubstNo(EDocStatusError, Action, Status)) = 0 then
            Error(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestStampBlank()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = '' and EDocAction = Request Stamp

        EInvoiceMgt.EDocActionValidation(EDocAction::"Request Stamp", EDocStatus::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestStampRequestStampError()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Stamp Request Error and EDocAction = Request Stamp

        EInvoiceMgt.EDocActionValidation(EDocAction::"Request Stamp", EDocStatus::"Stamp Request Error");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendStampReveiced()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Stamp Received and EDocAction = Send

        EInvoiceMgt.EDocActionValidation(EDocAction::Send, EDocStatus::"Stamp Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendSent()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Sent and EDocAction = Send

        EInvoiceMgt.EDocActionValidation(EDocAction::Send, EDocStatus::Sent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelBlank()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = '' and EDocAction = Cancel

        TestEInvoiceMgmtforEdocStatus(EDocAction::Cancel, EDocStatus::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCanceled()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Canceled and EDocAction = Cancel

        TestEInvoiceMgmtforEdocStatus(EDocAction::Cancel, EDocStatus::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelStampRequestError()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Stamp Request Error and EDocAction = Cancel

        TestEInvoiceMgmtforEdocStatus(EDocAction::Cancel, EDocStatus::"Stamp Request Error");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelStampReceived()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Stamp Received and EDocAction = Cancel

        EInvoiceMgt.EDocActionValidation(EDocAction::Cancel, EDocStatus::"Stamp Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelSent()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Sent and EDocAction = Cancel

        EInvoiceMgt.EDocActionValidation(EDocAction::Cancel, EDocStatus::Sent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCancelError()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Check if error comes when EdocStatus = Cancel Error and EDocAction = Cancel

        EInvoiceMgt.EDocActionValidation(EDocAction::Cancel, EDocStatus::"Cancel Error");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintCFDIDisabled()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        UpdateGLSetupPACEnvironment(false);
        EInvoiceMgt.EDocPrintValidation(EDocStatus::" ", LibraryUtility.GenerateGUID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintBlank()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        UpdateGLSetupPACEnvironment(true);
        EInvoiceMgt.EDocPrintValidation(EDocStatus::" ", LibraryUtility.GenerateGUID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintStampReceived()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        UpdateGLSetupPACEnvironment(true);
        EInvoiceMgt.EDocPrintValidation(EDocStatus::"Stamp Received", LibraryUtility.GenerateGUID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintSent()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        UpdateGLSetupPACEnvironment(true);
        EInvoiceMgt.EDocPrintValidation(EDocStatus::Sent, LibraryUtility.GenerateGUID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintCanceled()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        UpdateGLSetupPACEnvironment(true);
        EInvoiceMgt.EDocPrintValidation(EDocStatus::Canceled, LibraryUtility.GenerateGUID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintStampRequestError()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        UpdateGLSetupPACEnvironment(true);
        EInvoiceMgt.EDocPrintValidation(EDocStatus::"Stamp Request Error", LibraryUtility.GenerateGUID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintCancelError()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
    begin
        UpdateGLSetupPACEnvironment(true);
        EInvoiceMgt.EDocPrintValidation(EDocStatus::"Cancel Error", LibraryUtility.GenerateGUID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentsCFDIFieldsEnabled()
    var
        SalesOrder: TestPage "Sales Order";
        SalesInvoice: TestPage "Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesReturnOrder: TestPage "Sales Return Order";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are enabled for Sales Documents
        LibraryApplicationArea.EnableFoundationSetup;

        SalesOrder.OpenNew;
        Assert.IsTrue(SalesOrder."CFDI Purpose".Enabled, '');
        Assert.IsTrue(SalesOrder."CFDI Relation".Enabled, '');
        SalesOrder.Close;

        SalesInvoice.OpenNew;
        Assert.IsTrue(SalesInvoice."CFDI Purpose".Enabled, '');
        Assert.IsTrue(SalesInvoice."CFDI Relation".Enabled, '');
        SalesInvoice.Close;

        SalesCreditMemo.OpenNew;
        Assert.IsTrue(SalesCreditMemo."CFDI Purpose".Enabled, '');
        Assert.IsTrue(SalesCreditMemo."CFDI Relation".Enabled, '');
        SalesCreditMemo.Close;

        PostedSalesInvoice.OpenView;
        Assert.IsTrue(PostedSalesInvoice."CFDI Purpose".Enabled, '');
        Assert.IsTrue(PostedSalesInvoice."CFDI Relation".Enabled, '');
        Assert.IsFalse(PostedSalesInvoice."CFDI Purpose".Editable, '');
        Assert.IsFalse(PostedSalesInvoice."CFDI Relation".Editable, '');

        PostedSalesCreditMemo.OpenView;
        Assert.IsTrue(PostedSalesCreditMemo."CFDI Purpose".Enabled, '');
        Assert.IsTrue(PostedSalesCreditMemo."CFDI Relation".Enabled, '');
        Assert.IsFalse(PostedSalesCreditMemo."CFDI Purpose".Editable, '');
        Assert.IsFalse(PostedSalesCreditMemo."CFDI Relation".Editable, '');

        SalesReturnOrder.OpenNew;
        Assert.IsTrue(SalesReturnOrder."CFDI Purpose".Enabled, '');
        Assert.IsTrue(SalesReturnOrder."CFDI Relation".Enabled, '');
        SalesReturnOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentsCFDIFieldsEnabled()
    var
        ServiceOrder: TestPage "Service Order";
        ServiceInvoice: TestPage "Service Invoice";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [UI] [Service]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are enabled for Service Documents
        LibraryApplicationArea.EnableFoundationSetup;

        ServiceOrder.OpenNew;
        Assert.IsTrue(ServiceOrder."CFDI Purpose".Enabled, '');
        Assert.IsTrue(ServiceOrder."CFDI Relation".Enabled, '');
        ServiceOrder.Close;

        ServiceInvoice.OpenNew;
        Assert.IsTrue(ServiceInvoice."CFDI Purpose".Enabled, '');
        Assert.IsTrue(ServiceInvoice."CFDI Relation".Enabled, '');
        ServiceInvoice.Close;

        ServiceCreditMemo.OpenNew;
        Assert.IsTrue(ServiceCreditMemo."CFDI Purpose".Enabled, '');
        Assert.IsTrue(ServiceCreditMemo."CFDI Relation".Enabled, '');
        ServiceCreditMemo.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentCFDIFieldsUpdatedFromSellToCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are updated from Sell-to Customer in Sales Documents
        CreateCustomerWithCFDIFields(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.TestField("CFDI Purpose", Customer."CFDI Purpose");
        SalesHeader.TestField("CFDI Relation", Customer."CFDI Relation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentCFDIFieldsUpdatedFromSellToCustomer()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are updated from Sell-to Customer in Service Documents
        CreateCustomerWithCFDIFields(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.TestField("CFDI Purpose", Customer."CFDI Purpose");
        ServiceHeader.TestField("CFDI Relation", Customer."CFDI Relation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentCFDIFieldsUpdatedFromBillToCustomer()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are updated from Bill-To Customer in Sales Documents
        CreateCustomerWithCFDIFields(Customer);
        CreateCustomerWithCFDIFields(CustomerBillTo);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Bill-to Customer No.", CustomerBillTo."No.");
        SalesHeader.TestField("CFDI Purpose", CustomerBillTo."CFDI Purpose");
        SalesHeader.TestField("CFDI Relation", CustomerBillTo."CFDI Relation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceDocumentCFDIFieldsUpdatedFromBillToCustomer()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are updated from Bill-to Customer in Service Documents
        CreateCustomerWithCFDIFields(Customer);
        CreateCustomerWithCFDIFields(CustomerBillTo);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Validate("Bill-to Customer No.", CustomerBillTo."No.");
        ServiceHeader.TestField("CFDI Purpose", CustomerBillTo."CFDI Purpose");
        ServiceHeader.TestField("CFDI Relation", CustomerBillTo."CFDI Relation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentCFDIFieldsInPostedDocument()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are taken from Customer in Posted Sales Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.TestField("CFDI Purpose", Customer."CFDI Purpose");
        SalesInvoiceHeader.TestField("CFDI Relation", Customer."CFDI Relation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentCFDIFieldsInPostedDocument()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 304691] CFDI Purpose and CFDI Relation fields are taken from Customer in Posted Service Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst;
        ServiceInvoiceHeader.TestField("CFDI Purpose", Customer."CFDI Purpose");
        ServiceInvoiceHeader.TestField("CFDI Relation", Customer."CFDI Relation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentCFDIFieldsUpdatedInPostedDocument()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 304691] Changed CFDI Purpose and CFDI Relation fields are taken from Service Header in Posted Sales Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesHeader."CFDI Purpose" := Format(LibraryRandom.RandInt(99999));
        SalesHeader."CFDI Relation" := Format(LibraryRandom.RandInt(99999));
        SalesHeader.Modify();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.TestField("CFDI Purpose", SalesHeader."CFDI Purpose");
        SalesInvoiceHeader.TestField("CFDI Relation", SalesHeader."CFDI Relation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentCFDIFieldsUpdatedInPostedDocument()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 304691] Changed CFDI Purpose and CFDI Relation fields are taken from Service Header in Posted Service Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader."CFDI Purpose" := Format(LibraryRandom.RandInt(99999));
        ServiceHeader."CFDI Relation" := Format(LibraryRandom.RandInt(99999));
        ServiceHeader.Modify();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst;
        ServiceInvoiceHeader.TestField("CFDI Purpose", ServiceHeader."CFDI Purpose");
        ServiceInvoiceHeader.TestField("CFDI Relation", ServiceHeader."CFDI Relation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentCFDIRelatedDocsInPostedDocument()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeaderRel: Record "Sales Invoice Header";
        SalesCrMemoHeaderRel: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 319131] Post Sales Invoice with CFDI Relation Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        MockSalesInvHeader(SalesInvoiceHeaderRel, Customer."No.");
        MockSalesCrMemoHeader(SalesCrMemoHeaderRel, Customer."No.", SalesInvoiceHeaderRel."No.");
        CreateCFDIRelationDocument(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.", Customer."No.",
          SalesInvoiceHeaderRel."No.", SalesInvoiceHeaderRel."Fiscal Invoice Number PAC");

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Invoice Header", 0, SalesInvoiceHeader."No.",
          SalesInvoiceHeaderRel."No.", SalesInvoiceHeaderRel."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Invoice Header", 0, SalesInvoiceHeader."No.",
          SalesCrMemoHeaderRel."No.", SalesCrMemoHeaderRel."Fiscal Invoice Number PAC");
        VerifyNoCFDIRelationDocuments(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentCFDIRelatedDocsInPostedDocument()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceHeaderRel: Record "Service Invoice Header";
        ServiceCrMemoHeaderRel: Record "Service Cr.Memo Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 319131] Post Service Invoice with CFDI Relation Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        MockServiceInvHeader(ServiceInvoiceHeaderRel, Customer."No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeaderRel, Customer."No.", ServiceInvoiceHeaderRel."No.");
        CreateCFDIRelationDocument(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.", Customer."No.",
          ServiceInvoiceHeaderRel."No.", ServiceInvoiceHeaderRel."Fiscal Invoice Number PAC");

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst;

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Invoice Header", 0, ServiceInvoiceHeader."No.",
          ServiceInvoiceHeaderRel."No.", ServiceInvoiceHeaderRel."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Invoice Header", 0, ServiceInvoiceHeader."No.",
          ServiceCrMemoHeaderRel."No.", ServiceCrMemoHeaderRel."Fiscal Invoice Number PAC");
        VerifyNoCFDIRelationDocuments(DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAddCFDIRelationDocs()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoice: TestPage "Sales Invoice";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 319131] Add CFDI Related Documents from Sales Invoice page
        Initialize;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        MockSalesInvHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");
        MockSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."Sell-to Customer No.", SalesInvoiceHeader."No.");

        SalesInvoice.OpenEdit;
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        CFDIRelationDocuments.Trap;
        SalesInvoice.CFDIRelationDocuments.Invoke;
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesInvoiceHeader."No.", SalesInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesCrMemoHeader."No.", SalesCrMemoHeader."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderAddCFDIRelationDocs()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesOrder: TestPage "Sales Order";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 319131] Add CFDI Related Documents from Sales Order page
        Initialize;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        MockSalesInvHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");
        MockSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."Sell-to Customer No.", SalesInvoiceHeader."No.");

        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        CFDIRelationDocuments.Trap;
        SalesOrder.CFDIRelationDocuments.Invoke;
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesInvoiceHeader."No.", SalesInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesCrMemoHeader."No.", SalesCrMemoHeader."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderCFDIRelationDocsAddingRelatedCreditMemos()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader1: Record "Sales Cr.Memo Header";
        SalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        SalesOrder: TestPage "Sales Order";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 319131] Add CFDI Related Documents from Sales Order page
        Initialize;

        // [GIVEN] Sales Order for customer, posted sales invoice and two credit memos applied to the invoice
        // [GIVEN] Fiscal Invoice Numbers assigned to invoice and credit memos as "UUID-Inv","UUID-1", "UUID-2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        MockSalesInvHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");
        MockSalesCrMemoHeader(SalesCrMemoHeader1, SalesHeader."Sell-to Customer No.", SalesInvoiceHeader."No.");
        MockSalesCrMemoHeader(SalesCrMemoHeader2, SalesHeader."Sell-to Customer No.", SalesInvoiceHeader."No.");

        // [GIVEN] CFDI Related Document for the invoice is added
        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        CFDIRelationDocuments.Trap;
        SalesOrder.CFDIRelationDocuments.Invoke;
        CFDIRelationDocuments."Related Doc. Type".SetValue(GetCFDIRelatedDocTypeInvoice);
        CFDIRelationDocuments."Related Doc. No.".SetValue(SalesInvoiceHeader."No.");

        // [WHEN] Invoice Insert Related Credit Memos action
        CFDIRelationDocuments.InsertRelatedCreditMemos.Invoke;
        CFDIRelationDocuments.Close;

        // [THEN] Three CFDI Related Document lines are shown on CFDI Relation Documents page
        // [THEN] Invoice is shown with "UUID-Inv", credit memos - with "UUID-1" and "UUID-2" respectively
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesInvoiceHeader."No.", SalesInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesCrMemoHeader1."No.", SalesCrMemoHeader1."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesCrMemoHeader2."No.", SalesCrMemoHeader2."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceAddCFDIRelationDocs()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoice: TestPage "Service Invoice";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Service]
        // [SCENARIO 319131] Add CFDI Related Documents from Service Invoice page
        Initialize;

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        MockServiceInvHeader(ServiceInvoiceHeader, ServiceHeader."Customer No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeader, ServiceHeader."Customer No.", ServiceInvoiceHeader."No.");

        ServiceInvoice.OpenEdit;
        ServiceInvoice.FILTER.SetFilter("No.", ServiceHeader."No.");
        CFDIRelationDocuments.Trap;
        ServiceInvoice.CFDIRelationDocuments.Invoke;
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, ServiceInvoiceHeader."No.", ServiceCrMemoHeader."No.");

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderAddCFDIRelationDocs()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceOrder: TestPage "Service Order";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Service]
        // [SCENARIO 319131] Add CFDI Related Documents from Service Order page
        Initialize;

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        MockServiceInvHeader(ServiceInvoiceHeader, ServiceHeader."Customer No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeader, ServiceHeader."Customer No.", ServiceInvoiceHeader."No.");

        ServiceOrder.OpenEdit;
        ServiceOrder.FILTER.SetFilter("No.", ServiceHeader."No.");
        CFDIRelationDocuments.Trap;
        ServiceOrder.CFDIRelationDocuments.Invoke;
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, ServiceInvoiceHeader."No.", ServiceCrMemoHeader."No.");

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderCFDIRelationDocsAddingRelatedCreditMemos()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader1: Record "Service Cr.Memo Header";
        ServiceCrMemoHeader2: Record "Service Cr.Memo Header";
        ServiceOrder: TestPage "Service Order";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Service]
        // [SCENARIO 319131] Add CFDI Related Documents from Service Order page
        Initialize;

        // [GIVEN] Service Order for customer, posted service invoice and two credit memos applied to the invoice
        // [GIVEN] Fiscal Invoice Numbers assigned to invoice and credit memos as "UUID-Inv","UUID-1", "UUID-2"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        MockServiceInvHeader(ServiceInvoiceHeader, ServiceHeader."Customer No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeader1, ServiceHeader."Customer No.", ServiceInvoiceHeader."No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeader2, ServiceHeader."Customer No.", ServiceInvoiceHeader."No.");

        // [GIVEN] CFDI Related Document for the invoice is added
        ServiceOrder.OpenEdit;
        ServiceOrder.FILTER.SetFilter("No.", ServiceHeader."No.");
        CFDIRelationDocuments.Trap;
        ServiceOrder.CFDIRelationDocuments.Invoke;
        CFDIRelationDocuments."Related Doc. Type".SetValue(GetCFDIRelatedDocTypeInvoice);
        CFDIRelationDocuments."Related Doc. No.".SetValue(ServiceInvoiceHeader."No.");

        // [WHEN] Invoice Insert Related Credit Memos action
        CFDIRelationDocuments.InsertRelatedCreditMemos.Invoke;
        CFDIRelationDocuments.Close;

        // [THEN] Three CFDI Related Document lines are shown on CFDI Relation Documents page
        // [THEN] Invoice is shown with "UUID-Inv", credit memos - with "UUID-1" and "UUID-2" respectively
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceCrMemoHeader1."No.", ServiceCrMemoHeader1."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceCrMemoHeader2."No.", ServiceCrMemoHeader2."Fiscal Invoice Number PAC");
    end;

    [Test]
    [HandlerFunctions('RequestStampMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampMissedCFDIRelationsForReplacementSalesInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 319131] Cannot request for Replacement Sales Invoice stamp when "CFDI Relation" = Substitution of previous CFDIs
        Initialize;
        UpdateGLSetupSAT;
        CreateCustomerWithCFDIFields(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader."CFDI Relation" := '04';
        SalesInvoiceHeader.Modify();
        ErrorMessages.Trap;
        asserterror SalesInvoiceHeader.RequestStampEDocument;
        ErrorMessages.FILTER.SetFilter("Table Number", Format(DATABASE::"Sales Invoice Header"));
        ErrorMessages.FILTER.SetFilter("Field Number", Format(SalesInvoiceHeader.FieldNo("CFDI Relation")));
        ErrorMessages.Description.AssertEquals(NoRelationDocumentsExistErr);
    end;

    [Test]
    [HandlerFunctions('RequestStampMenuHandler')]
    [Scope('OnPrem')]
    procedure RequestStampMissedCFDIRelationsForReplacementServiceInvoice()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 319131] Cannot request for Replacement Service Invoice stamp when "CFDI Relation" = Substitution of previous CFDIs
        Initialize;
        UpdateGLSetupSAT;

        CreateCustomerWithCFDIFields(Customer);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst;
        ServiceInvoiceHeader."CFDI Relation" := '04';
        ServiceInvoiceHeader.Modify();
        ErrorMessages.Trap;
        asserterror ServiceInvoiceHeader.RequestStampEDocument;

        ErrorMessages.FILTER.SetFilter("Table Number", Format(DATABASE::"Service Invoice Header"));
        ErrorMessages.FILTER.SetFilter("Field Number", Format(ServiceInvoiceHeader.FieldNo("CFDI Relation")));
        ErrorMessages.Description.AssertEquals(NoRelationDocumentsExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAbstractDocumentSalesInvoiceHeader()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempDocumentHeader: Record "Document Header" temporary;
        TempDocumentLine: Record "Document Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 325332] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Sales Invoice Header with long values in fields "Bill-to Name" etc.
        Initialize;

        // [GIVEN] Sales Invoice Header, fields "Bill-to Name/Address/Contact", "Sell-to Customer Name/Address/Contact" contain values with maximum field length.
        // [GIVEN] Sales Invoice Line, field "Description" contains value with maximum field length.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        MockSalesInvHeader(SalesInvoiceHeader, LibrarySales.CreateCustomerNo);
        UpdateDocumentTextFieldsValuesToMaxLength(SalesInvoiceHeader);
        MockSalesInvLine(SalesInvoiceLine, SalesInvoiceHeader, VATPostingSetup);
        UpdateDocumentLineTextFieldsValuesToMaxLength(SalesInvoiceLine);
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        SalesInvoiceLine.Get(SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.");

        // [WHEN] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Sales Invoice Header.
        RunCreateTempDocument(SalesInvoiceHeader, TempDocumentHeader, TempDocumentLine);

        // [THEN] Fields values of Sales Invoice Header are copied to corresponding fields of Document Header.
        // [THEN] "Description" field value of Sales Invoice Line is copied to "Description" field of Document Line.
        VerifyDocumentHeaderFieldsValues(SalesInvoiceHeader, TempDocumentHeader);
        VerifyDocumentLineFieldsValues(SalesInvoiceLine, TempDocumentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAbstractDocumentSalesCrMemoHeader()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempDocumentHeader: Record "Document Header" temporary;
        TempDocumentLine: Record "Document Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 325332] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Sales Credit Memo Header with long values in fields "Bill-to Name" etc.
        Initialize;

        // [GIVEN] Sales Credit Memo Header, fields "Bill-to Name/Address/Contact", "Sell-to Customer Name/Address/Contact" contain values with maximum field length.
        // [GIVEN] Sales Credit Memo Line, field "Description" contains value with maximum field length.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        MockSalesCrMemoHeader(SalesCrMemoHeader, LibrarySales.CreateCustomerNo, '');
        UpdateDocumentTextFieldsValuesToMaxLength(SalesCrMemoHeader);
        MockSalesCrMemoLine(SalesCrMemoLine, SalesCrMemoHeader, VATPostingSetup);
        UpdateDocumentLineTextFieldsValuesToMaxLength(SalesCrMemoLine);
        SalesCrMemoHeader.Get(SalesCrMemoHeader."No.");
        SalesCrMemoLine.Get(SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.");

        // [WHEN] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Sales Credit Memo Header.
        RunCreateTempDocument(SalesCrMemoHeader, TempDocumentHeader, TempDocumentLine);

        // [THEN] Fields values of Sales Credit Memo Header are copied to corresponding fields of Document Header.
        // [THEN] "Description" field value of Sales Credit Memo Line is copied to "Description" field of Document Line.
        VerifyDocumentHeaderFieldsValues(SalesCrMemoHeader, TempDocumentHeader);
        VerifyDocumentLineFieldsValues(SalesCrMemoLine, TempDocumentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAbstractDocumentServiceInvoiceHeader()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        TempDocumentHeader: Record "Document Header" temporary;
        TempDocumentLine: Record "Document Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 325332] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Service Invoice Header with long values in fields "Bill-to Name" etc.
        Initialize;

        // [GIVEN] Service Invoice Header, fields "Bill-to Name/Address/Contact", "Name/Address/Contact Name" contain values with maximum field length.
        // [GIVEN] Service Invoice Line, field "Description" contains value with maximum field length.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        MockServiceInvHeader(ServiceInvoiceHeader, LibrarySales.CreateCustomerNo);
        UpdateDocumentTextFieldsValuesToMaxLength(ServiceInvoiceHeader);
        MockServiceInvLine(ServiceInvoiceLine, ServiceInvoiceHeader, VATPostingSetup);
        UpdateDocumentLineTextFieldsValuesToMaxLength(ServiceInvoiceLine);
        ServiceInvoiceHeader.Get(ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.Get(ServiceInvoiceLine."Document No.", ServiceInvoiceLine."Line No.");

        // [WHEN] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Service Invoice Header.
        RunCreateTempDocument(ServiceInvoiceHeader, TempDocumentHeader, TempDocumentLine);

        // [THEN] Fields values of Service Invoice Header are copied to corresponding fields of Document Header.
        // [THEN] "Description" field value of Service Invoice Line is copied to "Description" field of Document Line.
        VerifyDocumentHeaderFieldsValues(ServiceInvoiceHeader, TempDocumentHeader);
        VerifyDocumentLineFieldsValues(ServiceInvoiceLine, TempDocumentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAbstractDocumentServiceCrMemoHeader()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        TempDocumentHeader: Record "Document Header" temporary;
        TempDocumentLine: Record "Document Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 325332] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Service Credit Memo Header with long values in fields "Bill-to Name" etc.
        Initialize;

        // [GIVEN] Service Credit Memo Header, fields "Bill-to Name/Address/Contact", "Sell-to Customer Name/Address/Contact" contain values with maximum field length.
        // [GIVEN] Service Credit Memo Line, field "Description" contains value with maximum field length.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        MockServiceCrMemoHeader(ServiceCrMemoHeader, LibrarySales.CreateCustomerNo, '');
        UpdateDocumentTextFieldsValuesToMaxLength(ServiceCrMemoHeader);
        MockServiceCrMemoLine(ServiceCrMemoLine, ServiceCrMemoHeader, VATPostingSetup);
        UpdateDocumentLineTextFieldsValuesToMaxLength(ServiceCrMemoLine);
        ServiceCrMemoHeader.Get(ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.Get(ServiceCrMemoLine."Document No.", ServiceCrMemoLine."Line No.");

        // [WHEN] Run CreateTempDocument function of "E-Invoice Mgt." codeunit for Service Credit Memo Header.
        RunCreateTempDocument(ServiceCrMemoHeader, TempDocumentHeader, TempDocumentLine);

        // [THEN] Fields values of Service Credit Memo Header are copied to corresponding fields of Document Header.
        // [THEN] "Description" field value of Service Credit Memo Line is copied to "Description" field of Document Line.
        VerifyDocumentHeaderFieldsValues(ServiceCrMemoHeader, TempDocumentHeader);
        VerifyDocumentLineFieldsValues(ServiceCrMemoLine, TempDocumentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoCFDIRelatedDocsInPostedDocument()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeaderRel: Record "Sales Invoice Header";
        SalesCrMemoHeaderRel: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 334952] Post Sales Credit Memo with CFDI Relation Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader."Payment Method Code" := CreatePaymentMethod;
        SalesHeader.Modify;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        MockSalesInvHeader(SalesInvoiceHeaderRel, Customer."No.");
        MockSalesCrMemoHeader(SalesCrMemoHeaderRel, Customer."No.", SalesInvoiceHeaderRel."No.");
        CreateCFDIRelationDocument(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.", Customer."No.",
          SalesInvoiceHeaderRel."No.", SalesInvoiceHeaderRel."Fiscal Invoice Number PAC");

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
          SalesInvoiceHeaderRel."No.", SalesInvoiceHeaderRel."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
          SalesCrMemoHeaderRel."No.", SalesCrMemoHeaderRel."Fiscal Invoice Number PAC");
        VerifyNoCFDIRelationDocuments(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoCFDIRelatedDocsInPostedDocument()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeaderRel: Record "Service Invoice Header";
        ServiceCrMemoHeaderRel: Record "Service Cr.Memo Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 334952] Post Service Credit Memo with CFDI Relation Documents
        Initialize;

        CreateCustomerWithCFDIFields(Customer);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        ServiceHeader."Payment Method Code" := CreatePaymentMethod;
        ServiceHeader.Modify;
        MockServiceInvHeader(ServiceInvoiceHeaderRel, Customer."No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeaderRel, Customer."No.", ServiceInvoiceHeaderRel."No.");
        CreateCFDIRelationDocument(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.", Customer."No.",
          ServiceInvoiceHeaderRel."No.", ServiceInvoiceHeaderRel."Fiscal Invoice Number PAC");

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceCrMemoHeader.SetRange("Customer No.", Customer."No.");
        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindFirst;

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
          ServiceInvoiceHeaderRel."No.", ServiceInvoiceHeaderRel."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
          ServiceCrMemoHeaderRel."No.", ServiceCrMemoHeaderRel."Fiscal Invoice Number PAC");
        VerifyNoCFDIRelationDocuments(DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoAddCFDIRelationDocs()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 334952] Add CFDI Related Documents from Sales Credit Memo page
        Initialize;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo);
        MockSalesInvHeader(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");
        MockSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."Sell-to Customer No.", SalesInvoiceHeader."No.");

        SalesCreditMemo.OpenEdit;
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        CFDIRelationDocuments.Trap;
        SalesCreditMemo.CFDIRelationDocuments.Invoke;
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, SalesInvoiceHeader."No.", SalesCrMemoHeader."No.");

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesInvoiceHeader."No.", SalesInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
          SalesCrMemoHeader."No.", SalesCrMemoHeader."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoAddCFDIRelationDocs()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Service]
        // [SCENARIO 334952] Add CFDI Related Documents from Service Credit Memo page
        Initialize;

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo);
        MockServiceInvHeader(ServiceInvoiceHeader, ServiceHeader."Customer No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeader, ServiceHeader."Customer No.", ServiceInvoiceHeader."No.");

        ServiceCreditMemo.OpenEdit;
        ServiceCreditMemo.FILTER.SetFilter("No.", ServiceHeader."No.");
        CFDIRelationDocuments.Trap;
        ServiceCreditMemo.CFDIRelationDocuments.Invoke;
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, ServiceInvoiceHeader."No.", ServiceCrMemoHeader."No.");

        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoAddCFDIRelationDocs()
    var
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeaderRel: Record "Sales Invoice Header";
        SalesCrMemoHeaderRel: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 367627] Add CFDI Related Documents from Posted Sales Credit Memo page
        Initialize();

        // [GIVEN] Posted Sales Credit Memo
        CreateCustomerWithCFDIFields(Customer);
        MockSalesCrMemoHeader(SalesCrMemoHeader, Customer."No.", '');
        MockSalesInvHeader(SalesInvoiceHeaderRel, Customer."No.");
        MockSalesCrMemoHeader(SalesCrMemoHeaderRel, Customer."No.", Customer."No.");

        // [WHEN] Add two related documents sales invoice and sales credit memo
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        CFDIRelationDocuments.Trap();
        PostedSalesCreditMemo.CFDIRelationDocuments.Invoke();
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, SalesInvoiceHeaderRel."No.", SalesCrMemoHeaderRel."No.");

        // [THEN] Relation documents added with Fiscal Invoice Numbers
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
          SalesInvoiceHeaderRel."No.", SalesInvoiceHeaderRel."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
          SalesCrMemoHeaderRel."No.", SalesCrMemoHeaderRel."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoAddCFDIRelationDocs()
    var
        Customer: Record Customer;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeaderRel: Record "Service Invoice Header";
        ServiceCrMemoHeaderRel: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        CFDIRelationDocuments: TestPage "CFDI Relation Documents";
    begin
        // [FEATURE] [UI] [Service]
        // [SCENARIO 367627] Add CFDI Related Documents from Posted Service Credit Memo page
        Initialize();

        // [GIVEN] Posted Service Credit Memo
        CreateCustomerWithCFDIFields(Customer);
        MockServiceCrMemoHeader(ServiceCrMemoHeader, Customer."No.", '');
        MockServiceInvHeader(ServiceInvoiceHeaderRel, Customer."No.");
        MockServiceCrMemoHeader(ServiceCrMemoHeaderRel, Customer."No.", Customer."No.");

        // [WHEN] Add two related documents service invoice and service credit memo
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", ServiceCrMemoHeader."No.");
        CFDIRelationDocuments.Trap();
        PostedServiceCreditMemo.CFDIRelationDocuments.Invoke();
        CreateCFDIRelationDocumentsOnPage(CFDIRelationDocuments, ServiceInvoiceHeaderRel."No.", ServiceCrMemoHeaderRel."No.");

        // [THEN] Relation documents added with Fiscal Invoice Numbers
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
          ServiceInvoiceHeaderRel."No.", ServiceInvoiceHeaderRel."Fiscal Invoice Number PAC");
        VerifyFiscalInvoiceNumberInRelatedDoc(
          DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
          ServiceCrMemoHeaderRel."No.", ServiceCrMemoHeaderRel."Fiscal Invoice Number PAC");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetupVATExeptionFields()
    var
        VATPostingSetup: TestPage "VAT Posting Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 338353] 'VAT Exemption' and 'No Taxable' fields are enabled in VAT Posting Setup
        LibraryApplicationArea.EnableFoundationSetup;

        VATPostingSetup.OpenEdit;
        Assert.IsTrue(VATPostingSetup."CFDI VAT Exemption".Enabled, '');
        Assert.IsTrue(VATPostingSetup."CFDI Non-Taxable".Enabled, '');
        VATPostingSetup.Close;

        VATPostingSetupCard.OpenEdit;
        Assert.IsTrue(VATPostingSetupCard."CFDI VAT Exemption".Enabled, '');
        Assert.IsTrue(VATPostingSetupCard."CFDI Non-Taxable".Enabled, '');
        VATPostingSetupCard.Close;

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RetentionLineNoInSalesDocumentsPACDisabled()
    var
        SalesOrderSubform: TestPage "Sales Order Subform";
        SalesInvoiceSubform: TestPage "Sales Invoice Subform";
        SalesCrMemoSubform: TestPage "Sales Cr. Memo Subform";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 389401] 'Retention Attached to Line No.' and 'Retention VAT %' are not visible in sales document lines when PAC Environment is disabled
        UpdateGLSetupPACEnvironment(false);

        SalesOrderSubform.OpenEdit;
        Assert.IsFalse(
          SalesOrderSubform."Retention Attached to Line No.".Visible, SalesOrderSubform."Retention Attached to Line No.".Caption);
        Assert.IsFalse(
          SalesOrderSubform."Retention VAT %".Visible, SalesOrderSubform."Retention VAT %".Caption);

        SalesInvoiceSubform.OpenEdit;
        Assert.IsFalse(
          SalesInvoiceSubform."Retention Attached to Line No.".Visible, SalesInvoiceSubform."Retention Attached to Line No.".Caption);
        Assert.IsFalse(
          SalesInvoiceSubform."Retention VAT %".Visible, SalesInvoiceSubform."Retention VAT %".Caption);

        SalesCrMemoSubform.OpenEdit;
        Assert.IsFalse(
          SalesCrMemoSubform."Retention Attached to Line No.".Visible, SalesCrMemoSubform."Retention Attached to Line No.".Caption);
        Assert.IsFalse(
          SalesCrMemoSubform."Retention VAT %".Visible, SalesCrMemoSubform."Retention VAT %".Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RetentionLineNoInSalesDocumentsPACEnabled()
    var
        SalesOrderSubform: TestPage "Sales Order Subform";
        SalesInvoiceSubform: TestPage "Sales Invoice Subform";
        SalesCrMemoSubform: TestPage "Sales Cr. Memo Subform";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 389401] 'Retention Attached to Line No.' and 'Retention VAT %' are visible in sales document lines when PAC Environment is enabled
        UpdateGLSetupPACEnvironment(true);

        SalesOrderSubform.OpenEdit;
        Assert.IsTrue(
          SalesOrderSubform."Retention Attached to Line No.".Visible, SalesOrderSubform."Retention Attached to Line No.".Caption);
        Assert.IsTrue(
          SalesOrderSubform."Retention VAT %".Visible, SalesOrderSubform."Retention VAT %".Caption);

        SalesInvoiceSubform.OpenEdit;
        Assert.IsTrue(
          SalesInvoiceSubform."Retention Attached to Line No.".Visible, SalesInvoiceSubform."Retention Attached to Line No.".Caption);
        Assert.IsTrue(
          SalesInvoiceSubform."Retention VAT %".Visible, SalesInvoiceSubform."Retention VAT %".Caption);

        SalesCrMemoSubform.OpenEdit;
        Assert.IsTrue(
          SalesCrMemoSubform."Retention Attached to Line No.".Visible, SalesCrMemoSubform."Retention Attached to Line No.".Caption);
        Assert.IsTrue(
          SalesCrMemoSubform."Retention VAT %".Visible, SalesCrMemoSubform."Retention VAT %".Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRetentionLineNoPositiveQty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 389401] 'Retention Attached to Line No.' is assigned if line has negative Quantity
        Initialize();

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        LibrarySales.CreateSalesLine(
          SalesLineRetention, SalesHeader, SalesLineRetention.Type::Item, LibraryInventory.CreateItemNo(), 1);
        asserterror SalesLineRetention.Validate("Retention Attached to Line No.", SalesLine."Line No.");
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo('%1 must be equal to ''0''', SalesLineRetention.FieldCaption("Retention Attached to Line No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRetentionLineNoNegativeQty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 389401] 'Retention Attached to Line No.' cannot be assigned if line has positive Quantity
        Initialize();

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        LibrarySales.CreateSalesLine(
          SalesLineRetention, SalesHeader, SalesLineRetention.Type::Item, LibraryInventory.CreateItemNo(), -1);
        SalesLineRetention.Validate("Retention Attached to Line No.", SalesLine."Line No.");
        SalesLineRetention.TestField("Retention Attached to Line No.", SalesLine."Line No.");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        UpdateCompanyInfo;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateCustomerWithCFDIFields(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."CFDI Purpose" := LibraryUtility.GenerateRandomCode(Customer.FieldNo("CFDI Purpose"), DATABASE::Customer);
        Customer."CFDI Relation" := LibraryUtility.GenerateRandomCode(Customer.FieldNo("CFDI Relation"), DATABASE::Customer);
        Customer.Modify();
    end;

    local procedure CreatePACSetup(var PACWebService: Record "PAC Web Service")
    begin
        PACWebService.Init();
        PACWebService.Validate(Code, LibraryUtility.GenerateRandomCode(PACWebService.FieldNo(Code), DATABASE::"PAC Web Service"));
        PACWebService.Insert();
    end;

    local procedure CreateMultiplePACDetails(PACCode: Code[10])
    var
        EnvironmentOption: Option " ",Test,Production;
    begin
        CreatePACDetails(PACCode, EnvironmentOption::Test);
        CreatePACDetails(PACCode, EnvironmentOption::Production);
    end;

    local procedure CreatePACDetails(PACCode: Code[10]; EnvironmentOption: Option)
    var
        PACWebServiceDetail: Record "PAC Web Service Detail";
    begin
        PACWebServiceDetail.Init();
        PACWebServiceDetail."PAC Code" := PACCode;
        PACWebServiceDetail.Environment := EnvironmentOption;
        PACWebServiceDetail.Type := PACWebServiceDetail.Type::"Request Stamp";
        PACWebServiceDetail.Insert();
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Option; CustomerNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCFDIRelationDocument(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]; RelatedDocNo: Code[20]; FiscalInvoiceNumber: Text[50])
    var
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        CFDIRelationDocument.Init();
        CFDIRelationDocument."Document Table ID" := TableID;
        CFDIRelationDocument."Document Type" := DocumentType;
        CFDIRelationDocument."Document No." := DocumentNo;
        CFDIRelationDocument."Customer No." := CustomerNo;
        CFDIRelationDocument."Related Doc. No." := RelatedDocNo;
        CFDIRelationDocument."Fiscal Invoice Number PAC" := FiscalInvoiceNumber;
        CFDIRelationDocument.Insert();
        CFDIRelationDocument.InsertRelatedCreditMemos;
    end;

    local procedure CreateCFDIRelationDocumentsOnPage(var CFDIRelationDocuments: TestPage "CFDI Relation Documents"; InvoiceNo: Code[20]; CrMemoNo: Code[20])
    begin
        CFDIRelationDocuments.New;
        CFDIRelationDocuments."Related Doc. Type".SetValue(GetCFDIRelatedDocTypeInvoice);
        CFDIRelationDocuments."Related Doc. No.".SetValue(InvoiceNo);
        CFDIRelationDocuments.New;
        CFDIRelationDocuments."Related Doc. Type".SetValue(GetCFDIRelatedDocTypeCreditMemo);
        CFDIRelationDocuments."Related Doc. No.".SetValue(CrMemoNo);
        CFDIRelationDocuments.Close;
    end;

    local procedure GetCFDIRelatedDocTypeInvoice(): Integer
    var
        DummyCFDIRelationDocument: Record "CFDI Relation Document";
    begin
        exit(DummyCFDIRelationDocument."Related Doc. Type"::Invoice);
    end;

    local procedure GetCFDIRelatedDocTypeCreditMemo(): Integer
    var
        DummyCFDIRelationDocument: Record "CFDI Relation Document";
    begin
        exit(DummyCFDIRelationDocument."Related Doc. Type"::"Credit Memo");
    end;

    local procedure MockSalesInvHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustomerNo: Code[20])
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader."Bill-to Customer No." := CustomerNo;
        SalesInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader.Insert();
        MockCustomerLedgerEntry(CustomerNo, DummyCustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeader."No.");
    end;

    local procedure MockSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustomerNo: Code[20]; AppliesToDocNo: Code[20])
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID;
        SalesCrMemoHeader."Bill-to Customer No." := CustomerNo;
        SalesCrMemoHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID;
        SalesCrMemoHeader."Applies-to Doc. Type" := SalesCrMemoHeader."Applies-to Doc. Type"::Invoice;
        SalesCrMemoHeader."Applies-to Doc. No." := AppliesToDocNo;
        SalesCrMemoHeader.Insert();
        MockCustomerLedgerEntry(CustomerNo, DummyCustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
    end;

    local procedure MockServiceInvHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; CustomerNo: Code[20])
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        ServiceInvoiceHeader."Bill-to Customer No." := CustomerNo;
        ServiceInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID;
        ServiceInvoiceHeader.Insert();
        MockCustomerLedgerEntry(CustomerNo, DummyCustLedgerEntry."Document Type"::Invoice, ServiceInvoiceHeader."No.");
    end;

    local procedure MockServiceCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; CustomerNo: Code[20]; AppliesToDocNo: Code[20])
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."No." := LibraryUtility.GenerateGUID;
        ServiceCrMemoHeader."Bill-to Customer No." := CustomerNo;
        ServiceCrMemoHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID;
        ServiceCrMemoHeader."Applies-to Doc. Type" := ServiceCrMemoHeader."Applies-to Doc. Type"::Invoice;
        ServiceCrMemoHeader."Applies-to Doc. No." := AppliesToDocNo;
        ServiceCrMemoHeader.Insert();
        MockCustomerLedgerEntry(CustomerNo, DummyCustLedgerEntry."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");
    end;

    local procedure MockCustomerLedgerEntry(CustomerNo: Code[20]; DocumentType: Option; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Insert();
    end;

    local procedure MockSalesInvLine(var SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeader: Record "Sales Invoice Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        SalesInvoiceLine.Init();
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine."Line No." := LibraryUtility.GetNewRecNo(SalesInvoiceLine, SalesInvoiceLine.FieldNo("Line No."));
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        SalesInvoiceLine."No." := LibraryInventory.CreateItemNo;
        SalesInvoiceLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesInvoiceLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesInvoiceLine.Insert();
    end;

    local procedure MockSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        SalesCrMemoLine.Init();
        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine."Line No." := LibraryUtility.GetNewRecNo(SalesCrMemoLine, SalesCrMemoLine.FieldNo("Line No."));
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Item;
        SalesCrMemoLine."No." := LibraryInventory.CreateItemNo;
        SalesCrMemoLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesCrMemoLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesCrMemoLine.Insert();
    end;

    local procedure MockServiceInvLine(var ServiceInvoiceLine: Record "Service Invoice Line"; ServiceInvoiceHeader: Record "Service Invoice Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        ServiceInvoiceLine.Init();
        ServiceInvoiceLine."Document No." := ServiceInvoiceHeader."No.";
        ServiceInvoiceLine."Line No." := LibraryUtility.GetNewRecNo(ServiceInvoiceLine, ServiceInvoiceLine.FieldNo("Line No."));
        ServiceInvoiceLine.Type := ServiceInvoiceLine.Type::Item;
        ServiceInvoiceLine."No." := LibraryInventory.CreateItemNo;
        ServiceInvoiceLine.Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        ServiceInvoiceLine."Amount Including VAT" := LibraryRandom.RandDecInRange(100, 200, 2);
        ServiceInvoiceLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        ServiceInvoiceLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        ServiceInvoiceLine.Insert();
    end;

    local procedure MockServiceCrMemoLine(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; ServiceCrMemoHeader: Record "Service Cr.Memo Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        ServiceCrMemoLine.Init();
        ServiceCrMemoLine."Document No." := ServiceCrMemoHeader."No.";
        ServiceCrMemoLine."Line No." := LibraryUtility.GetNewRecNo(ServiceCrMemoLine, ServiceCrMemoLine.FieldNo("Line No."));
        ServiceCrMemoLine.Type := ServiceCrMemoLine.Type::Item;
        ServiceCrMemoLine."No." := LibraryInventory.CreateItemNo;
        ServiceCrMemoLine.Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        ServiceCrMemoLine."Amount Including VAT" := LibraryRandom.RandDecInRange(100, 200, 2);
        ServiceCrMemoLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        ServiceCrMemoLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        ServiceCrMemoLine.Insert();
    end;

    local procedure RunCreateTempDocument(DocumentHeaderVariant: Variant; var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary)
    var
        TempDocumentLineRetention: Record "Document Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        SubTotal: Decimal;
        TotalTax: Decimal;
        TotalRetention: Decimal;
        TotalDiscount: Decimal;
    begin
        EInvoiceMgt.CreateTempDocument(
          DocumentHeaderVariant, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
          SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get;
            Name := LibraryUtility.GenerateGUID;
            "RFC No." := LibraryUtility.GenerateGUID;
            Address := LibraryUtility.GenerateGUID;
            City := LibraryUtility.GenerateGUID;
            "Post Code" := LibraryUtility.GenerateGUID;
            "E-Mail" := LibraryUtility.GenerateGUID;
            "Tax Scheme" := LibraryUtility.GenerateGUID;
            Modify;
        end;
    end;

    local procedure UpdateGLSetupPACCode(var GeneralLedgerSetup: Record "General Ledger Setup"; PACCode: Code[10]; ModifyRec: Boolean)
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("PAC Code", PACCode);
        if ModifyRec then
            GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateGLSetupPACEnvironment(Enabled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if Enabled then
            GeneralLedgerSetup."PAC Environment" := GeneralLedgerSetup."PAC Environment"::Test
        else
            GeneralLedgerSetup."PAC Environment" := GeneralLedgerSetup."PAC Environment"::Disabled;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateGLSetupSAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."SAT Certificate" := LibraryUtility.GenerateGUID;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateDocumentTextFieldsValuesToMaxLength(CustomerDocumentHeaderVariant: Variant)
    var
        "Field": Record "Field";
        DataTypeManagement: Codeunit "Data Type Management";
        CustDocRecRef: RecordRef;
        CustDocFieldRef: FieldRef;
    begin
        DataTypeManagement.GetRecordRef(CustomerDocumentHeaderVariant, CustDocRecRef);
        Field.SetRange(TableNo, DATABASE::"Document Header");
        Field.SetFilter("No.", '<>%1', 3); // except key fields
        Field.SetFilter(Type, '%1|%2', Field.Type::Text, Field.Type::Code);
        Field.FindSet();
        repeat
            CustDocFieldRef := CustDocRecRef.Field(Field."No.");
            CustDocFieldRef.Value := LibraryUtility.GenerateRandomText(CustDocFieldRef.Length);
        until Field.Next = 0;
        CustDocRecRef.Modify();
    end;

    local procedure UpdateDocumentLineTextFieldsValuesToMaxLength(CustomerDocumentLineVariant: Variant)
    var
        "Field": Record "Field";
        DataTypeManagement: Codeunit "Data Type Management";
        CustDocLineRecRef: RecordRef;
        CustDocLineFieldRef: FieldRef;
    begin
        DataTypeManagement.GetRecordRef(CustomerDocumentLineVariant, CustDocLineRecRef);
        Field.SetRange(TableNo, DATABASE::"Document Line");
        Field.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4', 3, 4, 89, 90); // except key fields
        Field.SetFilter(Type, '%1|%2', Field.Type::Text, Field.Type::Code);
        Field.FindSet();
        repeat
            CustDocLineFieldRef := CustDocLineRecRef.Field(Field."No.");
            CustDocLineFieldRef.Value := LibraryUtility.GenerateRandomText(CustDocLineFieldRef.Length);
        until Field.Next = 0;
        CustDocLineRecRef.Modify();
    end;

    local procedure VerifyFiscalInvoiceNumberInRelatedDoc(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; RelatedDocNo: Code[20]; FiscalInvoiceNo: Text[50])
    var
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        CFDIRelationDocument.SetRange("Document Table ID", TableID);
        CFDIRelationDocument.SetRange("Document Type", DocumentType);
        CFDIRelationDocument.SetRange("Document No.", DocumentNo);
        CFDIRelationDocument.SetRange("Related Doc. No.", RelatedDocNo);
        CFDIRelationDocument.FindFirst;
        CFDIRelationDocument.TestField("Fiscal Invoice Number PAC", FiscalInvoiceNo);
    end;

    local procedure VerifyNoCFDIRelationDocuments(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        CFDIRelationDocument.SetRange("Document Table ID", TableID);
        CFDIRelationDocument.SetRange("Document Type", DocumentType);
        CFDIRelationDocument.SetRange("Document No.", DocumentNo);
        CFDIRelationDocument.SetRange("Customer No.", CustomerNo);
        Assert.RecordIsEmpty(CFDIRelationDocument);
    end;

    local procedure VerifyDocumentHeaderFieldsValues(CustomerDocumentVariant: Variant; TempDocumentHeader: Record "Document Header" temporary)
    var
        "Field": Record "Field";
        DataTypeManagement: Codeunit "Data Type Management";
        DocHeaderRecRef: RecordRef;
        DocHeaderFieldRef: FieldRef;
        CustDocRecRef: RecordRef;
        CustDocFieldRef: FieldRef;
        CustDocFieldValue: Text;
    begin
        DataTypeManagement.GetRecordRef(CustomerDocumentVariant, CustDocRecRef);
        DocHeaderRecRef.GetTable(TempDocumentHeader);
        Field.SetRange(TableNo, DATABASE::"Document Header");
        Field.SetFilter("No.", '<>%1', 3);
        Field.SetFilter(Type, '%1|%2', Field.Type::Text, Field.Type::Code);
        Field.FindSet();
        repeat
            DocHeaderFieldRef := DocHeaderRecRef.Field(Field."No.");
            CustDocFieldRef := CustDocRecRef.Field(Field."No.");
            CustDocFieldValue := CustDocFieldRef.Value;
            Assert.AreEqual(CustDocFieldValue, DocHeaderFieldRef.Value, '');
            Assert.IsTrue(DocHeaderFieldRef.Length >= CustDocFieldRef.Length, '');
        until Field.Next = 0;
    end;

    local procedure VerifyDocumentLineFieldsValues(CustomerDocumentLineVariant: Variant; TempDocumentLine: Record "Document Line" temporary)
    var
        "Field": Record "Field";
        DataTypeManagement: Codeunit "Data Type Management";
        DocLineRecRef: RecordRef;
        DocLineFieldRef: FieldRef;
        CustDocLineRecRef: RecordRef;
        CustDocLineFieldRef: FieldRef;
        CustDocLineFieldValue: Text;
    begin
        DataTypeManagement.GetRecordRef(CustomerDocumentLineVariant, CustDocLineRecRef);
        DocLineRecRef.GetTable(TempDocumentLine);
        Field.SetRange(TableNo, DATABASE::"Document Line");
        Field.SetFilter("No.", '<>%1&<>%2', 3, 4);
        Field.SetFilter(Type, '%1|%2', Field.Type::Text, Field.Type::Code);
        Field.FindSet();
        repeat
            DocLineFieldRef := DocLineRecRef.Field(Field."No.");
            CustDocLineFieldRef := CustDocLineRecRef.Field(Field."No.");
            CustDocLineFieldValue := CustDocLineFieldRef.Value;
            Assert.AreEqual(CustDocLineFieldValue, DocLineFieldRef.Value, '');
            Assert.IsTrue(DocLineFieldRef.Length >= CustDocLineFieldRef.Length, '');
        until Field.Next = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure RequestStampMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;
}


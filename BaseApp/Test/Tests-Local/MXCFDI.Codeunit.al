codeunit 144001 "MX CFDI"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CFDI]
    end;

    var
        GLSetup: Record "General Ledger Setup";
        NameValueBuffer: Record "Name/Value Buffer";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        SATUtilities: Codeunit "SAT Utilities";
        MXCFDI: Codeunit "MX CFDI";
        isInitialized: Boolean;
        ValueErr: Label 'Value in %1 field is incorrect.';
        ActionOption: Option "Request Stamp",Send,"Request Stamp and Send",Cancel;
        ResponseOption: Option Success,Error;
        DateTimeStampedTxt: Label '2011-11-08T07:45:56';
        FiscalInvoiceNumberPACTxt: Label '9CDBDABD-9399-4DA1-8409-D1B70C5BA4DD';
        OptionNotSupportedErr: Label 'Option not supported by test function.';
        ErrorCodeTxt: Label '302';
        ErrorDescriptionTxt: Label 'Sello del Emisor No Valido';
        StatusOption: Option " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error";
        DigitalStampTxt: Label 'WDTveFcG+ANYGdjrNrDcpYGdz4p0XsH5C0UTsqcMM/dSe4MGGnsacrJ75DAT5B5KqZWSefkGeg/sG7i6K3+lZTEuxje+rBDAp/4fMfYeL2TTMLpkU6Oy1zl/N6ywt38Z2+WTwcBIuIkEY54e+mW+zkyJLAxkeDGJHAwEBdf2nu0=';
        MissingSalesPaymentMethodCodeExceptionErr: Label 'Payment Method Code must have a value in Sales Header';
        MissingServicePaymentMethodCodeExceptionErr: Label 'Payment Method Code must have a value in Service Header';
        MissingServiceUnitOfMeasureExcErr: Label 'Unit of Measure Code must have a value in Service Line';
        MissingSalesUnitOfMeasureExcErr: Label 'Unit of Measure Code must have a value in Sales Line';
        IncorrectSchemaVersionErr: Label 'Incorrect schema version in the original string %1.';
        IncorrectOriginalStrValueErr: Label 'Incorrect %1 in the original string %2.';
        ConceptoUnidadFieldTxt: Label 'ConceptoUnidad';
        MetodoDePagoFieldTxt: Label 'MetodoDePago';
        FormaDePagoFieldTxt: Label 'FormaDePago';
        RegimenFieldTxt: Label 'Regimen';
        RFCNoFieldTxt: Label 'RFC No.';
        CFDIPurposeFieldTxt: Label 'CFDI Purpose';
        CFDIRelationFieldTxt: Label 'CFDI Relation';
        PaymentMethodMissingErr: Label 'Payment Method Code must have a value in %1: Document Type=%2';
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        PACDetailDoesNotExistErr: Label 'Record %1 does not exist for %2, %3, %4.';
        WrongFieldValueErr: Label 'Wrong value %1 in field %2 of table %3.';
        NoElectronicStampErr: Label 'There is no electronic stamp';
        NoElectronicDocumentSentErr: Label 'There is no electronic Document sent yet';

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestStamp()
    begin
        RequestStampTest(DATABASE::"Sales Invoice Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoRequestStamp()
    begin
        RequestStampTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestStamp()
    begin
        RequestStampTest(DATABASE::"Service Invoice Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoRequestStamp()
    begin
        RequestStampTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Success, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestStampError()
    begin
        RequestStampTest(DATABASE::"Sales Invoice Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoRequestStampError()
    begin
        RequestStampTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestStampErro()
    begin
        RequestStampTest(DATABASE::"Service Invoice Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoRequestStampError()
    begin
        RequestStampTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Error, ActionOption::"Request Stamp");
    end;

    local procedure RequestStampTest(TableNo: Integer; Response: Option; "Action": Option)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, Response, Action);

        // Verify
        if Response = ResponseOption::Success then
            Verify(TableNo, PostedDocumentNo, StatusOption::"Stamp Received", 0)
        else
            Verify(TableNo, PostedDocumentNo, StatusOption::"Stamp Request Error", 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSend()
    begin
        SendTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoSend()
    begin
        SendTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSend()
    begin
        SendTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSend()
    begin
        SendTest(DATABASE::"Service Cr.Memo Header");
    end;

    local procedure SendTest(TableNo: Integer)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::Send);

        // Verify
        Verify(TableNo, PostedDocumentNo, StatusOption::Sent, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Sales Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Service Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSignAndSend()
    begin
        SignAndSendTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Sales Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Service Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSignAndSendError()
    begin
        SignAndSendTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Error);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceBlankPaymentMethodCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        PostSalesDocBlankPaymentMethodCode(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoBlankPaymentMethodCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        PostSalesDocBlankPaymentMethodCode(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceBlankPaymentMethodCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        PostServiceDocBlankPaymentMethodCode(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoBlankPaymentMethodCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        PostServiceDocBlankPaymentMethodCode(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceBlankUnitOfMeasureCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        PostSalesDocBlankUnitOfMeasureCode(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoBlankUnitOfMeasureCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        PostSalesDocBlankUnitOfMeasureCode(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceBlankUnitOfMeasureCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        PostServiceDocBlankUnitOfMeasureCode(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoBlankUnitOfMeasureCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        PostServiceDocBlankPaymentMethodCode(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesCreditMemoRequestBlankTaxSchemeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        SendSalesStampRequestBlankTaxSchemeError(SalesHeader."Document Type"::"Credit Memo", DATABASE::"Sales Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesInvoiceRequestBlankTaxSchemeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        SendSalesStampRequestBlankTaxSchemeError(SalesHeader."Document Type"::Invoice, DATABASE::"Sales Invoice Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceCreditMemoRequestBlankTaxSchemeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        SendServiceStampRequestBlankTaxSchemeError(ServiceHeader."Document Type"::"Credit Memo", DATABASE::"Service Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceInvoiceRequestBlankTaxSchemeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        SendServiceStampRequestBlankTaxSchemeError(ServiceHeader."Document Type"::Invoice, DATABASE::"Service Invoice Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesCreditMemoRequestBlankCountryCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        SendSalesStampRequestBlankCountryCodeError(SalesHeader."Document Type"::"Credit Memo", DATABASE::"Sales Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampSalesInvoiceRequestBlankCountryCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        SendSalesStampRequestBlankCountryCodeError(SalesHeader."Document Type"::Invoice, DATABASE::"Sales Invoice Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceCreditMemoRequestBlankCountryCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        SendServiceStampRequestBlankCountryCodeError(ServiceHeader."Document Type"::"Credit Memo", DATABASE::"Service Cr.Memo Header")
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendStampServiceInvoiceRequestBlankCountryCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        SendServiceStampRequestBlankCountryCodeError(ServiceHeader."Document Type"::Invoice, DATABASE::"Service Invoice Header")
    end;

    local procedure SignAndSendTest(TableNo: Integer; Response: Option)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);

        // Exercise
        if Response = ResponseOption::Success then
            RequestStamp(TableNo, PostedDocumentNo, Response, ActionOption::"Request Stamp and Send")
        else
            asserterror RequestStamp(TableNo, PostedDocumentNo, Response, ActionOption::"Request Stamp and Send");

        // Verify
        if Response = ResponseOption::Success then
            Verify(TableNo, PostedDocumentNo, StatusOption::Sent, 0)
        else
            Verify(TableNo, PostedDocumentNo, StatusOption::"Stamp Request Error", 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceResend()
    begin
        ResendTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoResend()
    begin
        ResendTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceResend()
    begin
        ResendTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoResend()
    begin
        ResendTest(DATABASE::"Service Cr.Memo Header");
    end;

    local procedure ResendTest(TableNo: Integer)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::Send);
        LibraryVariableStorage.Enqueue(true);
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::Send);

        // Verify
        Verify(TableNo, PostedDocumentNo, StatusOption::Sent, 1)
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCancel()
    begin
        CancelTest(DATABASE::"Sales Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCancel()
    begin
        CancelTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCancel()
    begin
        CancelTest(DATABASE::"Service Invoice Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoCancel()
    begin
        CancelTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Success);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCancelError()
    begin
        CancelTest(DATABASE::"Sales Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCancelError()
    begin
        CancelTest(DATABASE::"Sales Cr.Memo Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCancelError()
    begin
        CancelTest(DATABASE::"Service Invoice Header", ResponseOption::Error);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoCancelError()
    begin
        CancelTest(DATABASE::"Service Cr.Memo Header", ResponseOption::Error);
    end;

    local procedure CancelTest(TableNo: Integer; Response: Option)
    var
        PostedDocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        PostedDocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);

        // Exercise
        RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        LibraryVariableStorage.Enqueue(true);
        Cancel(TableNo, PostedDocumentNo, Response);

        // Verify
        if Response = ResponseOption::Success then
            Verify(TableNo, PostedDocumentNo, StatusOption::Canceled, 0)
        else
            Verify(TableNo, PostedDocumentNo, StatusOption::"Cancel Error", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoPostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPostAndPrint()
    begin
        PostAndPrintTest(DATABASE::"Service Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Sales Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoPostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Service Invoice Header");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPostAndPrintCFDIDisabled()
    begin
        PostAndPrintCFDIDisabledTest(DATABASE::"Service Cr.Memo Header");
    end;

    local procedure PostAndPrintTest(TableNo: Integer)
    var
        DocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        DocumentNo := CreateDoc(TableNo, CreatePaymentMethodForSAT);

        // Exercise
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        PostAndPrint(TableNo, DocumentNo);

        // Verify - that the right number of confirm handlers was executed
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure PostAndPrintCFDIDisabledTest(TableNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        GLSetup.Get();
        GLSetup.Validate("PAC Environment", GLSetup."PAC Environment"::Disabled);
        GLSetup.Modify(true);
        DocumentNo := CreateDoc(TableNo, '');

        // Exercise
        LibraryVariableStorage.Enqueue(true);
        PostAndPrint(TableNo, DocumentNo);

        // Verify - that the right number of confirm handlers was executed
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvOriginalStrMandatoryFields()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Sales Invoice Header", DATABASE::"Sales Invoice Line",
          SalesInvoiceHeader.FieldNo("No."), SalesInvoiceHeader.FieldNo("Sell-to Customer No."),
          SalesInvoiceHeader.FieldNo("CFDI Purpose"), SalesInvoiceHeader.FieldNo("CFDI Relation"),
          SalesInvoiceHeader.FieldNo("Payment Method Code"), SalesInvoiceHeader.FieldNo("Payment Terms Code"),
          SalesInvoiceLine.FieldNo("Unit of Measure Code"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoOriginalStrMandatoryFields()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Sales Cr.Memo Header", DATABASE::"Sales Cr.Memo Line",
          SalesCrMemoHeader.FieldNo("No."), SalesCrMemoHeader.FieldNo("Sell-to Customer No."),
          SalesCrMemoHeader.FieldNo("CFDI Purpose"), SalesCrMemoHeader.FieldNo("CFDI Relation"),
          SalesCrMemoHeader.FieldNo("Payment Method Code"), SalesCrMemoHeader.FieldNo("Payment Terms Code"),
          SalesCrMemoLine.FieldNo("Unit of Measure Code"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvOriginalStrMandatoryFields()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Service Invoice Header", DATABASE::"Service Invoice Line",
          ServiceInvoiceHeader.FieldNo("No."), ServiceInvoiceHeader.FieldNo("Customer No."),
          ServiceInvoiceHeader.FieldNo("CFDI Purpose"), ServiceInvoiceHeader.FieldNo("CFDI Relation"),
          ServiceInvoiceHeader.FieldNo("Payment Method Code"), ServiceInvoiceHeader.FieldNo("Payment Terms Code"),
          ServiceInvoiceLine.FieldNo("Unit of Measure Code"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoOriginalStrMandatoryFields()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        OriginalStringMandatoryFields(DATABASE::"Service Cr.Memo Header", DATABASE::"Service Cr.Memo Line",
          ServiceCrMemoHeader.FieldNo("No."), ServiceCrMemoHeader.FieldNo("Customer No."),
          ServiceCrMemoHeader.FieldNo("CFDI Purpose"), ServiceCrMemoHeader.FieldNo("CFDI Relation"),
          ServiceCrMemoHeader.FieldNo("Payment Method Code"), ServiceCrMemoHeader.FieldNo("Payment Terms Code"),
          ServiceCrMemoLine.FieldNo("Unit of Measure Code"), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPaymentTermsNoDisc()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize;

        // Exercise
        CreateBasicSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerNoDiscount);

        // Verify
        SalesHeader.TestField("Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPaymentTermsNoDisc()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize;

        // Exercise
        CreateBasicSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount);

        // Verify
        SalesHeader.TestField("Payment Method Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvPaymentTermsNoDisc()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup
        Initialize;

        // Exercise
        CreateBasicServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomerNoDiscount);

        // Verify
        ServiceHeader.TestField("Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPaymentTermsNoDisc()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup
        Initialize;

        // Exercise
        CreateBasicServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount);

        // Verify
        ServiceHeader.TestField("Payment Method Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPaymentTermsNoDiscError()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        // Setup
        CreateBasicSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount);

        // Exercise
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        Assert.ExpectedError(StrSubstNo(PaymentMethodMissingErr, SalesHeader.TableCaption, SalesHeader."Document Type"::"Credit Memo"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPaymentTermsNoDiscError()
    var
        ServiceHeader: Record "Service Header";
    begin
        Initialize;

        // Setup
        CreateBasicServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomerNoDiscount);

        // Exercise
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(PaymentMethodMissingErr, ServiceHeader.TableCaption, ServiceHeader."Document Type"::"Credit Memo"));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 308161] Request stamp for full payment of sales invoice
        Initialize;

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in local currency
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        UpdateCustomerSATPaymentFields(SalesInvoiceHeader."Sell-to Customer No.");

        // [GIVEN] Payment with amount of 1000 is applied to the invoice, Payment Terms set to "PT", Payment Method with '03' SAT Code
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        SalesInvoiceHeader."Payment Terms Code" := CreatePaymentTermsForSAT;
        SalesInvoiceHeader.Modify;
        // [GIVEN] Customer has Payment Method with '99' SAT Code
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.Validate("Payment Method Code", CreatePaymentMethodForSAT());
        Customer.Modify(true);

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'MXN'
        // [THEN] Invoice's amount is exported to attribute 'ImpSaldoAnt' = 1000
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago', 'MonedaP', 'MXN');
        // [THEN] 'Concepto' node has attributes 'ValorUnitario' = 0, 'Importe' = 0 (TFS 329513)
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ValorUnitario', '0');
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'Importe', '0');
        // [THEN] 'DoctoRelacionado' node has attribute 'NumParcialidad' (partial payment number) = '1' (TFS 363806)
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'NumParcialidad', '1');
        // [THEN] 'DoctoRelacionado' node has attribute 'MetodoDePagoDR' = "PT" (TFS 362812)
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'MetodoDePagoDR',
          SATUtilities.GetSATPaymentTerm(SalesInvoiceHeader."Payment Terms Code"));

        // [THEN] 'Complemento' node has attribute 'FormaDePagoP' = '03' (TFS 375439)          
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago', 'FormaDePagoP',
          SATUtilities.GetSATPaymentMethod(CustLedgerEntry."Payment Method Code"));

        // [THEN] String for digital stamp has 'ValorUnitario' = 0, 'Importe' = 0  (TFS 329513)
        // [THEN] Original stamp string has NumParcialidad (partial payment number) = '1' (TFS 363806)
        // [THEN] String for digital stamp has 'MetodoDePagoDR' = "PT" (TFS 362812)	
        // [THEN] String for digital stamp has 'FormaDePagoP' = '03' (TFS 375439)          
        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual('0', SelectStr(21, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ValorUnitario', OriginalStr));
        Assert.AreEqual('0', SelectStr(22, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));
        Assert.AreEqual('1', SelectStr(31, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
        Assert.AreEqual(
          SATUtilities.GetSATPaymentTerm(SalesInvoiceHeader."Payment Terms Code"),
          SelectStr(30, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MetodoDePagoDR', OriginalStr));
        Assert.AreEqual(
          SATUtilities.GetSATPaymentMethod(CustLedgerEntry."Payment Method Code"),
          SelectStr(25, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'FormaDePagoP', OriginalStr));

        // [THEN] "Date/Time First Req. Sent" is created in current time zone (TFS 323341)
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(CustLedgerEntry."Date/Time First Req. Sent"),
          CreateDateTime(CustLedgerEntry."Document Date", Time));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPayment2Docs()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        FileName: Text;
        OriginalStr: Text;
        PaymentNo1: Code[20];
        PaymentNo2: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 308161] Request stamp for second payment of sales invoice
        Initialize;

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in local currency
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        UpdateCustomerSATPaymentFields(SalesInvoiceHeader."Sell-to Customer No.");

        // [GIVEN] Payment "Pmt1" with amount of 300 is applied to the invoice
        PaymentNo1 :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT" / 2, '');

        // [GIVEN] Stamp is requested for the payment "Pmt1"
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo1, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo1);

        // [GIVEN] Payment "Pmt2" with amount of 700 is applied to the invoice
        PaymentNo2 :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT" / 2, '');

        // [WHEN] Request stamp for the payment "Pmt2"
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo2, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo2);

        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'MXN'
        // [THEN] Invoice's amount is exported to attribute 'ImpSaldoAnt' = 700
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'ImpSaldoAnt',
          FormatDecimal(SalesInvoiceHeader."Amount Including VAT" - Round(SalesInvoiceHeader."Amount Including VAT" / 2), 2));
        // [THEN] 'DoctoRelacionado' node has attribute 'NumParcialidad' (partial payment number) = '2' (363806)
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'NumParcialidad', '2');

        // [THEN] Original stamp string has NumParcialidad (partial payment number) = '2' (363806)
        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual('2', SelectStr(31, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentService()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 362812] Request stamp for payment of service invoice
        Initialize;

        // [GIVEN] Posted Service Invoice with "Amount Including VAT" = 1000 in local currency
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        ServiceInvoiceHeader.CalcFields("Amount Including VAT");
        UpdateCustomerSATPaymentFields(ServiceInvoiceHeader."Customer No.");

        // [GIVEN] Payment with amount of 1000 is applied to the invoice, Payment Terms set to "PT".
        PaymentNo :=
          CreatePostPayment(
            ServiceInvoiceHeader."Customer No.", ServiceInvoiceHeader."No.", -ServiceInvoiceHeader."Amount Including VAT", '');
        ServiceInvoiceHeader."Payment Terms Code" := CreatePaymentTermsForSAT;
        ServiceInvoiceHeader.Modify;

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'DoctoRelacionado' node has attribute 'NumParcialidad' (partial payment number) = '1' (TFS 363806)
        // [THEN] 'DoctoRelacionado' node has attribute 'MetodoDePagoDR' = "PT" (TFS 362812)
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'NumParcialidad', '1');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'MetodoDePagoDR',
          SATUtilities.GetSATPaymentTerm(ServiceInvoiceHeader."Payment Terms Code"));

        // [THEN] Original stamp string has NumParcialidad (partial payment number) = '1' (TFS 363806)
        // [THEN] String for digital stamp has 'MetodoDePagoDR' = "PT" (TFS 362812)	
        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual('1', SelectStr(31, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
        Assert.AreEqual(
          SATUtilities.GetSATPaymentTerm(ServiceInvoiceHeader."Payment Terms Code"),
          SelectStr(30, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MetodoDePagoDR', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentLCYAppliedToInvoiceFCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 366659] Request stamp for LCY payment applied to FCY invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in foreign currency "USD"
        Customer.Get(CreateCustomer);
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20)));
        Customer.Modify(true);
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomer(SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Payment with amount of -12345.67 in local currency is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'MXN'
        // [THEN] 'DoctoRelacionado' node has attribute 'TipoCambioDR' = '12.345670', 'MonedaDR' = 'USD'
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago', 'MonedaP', 'MXN');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'TipoCambioDR',
          FormatDecimal(1 / SalesInvoiceHeader."Currency Factor", 6));
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'MonedaDR', Customer."Currency Code");

        // [THEN] String for digital stamp has 'MonedaP' = 'MXN', 'TipoCambioDR' = '12.345670', 'MonedaDR' = 'USD'
        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          'MXN', SelectStr(25, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MonedaP', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(1 / SalesInvoiceHeader."Currency Factor", 6),
          SelectStr(29, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'TipoCambioDR', OriginalStr));
        Assert.AreEqual(
          Customer."Currency Code", SelectStr(28, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MonedaDR', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentFCYAppliedToInvoiceFCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 366659] Request stamp for FCY payment applied to FCY invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Amount Including VAT" = 1000 in foreign currency "USD"
        Customer.Get(CreateCustomer);
        Customer.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20)));
        Customer.Modify(true);
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomer(SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Payment with amount of -1000 in "USD" currency is applied to the invoice
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.",
            -SalesInvoiceHeader."Amount Including VAT", Customer."Currency Code");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] 'Complemento' node created with attribute 'MonedaP' = 'USD'
        // [THEN] 'DoctoRelacionado' node has attribute 'TipoCambioDR' is not exported, 'MonedaDR' = 'USD'
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago', 'MonedaP', Customer."Currency Code");
        LibraryXPathXMLReader.VerifyAttributeAbsence(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'TipoCambioDR');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'MonedaDR', Customer."Currency Code");

        // [THEN] String for digital stamp has 'TipoCambioDR' is not exported, 'MonedaP' = 'USD', 'MonedaDR' = 'USD'
        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          Customer."Currency Code", SelectStr(25, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MonedaP', OriginalStr));
        Assert.AreEqual(
          Customer."Currency Code", SelectStr(29, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'MonedaDR', OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesFullyApplied()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            SalesInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID();
            SalesInvoiceHeader.Modify();
            InvAmount += CustLedgerEntryInv[i].Amount;
        end;

        // [GIVEN] Payment with amount of -600 is applied to all invoices
        PaymentNo :=
          CreatePostPayment(CustomerNo, '', -InvAmount, '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] ImpSaldoAnt = 100, 200, 300,  for each invoice respectively, ImpSaldoInsoluto = 0.
        // [THEN] IdDocumento = "Fiscal Invoice Number PAC" for each invoice.
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');

        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            VerifyComplementoPago(
              OriginalStr,
              CustLedgerEntryInv[i].Amount, CustLedgerEntryInv[i].Amount, 0,
              SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', i - 1);
        end;
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesWithRemAmtForPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices with remaining amount
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            SalesInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID();
            SalesInvoiceHeader.Modify();
            InvAmount += CustLedgerEntryInv[i].Amount;
        end;

        // [GIVEN] Payment with amount of -450 is applied to all invoices
        PaymentNo :=
          CreatePostPayment(CustomerNo, '', -(InvAmount - CustLedgerEntryInv[i].Amount / 2), '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] ImpSaldoAnt = 100, 200, 150, for each invoice respectively,
        // [THEN] ImpSaldoInsoluto = 0 for 1st and 2nd invoice, ImpSaldoInsoluto = 150 for 3rd invoice.
        // [THEN] IdDocumento = "Fiscal Invoice Number PAC" for each invoice.
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');

        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        for i := 1 to ArrayLen(CustLedgerEntryInv) - 1 do begin
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            VerifyComplementoPago(
              OriginalStr,
              CustLedgerEntryInv[i].Amount, CustLedgerEntryInv[i].Amount, 0,
              SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', i - 1);
        end;

        SalesInvoiceHeader.Get(CustLedgerEntryInv[3]."Document No.");
        CustLedgerEntryInv[3].CalcFields("Remaining Amount");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[3].Amount, CustLedgerEntryInv[3].Amount - CustLedgerEntryInv[3]."Remaining Amount",
          CustLedgerEntryInv[3]."Remaining Amount",
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 2);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesWithRemAmtForInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices with remaining amount
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            SalesInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID();
            SalesInvoiceHeader.Modify();
            InvAmount += CustLedgerEntryInv[i].Amount;
        end;

        // [GIVEN] Payment with amount of -600 is applied to all invoices, 3rd invoice is applied partially.
        PaymentNo :=
          CreatePostPayment(CustomerNo, '', -InvAmount, '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) - 1 do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryInv[3]);
        CustLedgerEntryInv[3].CalcFields(Amount);
        CustLedgerEntryInv[3].Validate("Amount to Apply", CustLedgerEntryInv[3].Amount / 2);
        CustLedgerEntryInv[3].Modify(true);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] ImpSaldoAnt = 100, 200, 150, for each invoice respectively,
        // [THEN] ImpSaldoInsoluto = 0 for 1st and 2nd invoice, ImpSaldoInsoluto = 150 for 3rd invoice.
        // [THEN] IdDocumento = "Fiscal Invoice Number PAC" for each invoice.
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');

        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        for i := 1 to ArrayLen(CustLedgerEntryInv) - 1 do begin
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            VerifyComplementoPago(
              OriginalStr,
              CustLedgerEntryInv[i].Amount, CustLedgerEntryInv[i].Amount, 0,
              SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', i - 1);
        end;

        SalesInvoiceHeader.Get(CustLedgerEntryInv[3]."Document No.");
        CustLedgerEntryInv[3].CalcFields("Remaining Amount");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[3].Amount, CustLedgerEntryInv[3].Amount - CustLedgerEntryInv[3]."Remaining Amount",
          CustLedgerEntryInv[3]."Remaining Amount",
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 2);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SendPaymentForMultipleInvoicesWithRemAmtForFirstInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntryInv: array[3] of Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InStream: InStream;
        OriginalStr: Text;
        FileName: Text;
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        PmtAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 386332] Request stamp for payment of multiple invoices with remaining amount for first and last invoice
        Initialize();

        // [GIVEN] Three posted Sales Invoices with "Amount Including VAT" = 100, 200, 300
        CustomerNo := CreateCustomer();
        UpdateCustomerSATPaymentFields(CustomerNo);
        for i := 1 to ArrayLen(CustLedgerEntryInv) do begin
            CreateAndPostSalesInvoice(CustLedgerEntryInv[i], CustomerNo);
            SalesInvoiceHeader.Get(CustLedgerEntryInv[i]."Document No.");
            SalesInvoiceHeader."Fiscal Invoice Number PAC" := LibraryUtility.GenerateGUID;
            SalesInvoiceHeader.Modify();
        end;
        PmtAmount := CustLedgerEntryInv[1].Amount / 2 + CustLedgerEntryInv[2].Amount + CustLedgerEntryInv[3].Amount / 2;

        // [GIVEN] Payment "Pmt1" with amount of -50 is applied to first invoice
        PaymentNo := CreatePostPayment(CustomerNo, '', -CustLedgerEntryInv[1].Amount / 2, '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        CustLedgerEntry."Date/Time Stamped" := Format(WorkDate);
        CustLedgerEntry.Modify();
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[1]."Document Type"::Invoice,
          PaymentNo, CustLedgerEntryInv[1]."Document No.");

        // [GIVEN] Payment "Pmt2" with amount = 400 is applied to all documents (50 + 200 + 150 respectively)
        PaymentNo := CreatePostPayment(CustomerNo, '', -PmtAmount, '');
        for i := 1 to ArrayLen(CustLedgerEntryInv) do
            LibraryERM.ApplyCustomerLedgerEntries(
              CustLedgerEntry."Document Type"::Payment, CustLedgerEntryInv[i]."Document Type"::Invoice,
              PaymentNo, CustLedgerEntryInv[i]."Document No.");

        // [WHEN] Request stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ExportPaymentToServerFile(CustLedgerEntry, FileName, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] First invoice line has NumParcialidad='2' ImpSaldoAnt='50' ImpPagado='50' ImpSaldoInsoluto='0.00'
        // [THEN] Second invoice line has NumParcialidad='1' ImpSaldoAnt='200' ImpPagado='200' ImpSaldoInsoluto='0.00'
        // [THEN] Third invoice line has NumParcialidad='1' ImpSaldoAnt='300' ImpPagado='150' ImpSaldoInsoluto='150'
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.AddAdditionalNamespace('pago10', 'http://www.sat.gob.mx/Pagos');

        CustLedgerEntry.CalcFields("Original String");
        CustLedgerEntry."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        SalesInvoiceHeader.Get(CustLedgerEntryInv[1]."Document No.");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[1].Amount / 2, CustLedgerEntryInv[1].Amount / 2, 0,
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '2', 0);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[2]."Document No.");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[2].Amount, CustLedgerEntryInv[2].Amount, 0,
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 1);

        SalesInvoiceHeader.Get(CustLedgerEntryInv[3]."Document No.");
        CustLedgerEntryInv[3].CalcFields("Remaining Amount");
        VerifyComplementoPago(
          OriginalStr,
          CustLedgerEntryInv[3].Amount, CustLedgerEntryInv[3].Amount / 2, CustLedgerEntryInv[3]."Remaining Amount",
          SalesInvoiceHeader."Fiscal Invoice Number PAC", '1', 2);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithRelationDocumentsRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        EncodedDescr: Text;
        i: Integer;
    begin
        // [SCENARIO 319131] Request Stamp for Sales Invoice with multiple CFDI Related Documents
        Initialize;

        // [GIVEN] Posted Sales Invoice where CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3" for CFDI Relation = '04'
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        SalesInvoiceLine.Description := '"Reparación de lavadora"&''<> ';
        SalesInvoiceLine.Modify();
        EncodedDescr := '&quot;Reparaci&#243;n de lavadora&quot;&amp;&#39;&lt;&gt;';

        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Sales Invoice Header", 0, SalesInvoiceHeader."No.",
              SalesInvoiceHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID, LibraryUtility.GenerateGUID);

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has attribute 'TipoRelacion' = '04' under 'cfdi:CfdiRelacionados'
        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with attributes 'UUID' of "UUID1", "UUID2", "UUID3"
        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:CfdiRelacionados', 'TipoRelacion', SalesInvoiceHeader."CFDI Relation");
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i - 1);
        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto' with Descrition containing encoded special characters (TFS327477)
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'Descripcion', EncodedDescr);

        // [THEN] String for digital stamp has CFDI Relation = '04' following by Fiscal Invoices Numbers "UUID1", "UUID2", "UUID3"
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader."CFDI Relation", SelectStr(14, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader.FieldCaption("CFDI Relation"), OriginalStr));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(14 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
        // [THEN] String for digital stamp contains Descrition with encoded special characters (TFS327477)
        Assert.AreEqual(
          EncodedDescr, SelectStr(30, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceLine.FieldCaption(Description), OriginalStr));
        // [THEN] "Date/Time First Req. Sent" is created in current time zone (TFS 323341)
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesInvoiceHeader."Date/Time First Req. Sent"),
          CreateDateTime(SalesInvoiceHeader."Document Date", Time));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppliedToInvoiceRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 319131] Request Stamp for Sales Credit Memo applied to Sales Invoice
        Initialize;

        // [GIVEN] Posted and stamped Sales Invoice with Fiscal Invoice Number = "UUID-Inv"
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice
        SalesCrMemoHeader.Get(CreatePostApplySalesCrMemo(SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."No."));

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find;
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has attribute 'TipoRelacion' from CFDI Relation of Credit Memo under 'cfdi:CfdiRelacionados'
        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with attribute 'UUID' of "UUID-Inv"
        TempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:CfdiRelacionados', 'TipoRelacion', SalesCrMemoHeader."CFDI Relation");
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader."Fiscal Invoice Number PAC");

        // [THEN] String for digital stamp has CFDI Relation = from Credit Memo following by Fiscal Invoices Numbers "UUID-Inv"
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesCrMemoHeader."CFDI Relation", SelectStr(14, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesCrMemoHeader.FieldCaption("CFDI Relation"), OriginalStr));
        Assert.AreEqual(
          SalesInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(15, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
        // [THEN] "Date/Time First Req. Sent" is created in current time zone (TFS 323341)
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesCrMemoHeader."Date/Time First Req. Sent"),
          CreateDateTime(SalesCrMemoHeader."Document Date", Time));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemosWithRelationAppliedToInvoiceRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 334952] Request Stamp for Sales Credit Memo applied to Sales Invoice with multiple CFDI Related Documents
        Initialize;

        // [GIVEN] Posted and stamped Sales Invoice with Fiscal Invoice Number = "UUID-Inv"
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice
        SalesCrMemoHeader.Get(
          CreatePostApplySalesCrMemo(SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
              SalesCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID, LibraryUtility.GenerateGUID);

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find;
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        TempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader."Fiscal Invoice Number PAC");
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(15, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(15 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppliedToAnotherInvoiceRequestStamp()
    var
        SalesInvoiceHeader1: Record "Sales Invoice Header";
        SalesInvoiceHeader2: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 372201] Request Stamp for Sales Credit Memo applied to Sales Invoice not equal to Applied-to Doc No.
        Initialize();

        // [GIVEN] Posted and stamped two Sales Invoices with Fiscal Invoice Number = "UUID-Inv1", "UUID-Inv2"
        SalesInvoiceHeader1.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomer(
            SalesHeader."Document Type"::Invoice, SalesInvoiceHeader1."Bill-to Customer No.", CreatePaymentMethodForSAT()));
        SalesInvoiceHeader2.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader2."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader2.Find();

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice 1, unapplied and applied to Sales Invoice 2
        SalesCrMemoHeader.Get(CreatePostApplySalesCrMemo(SalesInvoiceHeader1."Bill-to Customer No.", SalesInvoiceHeader1."No."));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::"Credit Memo", CustLedgerEntry."Document Type"::Invoice,
          SalesCrMemoHeader."No.", SalesInvoiceHeader2."No.");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with attribute 'UUID' of "UUID-Inv2"
        TempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader2."Fiscal Invoice Number PAC");

        // [THEN] String for digital stamp has Fiscal Invoice Numbers "UUID-Inv2" of Sales Invoice 2
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader2."Fiscal Invoice Number PAC", SelectStr(15, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader2."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithRelationsAppliedToInvoiceInRelationsRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        CFDIRelationDocumentInv: Record "CFDI Relation Document";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 334952] Request Stamp for Sales Credit Memo applied to Sales Invoice with multiple CFDI Related Documents
        // [SCENARIO 334952] and the Invoice is included in Related Documents
        Initialize;

        // [GIVEN] Posted and stamped Sales Invoice with Fiscal Invoice Number = "UUID-Inv"
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;

        // [GIVEN] Posted Sales Credit Memo applied to the Sales Invoice
        SalesCrMemoHeader.Get(
          CreatePostApplySalesCrMemo(SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
              SalesCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID, LibraryUtility.GenerateGUID);
        // [GIVEN] CFDI Relation Documents has Sales Invoice with "UUID-Inv"
        CreateCFDIRelationDocument(
          CFDIRelationDocumentInv, DATABASE::"Sales Cr.Memo Header", 0, SalesCrMemoHeader."No.",
          SalesCrMemoHeader."Bill-to Customer No.", SalesInvoiceHeader."No.", SalesInvoiceHeader."Fiscal Invoice Number PAC");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find;
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        TempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', SalesInvoiceHeader."Fiscal Invoice Number PAC");
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          SalesInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(15, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, SalesInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(15 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosWithRelationAppliedToInvoiceRequestStamp()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 334952] Request Stamp for Service Credit Memo applied to Service Invoice with multiple CFDI Related Documents
        Initialize;

        // [GIVEN] Posted and stamped Service Invoice with Fiscal Invoice Number = "UUID-Inv"
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find;

        // [GIVEN] Posted Service Credit Memo applied to the Service Invoice
        ServiceCrMemoHeader.Get(
          CreatePostApplyServiceCrMemo(ServiceInvoiceHeader."Bill-to Customer No.", ServiceInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
              ServiceCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID, LibraryUtility.GenerateGUID);

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find;
        ServiceCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        TempBlob.FromRecord(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i - 1);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', ServiceInvoiceHeader."Fiscal Invoice Number PAC", i);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        ServiceCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(14 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
        Assert.AreEqual(
          ServiceInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(15 + i, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, ServiceInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoWithRelationsAppliedToInvoiceInRelationsRequestStamp()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CFDIRelationDocument: array[3] of Record "CFDI Relation Document";
        CFDIRelationDocumentInv: Record "CFDI Relation Document";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        i: Integer;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 334952] Request Stamp for Service Credit Memo applied to Service Invoice with multiple CFDI Related Documents
        // [SCENARIO 334952] and the Invoice is included in Related Documents
        Initialize;

        // [GIVEN] Posted and stamped Service Invoice with Fiscal Invoice Number = "UUID-Inv"
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find;

        // [GIVEN] Posted Service Credit Memo applied to the Service Invoice
        ServiceCrMemoHeader.Get(
          CreatePostApplyServiceCrMemo(ServiceInvoiceHeader."Bill-to Customer No.", ServiceInvoiceHeader."No."));

        // [GIVEN] CFDI Relation Documents has Fiscal Invoice Numbers "UUID1", "UUID2", "UUID3"
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            CreateCFDIRelationDocument(
              CFDIRelationDocument[i], DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
              ServiceCrMemoHeader."Bill-to Customer No.", LibraryUtility.GenerateGUID, LibraryUtility.GenerateGUID);
        // [GIVEN] CFDI Relation Documents has Service Invoice with "UUID-Inv"
        CreateCFDIRelationDocument(
          CFDIRelationDocumentInv, DATABASE::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.",
          ServiceCrMemoHeader."Bill-to Customer No.", ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Fiscal Invoice Number PAC");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find;
        ServiceCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID's of "UUID-Inv", "UUID1", "UUID2", "UUID3"
        TempBlob.FromRecord(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
              'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', CFDIRelationDocument[i]."Fiscal Invoice Number PAC", i - 1);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', ServiceInvoiceHeader."Fiscal Invoice Number PAC", i);

        // [THEN] String for digital stamp has Fiscal Invoices Numbers "UUID-Inv", "UUID1", "UUID2", "UUID3"
        ServiceCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        for i := 1 to ArrayLen(CFDIRelationDocument) do
            Assert.AreEqual(
              CFDIRelationDocument[i]."Fiscal Invoice Number PAC", SelectStr(14 + i, OriginalStr),
              StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationDocument[i]."Fiscal Invoice Number PAC", OriginalStr));
        Assert.AreEqual(
          ServiceInvoiceHeader."Fiscal Invoice Number PAC", SelectStr(15 + i, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, ServiceInvoiceHeader."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoAppliedToAnotherInvoiceRequestStamp()
    var
        ServiceInvoiceHeader1: Record "Service Invoice Header";
        ServiceInvoiceHeader2: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 372201] Request Stamp for Service Credit Memo applied to Service Invoice not equal to Applied-to Doc No.
        Initialize();

        // [GIVEN] Posted and stamped two Service Invoices with Fiscal Invoice Numbers = "UUID-Inv1", "UUID-Inv2"
        ServiceInvoiceHeader1.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));
        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice,
          CreateServiceDocForCustomer(
            ServiceHeader."Document Type"::Invoice, ServiceInvoiceHeader1."Customer No.", CreatePaymentMethodForSAT()));
        ServiceInvoiceHeader2.Get(PostServiceDocument(ServiceHeader));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader2."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader2.Find();

        // [GIVEN] Posted Service Credit Memo applied to the Service Invoice
        ServiceCrMemoHeader.Get(
          CreatePostApplyServiceCrMemo(ServiceInvoiceHeader2."Bill-to Customer No.", ServiceInvoiceHeader2."No."));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::"Credit Memo", CustLedgerEntry."Document Type"::Invoice,
          ServiceCrMemoHeader."No.", ServiceInvoiceHeader2."No.");

        // [WHEN] Request Stamp for the Credit Memo
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado' with 'UUID' = "UUID-Inv2"
        TempBlob.FromRecord(ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:CfdiRelacionados/cfdi:CfdiRelacionado', 'UUID', ServiceInvoiceHeader2."Fiscal Invoice Number PAC");

        // [THEN] String for digital stamp has Fiscal Invoices Number = "UUID-Inv2" of Sales Invoice 2
        ServiceCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          ServiceInvoiceHeader2."Fiscal Invoice Number PAC", SelectStr(15, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, ServiceInvoiceHeader2."Fiscal Invoice Number PAC", OriginalStr));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampSalesInvoiceShipTo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Request Stamp for Sales Invoice in 'Ship-to' Time Zone
        Initialize;
        TableNo := DATABASE::"Sales Invoice Header";

        // [GIVEN] Sales Invoice has 'Ship-To City' and 'Ship-to Post Code' with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Ship-to City"), SalesInvoiceHeader.FieldNo("Ship-to Post Code"), TimeZoneID);

        // [WHEN] Request stamp for the Sales Invoice
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Sales Invoice has 'Date/Time First Req. Sent' with offset 2h from current time
        SalesInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesInvoiceHeader."Date/Time First Req. Sent"),
          CreateDateTime(SalesInvoiceHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampSalesCreditMemoSellTo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Request Stamp for Sales Credit Memo in 'Sell-to' Time Zone
        Initialize;
        TableNo := DATABASE::"Sales Cr.Memo Header";

        // [GIVEN] Sales Credit memo has 'Sell-To City' and 'Sell-to Post Code' with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesCrMemoHeader.FieldNo("No."), DocumentNo,
          SalesCrMemoHeader.FieldNo("Ship-to City"), SalesCrMemoHeader.FieldNo("Ship-to Post Code"), TimeZoneID);

        // [WHEN] Request stamp for the Sales Credit Memo
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Sales Credit Memo has 'Date/Time First Req. Sent' with offset 2h from current time
        SalesCrMemoHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesCrMemoHeader."Date/Time First Req. Sent"),
          CreateDateTime(SalesCrMemoHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampServiceInvoiceBillTo()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Request Stamp for Service Invoice in 'Bill-to' Time Zone
        Initialize;
        TableNo := DATABASE::"Service Invoice Header";

        // [GIVEN] Service Invoice has 'Bill-To City' and 'Bill-to Post Code' with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, ServiceInvoiceHeader.FieldNo("No."), DocumentNo,
          ServiceInvoiceHeader.FieldNo("Ship-to City"), ServiceInvoiceHeader.FieldNo("Ship-to Post Code"), TimeZoneID);

        // [WHEN] Request stamp for the Service Invoice
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Service Invoice has 'Date/Time First Req. Sent' with offset 2h from current time
        ServiceInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(ServiceInvoiceHeader."Date/Time First Req. Sent"),
          CreateDateTime(ServiceInvoiceHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampServiceCreditMemoCust()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Request Stamp for Service Credit Memo for customer with defined Time Zone
        Initialize;
        TableNo := DATABASE::"Service Cr.Memo Header";

        // [GIVEN] Service Credit Memo  has Customer with Post Code of Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, ServiceCrMemoHeader.FieldNo("No."), DocumentNo,
          ServiceCrMemoHeader.FieldNo("Ship-to City"), ServiceCrMemoHeader.FieldNo("Ship-to Post Code"),
          TimeZoneID);

        // [WHEN] Request stamp for the Service Credit Memo
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Service Credit Memo has 'Date/Time First Req. Sent' with offset 2h from current time
        ServiceCrMemoHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(ServiceCrMemoHeader."Date/Time First Req. Sent"),
          CreateDateTime(ServiceCrMemoHeader."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneRequestStampPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostCode: Record "Post Code";
        PaymentNo: Code[20];
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Request Stamp for payment for customer with defined Time Zone
        Initialize;

        // [GIVEN] Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Applied Payment has Customer with Post Code of Time Zone offset = 2h
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        CreatePostCode(PostCode, TimeZoneID);
        UpdateCustomerPostCode(SalesInvoiceHeader."Sell-to Customer No.", PostCode.City, PostCode.Code);

        // [WHEN] Request Stamp for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Customer Ledger Entry has 'Date/Time First Req. Sent' with offset 2h from current time
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(CustLedgerEntry."Date/Time First Req. Sent"),
          CreateDateTime(CustLedgerEntry."Document Date", Time) + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneSendSalesInvoiceShipTo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Send document for Sales Invoice in 'Ship-to' Time Zone
        Initialize;
        TableNo := DATABASE::"Sales Invoice Header";

        // [GIVEN] Stamped Sales Invoice has 'Ship-To City' and 'Ship-to Post Code' with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);
        UpdateDocumentFieldValue(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Electronic Document Status"), SalesInvoiceHeader."Electronic Document Status"::"Stamp Received");
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Ship-to City"), SalesInvoiceHeader.FieldNo("Ship-to Post Code"), TimeZoneID);

        // [WHEN] Send Electronic Document for the Sales Invoice
        RequestStamp(TableNo, DocumentNo, ResponseOption::Success, ActionOption::Send);

        // [THEN] Sales Invoice has 'Date/Time Sent' with offset 2h from current time
        SalesInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesInvoiceHeader."Date/Time Sent"), CurrentDateTime + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneSendPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostCode: Record "Post Code";
        PaymentNo: Code[20];
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Send document for payment for customer with defined Time Zone
        Initialize;

        // [GIVEN] Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Applied and stamped Payment has Customer with Post Code of Time Zone offset = 2h
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        CreatePostCode(PostCode, TimeZoneID);
        UpdateCustomerPostCode(SalesInvoiceHeader."Sell-to Customer No.", PostCode.City, PostCode.Code);
        UpdateDocumentFieldValue(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Document No."), PaymentNo,
          CustLedgerEntry.FieldNo("Electronic Document Status"), CustLedgerEntry."Electronic Document Status"::"Stamp Received");

        // [WHEN] Send Electronic Document for the payment
        RequestStamp(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success, ActionOption::Send);

        // [THEN] Customer Ledger Entry has 'Date/Time Sent' with offset 2h from current time
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(CustLedgerEntry."Date/Time Sent"),
          CurrentDateTime + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneCancelInvoiceShipTo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
        TableNo: Integer;
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Cancel Sales Invoice in 'Ship-to' Time Zone
        Initialize;
        TableNo := DATABASE::"Sales Invoice Header";

        // [GIVEN] Stamped Sales Invoice has 'Ship-To City' and 'Ship-to Post Code' with Time Zone offset = 2h
        DocumentNo := CreateAndPostDoc(TableNo, CreatePaymentMethodForSAT);
        UpdateDocumentFieldValue(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Electronic Document Status"), SalesInvoiceHeader."Electronic Document Status"::"Stamp Received");
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        UpdateDocumentWithTimeZone(
          TableNo, SalesInvoiceHeader.FieldNo("No."), DocumentNo,
          SalesInvoiceHeader.FieldNo("Ship-to City"), SalesInvoiceHeader.FieldNo("Ship-to Post Code"), TimeZoneID);

        // [WHEN] Cancel Sales Invoice
        LibraryVariableStorage.Enqueue(true);
        Cancel(TableNo, DocumentNo, ResponseOption::Success);

        // [THEN] Sales Invoice has 'Date/Time Sent' with offset 2h from current time
        SalesInvoiceHeader.Get(DocumentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(SalesInvoiceHeader."Date/Time Canceled"), CurrentDateTime + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TimeZoneCancelPayment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostCode: Record "Post Code";
        PaymentNo: Code[20];
        TimeZoneID: Text[180];
        TimeZoneOffset: Duration;
        UserOffset: Duration;
    begin
        // [SCENARIO 323341] Cancel payment for customer with defined Time Zone
        Initialize;

        // [GIVEN] Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Applied and stamped Payment has Customer with Post Code of Time Zone offset = 2h
        PaymentNo :=
          CreatePostPayment(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT", '');
        FindTimeZone(TimeZoneID, TimeZoneOffset, UserOffset);
        CreatePostCode(PostCode, TimeZoneID);
        UpdateCustomerPostCode(SalesInvoiceHeader."Sell-to Customer No.", PostCode.City, PostCode.Code);
        UpdateDocumentFieldValue(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Document No."), PaymentNo,
          CustLedgerEntry.FieldNo("Electronic Document Status"), CustLedgerEntry."Electronic Document Status"::"Stamp Received");

        // [WHEN] Cancel payment
        LibraryVariableStorage.Enqueue(true);
        Cancel(DATABASE::"Cust. Ledger Entry", PaymentNo, ResponseOption::Success);

        // [THEN] Customer Ledger Entry has 'Date/Time Canceled' with offset 2h from current time
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyIsNearlyEqualDateTime(
          ConvertTxtToDateTime(CustLedgerEntry."Date/Time Canceled"), CurrentDateTime + TimeZoneOffset - UserOffset);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for G/L Setup
        Initialize;

        // [GIVEN] G/L Setup has blank fields "PAC Code", "PAC Environment", "SAT Certificate"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."PAC Code" := '';
        GeneralLedgerSetup."PAC Environment" := 0;
        GeneralLedgerSetup."SAT Certificate" := '';
        GeneralLedgerSetup.Modify();

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT);

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for "PAC Code", "PAC Environment", "SAT Certificate" fields
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, GeneralLedgerSetup.FieldCaption("SAT Certificate"), GeneralLedgerSetup.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, GeneralLedgerSetup.FieldCaption("PAC Code"), GeneralLedgerSetup.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, GeneralLedgerSetup.FieldCaption("PAC Environment"), GeneralLedgerSetup.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Company Information
        Initialize;

        // [GIVEN] Company Information has blank fields Name, Address, E-Mail, "RFC No.", "SAT Tax Regime Classification", "SAT Postal Code"
        CompanyInformation.Get();
        CompanyInformation.Name := '';
        CompanyInformation.Address := '';
        CompanyInformation."E-Mail" := '';
        CompanyInformation."RFC No." := '';
        CompanyInformation."SAT Tax Regime Classification" := '';
        CompanyInformation."SAT Postal Code" := '';
        CompanyInformation.Modify();

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT);

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Company Information
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption(Name), CompanyInformation.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption(Address), CompanyInformation.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("E-Mail"), CompanyInformation.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("RFC No."), CompanyInformation.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("SAT Tax Regime Classification"), CompanyInformation.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInformation.FieldCaption("SAT Postal Code"), CompanyInformation.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentNoPACDetails()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log when no PAC Details
        Initialize;

        // [GIVEN] PAC Web Service has details with blank address
        GeneralLedgerSetup.Get();

        PACWebService.Get(GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.SetRange("PAC Code", GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.DeleteAll();

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT);

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for missed Web Services PAC Details
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(
            PACDetailDoesNotExistErr, PACWebServiceDetail.TableCaption,
            PACWebService.Code, GeneralLedgerSetup."PAC Environment", PACWebServiceDetail.Type::"Request Stamp"));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(
            PACDetailDoesNotExistErr, PACWebServiceDetail.TableCaption,
            PACWebService.Code, GeneralLedgerSetup."PAC Environment", PACWebServiceDetail.Type::Cancel));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentPACDetailsMissedAddress()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        ErrorMessages: TestPage "Error Messages";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for PAC Details when no Address specified
        Initialize;

        // [GIVEN] PAC Web Service has details with blank address
        GeneralLedgerSetup.Get();

        PACWebService.Get(GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.SetRange("PAC Code", GeneralLedgerSetup."PAC Code");
        PACWebServiceDetail.ModifyAll(Address, '');

        // [GIVEN] Posted Sales Invoice
        DocumentNo := CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT);

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(DATABASE::"Sales Invoice Header", DocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank Address in Web Services PAC Details
        PACWebServiceDetail.FindFirst;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PACWebServiceDetail.FieldCaption(Address), PACWebServiceDetail.RecordId));
        PACWebServiceDetail.FindLast;
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PACWebServiceDetail.FieldCaption(Address), PACWebServiceDetail.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckCustomer()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Customer
        Initialize;

        // [GIVEN] Posted Sales Invoice when Customer has blank values in "RFC No." and "Country/Region Code"
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer."RFC No." := '';
        Customer."Country/Region Code" := '';
        Customer.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Customer Table
        ErrorMessages.Description.AssertEquals(StrSubstNo(IfEmptyErr, Customer.FieldCaption("RFC No."), Customer.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(StrSubstNo(IfEmptyErr, Customer.FieldCaption("Country/Region Code"), Customer.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentHeader()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice
        Initialize;

        // [GIVEN] Posted Sales Invoice with blank fields "Document Date", "Payment Terms Code", "Payment Method Code",
        // [GIVEN] "Bill-to Address", "Bill-to Post Code", "CFDI Purpose", "CFDI Relation"
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceHeader."Document Date" := 0D;
        SalesInvoiceHeader."Payment Terms Code" := '';
        SalesInvoiceHeader."Payment Method Code" := '';
        SalesInvoiceHeader."Bill-to Address" := '';
        SalesInvoiceHeader."Bill-to Post Code" := '';
        SalesInvoiceHeader."CFDI Purpose" := '';
        SalesInvoiceHeader."CFDI Relation" := '';
        SalesInvoiceHeader.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Customer Table
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Document Date"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Payment Terms Code"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Payment Method Code"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Bill-to Address"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("Bill-to Post Code"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("CFDI Purpose"), SalesInvoiceHeader.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceHeader.FieldCaption("CFDI Relation"), SalesInvoiceHeader.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentHeaderSATMissed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice when SAT code is not specified
        Initialize;

        // [GIVEN] Posted Sales Invoice where SAT code is not specified for Payment Terms and Payment Methods
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        PaymentTerms.Get(SalesInvoiceHeader."Payment Terms Code");
        PaymentTerms."SAT Payment Term" := '';
        PaymentTerms.Modify();
        PaymentMethod.Get(SalesInvoiceHeader."Payment Method Code");
        PaymentMethod."SAT Method of Payment" := '';
        PaymentMethod.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Payment Terms and Payment Method tables
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PaymentTerms.FieldCaption("SAT Payment Term"), PaymentTerms.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, PaymentMethod.FieldCaption("SAT Method of Payment"), PaymentMethod.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentLines()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice Lines
        Initialize;

        // [GIVEN] Posted Sales Invoice has line with blank Description, "Unit Price", "Amount Including VAT", "Unit of Measure Code"
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        SalesInvoiceLine.Description := '';
        SalesInvoiceLine."Unit Price" := 0;
        SalesInvoiceLine."Amount Including VAT" := 0;
        SalesInvoiceLine."Unit of Measure Code" := '';
        SalesInvoiceLine.Modify();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Sales Line table
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption(Description), SalesInvoiceLine.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption("Unit Price"), SalesInvoiceLine.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption("Amount Including VAT"), SalesInvoiceLine.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, SalesInvoiceLine.FieldCaption("Unit of Measure Code"), SalesInvoiceLine.RecordId));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentLineTypes()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceLineGL: Record "Sales Invoice Line";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log]
        // [SCENARIO 323132]  Error Log for Sales Invoice Lines of G/L Account Type
        Initialize;

        // [GIVEN] Posted Sales Invoice has lines with type G/L Account
        // [GIVEN] Item and Unit Of Measure with blank SAT codes
        SalesInvoiceHeader.Get(CreateAndPostDoc(DATABASE::"Sales Invoice Header", CreatePaymentMethodForSAT));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        Item.Get(SalesInvoiceLine."No.");
        Item."SAT Item Classification" := '';
        Item.Modify();
        UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code");
        UnitOfMeasure."SAT UofM Classification" := '';
        UnitOfMeasure.Modify();

        SalesInvoiceLineGL := SalesInvoiceLine;
        SalesInvoiceLineGL."Line No." := LibraryUtility.GetNewRecNo(SalesInvoiceLineGL, SalesInvoiceLineGL.FieldNo("Line No."));
        SalesInvoiceLineGL.Type := SalesInvoiceLineGL.Type::"G/L Account";
        SalesInvoiceLineGL."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceLineGL.Insert();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged error for not allowed type in Sales Line
        // [THEN] Item and Unit Of Measure are added with errors of blank fields
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, Item.FieldCaption("SAT Item Classification"), Item.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, UnitOfMeasure.FieldCaption("SAT UofM Classification"), UnitOfMeasure.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(
            WrongFieldValueErr,
            SalesInvoiceLineGL.Type, SalesInvoiceLineGL.FieldCaption(Type), SalesInvoiceLineGL.TableCaption));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorLogCheckDocumentLinesWithRetentions()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Error Log] [Retention]
        // [SCENARIO 389401] Error Log for Sales Invoice Lines with retentions
        Initialize();

        // [GIVEN] Posted Sales Invoice has tree lines
        // [GIVEN] Normal sales line
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(1000, 2000)),
          LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLine.Description := '';
        SalesLine.Modify();
        // [GIVEN] Sales line with negative quantity supposed to be retention line, 'Retention Attached to Line No.' is not assigned
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        // [GIVEN] Retention Sales line with assigned 'Retention Attached to Line No.', 'Retention VAT %' is not assigned
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLine."Retention Attached to Line No." := LibraryRandom.RandIntInRange(1000, 2000);
        SalesLine.Modify();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindSet();

        // [WHEN] Request Stamp Sales Invoice
        ErrorMessages.Trap;
        asserterror
          RequestStamp(
            DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        // [THEN] Error Messages page is opened with logged errors for blank fields in Sales Line table
        Assert.ExpectedMessage(
          StrSubstNo('''%1'' in ''%2: %3,%4'' must not be blank.',
            SalesInvoiceLine.FieldCaption(Description), SalesInvoiceLine.TableCaption,
            SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No."),
          ErrorMessages.Description.Value);
        // [THEN] Warning is registered for the line with negative Quantity and 'Retention Attached to Line No.' = 0
        ErrorMessages.Next;
        SalesInvoiceLine.Next();
        Assert.ExpectedMessage(
          StrSubstNo('''%1'' in ''Document Line: %2,%3'' must be greater than or equal to 0.',
            SalesInvoiceLine.FieldCaption(Quantity),
            SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No."),
          ErrorMessages.Description.Value);
        // [THEN] Warning is registered for the line with line having 'Retention Attached to Line No.' and 'Retention VAT %' = 0
        ErrorMessages.Next;
        SalesInvoiceLine.Next();
        Assert.ExpectedMessage(
          StrSubstNo('''%1'' in ''Document Line: %2,%3'' must not be blank.',
            SalesInvoiceLine.FieldCaption("Retention VAT %"),
            SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No."),
          ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceNormalVATRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 338353] Request Stamp for Sales Invoice with normal VAT
        Initialize;

        // [GIVEN] Posted Sales Invoice with Amount = 100, VAT Amount = 10
        SalesInvoiceHeader.Get(CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'Importe' = 10, 'TipoFactor' = 'Tasa', 'Impuesto' = '003', 'Base' = 100.
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst;
        SalesInvoiceLine."Amount Including VAT" := SalesInvoiceLine.Amount * (1 + SalesInvoiceLine."VAT %" / 100);
        VerifyVATAmountLines(
          OriginalStr, SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount,
          SalesInvoiceLine."VAT %", '003', 0, 0);

        // [THEN] Total VAT Amount is exported as attribute 'cfdi:Impuestos/TotalImpuestosTrasladados' = 10
        // [THEN] XML Document has node 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with total VAT line
        // [THEN] and attributes 'Importe' = 10, 'TipoFactor' = 'Tasa', 'Impuesto' = '003'.
        VerifyVATTotalLine(
          OriginalStr,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, SalesInvoiceLine."VAT %",
          '003', 0, 1, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 38);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceZeroVATRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 338353] Request Stamp for Sales Invoice with normal zero VAT
        Initialize;

        // [GIVEN] Posted Sales Invoice with Amount = 100, VAT Amount = 0
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, CreateCustomer, CreatePaymentMethodForSAT, 0, false, false));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount);

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 100.
        VerifyVATAmountLines(
          OriginalStr, SalesInvoiceHeader.Amount, 0, 0, '002', 0, 0);

        // [THEN] Total VAT Amount is exported as attribute 'cfdi:Impuestos/TotalImpuestosTrasladados' = 10
        // [THEN] XML Document has node 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with total VAT line
        // [THEN] and attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        VerifyVATTotalLine(
          OriginalStr, 0, 0, '002', 0, 1, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', 0, 38);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceVATExemptRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 338353] Request Stamp for Sales Invoice with VAT exemption
        Initialize;

        // [GIVEN] Posted Sales Invoice with Amount = 100 and 'VAT Exemption' marked in VAT Posting Setup
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, CreateCustomer, CreatePaymentMethodForSAT, 0, true, false));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount);

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'TipoFactor' = 'Exento', 'Impuesto' = '002', 'Base' = 100.
        VerifyVATAmountLinesExempt(
          OriginalStr, SalesInvoiceHeader.Amount, '002');

        // [THEN] 'cfdi:Comprobante/cfdi:Impuestos' node is not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('cfdi:Comprobante/cfdi:Impuestos');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceNoTaxableRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 338353] Request Stamp for Sales Invoice with No Taxable VAT
        Initialize;

        // [GIVEN] Posted Sales Invoice with Amount = 100 and 'No Taxable' marked in VAT Posting Setup
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomerWithVAT(
            SalesHeader."Document Type"::Invoice, CreateCustomer, CreatePaymentMethodForSAT, 0, false, true));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find;
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount);

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados node is not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados');

        // [THEN] 'cfdi:Comprobante/cfdi:Impuestos' node is not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('cfdi:Comprobante/cfdi:Impuestos');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDiferentVATLinesStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 387092] Request Stamp for Sales Invoice with lines having different VAT
        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        // [GIVEN] First line of Amount = 100, VAT Amount = 10, second line of Amount = 100, VAT Amount = 20
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer, CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          1, 0, LibraryRandom.RandIntInRange(10, 15), false, false);
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItemWithPrice(LibraryRandom.RandIntInRange(100, 200)),
          1, 0, LibraryRandom.RandIntInRange(16, 20), false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML Document has nodes 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for each line
        // [THEN] Attributes for first line 'Importe' = 10, 'TipoFactor' = 'Tasa', 'Impuesto' = '003', 'Base' = 100.
        // [THEN] Attributes for first line 'Importe' = 20, 'TipoFactor' = 'Tasa', 'Impuesto' = '003', 'Base' = 100.
        // [THEN] Total VAT Amount is exported as attribute 'cfdi:Impuestos/TotalImpuestosTrasladados' = 10
        // [THEN] XML Document has nodes 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with total VAT lines
        // [THEN] Attributes for first line 'Importe' = 10, , TasaOCuota='0.100000', 'TipoFactor' = 'Tasa', 'Impuesto' = '003'.
        // [THEN] Attributes for first line 'Importe' = 20, , TasaOCuota='0.200000', 'TipoFactor' = 'Tasa', 'Impuesto' = '003'.
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        VerifyVATAmountLines(
          OriginalStr, SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount,
          SalesInvoiceLine."VAT %", '003', 0, 0);
        VerifyVATTotalLine(
          OriginalStr,
          SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, SalesInvoiceLine."VAT %",
          '003', 0, 2, 0);
        SalesInvoiceLine.FindLast;
        VerifyVATAmountLines(
          OriginalStr, SalesInvoiceLine.Amount, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount,
          SalesInvoiceLine."VAT %", '003', 1, 1);
        VerifyVATTotalLine(
          OriginalStr,
          SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, SalesInvoiceLine."VAT %",
          '003', 1, 2, 0);
        VerifyTotalImpuestos(
          OriginalStr, 'TotalImpuestosTrasladados', SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 57);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePricesInclVATRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDisc: Record "Sales Line";
        Customer: Record Customer;
        Currency: Record Currency;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        UnitPrice: Decimal;
        LineDiscExclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [VAT] [Prices Including VAT] [Line Discount]
        // [SCENARIO 352547] Request Stamp for Sales Invoice with Prices Including VAT and line discount
        Initialize();

        // [GIVEN] Posted Sales Invoice with VAT% = 15, Prices Including VAT = true
        // [GIVEN] Sales Line 1 has Quantity = 3, Unit Price 1150
        // [GIVEN] Sales Line 2 has Quantity = 2, Unit Price 1150, Line Discount % = 7, Line Discount Amount = 161 (2300 * 7%)
        // [GIVEN] Amount = 4860 (3000 + 2000 + 140 discount no VAT)
        // [GIVEN] Amount Including VAT = 5589 (3450 + 2300 - 161)
        Customer.Get(CreateCustomer());
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomer(SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLineDisc := SalesLine;
        SalesLineDisc."Line No." := 0;
        SalesLineDisc.Validate(Quantity, LibraryRandom.RandIntInRange(3, 5));
        SalesLineDisc.Validate("Line Discount %", LibraryRandom.RandIntInRange(5, 10));
        SalesLineDisc.Insert(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML header has 'Total' = 5589, 'Descuento' = 140, 'SubTotal' = 5000 (4860 + 140)
        Currency.InitRoundingPrecision();
        UnitPrice := SalesLine."Unit Price" * 100 / (100 + SalesLine."VAT %");
        SalesLine."Amount Including VAT" := SalesLine.Amount * (1 + SalesLine."VAT %" / 100);
        SalesLineDisc."Amount Including VAT" := SalesLineDisc.Amount * (1 + SalesLineDisc."VAT %" / 100);
        LineDiscExclVAT := 
          Round(SalesLineDisc."Line Discount Amount" / (1 + SalesLineDisc."VAT %" / 100),Currency."Amount Rounding Precision");
        VerifyRootNodeTotals(
          OriginalStr,
          SalesInvoiceHeader."Amount Including VAT", UnitPrice * (SalesLine.Quantity + SalesLineDisc.Quantity),
          LineDiscExclVAT);

        // [THEN] 'Concepto' node for discount line has 'Descuento' = 140, Importe = 2000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for discount line has 'Importe' = 279 (2300 - 1860 -161), 'Base' = 1860 (2000 - 140)
        VerifyLineAmountsByIndex(
          LineDiscExclVAT, UnitPrice * SalesLineDisc.Quantity, UnitPrice,
          SalesLineDisc."Amount Including VAT" - SalesLineDisc.Quantity * UnitPrice + LineDiscExclVAT,
          UnitPrice * SalesLineDisc.Quantity - LineDiscExclVAT, 0);
        // [THEN] 'Concepto' node for normal line has 'Descuento' = 0, Importe = 3000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for normal line has 'Importe' = 450 (3450 - 3000), 'Base' = 3000        VerifyLineAmountsByIndex(
        VerifyLineAmountsByIndex(
          0, UnitPrice * SalesLine.Quantity, UnitPrice,
          SalesLine."Amount Including VAT" - SalesLine.Amount,
          UnitPrice * SalesLine.Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePricesInclVATRequestStamp()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineDisc: Record "Service Line";
        Customer: Record Customer;
        Currency: Record Currency;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        UnitPrice: Decimal;
        LineDiscExclVAT: Decimal;
    begin
        // [FEATURE] [Service] [VAT] [Prices Including VAT] [Line Discount]
        // [SCENARIO 352547] Request Stamp for Service Invoice with Prices Including VAT and line discount
        Initialize();

        // [GIVEN] Posted Service Invoice with VAT% = 15, Prices Including VAT = true
        // [GIVEN] Service Line 1 has Quantity = 3, Unit Price 1150
        // [GIVEN] Service Line 2 has Quantity = 2, Unit Price 1150, Line Discount % = 7, Line Discount Amount = 161 (2300 * 7%)
        // [GIVEN] Amount = 4860 (3000 + 2000 + 140 discount no VAT)
        // [GIVEN] Amount Including VAT = 5589 (3450 + 2300 - 161)
        Customer.Get(CreateCustomer());
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
        ServiceHeader.Get(
          ServiceHeader."Document Type"::Invoice,
          CreateServiceDocForCustomer(ServiceHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT));
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLineDisc := ServiceLine;
        ServiceLineDisc."Line No." := 0;
        ServiceLineDisc.Validate(Quantity, LibraryRandom.RandIntInRange(3, 5));
        ServiceLineDisc.Validate("Line Discount %", LibraryRandom.RandIntInRange(5, 10));
        ServiceLineDisc.Insert(true);
        ServiceInvoiceHeader.Get(PostServiceDocument(ServiceHeader));

        // [WHEN] Request Stamp for the Service Invoice
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find();
        ServiceInvoiceHeader.CalcFields("Original String", "Original Document XML", Amount, "Amount Including VAT");

        TempBlob.FromRecord(ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        ServiceInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] XML header has 'Total' = 5589, 'Descuento' = 140, 'SubTotal' = 5000 (4860 + 140)
        Currency.InitRoundingPrecision();
        UnitPrice := ServiceLine."Unit Price" * 100 / (100 + ServiceLine."VAT %");
        ServiceLine."Amount Including VAT" := ServiceLine.Amount * (1 + ServiceLine."VAT %" / 100);
        ServiceLineDisc."Amount Including VAT" := ServiceLineDisc.Amount * (1 + ServiceLineDisc."VAT %" / 100);
        LineDiscExclVAT := 
          Round(ServiceLineDisc."Line Discount Amount" / (1 + ServiceLineDisc."VAT %" / 100),Currency."Amount Rounding Precision");
        VerifyRootNodeTotals(
          OriginalStr,
          ServiceInvoiceHeader."Amount Including VAT", UnitPrice * (ServiceLine.Quantity + ServiceLineDisc.Quantity),
          LineDiscExclVAT);

        // [THEN] 'Concepto' node for discount line has 'Descuento' = 140, Importe = 2000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for discount line has 'Importe' = 279 (2300 - 1860 -161), 'Base' = 1860 (2000 - 140)
        VerifyLineAmountsByIndex(
          LineDiscExclVAT, UnitPrice * ServiceLineDisc.Quantity, UnitPrice,
          ServiceLineDisc."Amount Including VAT" - ServiceLineDisc.Quantity * UnitPrice + LineDiscExclVAT,
          UnitPrice * ServiceLineDisc.Quantity - LineDiscExclVAT, 0);
        // [THEN] 'Concepto' node for normal line has 'Descuento' = 0, Importe = 3000, 'ValorUnitario' = 1000
        // [THEN] 'Traslado' node for normal line has 'Importe' = 450 (3450 - 3000), 'Base' = 3000        VerifyLineAmountsByIndex(
        VerifyLineAmountsByIndex(
          0, UnitPrice * ServiceLine.Quantity, UnitPrice,
          ServiceLine."Amount Including VAT" - ServiceLine.Amount,
          UnitPrice * ServiceLine.Quantity, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceNoStampExportPDF()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364057] Error when export electronic document as PDF for Sales Invoice without stamp
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));

        // [WHEN] Export Electronic Document as PDF
        asserterror SalesInvoiceHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicStampErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoNoStampExportPDF()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364057] Error when export electronic document as PDF for Sales Credit Memo without stamp
        Initialize();

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT));

        // [WHEN] Export Electronic Document as PDF
        asserterror SalesCrMemoHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicStampErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceNoStampExportPDF()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 364057] Error when export electronic document as PDF for Service Invoice without stamp
        Initialize();

        // [GIVEN] Posted Service Invoice
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));

        // [WHEN] Export Electronic Document as PDF
        asserterror ServiceInvoiceHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicDocumentSentErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoNoStampExportPDF()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 364057] Error when export electronic document as PDF for Service Credit Memo without stamp
        Initialize();

        // [GIVEN] Posted Service Credit Memo
        ServiceCrMemoHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT));

        // [WHEN] Export Electronic Document as PDF
        asserterror ServiceCrMemoHeader.ExportEDocumentPDF();

        // [THEN] PDF file for the report is created
        Assert.ExpectedError(NoElectronicStampErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithStampExportPDF()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Sales Invoice with stamp
        Initialize();

        // [GIVEN] Posted and stamped Sales Invoice
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        BindSubscription(MXCFDI);
        PostedSalesInvoice.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithStampExportPDF()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Sales Credit Memo with stamp
        Initialize();

        // [GIVEN] Posted and stamped Sales Credit Memo
        SalesCrMemoHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        BindSubscription(MXCFDI);
        PostedSalesCreditMemo.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithStampExportPDF()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceHeader: Record "Service Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Service Invoice with stamp
        Initialize();

        // [GIVEN] Posted and stamped Service Invoice
        ServiceInvoiceHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Service Invoice Header", ServiceInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceInvoiceHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");
        BindSubscription(MXCFDI);
        PostedServiceInvoice.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoWithStampExportPDF()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        // [FEATURE] [Service] [UI] [Export]
        // [SCENARIO 364057] Export electronic document as PDF for Service credit Memo with stamp
        Initialize();

        // [GIVEN] Posted and stamped Service Credit Memo
        ServiceCrMemoHeader.Get(
          CreateAndPostServiceDoc(ServiceHeader."Document Type"::"Credit Memo", CreatePaymentMethodForSAT));
        RequestStamp(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        ServiceCrMemoHeader.Find();

        // [WHEN] Export Electronic Document as PDF
        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", ServiceCrMemoHeader."No.");
        BindSubscription(MXCFDI);
        PostedServiceCreditMemo.ExportEDocumentPDF.Invoke();
        UnbindSubscription(MXCFDI);

        // [THEN] PDF file for the report is created
        VerifyPDFFile();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFixedAssetRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        FANo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364407] Request Stamp for Sales Invoice with fixed asset
        Initialize();

        // [GIVEN] Posted Sales Invoice with fixed asset "FA"
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer, CreatePaymentMethodForSAT);
        FANo := CreateSalesLineFixedAsset(SalesHeader, 0, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] The stamp is received
        SalesInvoiceHeader.TestField("Electronic Document Status", SalesInvoiceHeader."Electronic Document Status"::"Stamp Received");
        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);

        // [THEN] 'Concepto' node has attributes 'ClaveProdServ' = '01010101', 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        // [THEN] String for digital stamp has 'ClaveProdServ' = '01010101', 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        VerifyCFDIFixedAssetFields(OriginalStr, FANo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithFixedAssetRequestStamp()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        FANo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364407] Request Stamp for Sales Credit Memo with fixed asset
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with fixed asset "FA"
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer, CreatePaymentMethodForSAT);
        FANo := CreateSalesLineFixedAsset(SalesHeader, 0, false, false);
        MockFADisposalEntry(FANo);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Credi Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] The stamp is received
        SalesCrMemoHeader.TestField("Electronic Document Status", SalesCrMemoHeader."Electronic Document Status"::"Stamp Received");
        TempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);

        // [THEN] 'Concepto' node has attributes 'ClaveProdServ' = '01010101', 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        // [THEN] String for digital stamp has 'ClaveProdServ' = '01010101', 'NoIdentificacion' = "FA", 'ClaveUnidad' = 'H87'
        VerifyCFDIFixedAssetFields(OriginalStr, FANo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNumeroPedimentoRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [SCENARIO 366659] Request Stamp for Sales Invoice with 'NumeroPedimento'
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, CreatePaymentMethodForSAT()));

        NameValueBuffer.Init;
        NameValueBuffer.ID := CODEUNIT::"MX CFDI";
        NameValueBuffer.Name := '20 16 1742 0001871'; // value for signed string is separated with 1 space
        NameValueBuffer.Value := '20  16  1742  0001871'; // formatted as 2/2/4/7 digits separated with 2 spaces
        NameValueBuffer.Insert;

        // [WHEN] Request Stamp for the Sales Invoice with NumeroPedimento
        BindSubscription(MXCFDI);
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        UnbindSubscription(MXCFDI);

        SalesInvoiceHeader.Find;
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML", "Signed Document XML");

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera' with attribute 'NumeroPedimento' in proper format
        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera', 'NumeroPedimento', NameValueBuffer.Value);

        // [THEN] String for digital stamp has NumeroPedimento exported in proper format
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        Assert.AreEqual(
          NameValueBuffer.Name, SelectStr(35, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumeroPedimento', OriginalStr));

        NameValueBuffer.Delete();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLCYRoundingRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        ItemNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Line Discount] [Rounding]
        // [SCENARIO 368294] Request Stamp for LCY Sales Invoice with multiple lines and "Amount Decimal Places" = 5 in G/L Setup
        Initialize();
        UpdateGLSetupRounding(':5');

        // [GIVEN] G/L Setup has "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5
        // [GIVEN] Posted Sales Invoice with VAT % = 16
        // [GIVEN] 4 lines with Unit Price = 32462.00, Quantity = 1, Line Discount = 5, Amount (without VAT) = 30838.90
        ItemNo := CreateItemWithPrice(32462.0);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        for i := 1 to 4 do
            CreateSalesLineItem(SalesLine, SalesHeader, ItemNo, 1, 5, 16, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.ModifyAll("Amount Including VAT", 35773.124); // emulate posting with 0.00001 rounding precision

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'Importe' = 4934.22400, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 30838.90.
        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Moneda', 'MXN');
        VerifyVATAmountLines(OriginalStr, 30838.9, 4934.224, 16, '002', 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFCYRoundingRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
        ItemNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Line Discount] [Rounding]
        // [SCENARIO 368294] Request Stamp for FCY Sales Invoice with multiple lines and "Amount Decimal Places" = 5 in currency setup
        Initialize();
        UpdateGLSetupRounding(':2');

        // [GIVEN] Customer with currency having "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, 1, 1));
        Customer.Modify(true);
        UpdateCurrencyWithRounding(Customer."Currency Code", 0.00001, ':5');

        // [GIVEN] Posted FCY Sales Invoice with VAT % = 16
        // [GIVEN] 4 lines with Unit Price = 32462.00, Quantity = 1, Line Discount = 5, Amount (without VAT) = 30838.90
        ItemNo := CreateItemWithPrice(32462.0);
        CreateSalesHeaderForCustomer(
          SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CreatePaymentMethodForSAT());
        for i := 1 to 4 do
            CreateSalesLineItem(SalesLine, SalesHeader, ItemNo, 1, 5, 16, false, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");

        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        // [THEN] XML Document has node 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' with VAT data for the line
        // [THEN] and attributes 'Importe' = 4934.22400, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 30838.90.
        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Moneda', Customer."Currency Code");
        VerifyVATAmountLines(OriginalStr, 30838.9, 4934.224, 16, '002', 1, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRetentionRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention: Record "Sales Line";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Retention]
        // [SCENARIO 389401] Request Stamp for Sales Invoice with retention line
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = 1000, VAT Amount = 0
        // [GIVEN] Retention Line with Amount = -100, Retention VAT % = 10
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem, LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        CreateSalesLineItem(
          SalesLineRetention, SalesHeader, CreateItem, -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLineRetention."Retention Attached to Line No." := SalesLine."Line No.";
        SalesLineRetention."Retention VAT %" := LibraryRandom.RandIntInRange(10, 20);
        SalesLineRetention.Modify();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Subtotal = 1000, Total = 900
        VerifyRootNodeTotals(
          OriginalStr, SalesLine."Amount Including VAT" + SalesLineRetention."Amount Including VAT", SalesLine."Amount Including VAT", 0);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado'
        // [THEN] has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 100, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        VerifyVATAmountLines(
          OriginalStr, SalesLine."Amount Including VAT", 0, 0, '002', 0, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine."Amount Including VAT", SalesLineRetention."Amount Including VAT", SalesLineRetention."Retention VAT %", '002', 39, 0);

        // [THEN] 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        // [THEN] 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 100, 'Impuesto' = '002'.
        VerifyVATTotalLine(OriginalStr, 0, 0, '002', 0, 1, 8);
        VerifyRetentionTotalLine(OriginalStr, -SalesLineRetention."Amount Including VAT", '002', 40, 0);

        // [THEN] Total Impuestos:  'cfdi:Impuestos/TotalImpuestosTrasladados' = 0, 'cfdi:Impuestos/TotalImpuestosRetenidos' = 100
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', 0, 46);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosRetenidos', -SalesLineRetention."Amount Including VAT", 41);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoRetentionRequestStamp()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention: Record "Sales Line";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Retention]
        // [SCENARIO 389401] Request Stamp for Sales Credit Memo with retention line
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Amount = 1000, VAT Amount = 0
        // [GIVEN] Retention Line with Amount = -100, Retention VAT % = 10
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem, LibraryRandom.RandIntInRange(100, 200), 0, 0, false, false);
        CreateSalesLineItem(
          SalesLineRetention, SalesHeader, CreateItem, -LibraryRandom.RandIntInRange(1, 10), 0, 0, false, false);
        SalesLineRetention."Retention Attached to Line No." := SalesLine."Line No.";
        SalesLineRetention."Retention VAT %" := LibraryRandom.RandIntInRange(10, 20);
        SalesLineRetention.Modify();
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Credit Memo
        RequestStamp(
          DATABASE::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.CalcFields("Original String", "Original Document XML");

        TempBlob.FromRecord(SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesCrMemoHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Subtotal = 1000, Total = 900
        VerifyRootNodeTotals(
          OriginalStr, SalesLine."Amount Including VAT" + SalesLineRetention."Amount Including VAT", SalesLine."Amount Including VAT", 0);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado'
        // [THEN] has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 100, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 1000.
        VerifyVATAmountLines(
          OriginalStr, SalesLine."Amount Including VAT", 0, 0, '002', 0, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine."Amount Including VAT", SalesLineRetention."Amount Including VAT", SalesLineRetention."Retention VAT %", '002', 39, 0);

        // [THEN] 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has attributes 'Importe' = 0, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        // [THEN] 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 100, 'Impuesto' = '002'.
        VerifyVATTotalLine(OriginalStr, 0, 0, '002', 0, 1, 8);
        VerifyRetentionTotalLine(OriginalStr, -SalesLineRetention."Amount Including VAT", '002', 40, 0);

        // [THEN] Total Impuestos:  'cfdi:Impuestos/TotalImpuestosTrasladados' = 0, 'cfdi:Impuestos/TotalImpuestosRetenidos' = 100
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', 0, 46);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosRetenidos', -SalesLineRetention."Amount Including VAT", 41);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceRetentionTwoLinesRequestStamp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineRetention1: Record "Sales Line";
        SalesLineRetention2: Record "Sales Line";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OriginalStr: Text;
    begin
        // [FEATURE] [Retention]
        // [SCENARIO 389401] Request Stamp for Sales Invoice with two retention lines
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = 78000, VAT Amount = 12480, VAT % = 16
        // [GIVEN] Retention Line 1 with Amount = -7800, Retention VAT % = 10
        // [GIVEN] Retention Line 2 with Amount = -8319.948, Retention VAT % = 10.6666
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(), CreatePaymentMethodForSAT());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem, 1, 0, 16, false, false);
        SalesLine.Validate("Unit Price", 78000);
        SalesLine.Modify(true);
        CreateRetentionSalesLine(
          SalesLineRetention1, SalesHeader, SalesLine."Line No.", -1, SalesLine.Amount, 10);
        CreateRetentionSalesLine(
          SalesLineRetention2, SalesHeader, SalesLine."Line No.", -1, SalesLine.Amount, 10.6666);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Request Stamp for the Sales Invoice
        RequestStamp(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader."No.", ResponseOption::Success, ActionOption::"Request Stamp");
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields("Original String", "Original Document XML");

        TempBlob.FromRecord(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', 'http://www.sat.gob.mx/cfd/3');
        SalesInvoiceHeader."Original String".CreateInStream(InStream);
        InStream.ReadText(OriginalStr);
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        // [THEN] Subtotal = 78000, Total = 74360.05 (78000 + 12480 - 7800 - 8319.948)
        VerifyRootNodeTotals(
          OriginalStr,
          SalesLine."Amount Including VAT" + SalesLineRetention1."Amount Including VAT" + SalesLineRetention2."Amount Including VAT",
          SalesLine.Amount, 0);

        // [THEN] 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado'
        // [THEN] has attributes 'Importe' = 12480, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 78000.
        // [THEN] Line 1 of 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 7800, 'TipoFactor' = 'Tasa', 'Impuesto' = '001', 'Base' = 78000.
        // [THEN] Line 2 of 'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion'
        // [THEN] has attributes 'Importe' = 8319.948, 'TipoFactor' = 'Tasa', 'Impuesto' = '002', 'Base' = 78000.
        VerifyVATAmountLines(
          OriginalStr,
          SalesLine.Amount, SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."VAT %", '002', 0, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine.Amount, SalesLineRetention1.Amount, SalesLineRetention1."Retention VAT %", '001', 39, 0);
        VerifyRetentionAmountLine(
          OriginalStr,
          SalesLine.Amount,
          SalesLineRetention2."Unit Price" * SalesLineRetention2.Quantity, SalesLineRetention2."Retention VAT %", '002', 44, 1);

        // [THEN] 'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado' has attributes 'Importe' = 12480, 'TipoFactor' = 'Tasa', 'Impuesto' = '002'.
        // [THEN] Line 1 of 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 7800, 'Impuesto' = '001'.
        // [THEN] Line 2 of 'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion' has attributes 'Importe' = 8319.95, 'Impuesto' = '002'.
        VerifyVATTotalLine(
          OriginalStr, SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."VAT %", '002', 0, 1, 15);
        VerifyRetentionTotalLine(OriginalStr, -SalesLineRetention1."Amount Including VAT", '001', 45, 0);
        VerifyRetentionTotalLine(OriginalStr, -SalesLineRetention2."Amount Including VAT", '002', 47, 1);

        // [THEN] Total Impuestos:  'cfdi:Impuestos/TotalImpuestosTrasladados' = 12480, 'cfdi:Impuestos/TotalImpuestosRetenidos' = 16119.95
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosTrasladados', SalesLine."Amount Including VAT" - SalesLine.Amount, 54);
        VerifyTotalImpuestos(OriginalStr, 'TotalImpuestosRetenidos',
          SalesLineRetention1.Amount + SalesLineRetention2.Amount, 49);
    end;

    local procedure Initialize()
    var
        PostCode: Record "Post Code";
    begin
        LibrarySetupStorage.Restore;
        SetupPACService;
        LibraryVariableStorage.Clear;

        NameValueBuffer.SetRange(Name, Format(CODEUNIT::"MX CFDI"));
        NameValueBuffer.DeleteAll();
        PostCode.ModifyAll("Time Zone", '');
        SetupCompanyInformation;
        ClearLastError;

        if isInitialized then
            exit;

        LibrarySales.SetCreditWarningsToNoWarnings;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        SATUtilities.PopulateSATInformation;
        isInitialized := true;
        Commit();
    end;

    local procedure Cancel(TableNo: Integer; PostedDocumentNo: Code[20]; Response: Option)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        MockCancel(Response, TempBlob);
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.Modify(true);
                    SalesInvoiceHeader.CancelEDocument;
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.Modify(true);
                    SalesCrMemoHeader.CancelEDocument;
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.Modify(true);
                    ServiceInvoiceHeader.CancelEDocument;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.Modify(true);
                    ServiceCrMemoHeader.CancelEDocument;
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedDocumentNo);
                    RecordRef.GetTable(CustLedgerEntry);
                    TempBlob.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(CustLedgerEntry);
                    CustLedgerEntry.Modify(true);
                    CustLedgerEntry.CancelEDocument;
                end;
        end;
    end;

    local procedure CreateDoc(TableNo: Integer; PaymentMethodCode: Code[10]) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                DocumentNo := CreateSalesDocWithPaymentMethodCode(SalesHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Sales Cr.Memo Header":
                DocumentNo := CreateSalesDocWithPaymentMethodCode(SalesHeader."Document Type"::"Credit Memo", PaymentMethodCode);
            DATABASE::"Service Invoice Header":
                DocumentNo := CreateServiceDocWithPaymentMethodCode(ServiceHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Service Cr.Memo Header":
                DocumentNo := CreateServiceDocWithPaymentMethodCode(ServiceHeader."Document Type"::"Credit Memo", PaymentMethodCode);
        end;
    end;

    local procedure CreateAndPostDoc(TableNo: Integer; PaymentMethodCode: Code[10]) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                PostedDocumentNo := CreateAndPostSalesDoc(SalesHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Sales Cr.Memo Header":
                PostedDocumentNo := CreateAndPostSalesDoc(SalesHeader."Document Type"::"Credit Memo", PaymentMethodCode);
            DATABASE::"Service Invoice Header":
                PostedDocumentNo := CreateAndPostServiceDoc(ServiceHeader."Document Type"::Invoice, PaymentMethodCode);
            DATABASE::"Service Cr.Memo Header":
                PostedDocumentNo := CreateAndPostServiceDoc(ServiceHeader."Document Type"::"Credit Memo", PaymentMethodCode);
        end;
    end;

    local procedure CreateSalesDocWithPaymentMethodCode(DocumentType: Option; PaymentMethodCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(
          DocumentType, CreateSalesDocForCustomer(DocumentType, CreateCustomer, PaymentMethodCode));
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocForCustomer(DocumentType: Option; CustomerNo: Code[20]; PaymentMethodCode: Code[10]): Code[20]
    begin
        exit(
          CreateSalesDocForCustomerWithVAT(DocumentType, CustomerNo, PaymentMethodCode, LibraryRandom.RandIntInRange(10, 20), false, false));
    end;

    local procedure CreateSalesDocForCustomerWithVAT(DocumentType: Option; CustomerNo: Code[20]; PaymentMethodCode: Code[10]; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderForCustomer(SalesHeader, DocumentType, CustomerNo, PaymentMethodCode);
        CreateSalesLineItem(
          SalesLine, SalesHeader, CreateItem, LibraryRandom.RandInt(10), 0, VATPct, IsVATExempt, IsNoTaxable);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesHeaderForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerNo: Code[20]; PaymentMethodCode: Code[10]): Code[20]
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTermsForSAT);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Bill-to Address", SalesHeader."Sell-to Customer No.");
        SalesHeader.Validate("Bill-to Post Code", SalesHeader."Sell-to Customer No.");
        SalesHeader.Validate("CFDI Purpose", CreateCFDIPurpose);
        SalesHeader.Validate("CFDI Relation", CreateCFDIRelation);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LineDiscountPct: Decimal; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate(
          "VAT Prod. Posting Group", CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", VATPct, IsVATExempt, IsNoTaxable));
        SalesLine.Validate(Description, SalesLine."No.");
        SalesLine.Validate("Line Discount %", LineDiscountPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineFixedAsset(SalesHeader: Record "Sales Header"; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean): Code[20]
    var
        SalesLine: Record "Sales Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateFixedAsset(FADepreciationBook);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FADepreciationBook."FA No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate(
          "VAT Prod. Posting Group", CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", VATPct, IsVATExempt, IsNoTaxable));
        SalesLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        SalesLine.Validate(Description, SalesLine."No.");
        SalesLine.Modify(true);
        exit(FADepreciationBook."FA No.");
    end;

    local procedure CreateAndPostSalesDoc(DocumentType: Option; PaymentMethodCode: Code[10]) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocWithPaymentMethodCode(DocumentType, PaymentMethodCode));
        PostedDocumentNo := NoSeriesManagement.GetNextNo(SalesHeader."Posting No. Series", WorkDate, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
    begin
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateSalesDocForCustomer(SalesHeader."Document Type"::Invoice, CustomerNo, CreatePaymentMethodForSAT()));
        SalesHeader.Modify(true);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);
    end;

    local procedure CreateRetentionSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineNo: Integer; Quantity: Decimal; BaseAmount: Decimal; RetentionVATPct: Decimal)
    begin
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem, Quantity, 0, 0, false, false);
        SalesLine.Validate("Retention Attached to Line No.", LineNo);
        SalesLine.Validate("Retention VAT %", RetentionVATPct);
        SalesLine.Validate("Unit Price", BaseAmount * RetentionVATPct / 100);
        SalesLine.Modify(true);
    end;

    local procedure CreatePostApplySalesCrMemo(CustomerNo: Code[20]; InvoiceNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(
          SalesHeader."Document Type"::"Credit Memo",
          CreateSalesDocForCustomer(SalesHeader."Document Type"::"Credit Memo", CustomerNo, CreatePaymentMethodForSAT));
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateServiceDocWithPaymentMethodCode(DocumentType: Option; PaymentMethodCode: Code[10]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(
          DocumentType, CreateServiceDocForCustomer(DocumentType, CreateCustomer, PaymentMethodCode));
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceDocForCustomer(DocumentType: Option; CustomerNo: Code[20]; PaymentMethodCode: Code[10]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Payment Terms Code", CreatePaymentTermsForSAT);
        ServiceHeader.Validate("Bill-to Address", ServiceHeader."Customer No.");
        ServiceHeader.Validate("Bill-to Post Code", ServiceHeader."Customer No.");
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Validate("CFDI Purpose", CreateCFDIPurpose);
        ServiceHeader.Validate("CFDI Relation", CreateCFDIRelation);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem);
        ServiceLine.Validate(Description, ServiceLine."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateAndPostServiceDoc(DocumentType: Option; PaymentMethodCode: Code[10]) PostedDocumentNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        ServiceHeader.Get(DocumentType, CreateServiceDocWithPaymentMethodCode(DocumentType, PaymentMethodCode));
        PostedDocumentNo := NoSeriesManagement.GetNextNo(ServiceHeader."Posting No. Series", WorkDate, false);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreatePostApplyServiceCrMemo(CustomerNo: Code[20]; InvoiceNo: Code[20]) PostedDocumentNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        ServiceHeader.Get(
          ServiceHeader."Document Type"::"Credit Memo",
          CreateServiceDocForCustomer(ServiceHeader."Document Type"::"Credit Memo", CustomerNo, CreatePaymentMethodForSAT));
        ServiceHeader.Validate("Applies-to Doc. Type", ServiceHeader."Applies-to Doc. Type"::Invoice);
        ServiceHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        ServiceHeader.Modify(true);
        PostedDocumentNo := NoSeriesManagement.GetNextNo(ServiceHeader."Posting No. Series", WorkDate, false);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail);
        Customer.Validate("RFC No.", GenerateString(12));  // Valid RFC No.
        CountryRegion.FindFirst;
        CountryRegion."SAT Country Code" := CountryRegion.Code;
        CountryRegion.Modify();
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    begin
        exit(
          CreateItemWithPrice(LibraryRandom.RandDec(1000, 2)));
    end;

    local procedure CreateItemWithPrice(UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SATClassification: Record "SAT Classification";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item."SAT Item Classification" := LibraryUtility.GenerateRandomCode(Item.FieldNo("SAT Item Classification"), DATABASE::Item);
        Item.Modify(true);
        SATClassification."SAT Classification" := Item."SAT Item Classification";
        SATClassification.Insert();
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        UnitOfMeasure."SAT UofM Classification" := UnitOfMeasure.Code;
        UnitOfMeasure.Modify();
        exit(Item."No.");
    end;

    local procedure CreateFixedAsset(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("Allow Correction of Disposal", true);
        DepreciationBook.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Acquisition Date", WorkDate);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreatePostPayment(CustomerNo: Code[20]; ApplToDocNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePaymentMethodForSAT(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
        SATPaymentMethod: Record "SAT Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."SAT Method of Payment" := PaymentMethod.Code;
        PaymentMethod.Modify();
        SATPaymentMethod.Code := PaymentMethod."SAT Method of Payment";
        SATPaymentMethod.Insert();
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePaymentTermsForSAT(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        SATPaymentTerm: Record "SAT Payment Term";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms."SAT Payment Term" := PaymentTerms.Code;
        PaymentTerms.Modify();
        SATPaymentTerm.Code := PaymentTerms."SAT Payment Term";
        SATPaymentTerm.Insert();
        exit(PaymentTerms.Code);
    end;

    local procedure CreateCFDIPurpose(): Code[10]
    var
        SATUseCode: Record "SAT Use Code";
    begin
        SATUseCode.Init();
        SATUseCode."SAT Use Code" := LibraryUtility.GenerateRandomCode(SATUseCode.FieldNo("SAT Use Code"), DATABASE::"SAT Use Code");
        SATUseCode.Insert();
        exit(SATUseCode."SAT Use Code");
    end;

    local procedure CreateCFDIRelation(): Code[10]
    var
        SATRelationshipType: Record "SAT Relationship Type";
    begin
        SATRelationshipType.Init();
        SATRelationshipType."SAT Relationship Type" :=
          LibraryUtility.GenerateRandomCode(SATRelationshipType.FieldNo("SAT Relationship Type"), DATABASE::"SAT Relationship Type");
        SATRelationshipType.Insert();
        exit(SATRelationshipType."SAT Relationship Type");
    end;

    [Scope('OnPrem')]
    procedure CreateCFDIRelationDocument(var CFDIRelationDocument: Record "CFDI Relation Document"; TableID: Integer; DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]; RelatedDocumentNo: Code[20]; FiscalInvoiceNumberPAC: Text[50])
    begin
        CFDIRelationDocument.Init();
        CFDIRelationDocument."Document Table ID" := TableID;
        CFDIRelationDocument."Document Type" := DocumentType;
        CFDIRelationDocument."Document No." := DocumentNo;
        CFDIRelationDocument."Customer No." := CustomerNo;
        CFDIRelationDocument."Related Doc. No." := RelatedDocumentNo;
        CFDIRelationDocument."Fiscal Invoice Number PAC" := FiscalInvoiceNumberPAC;
        CFDIRelationDocument.Insert();
    end;

    local procedure CreateIsolatedCertificate(): Code[20]
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        IsolatedCertificate.Code := LibraryUtility.GenerateGUID;
        IsolatedCertificate.ThumbPrint := IsolatedCertificate.Code;
        IsolatedCertificate.Insert();
        exit(IsolatedCertificate.Code);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code"; TimeZoneID: Text[180])
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode."Time Zone" := TimeZoneID;
        PostCode.Modify();
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATPct: Decimal; IsVATExempt: Boolean; IsNoTaxable: Boolean): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo);
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("CFDI VAT Exemption", IsVATExempt);
        VATPostingSetup.Validate("CFDI Non-Taxable", IsNoTaxable);
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID;
        VATPostingSetup.Modify(true);
        exit(VATProductPostingGroup.Code);
    end;

    local procedure GenerateString(Length: Integer) String: Text[30]
    var
        I: Integer;
        GUIDLength: Integer;
    begin
        String := LibraryUtility.GenerateGUID;
        GUIDLength := StrLen(String);
        for I := GUIDLength to Length do begin
            String := InsStr(String, Format(LibraryRandom.RandInt(9)), I);
            I += 1;
        end;
    end;

    local procedure PostSalesDocBlankPaymentMethodCode(DocumentType: Option)
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        DocumentNo := CreateSalesDocWithPaymentMethodCode(DocumentType, '');
        SalesHeader.Get(DocumentType, DocumentNo);

        // Verify
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(MissingSalesPaymentMethodCodeExceptionErr);
    end;

    local procedure PostServiceDocBlankPaymentMethodCode(DocumentType: Option)
    var
        ServiceHeader: Record "Service Header";
        DocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        DocumentNo := CreateServiceDocWithPaymentMethodCode(DocumentType, '');
        ServiceHeader.Get(DocumentType, DocumentNo);

        // Verify
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Assert.ExpectedError(MissingServicePaymentMethodCodeExceptionErr);
    end;

    local procedure PostSalesDocBlankUnitOfMeasureCode(DocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        DocumentNo := CreateSalesDocWithPaymentMethodCode(DocumentType, CreatePaymentMethodForSAT);
        SalesHeader.Get(DocumentType, DocumentNo);

        // Verify
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;

        asserterror SalesLine.Validate("Unit of Measure Code", '');
        Assert.ExpectedError(MissingSalesUnitOfMeasureExcErr);
    end;

    local procedure PostServiceDocBlankUnitOfMeasureCode(DocumentType: Option Quote,"Order",Invoice,"Credit Memo")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        DocumentNo := CreateServiceDocWithPaymentMethodCode(DocumentType, CreatePaymentMethodForSAT);
        ServiceHeader.Get(DocumentType, DocumentNo);

        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst;

        // Verify
        asserterror ServiceLine.Validate("Unit of Measure Code", '');
        Assert.ExpectedError(MissingServiceUnitOfMeasureExcErr);
    end;

    local procedure PostServiceDocument(var ServiceHeader: Record "Service Header") PostedDocumentNo: Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        PostedDocumentNo := NoSeriesManagement.GetNextNo(ServiceHeader."Posting No. Series", WorkDate, false);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure PostAndPrint(TableNo: Integer; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        SalesPostPrint: Codeunit "Sales-Post + Print";
        ServicePostPrint: Codeunit "Service-Post+Print";
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocumentNo);
                    SalesPostPrint.Run(SalesHeader);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", DocumentNo);
                    SalesPostPrint.Run(SalesHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, DocumentNo);
                    ServicePostPrint.PostDocument(ServiceHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", DocumentNo);
                    ServicePostPrint.PostDocument(ServiceHeader);
                end;
        end;
    end;

    local procedure RequestStamp(TableNo: Integer; PostedDocumentNo: Code[20]; Response: Option; "Action": Option)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        MockRequestStamp(Response, TempBlob);
        LibraryVariableStorage.Enqueue(Action);
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.Modify(true);
                    SalesInvoiceHeader.RequestStampEDocument;
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.Modify(true);
                    SalesCrMemoHeader.RequestStampEDocument;
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.Modify(true);
                    ServiceInvoiceHeader.RequestStampEDocument;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.Modify(true);
                    ServiceCrMemoHeader.RequestStampEDocument;
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedDocumentNo);
                    RecordRef.GetTable(CustLedgerEntry);
                    TempBlob.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(CustLedgerEntry);
                    CustLedgerEntry.Modify();
                    CustLedgerEntry.RequestStampEDocument;
                end;
        end;
    end;

    local procedure SetupCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        PostCode.SetFilter(City, '<>%1', '');
        PostCode.SetFilter("Country/Region Code", '<>%1', '');
        PostCode.FindFirst;

        CompanyInformation.Get();
        CompanyInformation.Validate("RFC No.", GenerateString(12));
        CompanyInformation.Validate("Country/Region Code", PostCode."Country/Region Code");
        CompanyInformation.Validate(City, PostCode.City);
        CompanyInformation.Validate("Post Code", PostCode.Code);
        CompanyInformation.Validate("SAT Postal Code", Format(LibraryRandom.RandIntInRange(10000, 99999)));
        CompanyInformation.Validate("E-Mail", LibraryUtility.GenerateRandomEmail);
        CompanyInformation.Validate("Tax Scheme", LibraryUtility.GenerateGUID);
        CompanyInformation."SAT Tax Regime Classification" :=
          LibraryUtility.GenerateRandomCode(
            CompanyInformation.FieldNo("SAT Tax Regime Classification"), DATABASE::"Company Information");
        CompanyInformation.Modify(true);
    end;

    local procedure SendSalesStampRequestBlankTaxSchemeError(DocumentType: Option; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Tax Scheme", '');
        CompanyInfo.Modify(true);

        // Exercise
        PostedDocumentNo := CreateAndPostSalesDoc(DocumentType, CreatePaymentMethodForSAT);

        // Verify
        ErrorMessages.Trap;
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Tax Scheme"), CompanyInfo.RecordId));
    end;

    local procedure SendServiceStampRequestBlankTaxSchemeError(DocumentType: Option; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Tax Scheme", '');
        CompanyInfo.Modify(true);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceDoc(DocumentType, CreatePaymentMethodForSAT);

        // Verify
        ErrorMessages.Trap;
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Tax Scheme"), CompanyInfo.RecordId));
    end;

    local procedure SendSalesStampRequestBlankCountryCodeError(DocumentType: Option; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Country/Region Code", '');
        CompanyInfo.Modify();

        // Exercise
        PostedDocumentNo := CreateAndPostSalesDoc(DocumentType, CreatePaymentMethodForSAT);

        // Verify
        ErrorMessages.Trap;
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption(City), CompanyInfo.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Country/Region Code"), CompanyInfo.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Post Code"), CompanyInfo.RecordId));
    end;

    local procedure SendServiceStampRequestBlankCountryCodeError(DocumentType: Option; TableNo: Integer)
    var
        CompanyInfo: Record "Company Information";
        ErrorMessages: TestPage "Error Messages";
        PostedDocumentNo: Code[20];
    begin
        // Setup
        SetupPACEnvironment(GLSetup."PAC Environment"::Test);

        CompanyInfo.Get();
        CompanyInfo.Validate("Country/Region Code", '');
        CompanyInfo.Modify(true);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceDoc(DocumentType, CreatePaymentMethodForSAT);

        // Verify
        ErrorMessages.Trap;
        asserterror RequestStamp(TableNo, PostedDocumentNo, ResponseOption::Success, ActionOption::"Request Stamp");
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption(City), CompanyInfo.RecordId));
        ErrorMessages.Next;
        ErrorMessages.Description.AssertEquals(
          StrSubstNo(IfEmptyErr, CompanyInfo.FieldCaption("Country/Region Code"), CompanyInfo.RecordId));
    end;

    local procedure SetupPACEnvironment(PACEnvironment: Option)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("PAC Environment", PACEnvironment);
        GLSetup.Modify(true)
    end;

    local procedure SetupPACService()
    var
        GLSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        ReportSelections: Record "Report Selections";
    begin
        with PACWebService do begin
            Init;
            Validate(Code, LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"PAC Web Service"));
            Validate(Name, Code);
            Certificate := CreateIsolatedCertificate;
            Insert(true);
        end;

        with PACWebServiceDetail do begin
            Init;
            Validate("PAC Code", PACWebService.Code);
            Validate(Environment, Environment::Test);

            Validate("Method Name", LibraryUtility.GenerateRandomCode(FieldNo("Method Name"), DATABASE::"PAC Web Service Detail"));
            Validate(Address, LibraryUtility.GenerateRandomCode(FieldNo(Address), DATABASE::"PAC Web Service Detail"));

            Validate(Type, Type::"Request Stamp");
            Insert(true);

            Validate(Type, Type::Cancel);
            Insert(true);
        end;

        with GLSetup do begin
            Get;
            Validate("PAC Code", PACWebService.Code);
            Validate("PAC Environment", PACWebServiceDetail.Environment);
            Validate("Sim. Signature", true);
            Validate("Sim. Send", true);
            Validate("Sim. Request Stamp", true);
            Validate("Send PDF Report", true);
            "SAT Certificate" := CreateIsolatedCertificate;
            Modify(true);
        end;

        SetupReportSelection(ReportSelections.Usage::"S.Invoice", 10477);
        SetupReportSelection(ReportSelections.Usage::"S.Cr.Memo", 10476);
        SetupReportSelection(ReportSelections.Usage::"SM.Invoice", 10479);
        SetupReportSelection(ReportSelections.Usage::"SM.Credit Memo", 10478);
    end;

    local procedure SetupReportSelection(UsageOption: Option; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, UsageOption);
        ReportSelections.DeleteAll(true);
        ReportSelections.Init();
        ReportSelections.Validate(Usage, UsageOption);
        ReportSelections.Validate(Sequence, '1');
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Insert(true);
    end;

    local procedure Verify(TableNo: Integer; PostedDocumentNo: Code[20]; ExpectedStatus: Option; NoOfEmailsSent: Integer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        GLSetup: Record "General Ledger Setup";
        DummyTempBlob: Codeunit "Temp Blob";
        ExpectedNoOfEmailsSent: Integer;
        ExpectedDateTimeCanceledEmpty: Boolean;
        ExpectedDateTimeSentEmpty: Boolean;
        ExpectedDateTimeStamped: Text[50];
        ExpectedPACCode: Code[10];
        ExpectedInvoiceNoPAC: Text[50];
        ExpectedErrorCode: Code[10];
        ExpectedErrorDesc: Text[250];
        ExpectedDigitalStamp: Text[250];
    begin
        GLSetup.Get();
        ExpectedPACCode := GLSetup."PAC Code";
        ExpectedDateTimeStamped := DateTimeStampedTxt;
        ExpectedInvoiceNoPAC := FiscalInvoiceNumberPACTxt;
        ExpectedErrorCode := '';
        ExpectedErrorDesc := '';
        ExpectedNoOfEmailsSent := 0;
        ExpectedDateTimeSentEmpty := true;
        ExpectedDateTimeCanceledEmpty := true;
        ExpectedDigitalStamp := DigitalStampTxt;

        case ExpectedStatus of
            StatusOption::"Stamp Request Error":
                begin
                    ExpectedDateTimeStamped := '';
                    ExpectedInvoiceNoPAC := '';
                    ExpectedErrorCode := ErrorCodeTxt;
                    ExpectedErrorDesc := ErrorDescriptionTxt;
                    ExpectedDigitalStamp := '';
                end;
            StatusOption::Sent:
                begin
                    ExpectedNoOfEmailsSent := NoOfEmailsSent + 1;
                    ExpectedDateTimeSentEmpty := false;
                end;
            StatusOption::Canceled:
                ExpectedDateTimeCanceledEmpty := false;
            StatusOption::"Cancel Error":
                begin
                    ExpectedErrorCode := ErrorCodeTxt;
                    ExpectedErrorDesc := ErrorDescriptionTxt;
                end;
        end;

        case TableNo of
            DATABASE::"Sales Invoice Header":
                with SalesInvoiceHeader do begin
                    Get(PostedDocumentNo);
                    TestField("Electronic Document Status", ExpectedStatus);
                    TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, "Date/Time Sent" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, "Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Canceled")));
                    TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    TestField("PAC Web Service Name", ExpectedPACCode);
                    TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    TestField("Error Code", ExpectedErrorCode);
                    TestField("Error Description", ExpectedErrorDesc);
                    CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(SalesInvoiceHeader, FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                end;
            DATABASE::"Sales Cr.Memo Header":
                with SalesCrMemoHeader do begin
                    Get(PostedDocumentNo);
                    TestField("Electronic Document Status", ExpectedStatus);
                    TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, "Date/Time Sent" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, "Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Canceled")));
                    TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    TestField("PAC Web Service Name", ExpectedPACCode);
                    TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    TestField("Error Code", ExpectedErrorCode);
                    TestField("Error Description", ExpectedErrorDesc);
                    CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(SalesCrMemoHeader, FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                end;
            DATABASE::"Service Invoice Header":
                with ServiceInvoiceHeader do begin
                    Get(PostedDocumentNo);
                    TestField("Electronic Document Status", ExpectedStatus);
                    TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, "Date/Time Sent" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, "Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Canceled")));
                    TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    TestField("PAC Web Service Name", ExpectedPACCode);
                    TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    TestField("Error Code", ExpectedErrorCode);
                    TestField("Error Description", ExpectedErrorDesc);
                    CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(ServiceInvoiceHeader, FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                end;
            DATABASE::"Service Cr.Memo Header":
                with ServiceCrMemoHeader do begin
                    Get(PostedDocumentNo);
                    TestField("Electronic Document Status", ExpectedStatus);
                    TestField("No. of E-Documents Sent", ExpectedNoOfEmailsSent);
                    Assert.AreEqual(ExpectedDateTimeSentEmpty, "Date/Time Sent" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Sent")));
                    Assert.AreEqual(ExpectedDateTimeCanceledEmpty, "Date/Time Canceled" = '',
                      StrSubstNo(ValueErr, FieldName("Date/Time Canceled")));
                    TestField("Date/Time Stamped", ExpectedDateTimeStamped);
                    TestField("PAC Web Service Name", ExpectedPACCode);
                    TestField("Fiscal Invoice Number PAC", ExpectedInvoiceNoPAC);
                    TestField("Error Code", ExpectedErrorCode);
                    TestField("Error Description", ExpectedErrorDesc);
                    CalcFields("Digital Stamp PAC");
                    DummyTempBlob.FromRecord(ServiceCrMemoHeader, FieldNo("Digital Stamp PAC"));
                    VerifyDigitalStamp(DummyTempBlob, ExpectedDigitalStamp);
                end;
        end;
    end;

    local procedure VerifyDigitalStamp(StampTempBlob: Codeunit "Temp Blob"; ExpectedStamp: Text[250])
    var
        InStream: InStream;
        Stamp: Text[250];
        StampBigText: Text;
    begin
        StampTempBlob.CreateInStream(InStream);
        InStream.Read(StampBigText);
        Stamp := CopyStr(StampBigText, 1, 250);
        Assert.AreEqual(ExpectedStamp, Stamp, '');
    end;

    local procedure MockCancel(Response: Option; var TempBlob: Codeunit "Temp Blob")
    begin
        if Response = ResponseOption::Success then
            MockSuccessCancel(TempBlob)
        else
            MockFailure(TempBlob);
    end;

    local procedure MockRequestStamp(Response: Option; var TempBlob: Codeunit "Temp Blob")
    begin
        if Response = ResponseOption::Success then
            MockSuccessRequestStamp(TempBlob)
        else
            MockFailure(TempBlob);
    end;

    local procedure MockFailure(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="Sello del Emisor No Valido" IdRespuesta="302" />');
    end;

    local procedure MockSuccessRequestStamp(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="OK" IdRespuesta="1" >');
        OutStream.WriteText(
          '  <cfdi:Comprobante xsi:schemaLocation="http://www.sat.gob.mx/cfd/3' +
          ' http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv3.xsd"');
        OutStream.WriteText(' version="3.0" xmlns="" fecha="2011-11-08T09:02:03" formaDePago="Pago en una sola exhibici');
        OutStream.WriteText(
          'on" noCertificado="30001000000100000800" certificado="MIIE/TCCA+WgAwIBAgIUMzAwMDEwMDAwMDAxMDAwMDA4MDAwDQYJKoZIhvcNAQE');
        OutStream.WriteText('FBQAwggFvMRgwFgYDVQQDDA9BLkMuIGRlIHBydWViYXMxLzAtBgNVBAoMJlNlcnZpY2lvIGRlIEFkbWl');
        OutStream.WriteText('uaXN0cmFjacOzbiBUcmlidXRhcmlhMTgwNgYDVQQLDC9BZG1pbmlzdHJhY2nDs2');
        OutStream.WriteText(
          '4gZGUgU2VndXJpZGFkIGRlIGxhIEluZm9ybWFjacOzbjEpMCcGCSqGSIb3DQEJARYaYXNpc25ldEBwcnVlYmFzLnNhdC5nb2IubXgxJjAkBgNVBAkMHUF2');
        OutStream.WriteText('LiBIaWRhbGdvIDc3LCBDb2wuIEd1ZXJyZXJvMQ4wDAYDVQQRDAUwNjMwMDELMAkGA1UEBhMCTVgxGTA');
        OutStream.WriteText(
          'XBgNVBAgMEERpc3RyaXRvIEZlZGVyYWwxEjAQBgNVBAcMCUNveW9hY8OhbjEVMBMGA1UELRMMU0FUOTcwNzAxTk4zMTIwMAYJKoZIhvcNAQkCDCNSZXNwb2');
        OutStream.WriteText('5zYWJsZTogSMOpY3RvciBPcm5lbGFzIEFyY2lnYTAeFw0xMDA3MzAxNjU4NDBaFw0xMjA3MjkxNjU4');
        OutStream.WriteText(
          'NDBaMIGWMRIwEAYDVQQDDAlNYXRyaXogU0ExEjAQBgNVBCkMCU1hdHJpeiBTQTESMBAGA1UECgwJTWF0cml6IFNBMSUwIwYDVQQtExxBQUEwMTAxMDFBQUE');
        OutStream.WriteText('gLyBBQUFBMDEwMTAxQUFBMR4wHAYDVQQFExUgLyBBQUFBMDEwMTAxSERGUlhYMDExETAPBgNVBAsMC');
        OutStream.WriteText(
          'FVuaWRhZCAxMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDD0ltQNthUNUfzq0t1GpIyapjzOn1W5fGM5G/' +
          'pQyMluCzP9YlVAgBjGgzwYp9Z0J9gadg3y');
        OutStream.WriteText('2ZrYDwvv8b72goyRnhnv3bkjVRKlus6LDc00K7Jl23UYzNGlXn5+i0HxxuWonc2GYKFGsN4rFWKVy');
        OutStream.WriteText(
          '3Fnpv8Z2D7dNqsVyT5HapEqwIDAQABo4HqMIHnMAwGA1UdEwEB/wQCMAAwCwYDVR0PBA' +
          'QDAgbAMB0GA1UdDgQWBBSYodSwRczzj5H7mcO3+mAyXz+y0DAuBgN');
        OutStream.WriteText('VHR8EJzAlMCOgIaAfhh1odHRwOi8vcGtpLnNhdC5nb2IubXgvc2F0LmNybDAzBggrBgEFBQcBAQQ');
        OutStream.WriteText(
          'nMCUwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNhdC5nb2IubXgvMB8GA1UdIwQYMBaAFOtZfQQimlONnnEaoFiWKfU54KDFMBAGA1UdIAQJMAc');
        OutStream.WriteText(
          'wBQYDKgMEMBMGA1UdJQQMMAoGCCsGAQUFBwMCMA0GCSqGSIb3DQEBBQUAA4IBAQArHQEorApwqumSn5EqDOAjbezi8fLco1cYES/' +
          'PD+LQRM1Vb1g7VLE3hR4S');
        OutStream.WriteText('5NNBv0bMwwWAr0WfL9lRRj0PMKLorO8y4TJjRU8MiYXfzSuKYL5Z16kW8zlVHw7CtmjhfjoIMwjQ');
        OutStream.WriteText(
          'o3prifWxFv7VpfIBstKKShU0qB6KzUUNwg2Ola4t4gg2JJcBmyIAIInHSGoeinR2V1tQ10aRqJdXkGin4WZ75yMbQH4L0NfotqY6bp');
        OutStream.WriteText(
          'F2CqIY3aogQyJGhUJji4gYnS2DvHcyoICwgawshjSaX8Y0Xlwnuh6EusqhqlhTgwPNAPrKIXCmOWtqjlDhho/lhkHJMzuTn8AoVapbBUnj"' +
          ' condicionesDe');
        OutStream.WriteText('Pago="30 DIAS" subTotal="250.000000" total="287.500000" metodoDePago="CHEQUE');
        OutStream.WriteText(
          '" tipoDeComprobante="ingreso" sello="UjFPBbIfOXXlMsVgqeayMUi4gbp291Nwd0vn1e4DRkzjz3Nw3ZXno1jJNXlTdR3P' +
          'OT5BqHM7NYILVFs+KaqnO');
        OutStream.WriteText('msM/05UsapfnTtneGIraoU/F2o4rQvg823nr/l61Cadl0nEm73btQiBhtq/4MrGLiUCGdAvcMiE');
        OutStream.WriteText('4p4TcOf5qsE=" xmlns:cfdi="http://www.sat.gob.mx/cfd/3" ' +
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
        OutStream.WriteText('    <cfdi:Emisor rfc="SWC920404DA3" nombre="CARGILL MEXICO">');
        OutStream.WriteText(
          '      <cfdi:DomicilioFiscal calle="AVE ROBLE 525" colonia="VALLE DEL CAMPESTRE" localidad="MONTERREY" ' +
          'municipio="VALLE DEL CAMPE');
        OutStream.WriteText('STRE" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('      <cfdi:ExpedidoEn calle="AVE ROBLE 525" colonia="VALLE DEL CAMPESTRE" ' +
          'municipio="VALLE DEL CAMPESTRE" ');
        OutStream.WriteText('localidad="MONTERREY" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('    </cfdi:Emisor>');
        OutStream.WriteText('    <cfdi:Receptor rfc="123456789123" nombre="AVE ROBLE">');
        OutStream.WriteText('      <cfdi:Domicilio calle="AVE ROBLE" colonia="VALLE DEL CAMPESTRE" ' +
          'municipio="VALLE DEL CAMPESTRE" ');
        OutStream.WriteText('localidad="SAN PEDRO" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('    </cfdi:Receptor>');
        OutStream.WriteText('    <cfdi:Conceptos>');
        OutStream.WriteText('      <cfdi:Concepto cantidad="1.000000" ');
        OutStream.WriteText('descripcion="AP-BL-412 - CALCULADORA" valorUnitario="250.000000" importe="250.000000" />');
        OutStream.WriteText('    </cfdi:Conceptos>');
        OutStream.WriteText('    <cfdi:Impuestos totalImpuestosRetenidos="0.000000" totalImpuestosTrasladados="37.500000">');
        OutStream.WriteText('      <cfdi:Traslados>');
        OutStream.WriteText('        <cfdi:Traslado impuesto="IVA" tasa="15.000000" importe="37.500000" />');
        OutStream.WriteText('      </cfdi:Traslados>');
        OutStream.WriteText('    </cfdi:Impuestos>');
        OutStream.WriteText('    <cfdi:Complemento xmlns:cfdi="http://www.sat.gob.mx/cfd/3" xmlns="">');
        OutStream.WriteText(
          '      <tfd:TimbreFiscalDigital version="1.0" UUID="9CDBDABD-9399-4DA1-8409-D1B70C5BA4DD" ' +
          'FechaTimbrado="2011-11-08T07:45:56" ');
        OutStream.WriteText('selloCFD="UjFPBbIfOXXlMsVgqeayMUi4gbp291Nwd0vn1e4DRkzjz3Nw3ZXno1jJNXlTdR3');
        OutStream.WriteText(
          'POT5BqHM7NYILVFs+KaqnOmsM/05UsapfnTtneGIraoU/F2o4rQvg823nr/l61Cadl0nEm73btQiBhtq/4MrGLiUCGdAvcMiE4p4TcOf5qsE=' +
          '" NoCertificadoSAT');
        OutStream.WriteText('="30001000000100000801" SelloSAT="WDTveFcG+ANYGdjrNrDcpYGdz4p0XsH5C0UTs');
        OutStream.WriteText(
          'qcMM/dSe4MGGnsacrJ75DAT5B5KqZWSefkGeg/sG7i6K3+lZTEuxje+rBDAp/4fMfYeL2TTMLpkU6Oy1zl/N6ywt38Z2+WTwcBIuIkEY54e' +
          '+mW+zkyJLAxkeDGJHAwEBd');
        OutStream.WriteText('f2nu0=" xsi:schemaLocation="http://www.sat.gob.mx/TimbreFiscalDigital');
        OutStream.WriteText(
          ' http://www.sat.gob.mx/TimbreFiscalDigital/TimbreFiscalDigital.xsd" ' +
          'xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital" />');
        OutStream.WriteText('    </cfdi:Complemento>');
        OutStream.WriteText('  </cfdi:Comprobante>');
        OutStream.WriteText('</Resultado>');
    end;

    local procedure MockSuccessCancel(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="Ok" IdRespuesta="1">');
        OutStream.WriteText(' <Acuse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
          'xmlns:xsd="http://www.w3.org/2001/XMLSchema"');
        OutStream.WriteText(' RfcEmisor="CST081210DN2" Fecha="2011-08-04T12:55:17.6925706"> ' +
          '<Folios xmlns="http://cancelacfd.sat.gob.mx">');
        OutStream.WriteText(' <UUID>F6853AA8-C083-4220-832F-9C0BD04428D2</UUID> ' +
          '<EstatusUUID>201</EstatusUUID> </Folios> <Signature Id=');
        OutStream.WriteText('"SelloSAT" xmlns="http://www.w3.org/2000/09/xmldsig#"> <SignedInfo> <CanonicalizationMethod');
        OutStream.WriteText(' Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" /> <SignatureMethod');
        OutStream.WriteText(' Algorithm="http://www.w3.org/2001/04/xmldsig-more#hmac-sha512" /> <Reference URI="">');
        OutStream.WriteText(' <Transforms> <Transform Algorithm="http://www.w3.org/TR/1999/REC-xpath-19991116">');
        OutStream.WriteText(' <XPath>not(ancestor-or-self::*[local-name()=''Signature''])</XPath> </Transform> </Transforms>');
        OutStream.WriteText(' <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha512" />');
        OutStream.WriteText(' <DigestValue>KI/DxQBrWgYFVWUhEk2W/41RZEvwW848uZXHlRADEZBMauT0hV2ixpeuR0p' +
          'Gb430qRD4mv07vAw5Zr0uLL0BVw==');
        OutStream.WriteText('</DigestValue> </Reference> </SignedInfo> <SignatureValue>d1dTpD9XVCo4o1UJUx' +
          'B/SZXfpU47pyh0RgSe6g3lNZEj');
        OutStream.WriteText('2DeDaI7WAzuU83P8JgAn8FH9adEhQTs1Ei8BbtDwJQ==</SignatureValue> <KeyInfo> <KeyName>00001088888800000003');
        OutStream.WriteText('</KeyName> <KeyValue> <RSAKeyValue> <Modulus>5W8PNugL/HbQV7L7H0PPfI4123iMz' +
          'UsUXa2DdBKVemyGWGFdjhnzs+LLdU');
        OutStream.WriteText('4BnKne2UMBHPrOE0n2rK44DfdTFLBgMhRhzLsstiaC4rMslW5AWl/dXwgva2EVVhFAuTP31LAGV5shk' +
          'bPbp75ZCreFE00r14oQv4Ep');
        OutStream.WriteText('mZuoxhz4yEM=</Modulus> <Exponent>AQAB</Exponent> </RSAKeyValue> </KeyValue> </KeyInfo> </Signature>');
        OutStream.WriteText('</Acuse>');
        OutStream.WriteText('</Resultado>');
    end;

    local procedure MockFADisposalEntry(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        FALedgerEntry.Init();
        FALedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::"Proceeds on Disposal";
        FALedgerEntry."Depreciation Book Code" := FADepreciationBook."Depreciation Book Code";
        FALedgerEntry.Amount := -LibraryRandom.RandDecInRange(1000, 2000, 2);
        FALedgerEntry.Insert();
    end;

    local procedure ConvertTxtToDateTime(InputTxt: Text): DateTime
    var
        InputTime: Time;
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        if InputTxt = '' then
            exit(0DT);
        // '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'
        // 2021-01-29T16:32:10
        // YYYY-MM-DDThh:mm:ss
        Evaluate(Year, CopyStr(InputTxt, 1, 4));
        Evaluate(Month, CopyStr(InputTxt, 6, 2));
        Evaluate(Day, CopyStr(InputTxt, 9, 2));
        Evaluate(InputTime, CopyStr(InputTxt, 12, 8));
        exit(CreateDateTime(DMY2Date(Day, Month, Year), InputTime));
    end;

    local procedure CreateOriginalStringText(TableNo: Integer; DocumentNo: Code[20]) OriginalStringText: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
    begin
        GetOriginalString(TempBlob, TableNo, DocumentNo);
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(OriginalStringText);
    end;

    local procedure ExportPaymentToServerFile(var CustLedgerEntry: Record "Cust. Ledger Entry"; var FileName: Text; DocumentType: Option; DocumentNo: Code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount, "Original Document XML");
        TempBlob.FromRecord(CustLedgerEntry, CustLedgerEntry.FieldNo("Original Document XML"));
        FileName := FileManagement.ServerTempFileName('.xml');
        FileManagement.BLOBExportToServerFile(TempBlob, FileName);
    end;

    local procedure FindPostedHeader(var PostedHeaderRecRef: RecordRef; TableNo: Integer; FieldNo: Integer; DocumentNo: Code[20])
    var
        DocumentNoFieldRef: FieldRef;
    begin
        PostedHeaderRecRef.Open(TableNo);
        DocumentNoFieldRef := PostedHeaderRecRef.Field(FieldNo);
        DocumentNoFieldRef.SetRange(DocumentNo);
        PostedHeaderRecRef.FindLast;
    end;

    local procedure FindPostedLines(var PostedLineRecRef: RecordRef; TableNo: Integer; FieldNo: Integer; DocumentNo: Code[20])
    var
        DocumentNoFieldRef: FieldRef;
    begin
        PostedLineRecRef.Open(TableNo);
        DocumentNoFieldRef := PostedLineRecRef.Field(FieldNo);
        DocumentNoFieldRef.SetRange(DocumentNo);
        PostedLineRecRef.FindSet();
    end;

    local procedure FindTimeZone(var TimeZoneID: Text[180]; var TimeZoneOffset: Duration; var UserOffset: Duration)
    var
        TimeZone: Record "Time Zone";
        TypeHelper: Codeunit "Type Helper";
    begin
        TypeHelper.GetUserClientTypeOffset(UserOffset);
        TimeZone.SetFilter("Display Name", '*:00*');
        TimeZone.FindSet();
        TimeZone.Next(LibraryRandom.RandInt(TimeZone.Count));
        TimeZoneID := TimeZone.ID;
        TypeHelper.GetTimezoneOffset(TimeZoneOffset, TimeZone.ID);
    end;

    local procedure FormatDecimal(InAmount: Decimal; DecimalPlaces: Integer): Text
    begin
        exit(
          FormatDecimalRange(InAmount, DecimalPlaces, DecimalPlaces));
    end;

    local procedure FormatDecimalRange(InAmount: Decimal; DecimalPlacesFrom: Integer; DecimalPlacesTo: Integer): Text
    begin
        exit(
          Format(Abs(InAmount), 0, '<Precision,' + Format(DecimalPlacesFrom) + ':' + Format(DecimalPlacesTo) + '><Standard Format,1>'));
    end;

    local procedure GetHeaderFieldValue(TableNo: Integer; DocumentNo: Code[20]; DocumentNoFieldNo: Integer; FieldNo: Integer): Code[10]
    var
        PostedHeaderRecRef: RecordRef;
        SelectedFieldRef: FieldRef;
    begin
        FindPostedHeader(PostedHeaderRecRef, TableNo, DocumentNoFieldNo, DocumentNo);
        SelectedFieldRef := PostedHeaderRecRef.Field(FieldNo);
        exit(SelectedFieldRef.Value);
    end;

    local procedure GetLineFieldValue(TableNo: Integer; DocumentNo: Code[20]; DocumentNoFieldNo: Integer; FieldNo: Integer): Text[10]
    var
        PostedLineRecRef: RecordRef;
        SelectedFieldRef: FieldRef;
    begin
        FindPostedLines(PostedLineRecRef, TableNo, DocumentNoFieldNo, DocumentNo);
        SelectedFieldRef := PostedLineRecRef.Field(FieldNo);
        exit(SelectedFieldRef.Value);
    end;

    local procedure GetOriginalString(var TempBlob: Codeunit "Temp Blob"; TableNo: Integer; DocumentNo: Code[20])
    var
        TempDocumentHeader: Record "Document Header" temporary;
        TempDocumentLine: Record "Document Line" temporary;
        TempDocumentLineRetention: Record "Document Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        SubTotal: Decimal;
        TotalTax: Decimal;
        TotalRetention: Decimal;
        TotalDiscount: Decimal;
    begin
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.SetRange("No.", DocumentNo);
                    SalesInvoiceHeader.FindLast;
                    EInvoiceMgt.CreateTempDocument(
                        SalesInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(TempDocumentHeader, TempDocumentLine, '', 0, 0, false, TempBlob, '');
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.SetRange("No.", DocumentNo);
                    SalesCrMemoHeader.FindLast;
                    EInvoiceMgt.CreateTempDocument(
                        SalesCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(
                      TempDocumentHeader, TempDocumentLine, '', 0, 0, true, TempBlob, LibraryUtility.GenerateGUID);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.SetRange("No.", DocumentNo);
                    ServiceInvoiceHeader.FindLast;
                    EInvoiceMgt.CreateTempDocument(
                        ServiceInvoiceHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(TempDocumentHeader, TempDocumentLine, '', 0, 0, false, TempBlob, '');
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.SetRange("No.", DocumentNo);
                    ServiceCrMemoHeader.FindLast;
                    EInvoiceMgt.CreateTempDocument(
                        ServiceCrMemoHeader, TempDocumentHeader, TempDocumentLine, TempDocumentLineRetention, TempVATAmountLine,
                        SubTotal, TotalTax, TotalRetention, TotalDiscount, false);
                    EInvoiceMgt.CreateOriginalStr33WithUUID(
                      TempDocumentHeader, TempDocumentLine, '', 0, 0, true, TempBlob, LibraryUtility.GenerateGUID);
                end;
        end;
    end;

    local procedure GetSATItemClassificationDefault(): Code[10]
    begin
        exit('01010101');
    end;

    local procedure OriginalStringMandatoryFields(HeaderTableNo: Integer; LineTableNo: Integer; DocumentNoFieldNo: Integer; CustomerFieldNo: Integer; CFDIPurposeFieldNo: Integer; CFDIRelationFieldNo: Integer; PaymentMethodCodeFieldNo: Integer; PaymentTermsCodeFieldNo: Integer; UnitOfMeasureCodeFieldNo: Integer; RelationIdx: Integer)
    var
        Customer: Record Customer;
        DocumentNo: Code[20];
        OriginalStringText: Text;
    begin
        Initialize;

        // Setup
        DocumentNo := CreateAndPostDoc(HeaderTableNo, CreatePaymentMethodForSAT);

        // Exercise
        OriginalStringText := CreateOriginalStringText(HeaderTableNo, DocumentNo);

        Customer.Get(
          GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, CustomerFieldNo));

        // Verify
        VerifyOriginalStringFields(
          OriginalStringText,
          Customer."RFC No.",
          GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, CFDIPurposeFieldNo),
          GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, CFDIRelationFieldNo),
          SATUtilities.GetSATPaymentMethod(
            GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, PaymentMethodCodeFieldNo)),
          SATUtilities.GetSATPaymentTerm(
            GetHeaderFieldValue(HeaderTableNo, DocumentNo, DocumentNoFieldNo, PaymentTermsCodeFieldNo)),
          GetLineFieldValue(LineTableNo, DocumentNo, DocumentNoFieldNo, UnitOfMeasureCodeFieldNo),
          RelationIdx);
    end;

    local procedure UpdateDocumentFieldValue(TableNo: Integer; FieldNo: Integer; DocumentNo: Code[20]; ChangeFieldNo: Integer; ChangeValue: Variant)
    var
        PostedHeaderRecRef: RecordRef;
        ChangeFieldRef: FieldRef;
    begin
        FindPostedHeader(PostedHeaderRecRef, TableNo, FieldNo, DocumentNo);
        ChangeFieldRef := PostedHeaderRecRef.Field(ChangeFieldNo);
        ChangeFieldRef.Value := ChangeValue;
        PostedHeaderRecRef.Modify();
    end;

    local procedure UpdateDocumentPostCode(TableNo: Integer; FieldNoDocumentNo: Integer; DocumentNo: Code[20]; FieldNoCity: Integer; FieldNoPostCode: Integer; City: Variant; PostCode: Variant)
    var
        PostedHeaderRecRef: RecordRef;
        ChangeFieldRef: FieldRef;
    begin
        FindPostedHeader(PostedHeaderRecRef, TableNo, FieldNoDocumentNo, DocumentNo);
        ChangeFieldRef := PostedHeaderRecRef.Field(FieldNoCity);
        ChangeFieldRef.Value := City;
        ChangeFieldRef := PostedHeaderRecRef.Field(FieldNoPostCode);
        ChangeFieldRef.Value := PostCode;
        PostedHeaderRecRef.Modify();
    end;

    local procedure UpdateCustomerPostCode(CustomerNo: Code[20]; City: Variant; PostCode: Variant)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.City := City;
        Customer."Post Code" := PostCode;
        Customer.Modify();
    end;

    local procedure UpdateCustomerSATPaymentFields(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."Payment Method Code" := CreatePaymentMethodForSAT();
        Customer."Payment Terms Code" := CreatePaymentTermsForSAT();
        Customer.Modify();
    end;

    local procedure UpdateDocumentWithTimeZone(TableID: Integer; FieldNoDocumentNo: Integer; DocumentNo: Code[20]; FieldNoCity: Integer; FieldNoPostCode: Integer; TimeZoneID: Text[180])
    var
        PostCode: Record "Post Code";
    begin
        CreatePostCode(PostCode, TimeZoneID);
        UpdateDocumentPostCode(
          TableID, FieldNoDocumentNo, DocumentNo, FieldNoCity, FieldNoPostCode, PostCode.City, PostCode.Code);
    end;

    local procedure UpdateGLSetupRounding(Decimals: Text[5])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := GeneralLedgerSetup."Amount Rounding Precision";
        GeneralLedgerSetup."Amount Decimal Places" := Decimals;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateCurrencyWithRounding(CurrencyCode: Code[20]; RoundingPrecision: Decimal; Decimals: Text[5])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency."Amount Rounding Precision" := RoundingPrecision;
        Currency."Invoice Rounding Precision" := RoundingPrecision;
        Currency."Amount Decimal Places" := Decimals;
        Currency.Modify();
    end;

    local procedure VerifyMandatoryFields(OriginalString: Text; RFCNo: Code[13]; CFDIPurpose: Code[10]; CFDIRelation: Code[10]; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; UnitOfMeasureCode: Text[10]; RelationIdx: Integer)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Assert.AreEqual('3.3', SelectStr(3, OriginalString), StrSubstNo(IncorrectSchemaVersionErr, OriginalString));

        Assert.AreEqual(
          CompanyInformation."RFC No.",
          SelectStr(12 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, RFCNoFieldTxt, OriginalString));
        Assert.AreEqual(
          CompanyInformation."SAT Tax Regime Classification",
          SelectStr(14 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, RegimenFieldTxt, OriginalString));

        Assert.AreEqual(
          RFCNo,
          SelectStr(15 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, RFCNoFieldTxt, OriginalString));
        Assert.AreEqual(
          CFDIPurpose,
          SelectStr(18 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, CFDIPurposeFieldTxt, OriginalString));
        VerifyCFDIRelation(OriginalString, CFDIRelation, RelationIdx);

        Assert.AreEqual(
          PaymentMethodCode,
          SelectStr(5, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, FormaDePagoFieldTxt, OriginalString));
        Assert.AreEqual(
          PaymentTermsCode,
          SelectStr(10, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, MetodoDePagoFieldTxt, OriginalString));
        Assert.AreEqual(
          UpperCase(UnitOfMeasureCode),
          SelectStr(22 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, ConceptoUnidadFieldTxt, OriginalString));
    end;

    local procedure VerifyCFDIRelation(OriginalString: Text; CFDIRelation: Code[10]; RelationIdx: Integer)
    begin
        if RelationIdx = 0 then
            exit;

        Assert.AreEqual(
          CFDIRelation,
          SelectStr(10 + RelationIdx, OriginalString),
          StrSubstNo(IncorrectOriginalStrValueErr, CFDIRelationFieldTxt, OriginalString));
    end;

    local procedure VerifyOriginalStringFields(OriginalString: Text; RFCNo: Code[13]; CFDIPurpose: Code[10]; CFDIRelation: Code[10]; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; UnitOfMeasureCode: Text[10]; RelationIdx: Integer)
    var
        OriginalStrCSV: Text;
    begin
        OriginalStrCSV := ConvertStr(OriginalString, '|', ',');
        VerifyMandatoryFields(
          OriginalStrCSV, RFCNo, CFDIPurpose, CFDIRelation, PaymentMethodCode, PaymentTermsCode, UnitOfMeasureCode, RelationIdx);
    end;

    local procedure VerifyCFDIFixedAssetFields(OriginalStr: Text; FANo: Code[20])
    begin
        OriginalStr := ConvertStr(OriginalStr, '|', ',');

        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ClaveProdServ', GetSATItemClassificationDefault);
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'NoIdentificacion', FANo);
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Conceptos/cfdi:Concepto', 'ClaveUnidad', SATUtilities.GetSATUnitOfMeasureFixedAsset());

        Assert.AreEqual(
          GetSATItemClassificationDefault, SelectStr(21, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'SAT Item Classification', OriginalStr));
        Assert.AreEqual(
          FANo, SelectStr(22, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'NoIdentificacion', OriginalStr));
        Assert.AreEqual(
          SATUtilities.GetSATUnitOfMeasureFixedAsset(), SelectStr(24, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'SAT Unit of Measure', OriginalStr));
    end;

    local procedure VerifyComplementoPago(OriginalStr: Text; ImpSaldoAnt: Decimal; ImpPagado: Decimal; ImpSaldoInsoluto: Decimal; IdDocumento: Text; NumParcialidad: Text; Index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'ImpSaldoAnt',
          FormatDecimal(ImpSaldoAnt, 2), Index);
        Assert.AreEqual(
          FormatDecimal(ImpSaldoAnt, 2),
          SelectStr(33 + Index * 8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ImpSaldoAnt', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'ImpPagado',
          FormatDecimal(ImpPagado, 2), Index);
        Assert.AreEqual(
          FormatDecimal(ImpPagado, 2),
          SelectStr(34 + Index * 8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ImpPagado', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'ImpSaldoInsoluto',
          FormatDecimal(ImpSaldoInsoluto, 2), Index);
        Assert.AreEqual(
          FormatDecimal(ImpSaldoInsoluto, 2),
          SelectStr(35 + Index * 8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'ImpSaldoInsoluto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'IdDocumento',
          IdDocumento, Index);
        Assert.AreEqual(
          IdDocumento,
          SelectStr(28 + Index * 8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'IdDocumento', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Complemento/pago10:Pagos/pago10:Pago/pago10:DoctoRelacionado', 'NumParcialidad',
          NumParcialidad, Index);
        Assert.AreEqual(
          NumParcialidad,
          SelectStr(32 + Index * 8, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'NumParcialidad', OriginalStr));
    end;

    local procedure VerifyIsNearlyEqualDateTime(ActualDateTime: DateTime; ExpectedDateTime: DateTime)
    begin
        Assert.IsTrue(
          Abs(ActualDateTime - ExpectedDateTime) < 60 * 1000, StrSubstNo('%1 %2', ActualDateTime, ExpectedDateTime));
    end;

    local procedure VerifyRootNodeTotals(OriginalStr: Text; Total: Decimal; SubTotal: Decimal; Discount: Decimal)
    begin
        LibraryXPathXMLReader.VerityAttributeFromRootNode('SubTotal', FormatDecimal(SubTotal, 2));
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Total', FormatDecimal(Total, 2));
        LibraryXPathXMLReader.VerityAttributeFromRootNode('Descuento', FormatDecimal(Discount, 2));
        Assert.AreEqual(
          FormatDecimal(SubTotal, 2), SelectStr(7, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'SubTotal', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(Total, 2), SelectStr(10, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Total', OriginalStr));
        Assert.AreEqual(
          FormatDecimal(Discount, 2), SelectStr(8, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Descuento', OriginalStr));
    end;

    local procedure VerifyVATAmountLines(OriginalStr: Text; Amount: Decimal; VATAmount: Decimal; VATPct: Decimal; Impuesto: Text; Offset: Integer; index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Importe', FormatDecimal(VATAmount, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 6), SelectStr(34 + index * 13 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TasaOCuota', FormatDecimal(VATPct / 100, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATPct / 100, 6), SelectStr(33 + index * 13 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TasaOCuota', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TipoFactor', 'Tasa', index);
        Assert.AreEqual(
          'Tasa', SelectStr(32 + index * 13 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Tasa', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(31 + index * 13 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Base', FormatDecimal(Amount, 6), index);
        Assert.AreEqual(
          FormatDecimal(Amount, 6), SelectStr(30 + index * 13 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Base', OriginalStr));
    end;

    local procedure VerifyVATAmountLinesExempt(OriginalStr: Text; Amount: Decimal; Impuesto: Text)
    begin
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TipoFactor', 'Exento');
        Assert.AreEqual(
          'Exento', SelectStr(32, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Exento', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Impuesto', Impuesto);
        Assert.AreEqual(
          Impuesto, SelectStr(31, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Base', FormatDecimal(Amount, 6));
        Assert.AreEqual(
          FormatDecimal(Amount, 6), SelectStr(30, OriginalStr), StrSubstNo(IncorrectOriginalStrValueErr, 'Base', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeAbsence(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Importe');

        LibraryXPathXMLReader.VerifyAttributeAbsence(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'TasaOCuota');
    end;

    local procedure VerifyRetentionAmountLine(OriginalStr: Text; Amount: Decimal; VATAmount: Decimal; VATPct: Decimal; Impuesto: Text; Offset: Integer; index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'Importe', FormatDecimal(VATAmount, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 6), SelectStr(Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'TasaOCuota', FormatDecimal(VATPct / 100, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATPct / 100, 6), SelectStr(Offset - 1, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TasaOCuota', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'TipoFactor', 'Tasa', index);
        Assert.AreEqual(
          'Tasa', SelectStr(Offset - 2, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Tasa', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(Offset - 3, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',
          'Base', FormatDecimal(Amount, 6), index);
        Assert.AreEqual(
          FormatDecimal(Amount, 6), SelectStr(Offset - 4, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Base', OriginalStr));
    end;

    local procedure VerifyVATTotalLine(OriginalStr: Text; VATAmount: Decimal; VATPct: Decimal; Impuesto: Text; index: Integer; LineQty: Integer; Offset: Integer)
    var
        TotalOffset: Integer;
    begin
        TotalOffset := (LineQty - 1) * 14;

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'Importe', FormatDecimal(VATAmount, 2), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 2), SelectStr(38 + TotalOffset + index * 4 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'TasaOCuota', FormatDecimal(VATPct / 100, 6), index);
        Assert.AreEqual(
          FormatDecimal(VATPct / 100, 6), SelectStr(37 + TotalOffset + index * 4 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TasaOCuota', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'TipoFactor', 'Tasa', index);
        Assert.AreEqual(
          'Tasa', SelectStr(36 + TotalOffset + index * 4 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'TipoFactor', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado', 'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(35 + TotalOffset + index * 4 + Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));
    end;

    local procedure VerifyRetentionTotalLine(OriginalStr: Text; VATAmount: Decimal; Impuesto: Text; Offset: Integer; index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion', 'Importe', FormatDecimal(VATAmount, 2), index);
        Assert.AreEqual(
          FormatDecimal(VATAmount, 2), SelectStr(Offset + 1, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Importe', OriginalStr));

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion', 'Impuesto', Impuesto, index);
        Assert.AreEqual(
          Impuesto, SelectStr(Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, 'Impuesto', OriginalStr));
    end;

    local procedure VerifyTotalImpuestos(OriginalStr: Text; TotalImpuestosNode: Text; TotalVATAmount: Decimal; Offset: Integer)
    begin
        // 'TotalImpuestosTrasladados' or 'TotalImpuestosRetenidos'
        LibraryXPathXMLReader.VerifyAttributeValue(
          'cfdi:Impuestos', TotalImpuestosNode, FormatDecimal(TotalVATAmount, 2));
        Assert.AreEqual(
          FormatDecimal(TotalVATAmount, 2), SelectStr(Offset, OriginalStr),
          StrSubstNo(IncorrectOriginalStrValueErr, TotalImpuestosNode, OriginalStr));
    end;

    local procedure VerifyLineAmountsByIndex(DiscountAmount: Decimal; LineAmount: Decimal; UnitPrice: Decimal; VATAmount: Decimal; VATBase: Decimal; Index: Integer)
    begin
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto', 'Descuento', FormatDecimal(DiscountAmount, 2), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto', 'Importe', FormatDecimal(LineAmount, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto', 'ValorUnitario', FormatDecimal(UnitPrice, 6), Index);

        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Importe', FormatDecimal(VATAmount, 6), Index);
        LibraryXPathXMLReader.VerifyAttributeValueByNodeIndex(
          'cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',
          'Base', FormatDecimal(VATBase, 6), Index);
    end;

    local procedure VerifyPDFFile()
    var
        FilePath: Text;
    begin
        NameValueBuffer.SetRange(Name, Format(CODEUNIT::"MX CFDI"));
        NameValueBuffer.FindFirst();
        FilePath := NameValueBuffer.Value;
        NameValueBuffer.DeleteAll();

        Assert.IsTrue(Exists(FilePath), '');
        Assert.AreEqual('.pdf', CopyStr(FilePath, StrLen(FilePath) - 3), '');
    end;

    local procedure CreateBasicSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateBasicServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Option; CustomerNo: Code[20])
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibraryInventory.CreateItem(Item);
        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", DocumentType);
        ServiceHeader.Validate("Customer No.", CustomerNo);
        ServiceHeader.Validate("Due Date", WorkDate);
        ServiceHeader.Insert(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerNoDiscount() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Reply := Value;
    end;

    [StrMenuHandler]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        Value: Variant;
        "Action": Option;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Action := Value;
        case Action of
            ActionOption::"Request Stamp":
                Choice := 1;
            ActionOption::Send:
                Choice := 2;
            ActionOption::"Request Stamp and Send":
                Choice := 3;
            else
                Error(OptionNotSupportedErr);
        end;
    end;

    [ReportHandler]
    procedure SalesInvoiceReportHandler(var ElecSalesInvoiceMX: Report "Elec. Sales Invoice MX")
    begin
    end;

    [ReportHandler]
    procedure SalesCrMemoReportHandler(var ElecSalesCrMemoMX: Report "Elec. Sales Credit Memo MX")
    begin
    end;

    [ReportHandler]
    procedure ServiceInvoiceReportHandler(var ElecServiceInvoiceMX: Report "Elec. Service Invoice MX")
    begin
    end;

    [ReportHandler]
    procedure ServiceCrMemoReportHandler(var ElecServiceCrMemoMX: Report "Elec. Service Cr Memo MX")
    begin
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure SetFilePathOnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
        if NameValueBuffer.FindLast() then;
        NameValueBuffer.ID += 1;
        NameValueBuffer.Name := Format(CODEUNIT::"MX CFDI");
        NameValueBuffer.Value := FromFileName;
        NameValueBuffer.Insert();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 10145, 'OnBeforeGetNumeroPedimento', '', false, false)]
    local procedure SetNumeroPedimento(TempDocumentLine: Record "Document Line" temporary; var NumberPedimento: Text; var IsHandled: Boolean)
    begin
        NameValueBuffer.Get(CODEUNIT::"MX CFDI");
        NumberPedimento := NameValueBuffer.Value;
        IsHandled := true;
    end;
}


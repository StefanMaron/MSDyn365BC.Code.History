codeunit 144202 "FatturaPA II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Export]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySplitVAT: Codeunit "Library - Split VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementNameErr: Label 'Unexpected element name. Expected element name: %1. Actual element name: %2.', Comment = '%1=Expetced XML Element Name;%2=Actual XML Element Name;';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';
        FieldIsNotVisibleErr: Label 'Field is not visible.';
        TxtTok: Label 'TXT%1', Locked = true;
        ExemptionDataMsg: Label '%1 del %2.', Locked = true;
        VATExemptionPrefixTok: Label 'Dich.Intento n.', Locked = true;
        EuroReplacementTok: Label 'EUR';
        DefaultReplacementTok: Label '_';

    [Test]
    [Scope('OnPrem')]
    procedure SalesDatiDDTNodeWithMultipleShipments()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        PostedInvNo: Code[20];
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Shipment]
        // [SCENARIO 284632] DatiGenerali has node DatiDDT with information about shipment lines after posting Sales Invoice
        Initialize;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Posted shipments "A" and "B" coming from separate Sales Orders where first sales order has one lines and second sales order has three lines
        // [GIVEN] "SO1" has one Sales Line, "SO2" has two Sales Lines.
        CreateAndPostSalesOrder(CustomerNo, 1, true, false);
        CreateAndPostSalesOrder(CustomerNo, 2, true, false);

        // [GIVEN] Posted sales Invoice with three shipments, one from shipment "A" and two from shipment "B"
        PostedInvNo := CreateSalesInvFromShipment(CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("No.", PostedInvNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] DatiGenerali node has three DatiDDT nodes per each Sales Invoice Line with shipment information
        // TFS 313364: If you get more than one posted shipments in a Sale Invoice, the E-Invoice xml file is not accepted due to the the shipment description reported
        VerifyDatiDDTForMultipleSalesShipments(ServerFileName, PostedInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServDatiDDTNodeWithMultipleShipments()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Shipment]
        // [SCENARIO 284632] DatiGenerali has node DatiDDT with information about shipment lines after posting Service Invoice
        Initialize;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Posted shipments "A" and "B" coming from separate Service Orders where first service order has "X" lines and second sales order has "Y" lines
        // [GIVEN] "SO1" has one Service Line, "SO2" has two Service Lines.
        CreateAndPostServOrder(CustomerNo, 1, true, false);
        CreateAndPostServOrder(CustomerNo, 2, true, false);

        // [GIVEN] Posted Service Invoice with three shipments, one from shipment "A" and two from shipment "B"
        CreateServInvFromShipment(ServiceInvoiceHeader, CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        ServiceInvoiceHeader.SetRange("No.", ServiceInvoiceHeader."No.");
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] DatiGenerali node has three DatiDDT nodes per each Service Invoice Line with shipment information
        VerifyDatiDDTForMultipleServiceShipments(ServerFileName, ServiceInvoiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDatiDDTNodeWithMultipleShipments()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Order] [Shipment]
        // [SCENARIO 288977] DatiGenerali has node DatiDDT with information about shipment lines after posting Sales Order

        Initialize;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Sales Order with "X" lines posted as Ship and Invoice
        CreateAndPostSalesOrder(CustomerNo, LibraryRandom.RandInt(5), true, true);

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] DatiGenerali node has three DatiDDT nodes per each Sales Shipment Line created by "Ship" posting
        VerifyDatiDDTForMultipleSalesOrderShipments(ServerFileName, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServOrderDatiDDTNodeWithMultipleShipments()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Order] [Shipment]
        // [SCENARIO 284632] DatiGenerali has node DatiDDT with information about shipment lines after posting Service Order

        Initialize;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Service Order with "X" lines posted as Ship and Invoice
        CreateAndPostServOrder(CustomerNo, LibraryRandom.RandInt(5), true, true);

        // [WHEN] The document is exported to FatturaPA.
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] DatiGenerali node has three DatiDDT nodes per each Service Shipment Line created by "Ship" posting
        VerifyDatiDDTForMultipleServiceOrderShipments(ServerFileName, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDatiOrdineAcquistoNodeWithFirstShipment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Order] [Shipment]
        // [SCENARIO 288977] DatiOrdineAcquisto node has information about first shipment after posting Sales Order

        Initialize;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Sales order with "X" lines shipped twice and invoice once
        PostSalesOrderSomeLinesShipped(CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] DatiOrdineAcquisto node has information about Sales Shipment Lines of the first shipment of Sales Order
        VerifyDatiOrdineAcquistoForFirstSalesOrderShipment(ServerFileName, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServOrderDatiOrdineAcquistoNodeWithFirstShipment()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Order] [Shipment]
        // [SCENARIO 288977] DatiOrdineAcquisto node has information about first shipment after posting Service Order

        Initialize;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Service order with "X" lines shipped twice and invoice once
        PostServOrderSomeLinesShipped(CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] DatiOrdineAcquisto node has information about Service Shipment Lines of the first shipment of Service Order
        VerifyDatiOrdineAcquistoForFirstServiceOrderShipment(ServerFileName, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDCodiceNodeWhenCompanyInformationHasFiscalCode()
    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 284632] IdCodice node has value of company information's fiscal code if it's specified

        Initialize;

        // [GIVEN] Fiscal Code is "A" in Company Information
        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := LibraryUtility.GenerateGUID;
        CompanyInformation.Modify(true);

        // [GIVEN] Posted Sales Invoice
        DocumentNo := PostSalesInvoice(CreatePaymentMethod, CreatePaymentTerms);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] "ID Codice" node has value "A"
        VerifyIDCodiceNode(ServerFileName, CompanyInformation."Fiscal Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDCodiceNodeWhenCompanyInformationHasNoFiscalCode()
    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 284632] IdCodice node has value of company information's VAT registration code if fiscal code is not specified

        Initialize;

        // [GIVEN] Fiscal Code is blank and "VAT Registration No" is "B" in Company Information
        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := '';
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID;
        CompanyInformation.Modify(true);

        // [GIVEN] Posted Sales Invoice
        DocumentNo := PostSalesInvoice(CreatePaymentMethod, CreatePaymentTerms);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] "ID Codice" node has value "b"
        VerifyIDCodiceNode(ServerFileName, CompanyInformation."VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DettaglioPagamentoNodeWithSplitPmtTerms()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 284632] Multiple DettaglioPagamento nodes to be exported for payment terms with split payment lines

        Initialize;

        // [GIVEN] Two customer ledger entries posted from one sales invoice with two payment terms lines, each 50%
        DocumentNo := PostSalesInvoice(CreatePaymentMethod, CreatePaymentTermsWithMultiplePmtLines);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Two DettaglioPagamento nodes exported per each Customer Ledger ENtry
        VerifyDettaglioPagamentoMultipleInvoices(ServerFileName, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesGroupedByVATPctToBeExportedToDatiRiepilogoNode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ExpectedAmount: array[2] of Decimal;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 270181] VAT Entries are grouped by VAT percent to be exported to Dati Riepilogo node

        Initialize;

        // [GIVEN] Posted Sales Invoice with three lines
        // [GIVEN] Line 1 has "VAT %" = 10, "VAT Amount" = 20
        // [GIVEN] Line 2 has "VAT %" = 10, "VAT Amount" = 30
        // [GIVEN] Line 3 has "VAT %" = 15, "VAT Amount" = 60
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader);
        ExpectedAmount[1] += Round(SalesLine."Line Amount" * SalesLine."VAT %" / 100);
        ExpectedAmount[1] += CreateSalesLineWithSalesVATPct(SalesHeader, SalesLine, SalesLine."VAT %");
        ExpectedAmount[2] += CreateSalesLineWithSalesVATPct(SalesHeader, SalesLine, SalesLine."VAT %" + LibraryRandom.RandInt(5));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Two DatiRiepilogo nodes exported with the following values for node Imposta
        // [THEN] First node - 50
        // [THEN] Second node - 60
        VerifyMultipleDatiRiepilogoNodes(ServerFileName, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NaturaNodeHasValueOfVATNatureInCaseOfZeroVATPercent()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 270181] Natura node has value of "VAT Nature" of VAT Posting Setup associated with Sales Invoice Line in case of zero VAT percent

        Initialize;

        // [GIVEN] Posted Sales Invoice with VAT Posting Setup with "VAT %" = 0 and "VAT Nature" = "X"
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateSalesDocWithVATTransNatureAndZeroVATRate(SalesHeader, SalesLine, VATPostingSetup, CustomerNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Natura node has value "X"
        VerifyNaturaNode(ServerFileName, VATPostingSetup."VAT Transaction Nature");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankIDDocumentoIfCustomerPurchaseOrderNoNoSpecifiedInSalesInv()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        PostedInvNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEAUTURE] [Sales] [Invoice] [Shipment]
        // [SCENARIO 286708] IDDocument is blank if "Customer Purchase Order No." is not specified in Sales Invoice

        Initialize;

        // [GIVEN] Sales Order posted as shipment
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateAndPostSalesOrder(CustomerNo, 1, true, false);

        // [GIVEN] Sales invoice with shipment lines from sales order and "Customer Purchase Order No." = "X"
        PostedInvNo := CreateSalesInvFromShipment(CustomerNo);
        SalesInvoiceHeader.SetRange("No.", PostedInvNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] IdDocumento is "X" in exported xml file
        VerifyIDDocumentoNode(ServerFileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankIDDocumentoIfCustomerPurchaseOrderNoNoSpecifiedInServInv()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEAUTURE] [Sales] [Invoice] [Shipment]
        // [SCENARIO 286708] IDDocument is blank if "Customer Purchase Order No." is not specified in Service Invoice

        Initialize;

        // [GIVEN] Service Order posted as shipment
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateAndPostServOrder(CustomerNo, 1, true, false);

        // [GIVEN] Service invoice with shipment lines from service order and "Customer Purchase Order No." = "X"
        CreateServInvFromShipment(ServiceInvoiceHeader, CustomerNo);
        ServiceInvoiceHeader.SetRange("No.", ServiceInvoiceHeader."No.");

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] IdDocumento is "X" in exported xml file
        VerifyIDDocumentoNode(ServerFileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPurchaseOrderFieldIsVisibleOnSalesOrder()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 286708] A field "Customer Purchase Order No." is visible on Sales Order page

        Initialize;
        LibraryApplicationArea.EnableBasicSetup;
        SalesOrder.OpenView;
        Assert.IsTrue(SalesOrder."Customer Purchase Order No.".Visible, FieldIsNotVisibleErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPurchaseOrderFieldIsVisibleOnSalesInvoice()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 286708] A field "Customer Purchase Order No." is visible on Sales Invoice page

        Initialize;
        LibraryApplicationArea.EnableBasicSetup;
        SalesInvoice.OpenView;
        Assert.IsTrue(SalesInvoice."Customer Purchase Order No.".Visible, FieldIsNotVisibleErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPurchaseOrderFieldIsVisibleOnServiceOrder()
    var
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO 286708] A field "Customer Purchase Order No." is visible on Service Order page

        Initialize;
        LibraryApplicationArea.EnableServiceManagementSetup;
        ServiceOrder.OpenView;
        Assert.IsTrue(ServiceOrder."Customer Purchase Order No.".Visible, FieldIsNotVisibleErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPurchaseOrderFieldIsVisibleOnServiceInvoice()
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [SCENARIO 286708] A field "Customer Purchase Order No." is visible on Service Invoice page

        Initialize;
        LibraryApplicationArea.EnableServiceManagementSetup;
        ServiceInvoice.OpenView;
        Assert.IsTrue(ServiceInvoice."Customer Purchase Order No.".Visible, FieldIsNotVisibleErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaidInCapitalFiedIsVisibleOnCompanyInformation()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 287253] A field "Paid-In Capital" is visible on Company Information page

        Initialize;
        LibraryApplicationArea.EnableServiceManagementSetup;
        CompanyInformation.OpenView;
        Assert.IsTrue(CompanyInformation."Paid-In Capital".Visible, FieldIsNotVisibleErr);
        CompanyInformation.Close;
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PECEmailAddressIsVisibleOnCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 287428] A field "PEC E-mail Address" is visible on Customer Card

        Initialize;
        LibraryApplicationArea.EnableBasicSetup;
        CustomerCard.OpenView;
        Assert.IsTrue(CustomerCard."PEC E-Mail Address".Visible, FieldIsNotVisibleErr);
        CustomerCard.Close;
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvExtendedTextExportsToAltriDatiGestionaliNode()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        StandardText: Record "Standard Text";
        ItemNo: Code[20];
        DocumentNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEAUTURE] [Sales] [Invoice] [Extended Text] [Standard Text]
        // [SCENARIO 287245] An extended and standard texts of Sales Invoice exports to XML file in node RiferimentoTesto under node AltriDatiGestionali

        Initialize;

        // [GIVEN] Item "ITEM0123456789012345" with 3 extended texts, each text has length 100
        ItemNo := CreateItemWithMultipleExtendedText;

        // [GIVEN] Posted Sales invoice with two lines - Item and standard text with Code = "STDTEXT0123456789012" and value = "Y1"
        DocumentNo := CreateSalesDocWithItemAndStandardText(StandardText, SalesHeader."Document Type"::Invoice, ItemNo);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Each extended texts separated by length 60 and 40 with results in 2 RiferimentoTesto nodes, total 6 nodes for 3 extended texts
        // [THEN] One more RiferimentoTesto has value of "Y1"
        // [THEN] item's "AltriDatiGestionali"."TipoDato" = "TXTITEM012" (10 chars length) (TFS 296782)
        // [THEN] standard text's "AltriDatiGestionali"."TipoDato" = "STDTEXT012" (10 chars length) (TFS 296782)
        // TFS 387861: Each RiferimentoTesto tag should be under the AltriDatiGestionali tag
        VerifyAltriDatiGestionaliByExtTexts(ServerFileName, ItemNo, StandardText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoExtendedTextExportsToAltriDatiGestionaliNode()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        StandardText: Record "Standard Text";
        ItemNo: Code[20];
        DocumentNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEAUTURE] [Sales] [Credit Memo] [Extended Text] [Standard Text]
        // [SCENARIO 287245] An extended and standard texts of Sales Credit Memo exports to XML file in node RiferimentoTesto under node AltriDatiGestionali

        Initialize;

        // [GIVEN] Item with 3 extended texts, each text has length 100
        ItemNo := CreateItemWithMultipleExtendedText;

        // [GIVEN] Posted Sales Credit Memo with two lines - Item and standard text "Y1"
        DocumentNo :=
          CreateSalesDocWithItemAndStandardText(StandardText, SalesHeader."Document Type"::"Credit Memo", ItemNo);
        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Each extended texts separated by length 60 and 40 with results in 2 RiferimentoTesto nodes, total 6 nodes for 3 extended texts
        // [THEN] One more RiferimentoTesto has value of "Y1"
        // TFS 387861: Each RiferimentoTesto tag should be under the AltriDatiGestionali tag
        VerifyAltriDatiGestionaliByExtTexts(ServerFileName, ItemNo, StandardText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvExtendedTextExportsToAltriDatiGestionaliNode()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        StandardText: Record "Standard Text";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEAUTURE] [Service] [Invoice] [Extended Text] [Standard Text]
        // [SCENARIO 287245] An extended and standard texts of Service Invoice exports to XML file in node RiferimentoTesto under node AltriDatiGestionali

        Initialize;

        // [GIVEN] Item with 3 extended texts, each text has length 100
        ItemNo := CreateItemWithMultipleExtendedText;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Posted Service invoice with two lines - Item and standard text "Y1"
        CreateServDocWithItemAndStandardText(StandardText, ServiceHeader."Document Type"::Invoice, CustomerNo, ItemNo);
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Each extended texts separated by length 60 and 40 with results in 2 RiferimentoTesto nodes, total 6 nodes for 3 extended texts
        // [THEN] One more RiferimentoTesto has value of "Y1"
        // TFS 387861: Each RiferimentoTesto tag should be under the AltriDatiGestionali tag
        VerifyAltriDatiGestionaliByExtTexts(ServerFileName, ItemNo, StandardText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoExtendedTextExportsToAltriDatiGestionaliNode()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        StandardText: Record "Standard Text";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEAUTURE] [Service] [Credit Memo] [Extended Text] [Standard Text]
        // [SCENARIO 287245] An extended and standard texts of Service Credit Memo exports to XML file in node RiferimentoTesto under node AltriDatiGestionali

        Initialize;

        // [GIVEN] Item with 3 extended texts, each text has length 100
        ItemNo := CreateItemWithMultipleExtendedText;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Posted Service Credit Memo with two lines - Item and standard text "Y1"
        CreateServDocWithItemAndStandardText(StandardText, ServiceHeader."Document Type"::"Credit Memo", CustomerNo, ItemNo);
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Each extended texts separated by length 60 and 40 with results in 2 RiferimentoTesto nodes, total 6 nodes for 3 extended texts
        // [THEN] One more RiferimentoTesto has value of "Y1"
        // TFS 387861: Each RiferimentoTesto tag should be under the AltriDatiGestionali tag
        VerifyAltriDatiGestionaliByExtTexts(ServerFileName, ItemNo, StandardText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaidInCapitalExportsToCapitaleSocialeNode()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        PaidInCapital: Decimal;
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [SCENARIO 287253] A value of "Paid-In Capital" expors to CapitaleSociale node

        Initialize;

        // [GIVEN] "Paid-In Capital" is 100 in Company Information
        PaidInCapital := LibraryRandom.RandDec(100, 2);
        LibraryITLocalization.UpdatePaidInCapitalInCompanyInformation(PaidInCapital);

        // [GIVEN] Posted Sales Invoice
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::Invoice);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] CapitaleSociale node has value 100
        VerifyCapitaleSociale(ServerFileName, PaidInCapital);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDocumentTD02ForSalesPrepaymentInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Prepayment]
        // [SCENARIO 287458] The node "TipoDocumento" has value "TD02" for sales prepayment invoice

        Initialize;

        // [GIVEN] Posted Sales Prepayment Invoice
        CustomerNo := CreateCustomerWithPmtSetup;
        CreateSalesDocWithPrepmt(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, LibraryRandom.RandInt(10));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD02" in exported file
        VerifyTipoDocumento(ServerFileName, 'TD02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDocumentTD02ForSalesPrepaymentCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Prepayment]
        // [SCENARIO 287458] The node "TipoDocumento" has value "TD02" for sales prepayment credit memo

        Initialize;

        // [GIVEN] Posted Sales Prepayment Credit Memo
        CustomerNo := CreateCustomerWithPmtSetup;
        CreateSalesDocWithPrepmt(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, LibraryRandom.RandInt(10));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD02" in exported file
        VerifyTipoDocumento(ServerFileName, 'TD02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDocumentTD01ForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 287458] The node "TipoDocumento" has value "TD01" for sales  invoice

        Initialize;

        // [GIVEN] Posted Sales Invoice
        CustomerNo := CreateCustomerWithPmtSetup;
        CreateSalesDocWithPrepmt(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD01" in exported file
        VerifyTipoDocumento(ServerFileName, 'TD01');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDocumentTD04ForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 287458] The node "TipoDocumento" has value "TD04" for sales credit memo

        Initialize;

        // [GIVEN] Posted Sales Credit Memo
        CustomerNo := CreateCustomerWithPmtSetup;
        CreateSalesDocWithPrepmt(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD04" in exported file
        VerifyTipoDocumento(ServerFileName, 'TD04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDocumentTD20ForSalesInvoiceWhenVATRegistrationMatchesCompanyInfo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 298050] The node "TipoDocumento" has value "TD20" for self-billing sales invoice when "VAT Registration No." of Company Information matches to same number in customer card

        Initialize;

        // [GIVEN] Company Information with "VAT Registration No." = "X"
        // [GIVEN] Customer with "VAT Registration No." = "X"
        // [GIVEN] Posted Sales Invoice
        CustomerNo := CreateCustomerWithPmtSetup;
        SetVATRegistrationNoInCompanyInfoFromCustomer(CustomerNo);

        CreateSalesDocWithPrepmt(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD01" in exported file
        VerifyTipoDocumento(ServerFileName, 'TD20');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDocumentTD20ForSalesCrMemoWhenVATRegistrationMatchesCompanyInfo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 298050] The node "TipoDocumento" has value "TD20" for self-billing sales credit memo when "VAT Registration No." of Company Information matches to same number in customer card

        Initialize;

        // [GIVEN] Company Information with "VAT Registration No." = "X"
        // [GIVEN] Customer with "VAT Registration No." = "X"
        // [GIVEN] Posted Sales Credit Memo
        CustomerNo := CreateCustomerWithPmtSetup;
        SetVATRegistrationNoInCompanyInfoFromCustomer(CustomerNo);
        CreateSalesDocWithPrepmt(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD04" in exported file
        VerifyTipoDocumento(ServerFileName, 'TD20');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RiferimentoNormativoNodeHasVATTransNature()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Record "VAT Identifier";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294603] RiferimentoNormativo node has value of VAT Identifier description

        Initialize;

        // [GIVEN] Posted Sales Invoice with VAT Posting Setup with "VAT %" = 0 and "VAT Identifier" with description "X"
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateSalesDocWithVATTransNatureAndZeroVATRate(SalesHeader, SalesLine, VATPostingSetup, CustomerNo);
        SetVATIdentifierInSalesLine(SalesLine);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] RiferimentoNormativo node has value "X"
        VATIdentifier.Get(SalesLine."VAT Identifier");
        VerifyRiferimentoNormativoNode(ServerFileName, VATIdentifier.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RiferimentoNormativoNodeHasVATTransNatureAndExemption()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Record "VAT Identifier";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        VATExemption: Record "VAT Exemption";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294603] RiferimentoNormativo node has value of VAT Identifier description and VAT Exemption No. and Date formatted to dd/mm/yyyy

        Initialize;

        // [GIVEN] Validated the VAT Exemption Nos. in Purchases & Payables Setup
        UpdatePurchasesPayablesSetupVATExemptionNos(LibraryERM.CreateNoSeriesCode);

        // [GIVEN] Posted Sales Invoice with VAT Posting Setup with "VAT %" = 0, "VAT Identifier" with description "X", "VAT Exemption No." = "Y" and "VAT Exemption Date" = 01.02.2019 (dd.mm.yyyy format)
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateVATExemptionForCustomer(VATExemption, CustomerNo);
        CreateSalesDocWithVATTransNatureAndZeroVATRate(SalesHeader, SalesLine, VATPostingSetup, CustomerNo);
        SetVATIdentifierInSalesLine(SalesLine);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] RiferimentoNormativo node has value "X Dich.Intento n. Y del 02/01/2019"
        VATIdentifier.Get(SalesLine."VAT Identifier");
        VerifyRiferimentoNormativoNode(
          ServerFileName, StrSubstNo('%1 %2 %3', VATIdentifier.Description, VATExemptionPrefixTok,
            StrSubstNo(ExemptionDataMsg, VATExemption."VAT Exempt. No.",
              Format(VATExemption."VAT Exempt. Date", 0, '<Day,2>/<Month,2>/<Year4>'))));

        // Tear down
        VATBusinessPostingGroup.Get(SalesHeader."VAT Bus. Posting Group");
        VATBusinessPostingGroup.Validate("Check VAT Exemption", false);
        VATBusinessPostingGroup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RiferimentoNormativoNodeHasVATTransNatureAndExemptionWithProgressiveNo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Record "VAT Identifier";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        VATExemption: Record "VAT Exemption";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
        ExpectedVATExemptNo: Text;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 341871] RiferimentoNormativo node has value of VAT Identifier description and VAT Exemption No. plus Progressive No. and Date formatted to dd/mm/yyyy

        Initialize;

        // [GIVEN] Validated the VAT Exemption Nos. in Purchases & Payables Setup
        UpdatePurchasesPayablesSetupVATExemptionNos(LibraryERM.CreateNoSeriesCode);

        // [GIVEN] Posted Sales Invoice with VAT Posting Setup with "VAT %" = 0, "VAT Identifier" with description "X", "VAT Exemption No." = "Y", "Consecutive VAT Exempt. No." = "001" and "VAT Exemption Date" = 01.02.2019 (dd.mm.yyyy format)
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateVATExemptionForCustomer(VATExemption, CustomerNo);
        VATExemption.Validate("Consecutive VAT Exempt. No.", LibraryUtility.GenerateGUID);
        VATExemption.Modify(true);
        CreateSalesDocWithVATTransNatureAndZeroVATRate(SalesHeader, SalesLine, VATPostingSetup, CustomerNo);
        SetVATIdentifierInSalesLine(SalesLine);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] RiferimentoNormativo node has value "X Dich.Intento n. Y-001 del 02/01/2019"
        ExpectedVATExemptNo := VATExemption."VAT Exempt. No." + '-' + VATExemption."Consecutive VAT Exempt. No.";
        VATIdentifier.Get(SalesLine."VAT Identifier");
        VerifyRiferimentoNormativoNode(
          ServerFileName, StrSubstNo('%1 %2 %3', VATIdentifier.Description, VATExemptionPrefixTok,
            StrSubstNo(ExemptionDataMsg, ExpectedVATExemptNo,
              Format(VATExemption."VAT Exempt. Date", 0, '<Day,2>/<Month,2>/<Year4>'))));

        // Tear down
        VATBusinessPostingGroup.Get(SalesHeader."VAT Bus. Posting Group");
        VATBusinessPostingGroup.Validate("Check VAT Exemption", false);
        VATBusinessPostingGroup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithRemovedExtendedText()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ItemNo: Code[20];
        DocumentNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEAUTURE] [Sales] [Irder] [Extended Text] [Standard Text]
        // [SCENARIO 295046] No node AltriDatiGestionali exported when extended text removed from Sales Order before invoicing

        Initialize;

        // [GIVEN] Item with multiple extended texts
        ItemNo := CreateItemWithMultipleExtendedText;

        // [GIVEN] Posted Sales Order with Item and extended texts as Shipment
        // [GIVEN] Removed all lines with extended texts
        // [GIVEN] Posted Sales Order as Invoice
        DocumentNo := CreateSalesOrderWithRemovedExtText(ItemNo);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] No AltriDatiGestionali node exported
        VerifyNoAltriDatiGestionaliNodes(ServerFileName);
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);

        // [THEN] DatiBeniServizi located under FattiraElectronicBody
        VerifyDatiBeniServiziHasLineData(ServerFileName, SalesInvoiceLine.Description, 1);
        DeleteServerFile(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithRemovedExtendedText()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEAUTURE] [Service] [Order] [Extended Text] [Standard Text]
        // [SCENARIO 295046] No AltriDatiGestionali node exported when extended text removed from Service Order before invoicing

        Initialize;

        // [GIVEN] Item with multiple extended texts
        CustomerNo := LibraryITLocalization.CreateCustomer;
        ItemNo := CreateItemWithMultipleExtendedText;

        // [GIVEN] Posted Service Order with Item and extended texts as Shipment
        // [GIVEN] Removed all lines with extended texts
        // [GIVEN] Posted Service Order as Invoice
        CreateServOrderWithRemovedExtText(CustomerNo, ItemNo);
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] No AltriDatiGestionali node exported
        VerifyNoAltriDatiGestionaliNodes(ServerFileName);
        FindServiceInvoiceLine(ServiceInvoiceLine, CustomerNo);

        // [THEN] DatiBeniServizi located under FattiraElectronicBody
        VerifyDatiBeniServiziHasLineData(ServerFileName, ServiceInvoiceLine.Description, 1);
        DeleteServerFile(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAltriDatiGestionaliNodeIfExtendedTextValueIsBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ItemNo: Code[20];
        DocumentNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEAUTURE] [Sales] [Invoice] [Extended Text] [Standard Text]
        // [SCENARIO 295878] No AltriDatiGestionali node in XML file when extended text value is blank

        Initialize;

        // [GIVEN] Item with blank extended text
        ItemNo := CreateItemWithBlankExtendedText;

        // [GIVEN] Posted Sales invoice with extended text inserted
        CreateSalesDocWithItemAndExtendedText(SalesHeader, SalesHeader."Document Type"::Invoice, ItemNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] No AltriDatiGestionali node in the exported XML file
        VerifyNoAltriDatiGestionaliNode(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDatiOrdineAcquistoNodeIfOneShipment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Order] [Shipment]
        // [SCENARIO 295878] No DatiOrdineAcquisto node if only one shipment was posted

        Initialize;
        CustomerNo := LibraryITLocalization.CreateCustomer;

        // [GIVEN] Sales order with one line shipped
        PostSalesOrderOneLineShipped(CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] No DatiOrdineAcquisto node exists in the exported XML file
        VerifyNoDatiOrdineAcquistoNode(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDetailsForZeroTotalDocumentAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
        LineAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 297021] "DatiBeniServizi" (line details) is printed into XML in case of total document amount is zero
        Initialize;

        // [GIVEN] Posted sales invoice with two lines with Amounts 100, -100 (total zero)
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibraryITLocalization.CreateCustomer);
        LineAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateSalesLine(SalesLine[1], SalesHeader, LineAmount);
        CreateSalesLine(SalesLine[2], SalesHeader, -LineAmount);
        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          ServerFileName, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] "ImportoTotaleDocumento" = 0 (total document amount)
        // [THEN] "DatiBeniServizi" is printed for both document lines
        VerifyDocumentTotalAmount(ServerFileName, 0);
        VerifyDatiBeniServiziHasLineData(ServerFileName, SalesLine[1].Description, 1);
        VerifyDatiBeniServiziHasLineData(ServerFileName, SalesLine[2].Description, 2);
        DeleteServerFile(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvStandardTextExportsWithInvalidCharacter()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        StandardText: Record "Standard Text";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemNo: Code[20];
        DocumentNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
        EuroChar: Char;
    begin
        // [FEAUTURE] [Sales] [Invoice] [Standard Text]
        // [SCENARIO 297997] Euro specical char replaced with EUR when exported to XML
        Initialize;

        ItemNo := CreateItemWithMultipleExtendedText;

        // [GIVEN] Posted Sales invoice with standard text containing 'ъ' character
        CreateSalesDocWithItemAndExtendedText(SalesHeader, SalesHeader."Document Type"::Invoice, ItemNo);
        CreateStandardText(StandardText);
        EuroChar := 8364;
        StandardText.Validate(Description, Format(EuroChar));
        StandardText.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", StandardText.Code, 0);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Euro special character replaced with 'EUR' text
        // TFS 387861: Each RiferimentoTesto tag should be under the AltriDatiGestionali tag
        VerifyAltriDatiGestionaliByExtTextLines(TempXMLBuffer, ServerFileName, ItemNo);
        VerifyAltriDatiGestionaliShortText(TempXMLBuffer, StandardText.Code, StandardText.Description);
        DeleteServerFile(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImpostaNodeHasTotalAmountFromVATEntriesForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Rounding]
        // [SCENARIO 297990] Imposta node has value of total VAT amount of the Sales Invoice coming from VAT entries which considers rounding

        Initialize;

        // [GIVEN] Sales Invoice with multiples lines, all with fixed values which finally leads to rounding
        CreateSalesDocWithRounding(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          ServerFileName, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Imposta node has correctly rounded value
        VerifySingleDatiRiepilogo(ServerFileName, 176.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImpostaNodeHasTotalAmountFromVATEntriesForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Rounding]
        // [SCENARIO 297990] Imposta node has value of total VAT amount of the Sales Credit Memo coming from VAT entries

        Initialize;

        // [GIVEN] Sales Credit Memo with multiples lines, all with fixed values which finally leads to rounding
        CreateSalesDocWithRounding(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          ServerFileName, ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Imposta node has correctly rounded value
        VerifySingleDatiRiepilogo(ServerFileName, 176.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImpostaNodeHasTotalAmountFromVATEntriesForServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Rounding]
        // [SCENARIO 297990] Imposta node has value of total VAT amount of the Service Invoice coming from VAT entries which considers rounding

        Initialize;

        // [GIVEN] Service Invoice with multiples lines, all with fixed values which finally leads to rounding
        CreateServiceDocWithRounding(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          ServerFileName, ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Imposta node has correctly rounded value
        VerifySingleDatiRiepilogo(ServerFileName, 176.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImpostaNodeHasTotalAmountFromVATEntriesForServiceCrMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Rounding]
        // [SCENARIO 297990] Imposta node has value of total VAT amount of the Service Credit Memo coming from VAT entries which considers rounding

        Initialize;

        // [GIVEN] Service Credit Memo with multiples lines, all with fixed values which finally leads to rounding
        CreateServiceDocWithRounding(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceCrMemoHeader.SetRange("Customer No.", ServiceHeader."Customer No.");

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          ServerFileName, ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Imposta node has correctly rounded value
        VerifySingleDatiRiepilogo(ServerFileName, 176.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityXMLNodeValueHasFiveDecimalPlacesWhen()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 298038] A value in XML node for Quantity has five decimal places

        Initialize;

        // [GIVEN] Posted Sales Invoice with Quantity = 2.33333
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibraryITLocalization.CreateCustomer);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandDec(100, 5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          ServerFileName, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Quantita XML node has value "2.33333"
        VerifyQuantitaNode(ServerFileName, Format(SalesLine.Quantity, 0, '<Precision,2:5><Standard Format,9>'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CodiceFiscaleNodeUsedInsteadOfIDCodiceForIndividualPerson()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 299242] A "CodiceFiscale" node used in exported XML file instead of "IDCodice" for Individual Person

        Initialize;

        // [GIVEN] Posted Sales Invoice with Customer as Individual Person. "Fiscal Code" of the customer is "X", "VAT Registration No." is blank
        CreateCustomerAsIndividualPerson(Customer);
        CreateSalesDocWithPrepmt(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", 0);

        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          ServerFileName, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] A "CodiceFiscale" node has value "X"
        // TFS ID: 365067
        // [THEN] IdFiscaleIVA parent node does not exist
        VerifyIndividualPersonData(ServerFileName, Customer."Fiscal Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleDatiRiepilogoNodesExportsPerEachVATTransactionNature()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
        AmountArray: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 310192] Multiple DatiRiepilogo nodes exported per each "VAT Transaction Nature"

        Initialize;

        // [GIVEN] Posted Sales Invoice with multiple lines, each has its own "VAT Transaction Nature" code and VAT amounts "X" and "Y" accordingly
        CreateSalesDocWithMultipleVATTransNatures(SalesHeader, SalesLine, VATPostingSetup);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Two DatiRiepilogo exported, one with "X" and one with "Y"
        GetVATEntryAmounts(AmountArray, DocumentNo, SalesHeader."Posting Date");
        VerifyMultipleDatiRiepilogoNodes(ServerFileName, AmountArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LiquidationXMLNodeHasValueLSIfCompanyInLiquidation()
    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [SCENARIO 311977] A liquidation status StatoLiqudazione has value "LS" if "Liquidation Status" is "In Liquidation"

        Initialize;

        // [GIVEN] "Liquidation Status" is "In Liquidation" in Company Information
        CompanyInformation.Get();
        CompanyInformation.Validate("Liquidation Status", CompanyInformation."Liquidation Status"::"In Liquidation");
        CompanyInformation.Modify(true);

        // [GIVEN] Posted Sales Invoice
        DocumentNo := PostSalesInvoice(CreatePaymentMethod, CreatePaymentTerms);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] "StatoLiqudazione" node has value "LS"
        VerifyStatoLiqudazioneNode(ServerFileName, 'LS');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImponibileImportoNodeWhenSalesInvoiceHasPositiveAndNegativeLines()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
        VATAmount: array[2] of Decimal;
    begin
        // [SCENARIO 314517] ImponibileImporto node has either positive or negative value depends on the sign of original sales invoice
        // [FEATURE] [Sales] [Invoice]

        Initialize;

        // [GIVEN] Sales invoice with two lines
        // [GIVEN] First line has VAT Amount = 20
        // [GIVEN] Second line has VAT Amount = -15
        PostSalesDocWithPosAndNegLines(DocNo, VATAmount, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader.SetRange("No.", DocNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Two ImponibleImporto nodes exported
        // [THEN] First one has value 20
        // [THEN] Second one has value -15
        VerifyImponibileImportoNodes(ServerFileName, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImponibileImportoNodeWhenSalesCrMemoHasPositiveAndNegativeLines()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
        VATAmount: array[2] of Decimal;
    begin
        // [SCENARIO 314517] ImponibileImporto node has either positive or negative value depends on the sign of original sales credit memo
        // [FEATURE] [Sales] [Invoice]

        Initialize;

        // [GIVEN] Sales credit memo with two lines
        // [GIVEN] First line has VAT Amount = 20
        // [GIVEN] Second line has VAT Amount = -15
        PostSalesDocWithPosAndNegLines(DocNo, VATAmount, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.SetRange("No.", DocNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Two ImponibleImporto nodes exported
        // [THEN] First one has value 20
        // [THEN] Second one has value -15
        VerifyImponibileImportoNodes(ServerFileName, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RiferimentoNumeroLineaNodeDoesNotExistUnderSalesDatiDDTNodeWithSingleShipment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        PostedInvNo: Code[20];
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Shipment]
        // [SCENARIO 355434] RiferimentoNumeroLinea xml node does not exist under the DatiDDT xml node after posting Sales Invoice with the single shipment

        Initialize();
        CustomerNo := LibraryITLocalization.CreateCustomer();

        // [GIVEN] Posted sales order posted as shipment
        CreateAndPostSalesOrder(CustomerNo, 1, true, false);

        // [GIVEN] Posted sales Invoice with shipment
        PostedInvNo := CreateSalesInvFromShipment(CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("No.", PostedInvNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] RiferimentoNumeroLinea does not exist in the exported file
        VerifyNoRiferimentoNumeroLineaNodeExists(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RiferimentoNumeroLineaNodeDoesNotExistUnderServDatiDDTNodeWithSingleShipment()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Shipment]
        // [SCENARIO 355434] RiferimentoNumeroLinea xml node does not exist under the DatiDDT xml node after posting Service Invoice with the single shipment

        Initialize();
        CustomerNo := LibraryITLocalization.CreateCustomer();

        // [GIVEN] Posted service order posted as shipment
        CreateAndPostServOrder(CustomerNo, 1, true, false);

        // [GIVEN] Posted service Invoice with shipment"
        CreateServInvFromShipment(ServiceInvoiceHeader, CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        ServiceInvoiceHeader.SetRange("No.", ServiceInvoiceHeader."No.");
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] RiferimentoNumeroLinea does not exist in the exported file
        VerifyNoRiferimentoNumeroLineaNodeExists(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaProjectAndTenderCodesExportToDatiOrdineNodeForGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 392702] Fattura Project and Fattura Tender codes export under the DatiOrdine XML node for the line with G/L Account

        Initialize();

        // [GIVEN] Sales order with G/L Account and Fattura Project Code = "X", Fattura Tender Code = "Y"
        PostSalesOrderWithGLAccountAndFatturaCodes(SalesHeader, LibraryITLocalization.CreateCustomer());

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] DatiOrdineAcquisto node has two child nodes with values "X" and "Y"
        VerifyDatiOrdineAcquistoWithFatturaCodes(ServerFileName, SalesHeader."Fattura Project Code", SalesHeader."Fattura Tender Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDataExportsFromTheSalesInvoiceCombinedOfMultipleShipments()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        PostedInvNo: Code[20];
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Invoice] [Shipment]
        // [SCENARIO 395112] Fattura Data takes from each shipped sales order to be exported for the sales invoice that combines these shipments

        Initialize();
        CustomerNo := LibraryITLocalization.CreateCustomer();

        // [GIVEN] First shipped sales order with "Customer Purchase Order" = "X1", "Fattura Project Code" = "X2", "Fattura Tender Code" = "X3"
        // [GIVEN] Second shipped sales order with "Customer Purchase Order" = "Y1", "Fattura Project Code" = "Y2", "Fattura Tender Code" = "Y3"
        for i := 1 to ArrayLen(SalesHeader) do begin
            CreateSalesHeader(SalesHeader[i], SalesHeader[i]."Document Type"::Order, CustomerNo);
            SalesHeader[i].Validate("Fattura Project Code", LibraryITLocalization.CreateFatturaProjectCode());
            SalesHeader[i].Validate("Fattura Tender Code", LibraryITLocalization.CreateFatturaTenderCode());
            SalesHeader[i].Validate("Customer Purchase Order No.", LibraryUtility.GenerateGUID());
            SalesHeader[i].Modify(true);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader[i], SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader[i], true, false);
        end;

        // [GIVEN] Posted sales invoice combines from order shipments
        PostedInvNo := CreateSalesInvFromShipment(CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        SalesInvoiceHeader.SetRange("No.", PostedInvNo);
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Two DatiOrderLineAcquisto xml nodes
        // [THEN] The first one has all the data from the first shipped order (X1, X2, X3)
        // [THEN] The second one has all the data from the second shipped order (Y1, Y2, Y3)
        VerifyDatiOrdineAcquistoFatturaDataFromMultipleSalesOrders(ServerFileName, SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDataExportsFromTheServiceInvoiceCombinedOfMultipleShipments()
    var
        ServiceHeader: array[2] of Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceItem: Record "Service Item";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ServerFileName: Text[250];
        ClientFileName: Text[250];
        i: Integer;
    begin
        // [FEATURE] [Service] [Invoice] [Shipment]
        // [SCENARIO 395112] Fattura Data takes from each shipped service order to be exported for the service invoice that combines these shipments

        Initialize();
        CustomerNo := LibraryITLocalization.CreateCustomer();

        // [GIVEN] First shipped service order with "Customer Purchase Order" = "X1", "Fattura Project Code" = "X2", "Fattura Tender Code" = "X3"
        // [GIVEN] Second shipped service order with "Customer Purchase Order" = "Y1", "Fattura Project Code" = "Y2", "Fattura Tender Code" = "Y3"
        for i := 1 to ArrayLen(ServiceHeader) do begin
            CreateServiceHeader(ServiceHeader[i], ServiceHeader[i]."Document Type"::Order, CustomerNo);
            ServiceHeader[i].Validate("Fattura Project Code", LibraryITLocalization.CreateFatturaProjectCode());
            ServiceHeader[i].Validate("Fattura Tender Code", LibraryITLocalization.CreateFatturaTenderCode());
            ServiceHeader[i].Validate("Customer Purchase Order No.", LibraryUtility.GenerateGUID());
            ServiceHeader[i].Modify(true);
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader[i]."Customer No.");
            CreateServiceLineWithItem(ServiceLine, ServiceHeader[i], ServiceItem, '');
            LibraryService.PostServiceOrder(ServiceHeader[i], true, false, false);
        end;

        // [GIVEN] Posted service invoice combines from order shipments
        CreateServInvFromShipment(ServiceInvoiceHeader, CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        ServiceInvoiceHeader.SetRange("No.", ServiceInvoiceHeader."No.");
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Two DatiOrderLineAcquisto xml nodes
        // [THEN] The first one has all the data from the first shipped order (X1, X2, X3)
        // [THEN] The second one has all the data from the second shipped order (Y1, Y2, Y3)
        VerifyDatiOrdineAcquistoFatturaDataFromMultipleServiceOrders(ServerFileName, ServiceHeader);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA;
        LibrarySetupStorage.SaveCompanyInformation;
        LibrarySetupStorage.SaveSalesSetup;
        LibrarySetupStorage.SavePurchasesSetup;
        IsInitialized := true;
    end;

    local procedure DeleteServerFile(ServerFileName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.DeleteServerFile(ServerFileName);
    end;

    local procedure PostSalesInvoice(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        CustomerNo := LibraryITLocalization.CreateCustomer;
        CreateSalesDocument(
          SalesHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, SalesHeader."Document Type"::Invoice);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, CustomerNo, '', 5, '', 0D);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
        UpdateItemGTIN(SalesLine."No.", Format(LibraryRandom.RandIntInRange(1000, 2000)));
    end;

    local procedure CreateSalesDocWithItemAndStandardText(var StandardText: Record "Standard Text"; DocType: Enum "Sales Document Type"; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocWithItemAndExtendedText(SalesHeader, DocType, ItemNo);
        CreateStandardText(StandardText);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", StandardText.Code, 0);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocWithItemAndExtendedText(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CreateSalesHeader(SalesHeader, DocType, LibraryITLocalization.CreateCustomer);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
        TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure CreateSalesDocWithVATTransNatureAndZeroVATRate(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20])
    begin
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader);
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Validate("VAT Transaction Nature", LibrarySplitVAT.CreateVATTransactionNatureCode);
        VATPostingSetup.Modify(true);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocWithMultipleVATTransNatures(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATPostingSetup: array[2] of Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        i: Integer;
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibraryITLocalization.CreateCustomer);
        for i := 1 to ArrayLen(VATPostingSetup) do begin
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup[1], SalesHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
            VATPostingSetup[1].Validate("VAT %", LibraryRandom.RandDec(10, 2));
            VATPostingSetup[1].Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo);
            VATPostingSetup[1].Validate("VAT Transaction Nature", LibrarySplitVAT.CreateVATTransactionNatureCode);
            VATPostingSetup[1].Modify(true);
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
            SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group");
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateSalesOrderWithRemovedExtText(ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibraryITLocalization.CreateCustomer);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
        TransferExtendedText.InsertSalesExtText(SalesLine);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        RemoveSalesLinesAttachedToCurrentLine(SalesLine);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocWithRounding(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateSalesHeader(SalesHeader, DocType, LibraryITLocalization.CreateCustomer);
        LibraryInventory.CreateItem(Item);
        VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 22);
        VATPostingSetup.Modify(true);

        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 56.25);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 11.25);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 56.25);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 158.0);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 9.75);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 9.1);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 158.0);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 90.0);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 11.25);
        CreateSalesLineWithProductGroup(SalesLine, SalesHeader, Item."No.", VATPostingSetup."VAT Prod. Posting Group", 243.0);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithProductGroup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VATProdPostingGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateServDocWithItemAndStandardText(var StandardText: Record "Standard Text"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CreateServiceHeader(ServiceHeader, DocType, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem, ItemNo);

        TransferExtendedText.ServCheckIfAnyExtText(ServiceLine, true);
        TransferExtendedText.InsertServExtText(ServiceLine);

        CreateStandardText(StandardText);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::" ", StandardText.Code);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateServOrderWithRemovedExtText(CustomerNo: Code[20]; ItemNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem, ItemNo);

        TransferExtendedText.ServCheckIfAnyExtText(ServiceLine, true);
        TransferExtendedText.InsertServExtText(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        RemoveServiceLinesAttachedToCurrentLine(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateServiceDocWithRounding(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceItem: Record "Service Item";
    begin
        CreateServiceHeader(ServiceHeader, DocType, LibraryITLocalization.CreateCustomer);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        VATPostingSetup.Get(ServiceHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 22);
        VATPostingSetup.Modify(true);

        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 56.25);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 11.25);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 56.25);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 158.0);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 9.75);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 9.1);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 158.0);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 90.0);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 11.25);
        CreateServiceLineWithProductGroup(
          ServiceLine, ServiceHeader, Item."No.", ServiceItem."No.", VATPostingSetup."VAT Prod. Posting Group", 243.0);
    end;

    local procedure CreateServiceLineWithProductGroup(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ServiceItemNo: Code[20]; VATProdPostingGroupCode: Code[20]; UnitPrice: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure CreateAndPostSalesOrder(CustomerNo: Code[20]; LinesNo: Integer; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        for i := 1 to LinesNo do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
        exit(SalesHeader."No.");
    end;

    local procedure CreateAndPostServOrder(CustomerNo: Code[20]; LinesNo: Integer; Ship: Boolean; Invoice: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        i: Integer;
    begin
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        for i := 1 to LinesNo do
            CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem, '');
        LibraryService.PostServiceOrder(ServiceHeader, Ship, false, Invoice);
    end;

    local procedure CreateCustomerWithPmtSetup(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibraryITLocalization.CreateCustomer);
        Customer.Validate("Payment Method Code", CreatePaymentMethod);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerAsIndividualPerson(var Customer: Record Customer)
    begin
        Customer.Get(CreateCustomerWithPmtSetup);
        Customer.Validate("Individual Person", true);
        Customer.Validate("First Name", LibraryUtility.GenerateGUID);
        Customer.Validate("Last Name", LibraryUtility.GenerateGUID);
        Customer.Validate("VAT Registration No.", '');
        Customer.Modify(true);
    end;

    local procedure CreateItemWithMultipleExtendedText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        i: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Rename(PadStr(Item."No.", MaxStrLen(Item."No."), 'X'));
        CreateExtendedTextHeader(ExtendedTextHeader, Item."No.");
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            CreateExtendedTextLine(
              ExtendedTextHeader,
              LibraryUtility.GenerateRandomXMLText(MaxStrLen(ExtendedTextLine.Text)));
        exit(Item."No.");
    end;

    local procedure CreateItemWithBlankExtendedText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Rename(PadStr(Item."No.", MaxStrLen(Item."No."), 'X'));
        CreateExtendedTextHeader(ExtendedTextHeader, Item."No.");
        CreateExtendedTextLine(ExtendedTextHeader, '');
        exit(Item."No.");
    end;

    local procedure CreateExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; ItemNo: Code[20])
    begin
        LibraryService.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        ExtendedTextHeader.Validate("Starting Date", WorkDate);
        ExtendedTextHeader.Validate("Ending Date", WorkDate);
        ExtendedTextHeader.Validate("Sales Invoice", true);
        ExtendedTextHeader.Validate("Sales Credit Memo", true);
        ExtendedTextHeader.Validate("Service Invoice", true);
        ExtendedTextHeader.Validate("Service Credit Memo", true);
        ExtendedTextHeader.Modify(true);
    end;

    local procedure CreateExtendedTextLine(ExtendedTextHeader: Record "Extended Text Header"; TextValue: Text)
    var
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryService.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, CopyStr(TextValue, 1, MaxStrLen(ExtendedTextLine.Text)));
        ExtendedTextLine.Modify(true);
    end;

    local procedure CreatePaymentMethod(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentMethodCode);
    end;

    local procedure CreatePaymentTerms(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentTermsCode);
    end;

    local procedure CreatePaymentTermsWithMultiplePmtLines(): Code[10]
    var
        PaymentLines: Record "Payment Lines";
        PmtTermsCode: Code[10];
        i: Integer;
    begin
        PmtTermsCode := LibraryITLocalization.CreateFatturaPaymentTermsCode;
        PaymentLines.SetRange(Type, PaymentLines.Type::"Payment Terms");
        PaymentLines.SetRange(Code, PmtTermsCode);
        PaymentLines.DeleteAll(true);
        for i := 1 to 2 do begin
            LibraryERM.CreatePaymentLines(
              PaymentLines, PaymentLines."Sales/Purchase"::" ", PaymentLines.Type::"Payment Terms", PmtTermsCode, '', 0);
            Evaluate(PaymentLines."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(30)) + 'D>');
            PaymentLines.Validate("Due Date Calculation", PaymentLines."Due Date Calculation");
            PaymentLines.Validate("Payment %", 50);
            PaymentLines.Modify(true);
        end;
        exit(PmtTermsCode);
    end;

    local procedure CreateSalesInvFromShipment(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateServInvFromShipment(var ServiceInvoiceHeader: Record "Service Invoice Header"; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceGetShipment: Codeunit "Service-Get Shipment";
    begin
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceShipmentLine.SetRange("Customer No.", CustomerNo);
        ServiceGetShipment.SetServiceHeader(ServiceHeader);
        ServiceGetShipment.CreateInvLines(ServiceShipmentLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst;
    end;

    local procedure CreateSalesLineWithSalesVATPct(SalesHeader: Record "Sales Header"; CurrSalesLine: Record "Sales Line"; VATPct: Decimal): Decimal
    var
        GLAccount: Record "G/L Account";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        VATPostingSetup.Get(CurrSalesLine."VAT Bus. Posting Group", CurrSalesLine."VAT Prod. Posting Group");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate(
          "Sales VAT Account", LibraryERM.CreateGLAccountNo);
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
        exit(Round(SalesLine."Line Amount" * SalesLine."VAT %" / 100));
    end;

    local procedure CreateStandardText(var StandardText: Record "Standard Text"): Text[100]
    begin
        LibrarySales.CreateStandardText(StandardText);
        StandardText.Rename(PadStr(StandardText.Code, MaxStrLen(StandardText.Code), 'X'));
        StandardText.Validate(Description,
          LibraryUtility.GenerateRandomXMLText(MaxStrLen(StandardText.Description)));
        StandardText.Modify();
        exit(StandardText.Description);
    end;

    local procedure CreateSalesLineWithQtyToShip(SalesHeader: Record "Sales Header"; Quantity: Decimal; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateServLineWithQtyToShip(ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; Quantity: Decimal; QtyToShip: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Ship", QtyToShip);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateSalesDocWithPrepmt(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; PrepmtPct: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        SalesHeader.Validate("Prepayment %", PrepmtPct);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATExemptionForCustomer(var VATExemption: Record "VAT Exemption"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        VATExemption.Init();
        VATExemption.Validate(Type, VATExemption.Type::Customer);
        VATExemption.Validate("No.", CustNo);
        VATExemption.Validate("VAT Exempt. Starting Date", WorkDate);
        VATExemption.Validate("VAT Exempt. Ending Date", CalcDate('<+1D>', WorkDate));
        VATExemption.Validate("VAT Exempt. Int. Registry No.",
          LibraryUtility.GenerateRandomCode(VATExemption.FieldNo("VAT Exempt. Int. Registry No."), DATABASE::"VAT Exemption"));
        VATExemption.Validate("VAT Exempt. No.",
          LibraryUtility.GenerateRandomCode(VATExemption.FieldNo("VAT Exempt. No."), DATABASE::"VAT Exemption"));
        VATExemption.Validate("VAT Exempt. Date", LibraryRandom.RandDate(10));
        VATExemption.Insert(true);

        Customer.Get(CustNo);
        SetCheckInVATBusPostingGroupExemption(Customer."VAT Bus. Posting Group");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms);
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethod);
        SalesHeader.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type"; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, CustomerNo);
        ServiceHeader.Validate("Order Date", WorkDate);
        ServiceHeader.Validate("Payment Method Code", CreatePaymentMethod);
        ServiceHeader.Validate("Payment Terms Code", CreatePaymentTerms);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; ItemNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure PostSalesOrderSomeLinesShipped(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithQtyToShip(SalesHeader, 1, 0);
        CreateSalesLineWithQtyToShip(SalesHeader, 1, 1);
        CreateSalesLineWithQtyToShip(SalesHeader, 1, 0);
        CreateSalesLineWithQtyToShip(SalesHeader, 3, 1);
        CreateSalesLineWithQtyToShip(SalesHeader, 5, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."No.");
    end;

    local procedure PostSalesOrderOneLineShipped(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithQtyToShip(SalesHeader, 1, 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."No.");
    end;

    local procedure PostServOrderSomeLinesShipped(CustomerNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        CreateServLineWithQtyToShip(ServiceHeader, ServiceItem, 1, 0);
        CreateServLineWithQtyToShip(ServiceHeader, ServiceItem, 1, 1);
        CreateServLineWithQtyToShip(ServiceHeader, ServiceItem, 1, 0);
        CreateServLineWithQtyToShip(ServiceHeader, ServiceItem, 3, 1);
        CreateServLineWithQtyToShip(ServiceHeader, ServiceItem, 5, 0);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure PostSalesDocWithPosAndNegLines(var DocNo: Code[20]; var VATAmount: array[2] of Decimal; DocType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        UnitPrice: Decimal;
    begin
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, LibraryITLocalization.CreateCustomer, DocType);
        FindSalesLine(SalesLine, SalesHeader);
        VATAmount[1] := SalesLine.Amount;
        UnitPrice := SalesLine."Unit Price";

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo);
        VATPostingSetup.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, -1);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        VATAmount[2] := SalesLine.Amount;

        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostSalesOrderWithGLAccountAndFatturaCodes(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Fattura Project Code", LibraryITLocalization.CreateFatturaProjectCode);
        SalesHeader.Validate("Fattura Tender Code", LibraryITLocalization.CreateFatturaTenderCode);
        SalesHeader.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure FormatDate(DateToFormat: Date): Text
    begin
        exit(Format(DateToFormat, 0, '<Standard Format,9>'));
    end;

    local procedure AssertElementValue(var TempXMLBuffer: Record "XML Buffer" temporary; ElementName: Text; ElementValue: Text)
    begin
        FindNextElement(TempXMLBuffer);
        Assert.AreEqual(ElementName, TempXMLBuffer.GetElementName,
          StrSubstNo(UnexpectedElementNameErr, ElementName, TempXMLBuffer.GetElementName));
        Assert.AreEqual(ElementValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, ElementName, ElementValue, TempXMLBuffer.Value));
    end;

    local procedure AssertCurrentElementValue(TempXMLBuffer: Record "XML Buffer" temporary; ExpectedValue: Text)
    begin
        Assert.AreEqual(ExpectedValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, TempXMLBuffer.GetElementName, ExpectedValue, TempXMLBuffer.Value));
    end;

    local procedure FindNextElement(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        if TempXMLBuffer.HasChildNodes then
            TempXMLBuffer.FindChildElements(TempXMLBuffer)
        else
            if not (TempXMLBuffer.Next > 0) then begin
                TempXMLBuffer.GetParent;
                TempXMLBuffer.SetRange("Parent Entry No.", TempXMLBuffer."Parent Entry No.");
                if not (TempXMLBuffer.Next > 0) then
                    repeat
                        TempXMLBuffer.GetParent;
                        TempXMLBuffer.SetRange("Parent Entry No.", TempXMLBuffer."Parent Entry No.");
                    until (TempXMLBuffer.Next > 0);
            end;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; InvoiceNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.FindFirst;
    end;

    local procedure FindServiceInvoiceLine(var ServiceInvoiceLine: Record "Service Invoice Line"; CustNo: Code[20])
    begin
        ServiceInvoiceLine.SetRange("Bill-to Customer No.", CustNo);
        ServiceInvoiceLine.FindFirst;
    end;

    local procedure RemoveSalesLinesAttachedToCurrentLine(SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.SetRange("Attached to Line No.", SalesLine."Line No.");
        SalesLine.DeleteAll(true);
    end;

    local procedure RemoveServiceLinesAttachedToCurrentLine(ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.SetRange("Attached to Line No.", ServiceLine."Line No.");
        ServiceLine.DeleteAll(true);
    end;

    local procedure NormalizeText(var InputText: Text[100])
    var
        DotNet_StringBuilder: Codeunit DotNet_StringBuilder;
        Index: Integer;
        Length: Integer;
        InputChar: Char;
        SubstText: Text;
        InputCharCode: Integer;
    begin
        Index := 1;
        Length := StrLen(InputText);
        DotNet_StringBuilder.InitStringBuilder('');
        for Index := 1 to Length do begin
            InputChar := InputText[Index];
            InputCharCode := InputChar;
            SubstText := Format(InputChar);
            if not (InputChar in [1 .. 255]) then begin
                SubstText := DefaultReplacementTok;
                if InputCharCode = 8364 then
                    SubstText := EuroReplacementTok
            end;
            DotNet_StringBuilder.Append(SubstText);
        end;
        InputText := CopyStr(DotNet_StringBuilder.ToString, 1, MaxStrLen(InputText));
    end;

    local procedure UpdateItemGTIN(ItemNo: Code[20]; GTIN: Code[14])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate(GTIN, GTIN);
        Item.Modify(true);
    end;

    local procedure GetVATEntryAmounts(var AmountArray: array[2] of Decimal; DocNo: Code[20]; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.FindSet;
        repeat
            i += 1;
            AmountArray[i] := -VATEntry.Amount;
        until VATEntry.Next = 0;
    end;

    local procedure GetMaxRiferimentoTestoLength(): Integer
    begin
        exit(60);
    end;

    local procedure SetCheckInVATBusPostingGroupExemption(VATBusPostingGroupCode: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusinessPostingGroup.Get(VATBusPostingGroupCode);
        VATBusinessPostingGroup.Validate("Check VAT Exemption", true);
        VATBusinessPostingGroup.Modify(true);
    end;

    local procedure SetVATIdentifierInSalesLine(var SalesLine: Record "Sales Line")
    var
        VATIdentifier: Record "VAT Identifier";
    begin
        VATIdentifier.Init();
        VATIdentifier.Code :=
          LibraryUtility.GenerateRandomCode(VATIdentifier.FieldNo(Code), DATABASE::"VAT Identifier");
        VATIdentifier.Description := LibraryUtility.GenerateGUID;
        VATIdentifier.Insert();

        SalesLine.Validate("VAT Identifier", VATIdentifier.Code);
        SalesLine.Modify(true);
    end;

    local procedure SetVATRegistrationNoInCompanyInfoFromCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
    begin
        Customer.Get(CustomerNo);
        CompanyInformation.Get();
        CompanyInformation.Validate("VAT Registration No.", Customer."VAT Registration No.");
        CompanyInformation.Modify(true);
    end;

    local procedure VerifyDatiDDTForMultipleSalesShipments(ServerFileName: Text[250]; InvNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiDDT');
        SalesInvoiceLine.SetRange("Document No.", InvNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetFilter("Shipment No.", '<>%1', '');
        SalesInvoiceLine.FindSet;
        Assert.RecordCount(TempXMLBuffer, SalesInvoiceLine.Count);
        VerifyDatiDDTData(
          TempXMLBuffer, SalesInvoiceLine."Shipment No.", SalesInvoiceLine."Shipment Date", SalesInvoiceLine."Line No." / 10000);
        while SalesInvoiceLine.Next <> 0 do begin
            FindNextElement(TempXMLBuffer);
            VerifyDatiDDTData(
              TempXMLBuffer, SalesInvoiceLine."Shipment No.", SalesInvoiceLine."Shipment Date", SalesInvoiceLine."Line No." / 10000);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiDDTForMultipleServiceShipments(ServerFileName: Text[250]; InvNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiDDT');
        ServiceInvoiceLine.SetRange("Document No.", InvNo);
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Item);
        ServiceInvoiceLine.SetFilter("Shipment No.", '<>%1', '');
        ServiceInvoiceLine.FindSet;
        VerifyDatiDDTData(
          TempXMLBuffer, ServiceInvoiceLine."Shipment No.", ServiceInvoiceLine."Posting Date", ServiceInvoiceLine."Line No." / 10000);
        while ServiceInvoiceLine.Next <> 0 do begin
            FindNextElement(TempXMLBuffer);
            VerifyDatiDDTData(
              TempXMLBuffer, ServiceInvoiceLine."Shipment No.", ServiceInvoiceLine."Posting Date", ServiceInvoiceLine."Line No." / 10000);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiDDTForMultipleSalesOrderShipments(ServerFileName: Text[250]; CustomerNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesShipmentLine: Record "Sales Shipment Line";
        i: Integer;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiDDT');
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesShipmentLine.FindSet;
        i := 1;
        VerifyDatiDDTData(TempXMLBuffer, SalesShipmentLine."Document No.", SalesShipmentLine."Shipment Date", i);
        while SalesShipmentLine.Next <> 0 do begin
            i += 1;
            FindNextElement(TempXMLBuffer);
            VerifyDatiDDTData(TempXMLBuffer, SalesShipmentLine."Document No.", SalesShipmentLine."Shipment Date", i);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiDDTForMultipleServiceOrderShipments(ServerFileName: Text[250]; CustomerNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        ServiceShipmentLine: Record "Service Shipment Line";
        i: Integer;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiDDT');
        ServiceShipmentLine.SetRange("Customer No.", CustomerNo);
        ServiceShipmentLine.FindSet;
        i := 1;
        VerifyDatiDDTData(TempXMLBuffer, ServiceShipmentLine."Document No.", ServiceShipmentLine."Posting Date", i);
        while ServiceShipmentLine.Next <> 0 do begin
            i += 1;
            FindNextElement(TempXMLBuffer);
            VerifyDatiDDTData(TempXMLBuffer, ServiceShipmentLine."Document No.", ServiceShipmentLine."Posting Date", i);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiOrdineAcquistoForFirstSalesOrderShipment(ServerFileName: Text[250]; CustomerNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto');
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesShipmentLine.FindFirst;
        SalesShipmentLine.SetRange("Document No.", SalesShipmentLine."Document No.");
        SalesShipmentLine.FindSet;
        repeat
            AssertElementValue(TempXMLBuffer, 'RiferimentoNumeroLinea', Format(SalesShipmentLine."Order Line No." / 10000));
        until SalesShipmentLine.Next = 0;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiOrdineAcquistoForFirstServiceOrderShipment(ServerFileName: Text[250]; CustomerNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiDDT');
        ServiceShipmentLine.SetRange("Customer No.", CustomerNo);
        ServiceShipmentLine.FindFirst;
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ServiceShipmentLine.FindSet;
        VerifyDatiDDTData(
          TempXMLBuffer, ServiceShipmentLine."Document No.", ServiceShipmentLine."Posting Date",
          ServiceShipmentLine."Order Line No." / 10000);
        while ServiceShipmentLine.Next <> 0 do begin
            FindNextElement(TempXMLBuffer);
            VerifyDatiDDTData(
              TempXMLBuffer, ServiceShipmentLine."Document No.", ServiceShipmentLine."Posting Date",
              ServiceShipmentLine."Order Line No." / 10000);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiOrdineAcquistoWithFatturaCodes(ServerFileName: Text[250]; FatturaProjectCode: Code[15]; FatturaTenderCode: Code[15])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempResultElementXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto');
        TempXMLBuffer.FindChildElements(TempResultElementXMLBuffer);
        Assert.RecordCount(TempResultElementXMLBuffer, 2);
        AssertCurrentElementValue(TempResultElementXMLBuffer, FatturaProjectCode);
        FindNextElement(TempResultElementXMLBuffer);
        AssertCurrentElementValue(TempResultElementXMLBuffer, FatturaTenderCode);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiOrdineAcquistoFatturaDataFromMultipleSalesOrders(ServerFileName: Text[250]; SalesHeader: array[2] of Record "Sales Header")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        i: Integer;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto');
        for i := 1 to ArrayLen(SalesHeader) do begin
            AssertElementValue(TempXMLBuffer, 'RiferimentoNumeroLinea', Format(i * 2));
            AssertElementValue(TempXMLBuffer, 'IdDocumento', SalesHeader[i]."Customer Purchase Order No.");
            AssertElementValue(TempXMLBuffer, 'CodiceCUP', SalesHeader[i]."Fattura Project Code");
            AssertElementValue(TempXMLBuffer, 'CodiceCIG', SalesHeader[i]."Fattura Tender Code");
            FindNextElement(TempXMLBuffer);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiOrdineAcquistoFatturaDataFromMultipleServiceOrders(ServerFileName: Text[250]; ServiceHeader: array[2] of Record "Service Header")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        i: Integer;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto');
        for i := 1 to ArrayLen(ServiceHeader) do begin
            AssertElementValue(TempXMLBuffer, 'RiferimentoNumeroLinea', Format(i * 2));
            AssertElementValue(TempXMLBuffer, 'IdDocumento', ServiceHeader[i]."Customer Purchase Order No.");
            AssertElementValue(TempXMLBuffer, 'CodiceCUP', ServiceHeader[i]."Fattura Project Code");
            AssertElementValue(TempXMLBuffer, 'CodiceCIG', ServiceHeader[i]."Fattura Tender Code");
            FindNextElement(TempXMLBuffer);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyNoDatiOrdineAcquistoNode(ServerFileName: Text[250])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto');
        Assert.RecordCount(TempXMLBuffer, 0);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiDDTData(var TempXMLBuffer: Record "XML Buffer" temporary; ShipmentNo: Text; ShipmentDate: Date; LineNumber: Integer)
    begin
        AssertElementValue(TempXMLBuffer, 'NumeroDDT', ShipmentNo);
        AssertElementValue(TempXMLBuffer, 'DataDDT', FormatDate(ShipmentDate));
        AssertElementValue(TempXMLBuffer, 'RiferimentoNumeroLinea', Format(LineNumber));
    end;

    local procedure VerifyNoRiferimentoNumeroLineaNodeExists(ServerFileName: Text[250])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiDDT/RiferimentoNumeroLinea');
        Assert.IsTrue(TempXMLBuffer.IsEmpty(), 'RiferimentoNumeroLinea xml node exists');
    end;

    local procedure VerifyIDCodiceNode(ServerFileName: Text[250]; ExpectedValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/DatiTrasmissione/IdTrasmittente/IdCodice');
        AssertCurrentElementValue(TempXMLBuffer, ExpectedValue);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDettaglioPagamentoMultipleInvoices(ServerFileName: Text[250]; DocNo: Code[20])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        PaymentMethod: Record "Payment Method";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiPagamento/DettaglioPagamento');
        SalesInvoiceHeader.Get(DocNo);
        PaymentMethod.Get(SalesInvoiceHeader."Payment Method Code");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        CustLedgerEntry.FindSet;
        VerifyDettaglioPagamentoData(TempXMLBuffer, PaymentMethod."Fattura PA Payment Method", CustLedgerEntry);
        while CustLedgerEntry.Next <> 0 do begin
            FindNextElement(TempXMLBuffer);
            VerifyDettaglioPagamentoData(TempXMLBuffer, PaymentMethod."Fattura PA Payment Method", CustLedgerEntry);
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDettaglioPagamentoData(var TempXMLBuffer: Record "XML Buffer" temporary; FatturaPAMethodCode: Code[4]; CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        AssertElementValue(TempXMLBuffer, 'ModalitaPagamento', FatturaPAMethodCode);
        AssertElementValue(
          TempXMLBuffer, 'DataScadenzaPagamento', FormatDate(CustLedgerEntry."Due Date"));
        CustLedgerEntry.CalcFields("Amount (LCY)");
        AssertElementValue(TempXMLBuffer, 'ImportoPagamento', FormatAmount(CustLedgerEntry."Amount (LCY)"));
        AssertElementValue(TempXMLBuffer, 'IBAN', CompanyInformation.IBAN);
    end;

    local procedure VerifyMultipleDatiRiepilogoNodes(ServerFileName: Text[250]; ExpectedAmount: array[2] of Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        VerifyDatiRiepilogo(TempXMLBuffer, FormatAmount(ExpectedAmount[1]));
        FindNextElement(TempXMLBuffer);
        AssertCurrentElementValue(TempXMLBuffer, FormatAmount(ExpectedAmount[2]));
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifySingleDatiRiepilogo(ServerFileName: Text[250]; ExpectedAmount: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        VerifyDatiRiepilogo(TempXMLBuffer, FormatAmount(ExpectedAmount));
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDatiRiepilogo(var TempXMLBuffer: Record "XML Buffer" temporary; ExpectedValue: Text)
    begin
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo/Imposta');
        AssertCurrentElementValue(TempXMLBuffer, ExpectedValue);
    end;

    local procedure VerifyNaturaNode(ServerFileName: Text[250]; VATTransactionNature: Code[4])
    begin
        VerifySpecificNode(
          ServerFileName, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo/Natura', VATTransactionNature);
    end;

    local procedure VerifyRiferimentoNormativoNode(ServerFileName: Text[250]; ExpectedValue: Text)
    begin
        VerifySpecificNode(
          ServerFileName, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo/RiferimentoNormativo',
          ExpectedValue);
    end;

    local procedure VerifyIDDocumentoNode(ServerFileName: Text[250]; DocumentNo: Text[35])
    begin
        VerifySpecificNode(
          ServerFileName, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto/IdDocumento', DocumentNo);
    end;

    local procedure VerifySpecificNode(ServerFileName: Text[250]; XPath: Text; ExpectedElementValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        AssertCurrentElementValue(TempXMLBuffer, ExpectedElementValue);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyNoAltriDatiGestionaliNodes(ServerFileName: Text[250])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        XPath: Text;
    begin
        TempXMLBuffer.Load(ServerFileName);
        XPath := '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/AltriDatiGestionali/TipoDato';
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.RecordCount(TempXMLBuffer, 0);
    end;

    local procedure VerifyAltriDatiGestionaliByExtTexts(ServerFileName: Text[250]; ItemNo: Code[20]; StandardText: Record "Standard Text")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        VerifyAltriDatiGestionaliByExtTextLines(TempXMLBuffer, ServerFileName, ItemNo);
        VerifyAltriDatiGestionaliLongText(TempXMLBuffer, StandardText.Code, StandardText.Description);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyAltriDatiGestionaliByExtTextLines(var TempXMLBuffer: Record "XML Buffer" temporary; ServerFileName: Text[250]; ItemNo: Code[20])
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        XPath: Text;
    begin
        TempXMLBuffer.Load(ServerFileName);
        XPath := '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/AltriDatiGestionali';
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath), '');

        ExtendedTextLine.SetRange("Table Name", ExtendedTextLine."Table Name"::Item);
        ExtendedTextLine.SetRange("No.", ItemNo);
        ExtendedTextLine.FindSet;
        ExtendedTextHeader.Get(ExtendedTextLine."Table Name", ExtendedTextLine."No.", '', 1);

        repeat
            TempXMLBuffer.SetRange(Path);
            VerifyAltriDatiGestionaliLongText(TempXMLBuffer, StrSubstNo(TxtTok, ExtendedTextLine."No."), ExtendedTextLine.Text);
            TempXMLBuffer.SetFilter(Path, '*' + XPath);
            FindNextElement(TempXMLBuffer);
        until ExtendedTextLine.Next = 0;
        TempXMLBuffer.SetRange(Path);
    end;

    local procedure VerifyAltriDatiGestionaliLongText(var TempXMLBuffer: Record "XML Buffer" temporary; ExtendedItemNo: Text[100]; ExtendedText: Text[100])
    var
        XMLFieldLength: Integer;
    begin
        VerifyAltriDatiGestionaliShortText(TempXMLBuffer, ExtendedItemNo, ExtendedText);

        FindNextElement(TempXMLBuffer); // next AltriDatiGestionali
        FindNextElement(TempXMLBuffer);
        AssertCurrentElementValue(TempXMLBuffer, CopyStr(ExtendedItemNo, 1, 10));
        FindNextElement(TempXMLBuffer);
        XMLFieldLength := GetMaxRiferimentoTestoLength;
        AssertCurrentElementValue(TempXMLBuffer, CopyStr(ExtendedText, XMLFieldLength + 1, MaxStrLen(ExtendedText) - XMLFieldLength));
    end;

    local procedure VerifyAltriDatiGestionaliShortText(var TempXMLBuffer: Record "XML Buffer" temporary; ExtendedItemNo: Text[100]; ExtendedText: Text[100])
    var
        XMLFieldLength: Integer;
    begin
        FindNextElement(TempXMLBuffer); // go to TipoDato
        AssertCurrentElementValue(TempXMLBuffer, CopyStr(ExtendedItemNo, 1, 10));
        FindNextElement(TempXMLBuffer);
        XMLFieldLength := GetMaxRiferimentoTestoLength;
        NormalizeText(ExtendedText);
        AssertCurrentElementValue(TempXMLBuffer, CopyStr(ExtendedText, 1, XMLFieldLength));
    end;

    local procedure VerifyNoAltriDatiGestionaliNode(ServerFileName: Text[250])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        XPath: Text;
    begin
        TempXMLBuffer.Load(ServerFileName);
        XPath := '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/AltriDatiGestionali';
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.RecordCount(TempXMLBuffer, 0);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyCapitaleSociale(ServerFileName: Text[250]; ExpectedElementValue: Decimal)
    begin
        VerifySpecificNode(
          ServerFileName, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/IscrizioneREA/CapitaleSociale',
          FormatAmount(ExpectedElementValue));
    end;

    local procedure VerifyTipoDocumento(ServerFileName: Text[250]; ExpectedElementValue: Text)
    begin
        VerifySpecificNode(
          ServerFileName, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/TipoDocumento',
          ExpectedElementValue);
    end;

    local procedure VerifyDatiBeniServiziHasLineData(ServerFileName: Text[250]; Description: Text[100]; Occurrence: Integer)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/NumeroLinea');
        TempXMLBuffer.Next(Occurrence - 1);
        AssertCurrentElementValue(TempXMLBuffer, Format(Occurrence));
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/Descrizione');
        TempXMLBuffer.Next(Occurrence - 1);
        AssertCurrentElementValue(TempXMLBuffer, Description);
    end;

    local procedure VerifyDocumentTotalAmount(ServerFileName: Text; ExpectedAmount: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/ImportoTotaleDocumento');
        AssertCurrentElementValue(TempXMLBuffer, FormatAmount(ExpectedAmount));
    end;

    local procedure VerifyQuantitaNode(ServerFileName: Text; ExpectedValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/Quantita');
        AssertCurrentElementValue(TempXMLBuffer, ExpectedValue);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyIndividualPersonData(ServerFileName: Text; ExpectedValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente/DatiAnagrafici/CodiceFiscale');
        AssertCurrentElementValue(TempXMLBuffer, ExpectedValue);
        TempXMLBuffer.Reset();
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente/IdFiscaleIVA');
        Assert.RecordCount(TempXMLBuffer, 0);
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyStatoLiqudazioneNode(ServerFileName: Text; ExpectedValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/IscrizioneREA/StatoLiquidazione');
        AssertCurrentElementValue(TempXMLBuffer, ExpectedValue);
    end;

    local procedure VerifyImponibileImportoNodes(ServerFileName: Text[250]; VATAmount: array[2] of Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        i: Integer;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo/ImponibileImporto');
        Assert.RecordCount(TempXMLBuffer, ArrayLen(VATAmount));
        for i := 1 to ArrayLen(VATAmount) do begin
            TempXMLBuffer.SetRange(Value, FormatAmount(VATAmount[i]));
            TempXMLBuffer.FindFirst;
        end;
        DeleteServerFile(ServerFileName);
    end;

    local procedure UpdatePurchasesPayablesSetupVATExemptionNos(VATExemptionNos: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup."VAT Exemption Nos." := VATExemptionNos;
        PurchasesPayablesSetup.Modify;
    end;
}


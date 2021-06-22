codeunit 130509 "Library - Sales"
{
    // Contains all utility functions related to Sales.


    trigger OnRun()
    begin
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryUtility: Codeunit "Library - Utility";
        WrongDocumentTypeErr: Label 'Document type not supported: %1';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySmallBusiness: Codeunit "Library - Small Business";

    procedure BatchPostSalesHeaders(var SalesHeader: Record "Sales Header"; Ship: Boolean; Invoice: Boolean; PostingDate: Date; ReplacePostingDate: Boolean; ReplaceDocumentDate: Boolean; CalcInvDiscount: Boolean)
    var
        BatchPostSalesOrders: Report "Batch Post Sales Orders";
    begin
        BatchPostSalesOrders.UseRequestPage(false);
        BatchPostSalesOrders.InitializeRequest(Ship, Invoice, PostingDate, ReplacePostingDate, ReplaceDocumentDate, CalcInvDiscount);
        BatchPostSalesOrders.SetTableView(SalesHeader);
        BatchPostSalesOrders.RunModal;
    end;

    procedure BlanketSalesOrderMakeOrder(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesOrderHeader: Record "Sales Header";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        Clear(BlanketSalesOrderToOrder);
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
        exit(SalesOrderHeader."No.");
    end;

    procedure CopySalesDocument(SalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; FromDocNo: Code[20]; IncludeHeader: Boolean; RecalcLines: Boolean)
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(FromDocType, FromDocNo, IncludeHeader, RecalcLines);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    procedure CopySalesHeaderShipToAddressFromCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader.Validate("Ship-to Name", Customer.Name);
        SalesHeader.Validate("Ship-to Address", Customer.Address);
        SalesHeader.Validate("Ship-to Address 2", Customer."Address 2");
        SalesHeader.Validate("Ship-to City", Customer.City);
        SalesHeader.Validate("Ship-to Post Code", Customer."Post Code");
        SalesHeader.Validate("Ship-to Country/Region Code", Customer."Country/Region Code");
        SalesHeader.Validate("Ship-to County", Customer.County);
        SalesHeader.Modify(true);
    end;

    procedure CreateCustomer(var Customer: Record Customer)
    var
        PaymentMethod: Record "Payment Method";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryERM.SetSearchGenPostingTypeSales;
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Customer Nos."));

        Clear(Customer);
        Customer.Insert(true);
        Customer.Validate(Name, Customer."No.");  // Validating Name as No. because value is not important.
        Customer.Validate("Payment Method Code", PaymentMethod.Code);  // Mandatory for posting in ES build
        Customer.Validate("Payment Terms Code", LibraryERM.FindPaymentTermsCode);  // Mandatory for posting in ES build
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Customer Posting Group", FindCustomerPostingGroup);
        Customer.Modify(true);
        CustContUpdate.OnModify(Customer);

        OnAfterCreateCustomer(Customer);
    end;

    procedure CreateCustomerWithAddress(var Customer: Record Customer)
    begin
        CreateCustomer(Customer);
        CreateCustomerAddress(Customer);
    end;

    procedure CreateCustomerAddress(var Customer: Record Customer)
    var
        PostCode: Record "Post Code";
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        Customer.Validate(Address, CopyStr(LibraryUtility.GenerateGUID, 1, MaxStrLen(Customer.Address)));
        Customer.Validate("Address 2", CopyStr(LibraryUtility.GenerateGUID, 1, MaxStrLen(Customer."Address 2")));

        LibraryERM.CreatePostCode(PostCode);
        Customer.Validate("Country/Region Code", PostCode."Country/Region Code");
        Customer.Validate(City, PostCode.City);
        Customer.Validate(County, PostCode.County);
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
        CustContUpdate.OnModify(Customer);
    end;

    procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        CustomerBankAccount.Init();
        CustomerBankAccount.Validate("Customer No.", CustomerNo);
        CustomerBankAccount.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(Code), DATABASE::"Customer Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Customer Bank Account", CustomerBankAccount.FieldNo(Code))));
        CustomerBankAccount.Insert(true);
    end;

    procedure CreateCustomerPostingGroup(var CustomerPostingGroup: Record "Customer Posting Group")
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(CustomerPostingGroup.FieldNo(Code), DATABASE::"Customer Posting Group"));
        CustomerPostingGroup.Validate("Receivables Account", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Invoice Rounding Account", LibraryERM.CreateGLAccountWithSalesSetup);
        CustomerPostingGroup.Validate("Debit Rounding Account", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Credit Rounding Account", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Validate("Interest Account", LibraryERM.CreateGLAccountWithSalesSetup);
        CustomerPostingGroup.Validate("Additional Fee Account", LibraryERM.CreateGLAccountWithSalesSetup);
        CustomerPostingGroup.Validate("Add. Fee per Line Account", LibraryERM.CreateGLAccountWithSalesSetup);
        CustomerPostingGroup.Insert(true);
    end;

    procedure CreateCustomerPriceGroup(var CustomerPriceGroup: Record "Customer Price Group")
    begin
        CustomerPriceGroup.Init();
        CustomerPriceGroup.Validate(
          Code, LibraryUtility.GenerateRandomCode(CustomerPriceGroup.FieldNo(Code), DATABASE::"Customer Price Group"));
        CustomerPriceGroup.Validate(Description, CustomerPriceGroup.Code);
        // Validating Description as Code because value is not important.
        CustomerPriceGroup.Insert(true);
    end;

    procedure CreateCustomerTemplate(var CustomerTemplate: Record "Customer Template")
    begin
        CustomerTemplate.Init();
        CustomerTemplate.Validate(Code, LibraryUtility.GenerateRandomCode(CustomerTemplate.FieldNo(Code), DATABASE::"Customer Template"));
        CustomerTemplate.Insert(true);

        OnAfterCreateCustomerTemplate(CustomerTemplate);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerTemplateWithBusPostingGroups(GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]): Code[10]
    var
        CustomerTemplate: Record "Customer Template";
    begin
        CustomerTemplate.Init();
        CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Customer Posting Group", FindCustomerPostingGroup);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        CustomerTemplate.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        CustomerTemplate.Modify(true);
        exit(CustomerTemplate.Code);
    end;

    procedure CreateCustomerWithLocationCode(var Customer: Record Customer; LocationCode: Code[10]): Code[20]
    begin
        with Customer do begin
            CreateCustomer(Customer);
            Validate("Location Code", LocationCode);
            Modify(true);
            exit("No.");
        end;
    end;

    procedure CreateCustomerWithBusPostingGroups(GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        with Customer do begin
            CreateCustomer(Customer);
            Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
            Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    procedure CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        with Customer do begin
            CreateCustomer(Customer);
            Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    procedure CreateCustomerWithVATRegNo(var Customer: Record Customer): Code[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    procedure FilterSalesHeaderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; DocNoOccurence: Integer; Version: Integer)
    begin
        SalesHeaderArchive.SetRange("Document Type", DocumentType);
        SalesHeaderArchive.SetRange("No.", DocumentNo);
        SalesHeaderArchive.SetRange("Doc. No. Occurrence", DocNoOccurence);
        SalesHeaderArchive.SetRange("Version No.", Version);
    end;

    procedure FilterSalesLineArchive(var SalesLineArchive: Record "Sales Line Archive"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; DocNoOccurence: Integer; Version: Integer)
    begin
        SalesLineArchive.SetRange("Document Type", DocumentType);
        SalesLineArchive.SetRange("Document No.", DocumentNo);
        SalesLineArchive.SetRange("Doc. No. Occurrence", DocNoOccurence);
        SalesLineArchive.SetRange("Version No.", Version);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    procedure CreateItemChargeAssignment(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge"; DocType: Enum "Sales Document Type"; DocNo: Code[20]; DocLineNo: Integer; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        RecRef: RecordRef;
    begin
        Clear(ItemChargeAssignmentSales);

        with ItemChargeAssignmentSales do begin
            "Document Type" := SalesLine."Document Type";
            "Document No." := SalesLine."Document No.";
            "Document Line No." := SalesLine."Line No.";
            "Item Charge No." := SalesLine."No.";
            "Unit Cost" := SalesLine."Unit Cost";
            RecRef.GetTable(ItemChargeAssignmentSales);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "Item Charge No." := ItemCharge."No.";
            "Applies-to Doc. Type" := DocType;
            "Applies-to Doc. No." := DocNo;
            "Applies-to Doc. Line No." := DocLineNo;
            "Item No." := ItemNo;
            "Unit Cost" := UnitCost;
            Validate("Qty. to Assign", Qty);
        end;
    end;

    procedure CreatePaymentAndApplytoInvoice(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // Value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure CreatePrepaymentVATSetup(var LineGLAccount: Record "G/L Account"; VATCalculationType: Enum "Tax Calculation Type"): Code[20]
    var
        PrepmtGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Sale, VATCalculationType, VATCalculationType);
        exit(PrepmtGLAccount."No.");
    end;

    procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ShipmentDate: Date)
    begin
        CreateFCYSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, CustomerNo, ItemNo, Quantity, LocationCode, ShipmentDate, '');
    end;

    procedure CreateFCYSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ShipmentDate: Date; CurrencyCode: Code[10])
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        if LocationCode <> '' then
            SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo;
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if LocationCode <> '' then
            SalesLine.Validate("Location Code", LocationCode);
        if ShipmentDate <> 0D then
            SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20])
    begin
        DisableWarningOnCloseUnreleasedDoc;
        DisableWarningOnCloseUnpostedDoc;
        DisableConfirmOnPostingDoc;
        Clear(SalesHeader);
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        if SellToCustomerNo = '' then
            SellToCustomerNo := CreateCustomerNo;
        SalesHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.Validate(
          "External Document No.",
          CopyStr(LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("External Document No."), DATABASE::"Sales Header"), 1, 20));
        SetCorrDocNoSales(SalesHeader);
        SalesHeader.Modify(true);

        OnAfterCreateSalesHeader(SalesHeader, DocumentType.AsInteger(), SellToCustomerNo);
    end;

    procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, Type, No, SalesHeader."Shipment Date", Quantity);
    end;

    procedure CreateSalesLineWithShipmentDate(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; ShipmentDate: Date; Quantity: Decimal)
    begin
        CreateSalesLineSimple(SalesLine, SalesHeader);

        SalesLine.Validate(Type, Type);
        case Type of
            SalesLine.Type::Item:
                if No = '' then
                    No := LibraryInventory.CreateItemNo;
            SalesLine.Type::Resource:
                if No = '' then
                    No := LibraryResource.CreateResourceNo;
            SalesLine.Type::"Charge (Item)":
                if No = '' then
                    No := LibraryInventory.CreateItemChargeNo;
        end;
        SalesLine.Validate("No.", No);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        if Quantity <> 0 then
            SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);

        OnAfterCreateSalesLineWithShipmentDate(SalesLine, SalesHeader, Type.AsInteger(), No, ShipmentDate, Quantity);
    end;

    procedure CreateSalesLineSimple(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        SalesLine.Insert(true);
    end;

    procedure CreateSimpleItemSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type")
    begin
        CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, Type);
        SalesLine.Modify(true);
    end;

    procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
        CreateSalesInvoiceForCustomerNo(SalesHeader, CreateCustomerNo);
    end;

    procedure CreateSalesInvoiceForCustomerNo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerNo);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerNo);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    procedure CreateSalesQuoteForCustomerNo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    procedure CreateSalesperson(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        SalespersonPurchaser.Init();
        SalespersonPurchaser.Validate(
          Code, LibraryUtility.GenerateRandomCode(SalespersonPurchaser.FieldNo(Code), DATABASE::"Salesperson/Purchaser"));
        SalespersonPurchaser.Validate(Name, SalespersonPurchaser.Code);  // Validating Name as Code because value is not important.
        SalespersonPurchaser.Insert(true);
    end;

    procedure CreateSalesPrepaymentPct(var SalesPrepaymentPct: Record "Sales Prepayment %"; SalesType: Option; SalesCode: Code[20]; ItemNo: Code[20]; StartingDate: Date)
    begin
        SalesPrepaymentPct.Init();
        SalesPrepaymentPct.Validate("Item No.", ItemNo);
        SalesPrepaymentPct.Validate("Sales Type", SalesType);
        SalesPrepaymentPct.Validate("Sales Code", SalesCode);
        SalesPrepaymentPct.Validate("Starting Date", StartingDate);
        SalesPrepaymentPct.Insert(true);
    end;

    procedure CreateSalesCommentLine(var SalesCommentLine: Record "Sales Comment Line"; DocumentType: Enum "Sales Document Type"; No: Code[20]; DocumentLineNo: Integer)
    var
        RecRef: RecordRef;
    begin
        SalesCommentLine.Init();
        SalesCommentLine.Validate("Document Type", DocumentType);
        SalesCommentLine.Validate("No.", No);
        SalesCommentLine.Validate("Document Line No.", DocumentLineNo);
        RecRef.GetTable(SalesCommentLine);
        SalesCommentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesCommentLine.FieldNo("Line No.")));
        SalesCommentLine.Insert(true);
        // Validate Comment as primary key to enable user to distinguish between comments because value is not important.
        SalesCommentLine.Validate(
          Comment, Format(SalesCommentLine."Document Type") + SalesCommentLine."No." +
          Format(SalesCommentLine."Document Line No.") + Format(SalesCommentLine."Line No."));
        SalesCommentLine.Modify(true);
    end;

    procedure CreateSalesPrice(var SalesPrice: Record "Sales Price"; ItemNo: Code[20]; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; StartingDate: Date; CurrencyCode: Code[10]; VariantCode: Code[10]; UOMCode: Code[10]; MinQty: Decimal; UnitPrice: Decimal)
    begin
        Clear(SalesPrice);
        SalesPrice.Validate("Item No.", ItemNo);
        SalesPrice.Validate("Sales Type", SalesType);
        SalesPrice.Validate("Sales Code", SalesCode);
        SalesPrice.Validate("Starting Date", StartingDate);
        SalesPrice.Validate("Currency Code", CurrencyCode);
        SalesPrice.Validate("Variant Code", VariantCode);
        SalesPrice.Validate("Unit of Measure Code", UOMCode);
        SalesPrice.Validate("Minimum Quantity", MinQty);
        SalesPrice.Insert(true);
        SalesPrice.Validate("Unit Price", UnitPrice);
        SalesPrice.Modify(true);

        OnAfterCreateSalesPrice(SalesPrice, ItemNo, SalesType.AsInteger(), SalesCode, StartingDate, CurrencyCode, VariantCode, UOMCode, MinQty, UnitPrice);
    end;

    procedure CreateShipToAddress(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    begin
        ShipToAddress.Init();
        ShipToAddress.Validate("Customer No.", CustomerNo);
        ShipToAddress.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(ShipToAddress.FieldNo(Code), DATABASE::"Ship-to Address"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Ship-to Address", ShipToAddress.FieldNo(Code))));
        ShipToAddress.Insert(true);
    end;

    procedure CreateStandardSalesCode(var StandardSalesCode: Record "Standard Sales Code")
    begin
        StandardSalesCode.Init();
        StandardSalesCode.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(StandardSalesCode.FieldNo(Code), DATABASE::"Standard Sales Code"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Standard Sales Code", StandardSalesCode.FieldNo(Code))));
        // Validating Description as Code because value is not important.
        StandardSalesCode.Validate(Description, StandardSalesCode.Code);
        StandardSalesCode.Insert(true);
    end;

    procedure CreateStandardSalesLine(var StandardSalesLine: Record "Standard Sales Line"; StandardSalesCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        StandardSalesLine.Init();
        StandardSalesLine.Validate("Standard Sales Code", StandardSalesCode);
        RecRef.GetTable(StandardSalesLine);
        StandardSalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, StandardSalesLine.FieldNo("Line No.")));
        StandardSalesLine.Insert(true);
    end;

    procedure CreateCustomerSalesCode(var StandardCustomerSalesCode: Record "Standard Customer Sales Code"; CustomerNo: Code[20]; "Code": Code[10])
    begin
        StandardCustomerSalesCode.Init();
        StandardCustomerSalesCode.Validate("Customer No.", CustomerNo);
        StandardCustomerSalesCode.Validate(Code, Code);
        StandardCustomerSalesCode.Insert(true);
    end;

    procedure CreateCustomerMandate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustomerNo: Code[20]; CustomerBankCode: Code[20]; FromDate: Date; ToDate: Date)
    begin
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.Validate("Customer No.", CustomerNo);
        SEPADirectDebitMandate.Validate("Customer Bank Account Code", CustomerBankCode);
        SEPADirectDebitMandate.Validate("Valid From", FromDate);
        SEPADirectDebitMandate.Validate("Valid To", ToDate);
        SEPADirectDebitMandate.Validate("Date of Signature", FromDate);
        SEPADirectDebitMandate.Insert(true);
    end;

    procedure CreateStandardText(var StandardText: Record "Standard Text"): Code[20]
    begin
        StandardText.Init();
        StandardText.Code := LibraryUtility.GenerateRandomCode(StandardText.FieldNo(Code), DATABASE::"Standard Text");
        StandardText.Description := LibraryUtility.GenerateGUID;
        StandardText.Insert();
        exit(StandardText.Code);
    end;

    procedure CreateStandardTextWithExtendedText(var StandardText: Record "Standard Text"; var ExtendedText: Text): Code[20]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        StandardText.Init();
        StandardText.Code := LibraryUtility.GenerateRandomCode(StandardText.FieldNo(Code), DATABASE::"Standard Text");
        StandardText.Description := LibraryUtility.GenerateGUID;
        StandardText.Insert();
        LibrarySmallBusiness.CreateExtendedTextHeader(
          ExtendedTextHeader, ExtendedTextHeader."Table Name"::"Standard Text", StandardText.Code);
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);
        ExtendedText := ExtendedTextLine.Text;
        exit(StandardText.Code);
    end;

    procedure CreateCustomerDocumentLayout(CustomerNo: Code[20]; UsageValue: Option; ReportID: Integer; CustomReportLayoutCode: Code[20]; EmailAddress: Text)
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        with CustomReportSelection do begin
            Init;
            Validate("Source Type", DATABASE::Customer);
            Validate("Source No.", CustomerNo);
            Validate(Usage, UsageValue);
            Validate("Report ID", ReportID);
            Validate("Custom Report Layout Code", CustomReportLayoutCode);
            Validate("Send To Email", CopyStr(EmailAddress, 1, MaxStrLen("Send To Email")));
            Insert;
        end;
    end;

    procedure CombineReturnReceipts(var SalesHeader: Record "Sales Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; PostingDate: Date; DocDate: Date; CalcInvDiscount: Boolean; PostCreditMemos: Boolean)
    var
        TmpSalesHeader: Record "Sales Header";
        TmpReturnReceiptHeader: Record "Return Receipt Header";
        CombineReturnReceipts: Report "Combine Return Receipts";
    begin
        CombineReturnReceipts.InitializeRequest(PostingDate, DocDate, CalcInvDiscount, PostCreditMemos);
        if SalesHeader.HasFilter then
            TmpSalesHeader.CopyFilters(SalesHeader)
        else begin
            SalesHeader.Get(SalesHeader."No.", SalesHeader."Document Type");
            TmpSalesHeader.SetRange("Document Type", SalesHeader."Document Type");
            TmpSalesHeader.SetRange("No.", SalesHeader."No.");
        end;
        CombineReturnReceipts.SetTableView(TmpSalesHeader);
        if ReturnReceiptHeader.HasFilter then
            TmpReturnReceiptHeader.CopyFilters(ReturnReceiptHeader)
        else begin
            ReturnReceiptHeader.Get(ReturnReceiptHeader."No.");
            TmpReturnReceiptHeader.SetRange("No.", ReturnReceiptHeader."No.");
        end;
        CombineReturnReceipts.SetTableView(TmpReturnReceiptHeader);
        CombineReturnReceipts.UseRequestPage(false);
        CombineReturnReceipts.RunModal;
    end;

    procedure CombineShipments(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; PostingDate: Date; DocumentDate: Date; CalcInvDisc: Boolean; PostInvoices: Boolean; OnlyStdPmtTerms: Boolean; CopyTextLines: Boolean)
    var
        TmpSalesHeader: Record "Sales Header";
        TmpSalesShipmentHeader: Record "Sales Shipment Header";
        CombineShipments: Report "Combine Shipments";
    begin
        CombineShipments.InitializeRequest(PostingDate, DocumentDate, CalcInvDisc, PostInvoices, OnlyStdPmtTerms, CopyTextLines);
        if SalesHeader.HasFilter then
            TmpSalesHeader.CopyFilters(SalesHeader)
        else begin
            SalesHeader.Get(SalesHeader."No.", SalesHeader."Document Type");
            TmpSalesHeader.SetRange("Document Type", SalesHeader."Document Type");
            TmpSalesHeader.SetRange("No.", SalesHeader."No.");
        end;
        CombineShipments.SetTableView(TmpSalesHeader);
        if SalesShipmentHeader.HasFilter then
            TmpSalesShipmentHeader.CopyFilters(SalesShipmentHeader)
        else begin
            SalesShipmentHeader.Get(SalesShipmentHeader."No.");
            TmpSalesShipmentHeader.SetRange("No.", SalesShipmentHeader."No.");
        end;
        CombineShipments.SetTableView(TmpSalesShipmentHeader);
        CombineShipments.UseRequestPage(false);
        CombineShipments.RunModal;
    end;

    procedure DeleteInvoicedSalesOrders(var SalesHeader: Record "Sales Header")
    var
        TmpSalesHeader: Record "Sales Header";
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
    begin
        if SalesHeader.HasFilter then
            TmpSalesHeader.CopyFilters(SalesHeader)
        else begin
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
            TmpSalesHeader.SetRange("Document Type", SalesHeader."Document Type");
            TmpSalesHeader.SetRange("No.", SalesHeader."No.");
        end;
        DeleteInvoicedSalesOrders.SetTableView(TmpSalesHeader);
        DeleteInvoicedSalesOrders.UseRequestPage(false);
        DeleteInvoicedSalesOrders.RunModal;
    end;

    procedure DeleteInvoicedSalesReturnOrders(var SalesHeader: Record "Sales Header")
    var
        TmpSalesHeader: Record "Sales Header";
        DeleteInvdSalesRetOrders: Report "Delete Invd Sales Ret. Orders";
    begin
        if SalesHeader.HasFilter then
            TmpSalesHeader.CopyFilters(SalesHeader)
        else begin
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
            TmpSalesHeader.SetRange("Document Type", SalesHeader."Document Type");
            TmpSalesHeader.SetRange("No.", SalesHeader."No.");
        end;
        DeleteInvdSalesRetOrders.SetTableView(TmpSalesHeader);
        DeleteInvdSalesRetOrders.UseRequestPage(false);
        DeleteInvdSalesRetOrders.RunModal;
    end;

    procedure ExplodeBOM(var SalesLine: Record "Sales Line")
    var
        SalesExplodeBOM: Codeunit "Sales-Explode BOM";
    begin
        Clear(SalesExplodeBOM);
        SalesExplodeBOM.Run(SalesLine);
    end;

    procedure FindCustomerPostingGroup(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.FindFirst then
            CreateCustomerPostingGroup(CustomerPostingGroup);
        exit(CustomerPostingGroup.Code);
    end;

    procedure FindFirstSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
    end;

    procedure FindItem(var Item: Record Item)
    begin
        // Filter Item so that errors are not generated due to mandatory fields or Item Tracking.
        Item.SetFilter("Inventory Posting Group", '<>''''');
        Item.SetFilter("Gen. Prod. Posting Group", '<>''''');
        Item.SetRange("Item Tracking Code", '');
        Item.SetRange(Blocked, false);
        Item.SetFilter("Unit Price", '<>0');
        Item.SetFilter(Reserve, '<>%1', Item.Reserve::Always);

        Item.FindSet;
    end;

    procedure GetInvRoundingAccountOfCustPostGroup(CustPostingGroupCode: Code[20]): Code[20]
    var
        CustPostingGroup: Record "Customer Posting Group";
    begin
        CustPostingGroup.Get(CustPostingGroupCode);
        exit(CustPostingGroup."Invoice Rounding Account");
    end;

    procedure GetShipmentLines(var SalesLine: Record "Sales Line")
    var
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        Clear(SalesGetShipment);
        SalesGetShipment.Run(SalesLine);
    end;

    procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; NewShipReceive: Boolean; NewInvoice: Boolean): Code[20]
    begin
        exit(DoPostSalesDocument(SalesHeader, NewShipReceive, NewInvoice, false));
    end;

    procedure PostSalesDocumentAndEmail(var SalesHeader: Record "Sales Header"; NewShipReceive: Boolean; NewInvoice: Boolean): Code[20]
    begin
        exit(DoPostSalesDocument(SalesHeader, NewShipReceive, NewInvoice, true));
    end;

    local procedure DoPostSalesDocument(var SalesHeader: Record "Sales Header"; NewShipReceive: Boolean; NewInvoice: Boolean; AfterPostSalesDocumentSendAsEmail: Boolean) DocumentNo: Code[20]
    var
        SalesPost: Codeunit "Sales-Post";
        SalesPostPrint: Codeunit "Sales-Post + Print";
        Assert: Codeunit Assert;
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        OnBeforePostSalesDocument(SalesHeader, NewShipReceive, NewInvoice, AfterPostSalesDocumentSendAsEmail);

        // Taking name as NewInvoice to avoid conflict with table field name.
        // Post the sales document.
        // Depending on the document type and posting type return the number of the:
        // - sales shipment,
        // - posted sales invoice,
        // - sales return receipt, or
        // - posted credit memo
        SetCorrDocNoSales(SalesHeader);
        with SalesHeader do begin
            Validate(Ship, NewShipReceive);
            Validate(Receive, NewShipReceive);
            Validate(Invoice, NewInvoice);

            case "Document Type" of
                "Document Type"::Invoice:
                    NoSeriesCode := "Posting No. Series";  // posted sales invoice.
                "Document Type"::Order:
                    if NewShipReceive and not NewInvoice then
                        // posted sales shipment.
                        NoSeriesCode := "Shipping No. Series"
                    else
                        NoSeriesCode := "Posting No. Series";  // posted sales invoice.
                "Document Type"::"Credit Memo":
                    NoSeriesCode := "Posting No. Series";  // posted sales credit memo.
                "Document Type"::"Return Order":
                    if NewShipReceive and not NewInvoice then
                        // posted sales return receipt.
                        NoSeriesCode := "Return Receipt No. Series"
                    else
                        NoSeriesCode := "Posting No. Series";  // posted sales credit memo.
                else
                    Assert.Fail(StrSubstNo(WrongDocumentTypeErr, "Document Type"));
            end;
        end;

        if SalesHeader."Posting No." = '' then
            DocumentNo := NoSeriesManagement.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesSalesDate(NoSeriesCode), false)
        else
            DocumentNo := SalesHeader."Posting No.";
        Clear(SalesPost);
        if AfterPostSalesDocumentSendAsEmail then
            SalesPostPrint.PostAndEmail(SalesHeader)
        else
            SalesPost.Run(SalesHeader);
    end;

    procedure PostSalesPrepaymentCrMemo(var SalesHeader: Record "Sales Header")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.CreditMemo(SalesHeader);
    end;

    procedure PostSalesPrepaymentCreditMemo(var SalesHeader: Record "Sales Header") DocumentNo: Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := SalesHeader."Prepmt. Cr. Memo No. Series";
        if SalesHeader."Prepmt. Cr. Memo No." = '' then
            DocumentNo := NoSeriesMgt.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesSalesDate(NoSeriesCode), false)
        else
            DocumentNo := SalesHeader."Prepmt. Cr. Memo No.";
        SalesPostPrepayments.CreditMemo(SalesHeader);
    end;

    procedure PostSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header") DocumentNo: Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := SalesHeader."Prepayment No. Series";
        if SalesHeader."Prepayment No." = '' then
            DocumentNo := NoSeriesMgt.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesSalesDate(NoSeriesCode), false)
        else
            DocumentNo := SalesHeader."Prepayment No.";
        SalesPostPrepayments.Invoice(SalesHeader);
    end;

    procedure QuoteMakeOrder(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesOrderHeader: Record "Sales Header";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
    begin
        Clear(SalesQuoteToOrder);
        SalesQuoteToOrder.Run(SalesHeader);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesOrderHeader);
        exit(SalesOrderHeader."No.");
    end;

    procedure ReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
    end;

    procedure ReopenSalesDocument(var SalesHeader: Record "Sales Header")
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDoc.PerformManualReopen(SalesHeader);
    end;

    procedure CalcSalesDiscount(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
    end;

    procedure SetAllowVATDifference(AllowVATDifference: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetAllowDocumentDeletionBeforeDate(Date: Date)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow Document Deletion Before", Date);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetApplnBetweenCurrencies(ApplnBetweenCurrencies: Option)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Appln. between Currencies", ApplnBetweenCurrencies);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetCreateItemFromItemNo(NewValue: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Create Item from Item No.", NewValue);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetCreateItemFromDescription(NewValue: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Create Item from Description", NewValue);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetDiscountPosting(DiscountPosting: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Discount Posting", DiscountPosting);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetDiscountPostingSilent(DiscountPosting: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Discount Posting" := DiscountPosting;
        SalesReceivablesSetup.Modify();
    end;

    procedure SetCalcInvDiscount(CalcInvDiscount: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetCorrDocNoSales(var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do
            if "Document Type" in ["Document Type"::"Credit Memo", "Document Type"::"Return Order"] then;
    end;

    procedure SetCreditWarnings(CreditWarnings: Option)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetCreditWarningsToNoWarnings()
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetExactCostReversingMandatory(ExactCostReversingMandatory: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetGLFreightAccountNo(GLFreightAccountNo: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Freight G/L Acc. No.", GLFreightAccountNo);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetInvoiceRounding(InvoiceRounding: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetStockoutWarning(StockoutWarning: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetPreventNegativeInventory(PreventNegativeInventory: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Prevent Negative Inventory", PreventNegativeInventory);
        InventorySetup.Modify(true);
    end;

    procedure SetArchiveQuoteAlways()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Archive Quotes", SalesReceivablesSetup."Archive Quotes"::Always);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetArchiveOrders(ArchiveOrders: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Archive Orders", ArchiveOrders);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetArchiveBlanketOrders(ArchiveBlanketOrders: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Archive Blanket Orders", ArchiveBlanketOrders);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetArchiveReturnOrders(ArchiveReturnOrders: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Archive Return Orders", ArchiveReturnOrders);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetExtDocNo(ExtDocNoMandatory: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Ext. Doc. No. Mandatory", ExtDocNoMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetPostWithJobQueue(PostWithJobQueue: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Post with Job Queue", PostWithJobQueue);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetPostAndPrintWithJobQueue(PostAndPrintWithJobQueue: Boolean)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Post & Print with Job Queue", PostAndPrintWithJobQueue);
        SalesReceivablesSetup.Modify(true);
    end;

    procedure SetOrderNoSeriesInSetup()
    begin
        with SalesReceivablesSetup do begin
            Get;
            Validate("Order Nos.", LibraryERM.CreateNoSeriesCode);
            Modify;
        end;
    end;

    procedure SetPostedNoSeriesInSetup()
    begin
        with SalesReceivablesSetup do begin
            Get;
            Validate("Posted Invoice Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("Posted Shipment Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("Posted Credit Memo Nos.", LibraryERM.CreateNoSeriesCode);
            Modify;
        end;
    end;

    procedure SetReturnOrderNoSeriesInSetup()
    begin
        with SalesReceivablesSetup do begin
            Get;
            Validate("Return Order Nos.", LibraryERM.CreateNoSeriesCode);
            Validate("Posted Return Receipt Nos.", LibraryERM.CreateNoSeriesCode);
            Modify;
        end;
    end;

    procedure SetCopyCommentsOrderToInvoiceInSetup(CopyCommentsOrderToInvoice: Boolean)
    begin
        with SalesReceivablesSetup do begin
            Get;
            Validate("Copy Comments Order to Invoice", CopyCommentsOrderToInvoice);
            Modify(true);
        end;
    end;

    procedure UndoSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Undo Sales Shipment Line", SalesShipmentLine);
    end;

    procedure UndoReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Undo Return Receipt Line", ReturnReceiptLine);
    end;

    procedure AutoReserveSalesLine(SalesLine: Record "Sales Line")
    begin
        SalesLine.AutoReserve;
    end;

    procedure SelectCashReceiptJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.SelectGenJournalBatch(GenJournalBatch, SelectCashReceiptJnlTemplate);
    end;

    procedure SelectCashReceiptJnlTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        exit(LibraryJournals.SelectGenJournalTemplate(GenJournalTemplate.Type::"Cash Receipts", PAGE::"Cash Receipt Journal"));
    end;

    procedure DisableConfirmOnPostingDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode);
    end;

    procedure EnableConfirmOnPostingDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode);
    end;

    procedure DisableWarningOnCloseUnreleasedDoc()
    begin
        LibraryERM.DisableClosingUnreleasedOrdersMsg;
    end;

    procedure DisableWarningOnCloseUnpostedDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode);
    end;

    procedure EnableWarningOnCloseUnpostedDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode);
    end;

    procedure EnableSalesSetupIgnoreUpdatedAddresses()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Ignore Updated Addresses" := true;
        SalesSetup.Modify();
    end;

    procedure DisableSalesSetupIgnoreUpdatedAddresses()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Ignore Updated Addresses" := false;
        SalesSetup.Modify();
    end;

    procedure MockCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        with CustLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, FieldNo("Entry No."));
            "Customer No." := CustomerNo;
            "Posting Date" := WorkDate;
            Insert;
        end;
    end;

    procedure MockCustLedgerEntryWithAmount(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        MockCustLedgerEntry(CustLedgerEntry, CustomerNo);
        MockDetailedCustLedgEntry(CustLedgerEntry);
    end;

    procedure MockCustLedgerEntryWithZeroBalance(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        MockCustLedgerEntry(CustLedgerEntry, CustomerNo);
        MockDetailedCustLedgEntryZeroBalance(CustLedgerEntry);
    end;

    procedure MockDetailedCustLedgerEntryWithAmount(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with DetailedCustLedgEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, FieldNo("Entry No."));
            "Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
            "Customer No." := CustLedgerEntry."Customer No.";
            "Posting Date" := WorkDate;
            "Entry Type" := "Entry Type"::"Initial Entry";
            "Document Type" := "Document Type"::Invoice;
            Amount := LibraryRandom.RandDec(100, 2);
            "Amount (LCY)" := Amount;
            Insert;
        end;
    end;

    procedure MockDetailedCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockDetailedCustLedgerEntryWithAmount(DetailedCustLedgEntry, CustLedgerEntry);
        MockApplnDetailedCustLedgerEntry(DetailedCustLedgEntry, true, WorkDate);
        MockApplnDetailedCustLedgerEntry(DetailedCustLedgEntry, false, WorkDate);
    end;

    procedure MockDetailedCustLedgEntryZeroBalance(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockDetailedCustLedgerEntryWithAmount(DetailedCustLedgEntry, CustLedgerEntry);
        MockApplnDetailedCustLedgerEntry(DetailedCustLedgEntry, true, WorkDate);
        MockApplnDetailedCustLedgerEntry(DetailedCustLedgEntry, true, WorkDate + 1);
    end;

    procedure MockApplnDetailedCustLedgerEntry(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; UnappliedEntry: Boolean; PostingDate: Date)
    var
        ApplnDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with ApplnDetailedCustLedgEntry do begin
            Init;
            Copy(DetailedCustLedgEntry);
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
            "Entry Type" := "Entry Type"::Application;
            "Posting Date" := PostingDate;
            Amount := -Amount;
            "Amount (LCY)" := Amount;
            Unapplied := UnappliedEntry;
            Insert;
        end;
    end;

    procedure PreviewPostSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        SalesPostYesNo.Preview(SalesHeader);
    end;

    procedure SetDefaultCancelReasonCodeForSalesAndReceivablesSetup()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomer(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomerTemplate(var CustomerTemplate: Record "Customer Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option; SellToCustomerNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLineWithShipmentDate(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Option; No: Code[20]; ShipmentDate: Date; Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesPrice(var SalesPrice: Record "Sales Price"; ItemNo: Code[20]; SalesType: Option; SalesCode: Code[20]; StartingDate: Date; CurrencyCode: Code[10]; VariantCode: Code[10]; UOMCode: Code[10]; MinQty: Decimal; UnitPrice: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostSalesDocument(var SalesHeader: Record "Sales Header"; NewShipReceive: Boolean; NewInvoice: Boolean; AfterPostSalesDocumentSendAsEmail: Boolean)
    begin
    end;
}


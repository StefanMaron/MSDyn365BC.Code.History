codeunit 138400 "RS Pack Content - Evaluation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Evaluation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDemoData: Codeunit "Library - Demo Data";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        XOUTGOINGTxt: Label 'OUTGOING';
        PostingOutsideFYIsOnErr: Label 'Posting Outside Fiscal Year option is on';
        NonStockNoSeriesTok: Label 'NS-ITEM';
        TransShipmentNoSeriesTok: Label 'T-SHPT';
        TransReceiptNoSeriesTok: Label 'T-RCPT';
        TransOrderNoSeriesTok: Label 'T-ORD';
        ItemNoSeriesTok: Label 'ITEM';
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryExtensionPerm: Codeunit "Library - Extension Perm.";
        SalesReturnReceiptTok: Label 'S-RCPT';
        NOTAXTok: Label 'NO TAX';
        NONTAXABLETok: Label 'NonTAXABLE';
        xBANKTxt: Label 'BANK';
        XSALESTok: Label 'SALES';
        XPURCHASESTok: Label 'PURCHASES';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyIsDemoCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] The current Company is a Demo Company
        Initialize();

        CompanyInformation.Get();
        Assert.IsTrue(CompanyInformation."Demo Company", CompanyInformation.FieldName("Demo Company"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyNameEqualsDisplayNameAndShipToName()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] The ship-to name and display name equals the company name
        Initialize();

        CompanyInformation.Get();
        CompanyInformation.TestField(Name, CompanyName);
        CompanyInformation.TestField("Ship-to Name", CompanyName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingOutsideFYIsOn()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        // [SCENARIO 169269] "Posting Outside Fiscal Year Not Allowed" is on in "My Settings"
        Initialize();

        Assert.IsTrue(InstructionMgt.IsEnabled(InstructionMgt.PostingAfterCurrentCalendarDateNotAllowedCode), PostingOutsideFYIsOnErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenPostingGroupCount()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        // [SCENARIO] There is 1 Gen Bus. Posting group and 3 Prod. Posting groups
        Assert.RecordCount(GenBusPostingGroup, 1);

        Assert.RecordCount(GenProdPostingGroup, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenPostingSetupAccounts()
    begin
        // [SCENARIO] Inventory accounts filled for all groups, Sales/Purchase - for not blank Bus. Group.
        LibraryDemoData.VerifyGenPostingSetupAccounts;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NontaxableInGenPostingSetup()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] There are 2 Gen. Posting groups, where Product Group code is 'NO TAX'
        // [WHEN] Find "Gen. Posting Setup" records
        // [THEN] There are 2 groups, where "Gen. Prod. Posting Group" = 'NOTAX'
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", NOTAXTok);
        Assert.RecordCount(GeneralPostingSetup, 2);
        // [THEN] first, where "Gen. Bus. Posting Group" is blank
        GeneralPostingSetup.FindFirst;
        GeneralPostingSetup.TestField("Gen. Bus. Posting Group", '');
        // [THEN] second, where "Gen. Bus. Posting Group" is filled
        GeneralPostingSetup.FindLast;
        GenBusinessPostingGroup.FindFirst;
        GeneralPostingSetup.TestField("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are 7 Sales Invoices, 4 Orders, and 2 Quotes
        Initialize();

        with SalesHeader do begin
            SetRange("Document Type", "Document Type"::Invoice);
            Assert.RecordCount(SalesHeader, 7);

            SetRange("Document Type", "Document Type"::Order);
            Assert.RecordCount(SalesHeader, 4);

            SetRange("Document Type", "Document Type"::Quote);
            Assert.RecordCount(SalesHeader, 2);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountSalesDocumentsWithShippingAgentCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are 2 Sales Invoices and 4 Sales Orders with Shipping Agent Code
        Initialize();

        with SalesHeader do begin
            Reset;
            SetRange("Document Type", "Document Type"::Invoice);
            SetFilter("Shipping Agent Code", '<>%1', '');
            Assert.RecordCount(SalesHeader, 2);

            Reset;
            SetRange("Document Type", "Document Type"::Order);
            SetFilter("Shipping Agent Code", '<>%1', '');
            Assert.RecordCount(SalesHeader, 4);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoReleasedSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are no Released Sales Documents in the Evaluation data except orders
        // As we can reopen orders, we have will not open orders
        Initialize();

        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetFilter("Document Type", '<> %1', SalesHeader."Document Type"::Order);
        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAmountsAreCalculatedSalesDocuments()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] The Sales Lines have the Amount field set in the Evaluation data
        Initialize();

        SalesLine.SetRange(Amount, 0);
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        Assert.RecordIsEmpty(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateItemSalesXML()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempXMLBufferPeriods: Record "XML Buffer" temporary;
        Item: Record Item;
        FileManagement: Codeunit "File Management";
        Periods: Integer;
    begin
        // [FEATURE] [Item sales forecast]
        // [SCENARIO] The data on itemsales.xml are consistent
        Initialize();

        TempXMLBuffer.Load(FileManagement.CombinePath(
            ApplicationPath, '../../App/Demotool/Pictures/MachineLearning/itemsales.xml'));

        Item.SetRange("Assembly BOM", false);
        Evaluate(Periods, TempXMLBuffer.GetAttributeValue('Periods'));
        TempXMLBuffer.FindChildElements(TempXMLBuffer);
        TempXMLBuffer.FindSet;
        Assert.RecordCount(TempXMLBuffer, Item.Count);
        repeat
            TempXMLBuffer.FindChildElements(TempXMLBufferPeriods);
            Assert.AreEqual(Periods, TempXMLBufferPeriods.Count,
              StrSubstNo('Item %1 does not have %2 periods',
                TempXMLBuffer.GetAttributeValue('item'),
                Format(Periods)));
        until TempXMLBuffer.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnyCustomerHaveSalespersonCode()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Salesperson]
        // [SCENARIO] All customers should have "Salesperson Code" defined.
        Initialize();

        Customer.SetRange("Salesperson Code", '');
        Assert.RecordIsEmpty(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HistoricalSalesDataForAllItems()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        Date: Record Date;
        FirstDay: Date;
        LastDay: Date;
    begin
        // [FEATURE] [Item sales forecast]
        // [SCENARIO] There are historical sales data all items and for 15 periods
        Item.SetRange("Assembly BOM", false);
        Item.FindSet;
        repeat
            ItemLedgerEntry.SetCurrentKey("Posting Date");
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            ItemLedgerEntry.SetRange(Positive, false);
            ItemLedgerEntry.SetRange("Item No.", Item."No.");
            ItemLedgerEntry.FindFirst;

            FirstDay := ItemLedgerEntry."Posting Date";
            ItemLedgerEntry.FindLast;
            LastDay := ItemLedgerEntry."Posting Date";
            Date.SetRange("Period Type", Date."Period Type"::Month);
            Date.SetRange("Period Start", FirstDay, LastDay);
            Assert.IsTrue(Date.Count + 1 >= 15,
              StrSubstNo('Item %1 does not have sales data for at least 15 months', Item."No."));

        until Item.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountItemLedgerEntries()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Item sales forecast]
        // [SCENARIO] There are 634 in total item ledger entries 405 sales 241 purchases.
        Assert.RecordCount(ItemLedgerEntry, 650);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        Assert.RecordCount(ItemLedgerEntry, 241);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        Assert.RecordCount(ItemLedgerEntry, 405);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoices()
    var
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Existing Sales Invoices can be posted without errors
        Initialize();

        with SalesHeader do begin
            // [WHEN] Post all Invoices
            Reset;
            SetRange("Document Type", "Document Type"::Invoice);
            FindSet;
            repeat
                PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

                // [THEN] Cust. Ledger Entries are created
                CustLedgEntry.FindLast;
                CustLedgEntry.TestField("Document No.", PostedInvoiceNo);
            until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountPurchDocuments()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are 3 Purchase Invoices and 4 purchase orders but no documents of other types
        Initialize();

        with PurchHeader do begin
            SetRange("Document Type", "Document Type"::Invoice);
            Assert.RecordCount(PurchHeader, 3);

            SetRange("Document Type", "Document Type"::Order);
            Assert.RecordCount(PurchHeader, 5);

            SetFilter("Document Type", '<>%1&<>%2', "Document Type"::Order, "Document Type"::Invoice);
            Assert.RecordCount(PurchHeader, 0);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoReleasedPurchaseDocuments()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are no Released Purchase Documents in the Evaluation data
        Initialize();

        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Released);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMonthlyPurchaseAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PeriodStart: Date;
        PeriodEnd: Date;
        LastOrderDate: Date;
        Total: Decimal;
    begin
        // [FEATURE] [Cash Flow] [Forecast] [Azure AI]
        // [SCENARIO] Monthly purchases must be between 15.000 and 45.000
        Initialize();

        PurchaseHeader.Reset();
        PurchaseHeader.SetCurrentKey("Due Date");
        PurchaseHeader.FindFirst;
        PeriodStart := PurchaseHeader."Due Date";
        PurchaseHeader.FindLast;
        LastOrderDate := PurchaseHeader."Due Date";
        // First of the month
        PeriodStart := CalcDate('<CM + 1D>', CalcDate('<-1M>', PeriodStart));
        PeriodEnd := CalcDate('<CM>', PeriodStart);
        while PeriodEnd < LastOrderDate do begin
            Total := 0;
            PurchaseHeader.Reset();
            PurchaseHeader.SetRange("Due Date", PeriodStart, PeriodEnd);
            PurchaseHeader.FindSet;
            repeat
                PurchaseHeader.CalcFields("Amount Including VAT");
                Total := Total + PurchaseHeader."Amount Including VAT";
            until PurchaseHeader.Next = 0;
            Assert.IsTrue(Total >= 15000, 'There are less purchases than expected');
            Assert.IsTrue(Total <= 40000, 'There are more purchases than expected');
            PeriodStart := CalcDate('<+1M>', PeriodStart);
            PeriodEnd := CalcDate('<CM>', PeriodStart);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoices()
    var
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Existing Purchase Invoices can be posted without errors
        Initialize();

        with PurchHeader do begin
            // [WHEN] Post all Invoices
            Reset;
            SetRange("Document Type", "Document Type"::Invoice);
            FindSet;
            repeat
                PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

                // [THEN] Vendor Ledger Entries are created
                VendLedgEntry.FindLast;
                VendLedgEntry.TestField("Document No.", PostedInvoiceNo);
            until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrders()
    var
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PostedOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Existing Purchase Orders can be posted without errors
        Initialize();

        with PurchHeader do begin
            // [WHEN] Post all Orders
            Reset;
            SetRange("Document Type", "Document Type"::Order);
            FindSet;
            repeat
                PostedOrderNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

                // [THEN] Vendor Ledger Entries are created
                VendLedgEntry.FindLast;
                VendLedgEntry.TestField("Document No.", PostedOrderNo);
            until Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountContacts()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        ContactBusinessRelation: Record "Contact Business Relation";
        CompanyNo: Code[20];
    begin
        // [FEATURE] [Contacts]
        // [SCENARIO] There are two contacts (Company, Person) per each Customer, Vendor, Bank
        Initialize();

        if Customer.FindSet then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
                VerifyContactPerson(CompanyNo);
            until Customer.Next = 0;

        if Vendor.FindSet then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");
                VerifyContactPerson(CompanyNo);
            until Vendor.Next = 0;

        if BankAccount.FindSet then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::"Bank Account", BankAccount."No.");
            until BankAccount.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactsHaveSalutationCode()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 171741] All contacts have Saluation Code
        Contact.SetRange("Salutation Code", '');
        Assert.RecordIsEmpty(Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactsHaveBlankTerritiryCode()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 171741] All contacts have blank Territory Code
        Contact.SetFilter("Territory Code", '<>%1', '');
        Assert.RecordIsEmpty(Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomersAreTaxLiableAndUseBankTransfer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customers]
        // [SCENARIO] All customers are marked as Tax Liable and use "Bank" Payment Method
        Customer.Reset();
        Assert.IsFalse(Customer.IsEmpty, 'There should be demo customers.');

        Customer.SetRange("Tax Liable", false);
        Assert.IsTrue(Customer.IsEmpty, 'All demo customers should be marked as Tax Liable.');

        Customer.Reset();
        Customer.SetFilter("Payment Method Code", StrSubstNo('<>%1', xBANKTxt));
        Assert.IsTrue(Customer.IsEmpty, StrSubstNo('All demo customers should have Payment Method Code set to %1.', xBANKTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorsAreTaxLiableAndUseBankTransfer()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendors]
        // [SCENARIO] All vendor are marked as Tax Liable and use "Bank" Payment Method
        Vendor.Reset();
        Assert.IsFalse(Vendor.IsEmpty, 'There should be demo vendors.');

        Vendor.SetRange("Tax Liable", false);
        Assert.IsTrue(Vendor.IsEmpty, 'All demo vendors should be marked as Tax Liable.');

        Vendor.Reset();
        Vendor.SetFilter("Payment Method Code", StrSubstNo('<>%1', xBANKTxt));
        Assert.IsTrue(Vendor.IsEmpty, StrSubstNo('All demo vendors should have Payment Method Code set to %1.', xBANKTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentRelatedTablesAreNotEmpty()
    begin
        // [SCENARIO] Shipping Agent related tables should not be empty
        Initialize();

        Assert.TableIsNotEmpty(DATABASE::"Shipping Agent");
        Assert.TableIsNotEmpty(DATABASE::"Shipping Agent Services");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemRelatedTablesAreNotEmpty()
    begin
        // [SCENARIO 171192] Susan can set up Item Substitution
        // [SCENARIO 167751] Susan can set up Item Cross References
        Initialize();

        Assert.TableIsNotEmpty(DATABASE::"Item Substitution");
        Assert.TableIsNotEmpty(DATABASE::"Item Cross Reference");
    end;

    local procedure VerifyContactCompany(var CompanyNo: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table"; No: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", No);
        Assert.RecordCount(ContactBusinessRelation, 1);
        ContactBusinessRelation.FindFirst;
        CompanyNo := ContactBusinessRelation."Contact No.";
    end;

    local procedure VerifyContactPerson(CompanyNo: Code[20])
    var
        ContactPerson: Record Contact;
    begin
        ContactPerson.SetRange("Company No.", CompanyNo);
        ContactPerson.SetRange(Type, ContactPerson.Type::Person);
        Assert.RecordCount(ContactPerson, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionGroups()
    var
        InteractionGroup: Record "Interaction Group";
    begin
        // [FEATURE] [CRM] [Interaction Group]
        // [SCENARIO 174769] Interaction Group should have 6 groups.
        Initialize();

        Assert.RecordCount(InteractionGroup, 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplates()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 174769] Interaction Template should have 29 templates.
        Initialize();

        Assert.RecordCount(InteractionTemplate, 29);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplateOutgoingIgnoreCorrType()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 176595] Interaction Template OUTGOING should have Ignore Contact Corres. Type = TRUE
        Initialize();

        InteractionTemplate.Get(XOUTGOINGTxt);
        InteractionTemplate.TestField("Ignore Contact Corres. Type", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Locations()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Location]
        // [SCENARIO] Demo data contains 3 regular locations and 2 in-transit locations
        Initialize();

        Location.SetRange("Use As In-Transit", false);
        Assert.RecordCount(Location, 3);
        Location.SetRange("Use As In-Transit", true);
        Assert.RecordCount(Location, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRoutes()
    var
        TransferRoute: Record "Transfer Route";
    begin
        // [FEATURE] [Location Transfer]
        // [SCENARIO] Demo data contains 2 transfer routes
        Initialize();

        Assert.RecordCount(TransferRoute, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrders()
    var
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Location Transfer]
        // [SCENARIO] Demo data contains 2 transfer orders.
        Initialize();

        Assert.RecordCount(TransferHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipments()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        // [FEATURE] [Transfer] [Shipment]
        // [SCENARIO] Demo data contains 1 transfer shipment
        Initialize();

        Assert.RecordCount(TransferShipmentHeader, 1);
        Assert.RecordCount(TransferShipmentLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferReciepts()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        // [FEATURE] [Transfer] [Receipt]
        // [SCENARIO] Demo data contains 1 transfer receipt
        Initialize();

        Assert.RecordCount(TransferReceiptHeader, 1);
        Assert.RecordCount(TransferReceiptLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Employees()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Basic HR]
        // [SCENARIO] Demo data contains 7 employees
        Initialize();

        Assert.RecordCount(Employee, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxGroupNonTaxable()
    var
        TaxGroup: Record "Tax Group";
    begin
        // [SCENARIO] Tax Group NONTAXABLE should be one of 5 groups
        TaxGroup.Get(NONTAXABLETok);
        Assert.RecordCount(TaxGroup, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplateSetup()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTemplateSetup: Record "Interaction Template Setup";
    begin
        // [FEATURE] [CRM] [Interaction]
        // [SCENARIO 171761] Interaction Template Setup should have 8 Purchase, 11 Sales, 4 General fields filled.
        InteractionTemplate.SetRange("Interaction Group Code", XSALESTok);
        Assert.RecordCount(InteractionTemplate, 11);
        InteractionTemplate.SetRange("Interaction Group Code", XPURCHASESTok);
        Assert.RecordCount(InteractionTemplate, 8);

        InteractionTemplateSetup.Get();
        InteractionTemplateSetup.TestField("E-Mails");
        InteractionTemplateSetup.TestField("Cover Sheets");
        InteractionTemplateSetup.TestField("Outg. Calls");
        InteractionTemplateSetup.TestField("Meeting Invitation");

        InteractionTemplateSetup.TestField("Purch Invoices");

        InteractionTemplateSetup.TestField("Sales Cr. Memo");
        InteractionTemplateSetup.TestField("Sales Invoices");
        InteractionTemplateSetup.TestField("Sales Ord. Cnfrmn.");
        InteractionTemplateSetup.TestField("Sales Shpt. Note");
        InteractionTemplateSetup.TestField("Sales Quotes");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityChartShowsData()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        Opportunity: Record Opportunity;
        Period: Record Date;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        OpportunityChartMgt: Codeunit "Opportunity Chart Mgt.";
        SalesPersonName: Variant;
        I: Integer;
    begin
        // [FEATURE] [CRM] [Opportunity]
        // [SCENARIO 171440] Opportunity Chart shows opportunities "In Progress" for two sales persons
        OpportunityChartMgt.SetDefaultPeriod(Period);
        OpportunityChartMgt.SetDefaultOppStatus(Opportunity);
        OpportunityChartMgt.UpdateData(BusinessChartBuffer, Period, Opportunity.Status);
        for I := 0 to 1 do begin
            BusinessChartBuffer.GetXValue(I, SalesPersonName);
            SalespersonPurchaser.SetRange(Name, SalesPersonName);
            Assert.RecordIsNotEmpty(SalespersonPurchaser);
        end;
        Opportunity.TestField(Status, Opportunity.Status::"In Progress");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressIsNotEmpty()
    begin
        // [SCENARIO 173171] Cassie/Annie can select an existing alternative ship-to address on Sales Invoice
        Assert.TableIsNotEmpty(DATABASE::"Ship-to Address");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressIsInTheCorrectRegionCountry()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        with ShipToAddress do begin
            // [WHEN] Selecting an address from ship-to
            Reset;
            FindSet;
            // [THEN] The address is in the current Region/Country
            repeat
                TestField("Country/Region Code", 'US');
                VerifyPostCodeRegionCountry("Post Code", 'US');
            until Next = 0;
        end;
    end;

    local procedure VerifyPostCodeRegionCountry("Code": Code[20]; CountryRegionCode: Code[10])
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange(Code, Code);
        Assert.RecordCount(PostCode, 1);
        PostCode.FindFirst;
        PostCode.TestField("Country/Region Code", CountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarketingSetupDefaultFields()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 175276] Marketing Setup Default fields filled
        Initialize();

        MarketingSetup.Get();
        MarketingSetup.TestField("Default Language Code");
        MarketingSetup.TestField("Default Correspondence Type", MarketingSetup."Default Correspondence Type"::Email);
        MarketingSetup.TestField("Default Sales Cycle Code");
        MarketingSetup.TestField("Mergefield Language ID");
        MarketingSetup.TestField("Autosearch for Duplicates", true);
        MarketingSetup.TestField("Default Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Campaigns()
    var
        Campaign: Record Campaign;
    begin
        // [FEATURE] [CRM] [Campaigns]
        // [SCENARIO 180135] Demo data contain 3 campaigns
        Initialize();

        Assert.RecordCount(Campaign, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO] Demo DB should have at least one G/L Account.
        Initialize();

        Assert.RecordIsNotEmpty(GLAccount);

        // [THEN] Account 40000 must have Account Type = Heading
        GLAccount.Get('40000');
        GLAccount.TestField("Account Type", GLAccount."Account Type"::Heading);

        // [THEN] Account 40001 must have Account Type = Begin-Total
        GLAccount.Get('40001');
        GLAccount.TestField("Account Type", GLAccount."Account Type"::"Begin-Total");

        // [THEN] Account 40990 must have Account Type = End-Total
        GLAccount.Get('40990');
        GLAccount.TestField("Account Type", GLAccount."Account Type"::"End-Total");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMs()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [BOM]
        // [SCENARIO] Demo DB should have 5 BOMs with multiple components
        Initialize();

        // [THEN] 4 BOMs have 3 components
        // [THEN] 1 BOM has 2 components
        Item.SetRange("Assembly BOM", true);
        Assert.RecordCount(Item, 5);

        BOMComponent.SetRange("Parent Item No.", '1925-W');
        Assert.RecordCount(BOMComponent, 3);

        BOMComponent.SetRange("Parent Item No.", '1929-W');
        Assert.RecordCount(BOMComponent, 3);

        BOMComponent.SetRange("Parent Item No.", '1953-W');
        Assert.RecordCount(BOMComponent, 2);

        BOMComponent.SetRange("Parent Item No.", '1965-W');
        Assert.RecordCount(BOMComponent, 3);

        BOMComponent.SetRange("Parent Item No.", '1969-W');
        Assert.RecordCount(BOMComponent, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutomaticCostPostingInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();

        InventorySetup.Get();
        InventorySetup.TestField("Automatic Cost Posting", true);
        InventorySetup.TestField("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Always);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();

        InventorySetup.Get();
        InventorySetup.TestField("Item Nos.", ItemNoSeriesTok);
        ValidateNoSeriesExists(ItemNoSeriesTok);
        InventorySetup.TestField("Nonstock Item Nos.", NonStockNoSeriesTok);
        ValidateNoSeriesExists(NonStockNoSeriesTok);
        InventorySetup.TestField("Transfer Order Nos.", TransOrderNoSeriesTok);
        ValidateNoSeriesExists(TransOrderNoSeriesTok);
        InventorySetup.TestField("Posted Transfer Rcpt. Nos.", TransReceiptNoSeriesTok);
        ValidateNoSeriesExists(TransReceiptNoSeriesTok);
        InventorySetup.TestField("Posted Transfer Shpt. Nos.", TransShipmentNoSeriesTok);
        ValidateNoSeriesExists(TransShipmentNoSeriesTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportLayoutSelections()
    begin
        // [SCENARIO 215679] There should be BLUESIMPLE custom layouts defined for report layout selections
        Initialize();

        VerifyReportLayoutSelection(REPORT::"Standard Sales - Quote", 'MS-1304-BLUE');
        VerifyReportLayoutSelection(REPORT::"Standard Sales - Invoice", 'MS-1306-BLUE');
    end;

    local procedure VerifyReportLayoutSelection(ReportID: Integer; CustomReportLayoutCode: Code[20])
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.SetRange("Report ID", ReportID);
        ReportLayoutSelection.SetRange("Custom Report Layout Code", CustomReportLayoutCode);
        Assert.RecordIsNotEmpty(ReportLayoutSelection);
    end;

    local procedure ValidateNoSeriesExists(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.SetRange(Code, NoSeriesCode);
        Assert.RecordIsNotEmpty(NoSeries);
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        Assert.RecordIsNotEmpty(NoSeriesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountItemConfigTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [Item] [Config. Template]
        // [SCENARIO] There should be 6 Item Config. Templates
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        Assert.RecordCount(ConfigTemplateHeader, 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemTemplatesCostingMethodFIFO()
    var
        TypeConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
    begin
        // [FEATURE] [Item] [Config. Template]
        // [SCENARIO] All service Item Config. templates have 'FIFO' "Costing Method"
        TypeConfigTemplateLine.SetRange("Table ID", DATABASE::Item);
        TypeConfigTemplateLine.SetRange("Field ID", Item.FieldNo(Type));
        TypeConfigTemplateLine.SetRange("Default Value", Format(Item.Type::Service));
        TypeConfigTemplateLine.FindSet;
        repeat
            ConfigTemplateLine.SetRange("Data Template Code", TypeConfigTemplateLine."Data Template Code");
            ConfigTemplateLine.SetRange("Field ID", Item.FieldNo("Costing Method"));
            ConfigTemplateLine.SetRange("Default Value", Format(Item."Costing Method"::FIFO));
            Assert.RecordIsNotEmpty(ConfigTemplateLine);
        until TypeConfigTemplateLine.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryItemTemplatesNoCostingMethod()
    var
        TypeConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
    begin
        // [FEATURE] [Item] [Config. Template]
        // [SCENARIO] No Item Config. templates for inventory items have "Costing Method"
        TypeConfigTemplateLine.SetRange("Table ID", DATABASE::Item);
        TypeConfigTemplateLine.SetRange("Field ID", Item.FieldNo(Type));
        TypeConfigTemplateLine.SetRange("Default Value", Format(Item.Type::Inventory));
        TypeConfigTemplateLine.FindSet;
        repeat
            ConfigTemplateLine.SetRange("Data Template Code", TypeConfigTemplateLine."Data Template Code");
            ConfigTemplateLine.SetRange("Field ID", Item.FieldNo("Costing Method"));
            Assert.RecordIsEmpty(ConfigTemplateLine);
        until TypeConfigTemplateLine.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemConfigTemplatesHaveNotBlankBaseUoM()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        Item: Record Item;
    begin
        // [FEATURE] [Item] [Config. Template]
        // [SCENARIO] All Config. Templates for Item table, where "Base Unit of Measure" is not <blank>
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateHeader.FindSet;
        repeat
            ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
            ConfigTemplateLine.SetRange("Field ID", Item.FieldNo("Base Unit of Measure"));
            ConfigTemplateLine.FindSet;
            repeat
                ConfigTemplateLine.TestField("Default Value");
            until ConfigTemplateLine.Next = 0;
        until ConfigTemplateHeader.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageTablesPermissions()
    var
        ConfigPackageTable: Record "Config. Package Table";
        Permission: Record Permission;
    begin
        Initialize();

        if ConfigPackageTable.FindSet then begin
            Permission.SetRange("Role ID", LibraryExtensionPerm.D365BusFull);
            Permission.SetRange("Object Type", Permission."Object Type"::"Table Data");
            repeat
                Permission.SetRange("Object ID", ConfigPackageTable."Table ID");
                Permission.SetFilter("Insert Permission", '<>%1', Permission."Insert Permission"::" ");
                Assert.RecordIsNotEmpty(Permission);
            until ConfigPackageTable.Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemsHaveImages()
    var
        Item: Record Item;
    begin
        Initialize();

        Item.FindSet;
        repeat
            Assert.AreNotEqual(0, Item.Picture.Count, StrSubstNo('Expected at least one image for item %1', Item."No."));
        until Item.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesInPurchSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO 259575] Purchase Setup has all needed number series fields filled in to be able create and post purchase documents
        Initialize();

        with PurchSetup do begin
            Get;
            TestField("Vendor Nos.");
            ValidateNoSeriesExists("Vendor Nos.");
            TestField("Quote Nos.");
            ValidateNoSeriesExists("Quote Nos.");
            TestField("Order Nos.");
            ValidateNoSeriesExists("Order Nos.");
            TestField("Invoice Nos.");
            ValidateNoSeriesExists("Invoice Nos.");
            TestField("Posted Invoice Nos.");
            ValidateNoSeriesExists("Posted Invoice Nos.");
            TestField("Credit Memo Nos.");
            ValidateNoSeriesExists("Credit Memo Nos.");
            TestField("Posted Credit Memo Nos.");
            ValidateNoSeriesExists("Posted Credit Memo Nos.");
            TestField("Posted Receipt Nos.");
            ValidateNoSeriesExists("Posted Receipt Nos.");
            TestField("Blanket Order Nos.");
            ValidateNoSeriesExists("Blanket Order Nos.");
            TestField("Return Order Nos.");
            ValidateNoSeriesExists("Return Order Nos.");
            TestField("Posted Return Shpt. Nos.");
            ValidateNoSeriesExists("Posted Return Shpt. Nos.");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoPermissionSetWithEmptyHash()
    var
        PermissionSet: Record "Permission Set";
    begin
        Initialize();

        PermissionSet.SetRange(Hash, '');
        if PermissionSet.FindSet then
            repeat
                if StrPos(PermissionSet."Role ID", 'TEST') = 0 then // not a test created permission set
                    Assert.Fail(StrSubstNo('Some permissions sets, e,g. %1 have nothing filled in Hash field.', PermissionSet."Role ID"));
            until PermissionSet.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesReturnReceiptNoSeriesPopulated()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [No. Series] [UT]
        // [SCENARIO 291743] Posted Sales Return Receipt No. Series is populated
        Initialize();

        ValidateNoSeriesExists(SalesReturnReceiptTok);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Posted Return Receipt Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchasingCodes()
    var
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [UT] [Purchasing]
        // [SCENARIO 328635] There are 3 records of Purchasing table
        Initialize();

        Assert.RecordCount(Purchasing, 3);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"RS Pack Content - Evaluation");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"RS Pack Content - Evaluation");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"RS Pack Content - Evaluation");
    end;
}


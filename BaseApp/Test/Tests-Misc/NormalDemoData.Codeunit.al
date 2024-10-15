codeunit 138200 "Normal DemoData"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Normal]
    end;

    var
        Assert: Codeunit Assert;
        NoPurchHeaderErr: Label 'There is no Purchase Header within the filter.';
        EmptyBlobErr: Label 'BLOB field is empty.';
        NOTAXTok: Label 'NO TAX';
        NONTAXABLETok: Label 'NonTAXABLE';
        NoSalesHeaderErr: Label 'There is no Sales Header within the filter';

    [Test]
    [Scope('OnPrem')]
    procedure CompanyIsDemoCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] The current Company is a Demo Company
        CompanyInformation.Get;
        Assert.IsTrue(CompanyInformation."Demo Company", CompanyInformation.FieldName("Demo Company"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenPostingGroupCount()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        // [SCENARIO] There are 4 Gen Bus. Posting group and 6 Prod. Posting groups
        Assert.RecordCount(GenBusPostingGroup, 4);

        Assert.RecordCount(GenProdPostingGroup, 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenPostingSetupAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Sales/Purchase accounts are filled for not blank Bus. Group.
        GeneralPostingSetup.FindSet;
        repeat
            if GeneralPostingSetup."Gen. Bus. Posting Group" = '' then begin
                GeneralPostingSetup.TestField("Sales Account", '');
                GeneralPostingSetup.TestField("Purch. Account", '');
            end else begin
                GeneralPostingSetup.TestField("Sales Account");
                GeneralPostingSetup.TestField("Purch. Account");
            end;
        until GeneralPostingSetup.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NontaxableInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] There are 5 Gen. Posting groups, where Product Group code is 'NO TAX'
        // [WHEN] Find "Gen. Posting Setup" records
        // [THEN] There are 5 groups, where "Gen. Prod. Posting Group" = 'NOTAX'
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", NOTAXTok);
        Assert.RecordCount(GeneralPostingSetup, 5);
        // [THEN] first, where "Gen. Bus. Posting Group" is blank
        GeneralPostingSetup.FindFirst;
        GeneralPostingSetup.TestField("Gen. Bus. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are 0 Sales Invoices, 0 Orders, and 0 Quotes
        with SalesHeader do begin
            SetRange("Document Type", "Document Type"::Invoice);
            Assert.RecordCount(SalesHeader, 0);

            SetRange("Document Type", "Document Type"::Order);
            Assert.RecordCount(SalesHeader, 0);

            SetRange("Document Type", "Document Type"::Quote);
            Assert.RecordCount(SalesHeader, 0);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoices()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are 0 Sales Invoices
        with SalesHeader do begin
            // [WHEN] Post all Invoices
            Reset;
            SetRange("Document Type", "Document Type"::Invoice);
            asserterror FindFirst;
            // [THEN] An error: 'There is no Sales Header within the filter.'
            Assert.ExpectedError(NoSalesHeaderErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountPurchDocuments()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are 0 Purchase Invoices and 0 documents of other types
        with PurchHeader do begin
            SetRange("Document Type", "Document Type"::Invoice);
            Assert.RecordCount(PurchHeader, 0);

            SetFilter("Document Type", '<>%1', "Document Type"::Invoice);
            Assert.RecordCount(PurchHeader, 0);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoices()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are no Purchase Invoices to post
        with PurchHeader do begin
            // [WHEN] Post all Invoices
            Reset;
            SetRange("Document Type", "Document Type"::Invoice);
            asserterror FindFirst;
            // [THEN] Error: 'There is no Purchase Header within the filter.'
            Assert.ExpectedError(NoPurchHeaderErr);
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
        // [SCENARIO] There is a Company contact per each Customer, Vendor, Bank
        if Customer.FindSet then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
            until Customer.Next = 0;

        if Vendor.FindSet then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");
            until Vendor.Next = 0;

        if BankAccount.FindSet then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::"Bank Account", BankAccount."No.");
            until BankAccount.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuerySegmentLinesInDemo()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266325] "Tenant Web Service" and "Tenant Web Service OData" contain record for Query "Segment Lines"

        TenantWebService.Get(TenantWebService."Object Type"::Query, 'SegmentLines');
        TenantWebService.TestField("Object ID", QUERY::"Segment Lines");
        TenantWebService.TestField(Published, true);

        TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.RecordIsNotEmpty(TenantWebServiceOData);
    end;

    local procedure VerifyContactCompany(var CompanyNo: Code[20]; LinkToTable: Option; No: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", No);
        Assert.RecordCount(ContactBusinessRelation, 1);
        ContactBusinessRelation.FindFirst;
        CompanyNo := ContactBusinessRelation."Contact No.";
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionGroups()
    var
        InteractionGroup: Record "Interaction Group";
    begin
        // [FEATURE] [CRM] [Interaction Group]
        // [SCENARIO 174769] Interaction Group should have 6 groups.
        Assert.RecordCount(InteractionGroup, 8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplates()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 174769] Interaction Template should have 15 templates.
        Assert.RecordCount(InteractionTemplate, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicingEmailMediaResources()
    begin
        // [SCENARIO 213193] Media resources related to invoicing email are imported
        VerifyBLOBMediaResources('INVOICING - SALESMAIL.HTML');
        VerifyBLOBMediaResources('PAYMENT SERVICE - MICROSOFT-LOGO.PNG');
        VerifyBLOBMediaResources('PAYMENT SERVICE - PAYPAL-LOGO.PNG');
        VerifyBLOBMediaResources('PAYMENT SERVICE - WORLDPAY-LOGO.PNG');
        VerifyBLOBMediaResources('SOCIAL - FACEBOOK.PNG');
        VerifyBLOBMediaResources('SOCIAL - INSTAGRAM.PNG');
        VerifyBLOBMediaResources('SOCIAL - LINKEDIN.PNG');
        VerifyBLOBMediaResources('SOCIAL - PINTEREST.PNG');
        VerifyBLOBMediaResources('SOCIAL - TWITTER.PNG');
        VerifyBLOBMediaResources('SOCIAL - YELP.PNG');
        VerifyBLOBMediaResources('SOCIAL - YOUTUBE.PNG');
    end;

    local procedure VerifyBLOBMediaResources("Code": Code[50])
    var
        MediaResources: Record "Media Resources";
    begin
        MediaResources.Get(Code);
        MediaResources.CalcFields(Blob);
        Assert.IsTrue(MediaResources.Blob.HasValue, EmptyBlobErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLSetupTaxInvoiceRenamingThreshold()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Tax Invoice Threshold]
        // [SCENARIO 271628] "Tax Invoice Renaming Threshold" is 0.
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.TestField("Tax Invoice Renaming Threshold", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ElectronicDocumentFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        UsageOption: Option;
    begin
        // [FEATURE] [Electronic Document]
        // [SCENARIO 278316] Electronic document format has setup for PEPPOL 2.0, 2.1 for all Usage options
        with ElectronicDocumentFormat do
            for UsageOption := Usage::"Sales Invoice" to Usage::"Service Validation" do begin
                Get('PEPPOL 2.0', UsageOption);
                Get('PEPPOL 2.1', UsageOption);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobDefaultDimension()
    var
        Job: Record Job;
    begin
        // [FEATURE] [Job] [Dimensions]
        // [SCENARIO 282994] Job default dimensions are the same with bill-to customer default dimensions
        if Job.FindSet then
            repeat
                VerifyJobDefaultDimensions(Job);
            until Job.Next = 0;
    end;

    local procedure VerifyJobDefaultDimensions(Job: Record Job)
    var
        CustDefaultDimension: Record "Default Dimension";
        JobDefaultDimension: Record "Default Dimension";
    begin
        CustDefaultDimension.SetRange("Table ID", DATABASE::Customer);
        CustDefaultDimension.SetRange("No.", Job."Bill-to Customer No.");
        if CustDefaultDimension.FindSet then
            repeat
                JobDefaultDimension.Get(DATABASE::Job, Job."No.", CustDefaultDimension."Dimension Code");
                JobDefaultDimension.TestField("Dimension Value Code", CustDefaultDimension."Dimension Value Code");
            until CustDefaultDimension.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_ReturnPeriodDefaultSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
        DummyDateFormula: DateFormula;
    begin
        // [FEATURE] [VAT Return Period]
        // [SCENARIO 258181] TAB 743 "VAT Report Setup" default setup
        with VATReportSetup do begin
            Get;
            TestField("VAT Return Period No. Series");
            TestField("Report Version", '');
            TestField("Period Reminder Calculation", DummyDateFormula);
            TestField("Update Period Job Frequency", "Update Period Job Frequency"::Never);
            TestField("Manual Receive Period CU ID", 0);
            TestField("Receive Submitted Return CU ID", 0);
            TestField("Auto Receive Period CU ID", 0);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxGroupNonTaxable()
    var
        TaxGroup: Record "Tax Group";
    begin
        // [SCENARIO] Tax Group NONTAXABLE should be one of 5 group
        TaxGroup.Get(NONTAXABLETok);
        Assert.RecordCount(TaxGroup, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountItemConfigTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        // [FEATURE] [Item] [Config. Template]
        // [SCENARIO] There should be 3 Item Config. Templates
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        Assert.RecordCount(ConfigTemplateHeader, 3);
    end;
}


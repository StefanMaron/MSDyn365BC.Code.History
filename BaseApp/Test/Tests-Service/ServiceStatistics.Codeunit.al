// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Pricing;
using System.TestLibraries.Utilities;

codeunit 136130 "Service Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [Service]
        isInitialized := false;
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AmountError: Label 'Amount %1 must be equal to %2.';
        VATAmountError: Label 'VAT Amount %1 must be equal to %2.';
        InvoiceDiscountAmountError: Label 'Invoice Discount Amount %1 must be equal to %2.';
        SalesLCYError: Label 'Sales(LCY) %1 must be equal to %2.';
        VATBaseAmountError: Label 'VAT Base Amount %1 must be equal to %2.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        Type2: Option " ",Item,Resource,Cost,"G/L Account";
        No2: Code[20];
        ItemNo: Code[20];
        GLAccountNo: Code[20];
        ResourceNo: Code[20];
        CostCode: Code[20];
        DocumentNo2: Code[20];
        DocumentType2: Enum "Service Document Type";
        CreditLimitLCY: Decimal;
        UpdateDiscountAmount: Boolean;
        UpdateTotalVAT: Boolean;
        InvoiceDiscountAmountErr: Label 'Incorrect Invoice Discount Amount.';
        OrigProfitLCYErr: Label 'Original Profit (LCY) is incorrect for service order %1.';
        OrigProfitPctErr: Label 'Original Profit Percent  is incorrect for service order %1.';
        AdjProfitLCYErr: Label 'Adjusted Profit (LCY) is incorrect for service order %1.';
        AdjProfitPctErr: Label 'Adjusted Profit Percent  is incorrect for service order %1.';

    [Test]
    [HandlerFunctions('DocumentItemPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceStatisticsItem()
    var
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test creation of Service Invoice with Item and verify Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup.
        Initialize();

        // 2. Exercise: Create Customer, Item, Service Invoice with Item and open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CreateCustomer());
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentResourcePageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceStatisticsResource()
    var
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test creation of Service Invoice with Resource and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup.
        Initialize();

        // 2. Exercise: Create Customer, Resource, Service Invoice with Resource and open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CreateCustomer());
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentGLAccountPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceStatisticsGLAccount()
    var
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test creation of Service Invoice with G/L Account and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup.
        Initialize();

        // 2. Exercise: Create Customer, G/L Account, Create Service Invoice with G/L Account and open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CreateCustomer());
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentGLAccountPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceStatisticsCost()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test creation of Service Invoice with Cost and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup and Service Cost.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);

        // 2. Exercise: Create Customer, Service Invoice with Cost and open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CreateCustomer());
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Cost, ServiceCost.Code);
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,DocumentDiscountPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceWithInvoiceDiscount()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceInvoice: TestPage "Service Invoice";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Invoice with multiple lines, Allow Invoice Discount and verify Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup,Service Cost and
        // Create Customer, Customer Invoice Discount.
        Initialize();

        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);
        LibraryService.FindServiceCost(ServiceCost);

        // 2. Exercise: Create Item, Resource, G/L Account, Service Invoice with multiple lines, Calculate Invoice Discount
        // and open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CustomerNo);
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Cost, ServiceCost.Code);

        ServiceInvoice."Calculate Invoice Discount".Invoke();
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentWithVATPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceWithPriceIncludingVAT()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test creation of Service Invoice with multiple lines, Price Including Vat and verify Statistics page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Service Cost.
        Initialize();

        LibraryService.FindServiceCost(ServiceCost);

        // 2. Exercise: Create Customer, Item, Resource,G/L Account, Service Invoice with Prices Including VAT as True,
        // multiple lines, in lines Allow Invoice Discount as False and open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CreateCustomer());
        ServiceInvoice."Prices Including VAT".SetValue(true);
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Cost, ServiceCost.Code);

        LineWithoutAllowInvoiceDisc(ServiceLine."Document Type"::Invoice, ServiceInvoice."No.".Value);
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ChangeDiscountPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeDiscountAmountInvoice()
    var
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Invoice with Allow Invoice Discount and change Invoice Discount Amount on Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup, Create Customer and
        // Customer Invoice Discount.
        Initialize();

        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // 2. Exercise: Create Item, Service Invoice, Calculate Invoice Discount, open Statistics Page and change
        // Invoice Discount Amount and again open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CustomerNo);
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceInvoice."Calculate Invoice Discount".Invoke();
        ServiceInvoice.Statistics.Invoke();
        UpdateDiscountAmount := true;  // Assign global variable for page handler.
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ChangeTotalVATPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeTotalVATInvoice()
    var
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Invoice with Allow Invoice Discount and change Total Incl. VAT on Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup, Create Customer and
        // Customer Invoice Discount.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // 2. Exercise: Create Item, Service Invoice, Calculate Invoice Discount , open Statistics Page and change
        // Total Incl. VAT and again open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CustomerNo);
        DocumentNo2 := ServiceInvoice."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Invoice;  // Assign global variable for page handler.
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceInvoice."Calculate Invoice Discount".Invoke();
        ServiceInvoice.Statistics.Invoke();
        UpdateTotalVAT := true;  // Assign global variable for page handler.
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentCreditLimitPageHandler')]
    [Scope('OnPrem')]
    procedure CreditLimitLCYOnInvoice()
    var
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test creation of Service Invoice and verify Credit limit on Statistics Page.

        // 1. Setup: Create Customer with Credit Limit(LCY).
        Initialize();
        CreateCustomerWithCreditLimit(Customer);
        CreditLimitLCY := Customer."Credit Limit (LCY)";  // Assign global variable for page handler.

        // 2. Exercise: Create G/L Account, Service Invoice with G/L Account and open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, Customer."No.");
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Credit Limit (LCY) in Statistics Page on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentItemPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoStatisticsItem()
    var
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test creation of Service Credit Memo with Item and verify Statistics Page.

        // 1. Setup
        Initialize();

        // 2. Exercise: Create Customer, Item, Service Credit Memo with Item and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CreateCustomer());
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentResourcePageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoStatisticsResource()
    var
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test creation of Service Credit Memo with Resource and verify Statistics Page.

        // 1. Setup
        Initialize();

        // 2. Exercise: Create Customer, Resource, Service Credit Memo with Resource and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CreateCustomer());
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentGLAccountPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoStatisticsGLAccount()
    var
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test creation of Service Credit Memo with G/L Account and verify Statistics Page.

        // 1. Setup
        Initialize();

        // 2. Exercise: Create Customer, G/L Account, Service Credit Memo with G/L Account and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CreateCustomer());
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := "Service Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentGLAccountPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoStatisticsCost()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test creation of Service Credit Memo with Cost and verify Statistics Page.

        // 1. Setup: Find Service Cost.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);

        // 2. Exercise: Create Customer, Service Credit Memo with Cost and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CreateCustomer());
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Cost, ServiceCost.Code);
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,DocumentDiscountPageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoWithInvoiceDiscount()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Credit Memo with multiple lines, Allow Invoice Discount and verify Statistics Page.

        // 1. Setup: Find Service Cost and Create Customer, Customer Invoice Discount.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);
        LibraryService.FindServiceCost(ServiceCost);

        // 2. Exercise: Create Item, Resource, G/L Account, Service Credit Memo with multiple lines, Calculate Invoice Discount
        // and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CustomerNo);
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Cost, ServiceCost.Code);

        ServiceCreditMemo."Calculate Invoice Discount".Invoke();
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentWithVATPageHandler')]
    [Scope('OnPrem')]
    procedure MemoWithPriceIncludingVAT()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test creation of Service Credit Memo with multiple lines, Price Including Vat and verify Statistics page.

        // 1. Setup: Find Service Cost.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);

        // 2. Exercise: Create Customer, Item, Resource,G/L Account, Service Credit Memo with Prices Including VAT as True,
        // multiple lines, in lines Allow Invoice Discount as False and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CreateCustomer());
        ServiceCreditMemo."Prices Including VAT".SetValue(true);
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        CreateServiceCreditMemoLine(
          ServiceCreditMemo, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Cost, ServiceCost.Code);

        LineWithoutAllowInvoiceDisc(ServiceLine."Document Type"::"Credit Memo", ServiceCreditMemo."No.".Value);
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ChangeDiscountPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeDiscountAmountCreditMemo()
    var
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Credit Memo with Allow Invoice Discount and change Invoice Discount Amount on Statistics Page.

        // 1. Setup: Find VAT Posting Setup, Create Customer and Customer Invoice Discount.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // 2. Exercise: Create Item, Service Credit Memo, Calculate Invoice Discount, open Statistics Page and change
        // Invoice Discount Amount and again open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CustomerNo);
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceCreditMemo."Calculate Invoice Discount".Invoke();
        ServiceCreditMemo.Statistics.Invoke();
        UpdateDiscountAmount := true;  // Assign global variable for page handler.
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ChangeTotalVATPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeTotalVATCreditMemo()
    var
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Credit Memo with Allow Invoice Discount and change Total Incl. VAT on Statistics Page.

        // 1. Setup: Find VAT Posting Setup, Create Customer and Customer Invoice Discount.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // 2. Exercise: Create Item, Service Credit Memo, Calculate Invoice Discount , open Statistics Page and change
        // Total Incl. VAT and again open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CustomerNo);
        DocumentNo2 := ServiceCreditMemo."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::"Credit Memo";  // Assign global variable for page handler.
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceCreditMemo."Calculate Invoice Discount".Invoke();
        ServiceCreditMemo.Statistics.Invoke();
        UpdateTotalVAT := true;  // Assign global variable for page handler.
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('DocumentCreditLimitPageHandler')]
    [Scope('OnPrem')]
    procedure CreditLimitLCYOnCreditMemo()
    var
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test creation of Service Credit Memo and verify Credit limit on Statistics Page.

        // 1. Setup: Create Customer with Credit Limit(LCY).
        Initialize();
        CreateCustomerWithCreditLimit(Customer);
        CreditLimitLCY := Customer."Credit Limit (LCY)";  // Assign global variable for page handler.

        // 2. Exercise: Create G/L Account, Service Credit Memo with G/L Account and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, Customer."No.");
        CreateServiceCreditMemoLine(
          ServiceCreditMemo, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Credit Limit (LCY) in Statistics Page on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,OrderItemPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderStatisticsItem()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // Test creation of Service Order with Item and verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup and Create Item.
        Initialize();

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CreateCustomer());
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Type2 := Type2::Item;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,OrderResourcePageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderStatisticsResource()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // Test creation of Service Order with Resource and verify Service Order Statistics Page.

        // 1. Setup: Create Resource.
        Initialize();

        // Assign global variable for page handler.
        No2 := LibraryResource.CreateResourceNo();
        Type2 := Type2::Resource;

        // 2. Exercise: Create Customer Service Order with Resource and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CreateCustomer());
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Type2 := Type2::Resource;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page Handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,OrderGLAccountPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderStatisticsGLAccount()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // Test creation of Service Order with G/L Account and verify Service Order Statistics Page.

        // 1. Setup: Create G/L Account.
        Initialize();

        // Assign global variable for page handler.
        No2 := LibraryERM.CreateGLAccountWithSalesSetup();
        Type2 := Type2::"G/L Account";

        // 2. Exercise: Create Customer, Service Order with G/L Account and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CreateCustomer());
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Type2 := Type2::"G/L Account";  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page Handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,OrderGLAccountPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderStatisticsCost()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceOrder: TestPage "Service Order";
    begin
        // Test creation of Service Order with Cost and verify Service Order Statistics Page.

        // 1. Setup: Find Service Cost.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);

        // Assign global variable for page handler.
        No2 := ServiceCost.Code;
        Type2 := Type2::Cost;

        // 2. Exercise: Create Customer, Service Order with Cost and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CreateCustomer());
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Type2 := Type2::Cost;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesMultiPageHandler,OrderInvoiceDiscountHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderWithInvoiceDiscount()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order with multiple lines, Allow Invoice Discount and verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup and
        // Create Customer, Customer Invoice Discount ,Item, Resource and G/L Account.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        ItemNo := LibraryInventory.CreateItemNo();
        ResourceNo := LibraryResource.CreateResourceNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CostCode := ServiceCost.Code;

        // 2. Exercise: Create Service Order with multiple lines, Calculate Invoice Discount and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesMultiPageHandler,OrderWithVATPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderWithPriceIncludingVAT()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceOrder: TestPage "Service Order";
    begin
        // Test creation of Service Order with multiple lines, Price Including Vat and verify Service Order Statistics page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup, Service Cost and
        // Create Item, Resource and G/L Account.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);

        // Assign global variable for page handler.
        ItemNo := LibraryInventory.CreateItemNo();
        ResourceNo := LibraryResource.CreateResourceNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CostCode := ServiceCost.Code;

        // 2. Exercise: Create Service Order with Prices Including VAT as True,multiple lines,
        // in lines Allow Invoice Discount as False and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CreateCustomer());
        ServiceOrder."Prices Including VAT".SetValue(true);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        LineWithoutAllowInvoiceDisc(ServiceLine."Document Type"::Order, ServiceOrder."No.".Value);
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ChangeDiscountOrderPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeDiscountAmountOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order with Allow Invoice Discount and change Invoice Discount Amount on Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup, Create Customer,
        // Customer Invoice Discount and Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order, Calculate Invoice Discount, open Service Order Statistics Page and change
        // Invoice Discount Amount and again open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();
        UpdateDiscountAmount := true;  // Assign global variable for page handler.
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ChangeTotalVATOrderPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeTotalVATOrder()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order with Allow Invoice Discount and change Total Incl. VAT on Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup, Create Customer and
        // Customer Invoice Discount and Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order, Calculate Invoice Discount , open Service Order Statistics Page and change
        // Total Incl. VAT and again open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();
        UpdateTotalVAT := true;  // Assign global variable for page handler.
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,QuantityToShipPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderWithQuantityToShip()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order, Update Quantity to Ship and verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup, Create Customer,
        // Customer Invoice Discount and Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Ship and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,QuantityToShipPageHandler,ShipStrMenuHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderWithQuantityToShipPost()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order, Update Quantity to Ship, Post and verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer,
        // Customer Invoice Discount, Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Ship, Post and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        ServiceOrder.Post.Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ChangeDiscountOrderShipHandler,ShipStrMenuHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeDiscountAmountOrderShip()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order, Update Quantity to Ship, Post, Update Invoice Discount Amount on Statistics Page and
        // verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer,
        // Customer Invoice Discount, Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Ship, Post, Open Service Order Statistics Page,
        // Change Invoice Discount Amount, and again open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        ServiceOrder.Post.Invoke();
        ServiceOrder.Statistics.Invoke();
        UpdateDiscountAmount := true;  // Assign global variable for page handler.
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ChangeDiscountOrderShipHandler,ShipStrMenuHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountOrderShip()
    var
        CustomerNo: Code[20];
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 216154] Posted Service Line's Invoice Discount Amount after updating invoice discount amount on statistics page
        Initialize();

        // [GIVEN] Sales & Receivables Setup "Calc. Inv. Discount" = FALSE
        LibrarySales.SetCalcInvDiscount(false);
        // [GIVEN] Customer with Invoice Discount setup: "Minimum Amount" = 0, "Discount %" = 10
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // [GIVEN] Service Order: "Service Item No." = "", "Item No." = "X"
        // [GIVEN] Servie Line for item "X": "Type" = Item, "No." = "X", "Unit Price" = 100, "Quantity" = 1
        // [GIVEN] Calculate Invoice Discount for Service Line
        // [GIVEN] Service Line's "Inv. Discount Amount" = 10
        // [GIVEN] Open Service Order's Statistics
        // [GIVEN] Change Invoice Discount = 20
        // [WHEN] Post Service Invoice
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;
        CreateAndPostServiceOrderWithInvoiceDiscountAmount(CustomerNo, InvoiceDiscountAmount);

        // [THEN] Posted Service Line has "Inv. Discount Amount" = 20
        VerifyServiceLineInvoiceDiscountAmount(DocumentNo2, InvoiceDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ChangeTotalVATOrderShipHandler,ShipStrMenuHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeTotalVATAmountOrderShip()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order, Update Quantity to Ship, Post, Update Total Incl. VAT on Statistics Page and
        // verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer,
        // Customer Invoice Discount, Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Ship, Post, Open Service Order Statistics Page,
        // Change Total Incl. VAT , and again open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        ServiceOrder.Post.Invoke();
        ServiceOrder.Statistics.Invoke();
        UpdateTotalVAT := true;  // Assign global variable for page handler.
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,QuantityToInvoicePageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderWithQuantityToInvoice()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order with Item, Update Quantity to Invoice and verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer,
        // Customer Invoice Discount, Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Invoice and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToInvoiceLine(DocumentNo2);
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,QuantityToInvoicePageHandler,ShipAndInvoiceStrMenuHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OrderWithQuantityToInvoicePost()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order with Item, Update Quantity to Invoice, Post and verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer,
        // Customer Invoice Discount, Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Invoice, Post and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        UpdateQuantityToInvoiceLine(DocumentNo2);
        ServiceOrder.Post.Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ChangeDiscountOrderPostHandler,ShipAndInvoiceStrMenuHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeDiscountAmountOrderPost()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order with Item, Update Quantity to Invoice, Post, Update Invoice Discount Amount on Statistics Page and
        // verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer,
        // Customer Invoice Discount, Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Invoice, Post, Open Service Order Statistics Page,
        // Change Invoice Discount Amount, and again open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        UpdateQuantityToInvoiceLine(DocumentNo2);
        ServiceOrder.Post.Invoke();
        ServiceOrder.Statistics.Invoke();
        UpdateDiscountAmount := true;  // Assign global variable for page handler.
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ChangeTotalVATOrderPostHandler,ShipAndInvoiceStrMenuHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeTotalVATAmountOrderPost()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Order, Update Quantity to Invoice, Post, Update Total Incl. VAT on Statistics Page and
        // verify Service Order Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer,
        // Customer Invoice Discount, Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Order with Item, Update Quantity to Invoice, Post,
        // open Service Order Statistics Page, Change Total Incl. VAT, and again open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        UpdateQuantityToInvoiceLine(DocumentNo2);
        ServiceOrder.Post.Invoke();
        ServiceOrder.Statistics.Invoke();
        UpdateQuantityToShipLine(DocumentNo2);
        UpdateQuantityToInvoiceLine(DocumentNo2);
        UpdateTotalVAT := true;  // Assign global variable for page handler.
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,CreditLimitLCYPageHandler')]
    [Scope('OnPrem')]
    procedure CreditLimitLCYOnOrder()
    var
        Customer: Record Customer;
        ServiceOrder: TestPage "Service Order";
    begin
        // Test creation of Service Order and verify Credit limit on Service Order Statistics Page.

        // 1. Setup: Find VAT Posting Setup, Create Customer with Credit Limit(LCY) and G/L Account.
        Initialize();
        CreateCustomerWithCreditLimit(Customer);
        CreditLimitLCY := Customer."Credit Limit (LCY)";  // Assign global variable for page handler.

        // Assign global variable for page handler.
        No2 := LibraryERM.CreateGLAccountWithSalesSetup();
        Type2 := Type2::"G/L Account";

        // 2. Exercise: Create Service Order with G/L Account and open Service Order Statistics Page.
        CreateServiceOrderHeader(ServiceOrder, Customer."No.");
        CreateServiceOrderItemLine(ServiceOrder);
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();

        // 3. Verify: Verify Credit Limit (LCY) in Service Order Statistics Page on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesPageHandler,DocumentItemPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteStatisticsItem()
    var
        ServiceLine: Record "Service Line";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Test creation of Service Quote with Item and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup and Create Item.
        Initialize();

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Quote with Item and open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CreateCustomer());
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesPageHandler,DocumentResourcePageHandler')]
    [Scope('OnPrem')]
    procedure QuoteStatisticsResource()
    var
        ServiceLine: Record "Service Line";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Test creation of Service Quote with Resource and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup and Create Resource.
        Initialize();

        // Assign global variable for page handler.
        No2 := LibraryResource.CreateResourceNo();
        Type2 := Type2::Resource;

        // 2. Exercise: Create Customer Service Quote with Resource and open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CreateCustomer());
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesPageHandler,DocumentGLAccountPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteStatisticsGLAccount()
    var
        ServiceLine: Record "Service Line";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Test creation of Service Quote with G/L Account and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup and Create G/L Account.
        Initialize();

        // Assign global variable for page handler.
        No2 := LibraryERM.CreateGLAccountWithSalesSetup();
        Type2 := Type2::"G/L Account";

        // 2. Exercise: Create Customer, Service Quote with G/L Account and open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CreateCustomer());
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesPageHandler,DocumentGLAccountPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteStatisticsCost()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Test creation of Service Quote with Cost and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup and Service Cost.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);

        // Assign global variable for page handler.
        No2 := ServiceCost.Code;
        Type2 := Type2::Cost;

        // 2. Exercise: Create Customer, Service Quote with Cost and open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CreateCustomer());
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesMultiplePageHandler,DocumentDiscountPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteWithInvoiceDiscount()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceQuote: TestPage "Service Quote";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Quote with multiple lines, Allow Invoice Discount and verify Statistics Page.

        // 1. Setup: Find VAT Posting Setup,Service Cost, Create Customer, Customer Invoice Discount ,Item, Resource and G/L Account.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        ItemNo := LibraryInventory.CreateItemNo();
        ResourceNo := LibraryResource.CreateResourceNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CostCode := ServiceCost.Code;

        // 2. Exercise: Create Service Quote with multiple lines, Calculate Invoice Discount and open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CustomerNo);
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesMultiplePageHandler,DocumentWithVATPageHandler')]
    [Scope('OnPrem')]
    procedure QuoteWithPriceIncludingVAT()
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Test creation of Service Quote with multiple lines, Price Including Vat and verify Statistics page.

        // 1. Setup: Find VAT Posting Setup, Service Cost, Create Item, Resource and G/L Account.
        Initialize();
        LibraryService.FindServiceCost(ServiceCost);

        // Assign global variable for page handler.
        ItemNo := LibraryInventory.CreateItemNo();
        ResourceNo := LibraryResource.CreateResourceNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CostCode := ServiceCost.Code;

        // 2. Exercise: Create Service Quote with Prices Including VAT as True,multiple lines,
        // in lines Allow Invoice Discount as False and open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CreateCustomer());
        ServiceQuote."Prices Including VAT".SetValue(true);
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        LineWithoutAllowInvoiceDisc(ServiceLine."Document Type"::Quote, ServiceQuote."No.".Value);
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesPageHandler,ChangeDiscountPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeDiscountAmountQuote()
    var
        ServiceLine: Record "Service Line";
        ServiceQuote: TestPage "Service Quote";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Quote with Allow Invoice Discount and change Invoice Discount Amount on Statistics Page.

        // 1. Setup: Find VAT Posting Setup, Create Customer, Customer Invoice Discount and Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Quote, Calculate Invoice Discount, open Statistics Page, change
        // Invoice Discount Amount and again open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CustomerNo);
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();
        UpdateDiscountAmount := true;  // Assign global variable for page handler.
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesPageHandler,ChangeTotalVATPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeTotalVATQuote()
    var
        ServiceLine: Record "Service Line";
        ServiceQuote: TestPage "Service Quote";
        CustomerNo: Code[20];
    begin
        // Test creation of Service Quote with Allow Invoice Discount and change Total Incl. VAT on Statistics Page.

        // 1. Setup: Find VAT Posting Setup, Create Customer, Customer Invoice Discount and Item.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateCustomerInvoiceDiscount(CustomerNo);

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Service Quote, Calculate Invoice Discount , open Statistics Page, change
        // Total Incl. VAT and again open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, CustomerNo);
        CreateServiceQuoteItemLine(ServiceQuote);
        DocumentNo2 := ServiceQuote."No.".Value(); // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Quote;  // Assign global variable for page handler.
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();
        UpdateTotalVAT := true;  // Assign global variable for page handler.
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Service Order Statistics Page with details on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,QuoteLinesPageHandler,DocumentCreditLimitPageHandler')]
    [Scope('OnPrem')]
    procedure CreditLimitLCYOnQuote()
    var
        Customer: Record Customer;
        ServiceQuote: TestPage "Service Quote";
    begin
        // Test creation of Service Quote and verify Credit limit on Statistics Page.

        // 1. Setup: Find VAT Posting Setup, Create Customer with Credit Limit(LCY) and G/L Account.
        Initialize();
        CreateCustomerWithCreditLimit(Customer);
        CreditLimitLCY := Customer."Credit Limit (LCY)";  // Assign global variable for page handler.

        // Assign global variable for page handler.
        No2 := LibraryERM.CreateGLAccountWithSalesSetup();
        Type2 := Type2::"G/L Account";

        // 2. Exercise: Create Service Quote with G/L Account and open Statistics Page.
        CreateServiceQuoteHeader(ServiceQuote, Customer."No.");
        CreateServiceQuoteItemLine(ServiceQuote);
        Commit();
        ServiceQuote.ServItemLine.First();
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuote.Statistics.Invoke();

        // 3. Verify: Verify Credit Limit (LCY) in Service Statistics Page on Page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ServiceLinesPageHandler,ShipAndInvoiceStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipmentStatistics()
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceOrder: TestPage "Service Order";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        ServiceShipmentStatistics: TestPage "Service Shipment Statistics";
        DocumentNo: Code[20];
    begin
        // Test creation of Service Order with Item, post Service Order and verify Service Shipment Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Item.
        Initialize();

        // Assign global variable for page handler.
        No2 := LibraryInventory.CreateItemNo();
        Type2 := Type2::Item;

        // 2. Exercise: Create Customer, Service Order with Item, Post, Find Posted Service Shipment and open Statistics.
        CreateServiceOrderHeader(ServiceOrder, CreateCustomer());
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo := ServiceOrder."No.".Value();
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        LibrarySales.DisableConfirmOnPostingDoc();
        ServiceOrder.Post.Invoke();

        PostedServiceShipment.OpenView();
        PostedServiceShipment.FILTER.SetFilter("No.", FindServiceShipmentHeader(DocumentNo));
        ServiceShipmentStatistics.Trap();
        PostedServiceShipment."S&tatistics".Invoke();

        // 3. Verify: Verify Quantity on Service Shipment Statistics Page.
        ServiceShipmentLine.SetRange("Document No.", PostedServiceShipment."No.".Value);
        ServiceShipmentLine.FindFirst();
        ServiceShipmentStatistics.LineQty.AssertEquals(ServiceShipmentLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedInvoiceStatistics()
    var
        ServiceLine: Record "Service Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoice: TestPage "Service Invoice";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        ServiceInvoiceStatistics: TestPage "Service Invoice Statistics";
        DocumentNo: Code[20];
    begin
        // Test creation of Service Invoice with Item, post Service Invoice and verify Service Invoice Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup and Find VAT Posting Setup.
        Initialize();

        // 2. Exercise: Create Customer, Item, Service Invoice with Item, Find Posted Service Invoice and  open Statistics Page.
        CreateServiceInvoiceHeader(ServiceInvoice, CreateCustomer());
        DocumentNo := ServiceInvoice."No.".Value();
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        PostServiceInvoice(ServiceInvoice);

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("No.", FindServiceInvoiceHeader(DocumentNo));
        ServiceInvoiceStatistics.Trap();
        PostedServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Service Invoice Statistics Page with details.
        ServiceInvoiceLine.SetRange("Document No.", PostedServiceInvoice."No.".Value);
        ServiceInvoiceLine.FindFirst();

        ServiceInvoiceStatistics.Amount.AssertEquals(ServiceInvoiceLine.Amount);
        ServiceInvoiceStatistics.VATAmount.AssertEquals(ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount);
        ServiceInvoiceStatistics.Subform.First();
        ServiceInvoiceStatistics.Subform."VAT Amount".AssertEquals(
          ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditLimitLCYOnPostedInvoice()
    var
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        ServiceInvoiceStatistics: TestPage "Service Invoice Statistics";
        DocumentNo: Code[20];
    begin
        // Test creation of Service Invoice, post Service Invoice and verify Credit limit on Service Invoice Statistics Page.

        // 1. Setup: Update Stockout Warning on Sales & Receivables Setup, Find VAT Posting Setup and Create Customer with Credit Limit.
        Initialize();
        CreateCustomerWithCreditLimit(Customer);

        // 2. Exercise: Create Service Invoice with Item, post,Find Posted Service Invoice and open Statistic Page.
        CreateServiceInvoiceHeader(ServiceInvoice, Customer."No.");
        DocumentNo := ServiceInvoice."No.".Value();
        CreateServiceInvoiceLine(ServiceInvoice, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        PostServiceInvoice(ServiceInvoice);

        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("No.", FindServiceInvoiceHeader(DocumentNo));
        ServiceInvoiceStatistics.Trap();
        PostedServiceInvoice.Statistics.Invoke();

        // 3. Verify: Verify Credit Limit (LCY) on Service Invoice Statistics Page.
        ServiceInvoiceStatistics.CreditLimitLCY.AssertEquals(Customer."Credit Limit (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostedCreditMemoStatistics()
    var
        ServiceLine: Record "Service Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics";
        DocumentNo: Code[20];
    begin
        // Test creation of Service Credit Memo with Item, post Service Credit Memo and verify Service Credit Memo Statistics Page.

        // 1. Setup: Find VAT Posting Setup.
        Initialize();

        // 2. Exercise: Create Customer,Item,Service Credit Memo with Item, post, Find Posted Service Credit Memo and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, CreateCustomer());
        DocumentNo := ServiceCreditMemo."No.".Value();
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        LibrarySales.DisableConfirmOnPostingDoc();
        ServiceCreditMemo.Post.Invoke();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", FindServiceCreditMemoHeader(DocumentNo));
        ServiceCreditMemoStatistics.Trap();
        PostedServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Service Credit Memo Statistics Page with details.
        ServiceCrMemoLine.SetRange("Document No.", PostedServiceCreditMemo."No.".Value);
        ServiceCrMemoLine.FindFirst();
        ServiceCreditMemoStatistics.Amount.AssertEquals(ServiceCrMemoLine.Amount);
        ServiceCreditMemoStatistics.VATAmount.AssertEquals(ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount);
        ServiceCreditMemoStatistics.Subform.First();
        ServiceCreditMemoStatistics.Subform."VAT Amount".AssertEquals(
          ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreditLimitLCYOnPostedMemo()
    var
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics";
        DocumentNo: Code[20];
    begin
        // Test creation of Service Credit Memo, post Service Credit Memo and verify Credit limit on Service Credit Memo Statistics Page.

        // 1. Setup: Find VAT Posting Setup and Create Customer with Credit Limit.
        Initialize();
        CreateCustomerWithCreditLimit(Customer);

        // 2. Exercise: Create Item, Service Credit Memo with Item, post,Find Posted Service Credit Memo and open Statistics Page.
        CreateServiceCreditMemoHeader(ServiceCreditMemo, Customer."No.");
        DocumentNo := ServiceCreditMemo."No.".Value();
        CreateServiceCreditMemoLine(ServiceCreditMemo, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        LibrarySales.DisableConfirmOnPostingDoc();
        ServiceCreditMemo.Post.Invoke();

        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", FindServiceCreditMemoHeader(DocumentNo));
        ServiceCreditMemoStatistics.Trap();
        PostedServiceCreditMemo.Statistics.Invoke();

        // 3. Verify: Verify Credit Limit (LCY) on Service Credit Memo Statistics Page.
        ServiceCreditMemoStatistics.CreditLimitLCY.AssertEquals(Customer."Credit Limit (LCY)");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatNegativeProfitPageHandler')]
    [Scope('OnPrem')]
    procedure OrderStatisticsNegativeProfit()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        Item: Record Item;
        ServiceOrder: TestPage "Service Order";
        ProfitValue: Decimal;
        ProfitPct: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Service Order Statistics]
        // [SCENARIO 319397] Profit fields are filleed in correctly when Unit Price is less than Unit cost in Service Lines
        Initialize();

        // [GIVEN] Item "X" with Unit Cost = 100
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        Item.Modify(true);

        // [GIVEN] Service Order with Service Line for "X" priced at 10
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);

        // [WHEN] Open Service Order Statistics page
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceOrder.Statistics.Invoke();

        // [THEN] Validate Original Profit (LCY), Original Profit %, Adjusted Profit (LCY), Adjusted Profit %
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();
        ProfitValue := ServiceLine.Amount - ServiceLine."Unit Cost (LCY)" * ServiceLine.Quantity;
        ProfitPct := Round(ProfitValue / ServiceLine.Amount * 100, AmountRoundingPrecision);

        Assert.AreNearlyEqual(ProfitValue, LibraryVariableStorage.DequeueDecimal(), AmountRoundingPrecision,
          StrSubstNo(OrigProfitLCYErr, ServiceLine."Document No."));
        Assert.AreNearlyEqual(ProfitPct, LibraryVariableStorage.DequeueDecimal(), AmountRoundingPrecision,
          StrSubstNo(OrigProfitPctErr, ServiceLine."Document No."));
        Assert.AreEqual(ProfitValue, LibraryVariableStorage.DequeueDecimal(), AdjProfitLCYErr);
        Assert.AreEqual(ProfitPct, LibraryVariableStorage.DequeueDecimal(), AdjProfitPctErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Statistics");
        InitVariables();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Statistics");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibrarySales.SetStockoutWarning(false);

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Statistics");
    end;

    local procedure CreateCustomer(): Code[20]
    begin
        exit(LibrarySales.CreateCustomerNo());
    end;

    local procedure CreateCustomerInvoiceDiscount(CustomerNo: Code[20])
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(50, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateCustomerWithCreditLimit(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandDec(100, 2)); // Take Random Credit Limit (LCY).
        Customer.Modify(true);
    end;

    local procedure CreateServiceCreditMemoHeader(var ServiceCreditMemo: TestPage "Service Credit Memo"; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemoNo: Code[20];
    begin
        ServiceCreditMemoNo := LibraryService.CreateServiceCreditMemoHeaderUsingPage();
        Commit();

        Clear(ServiceCreditMemo);
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::"Credit Memo"));
        ServiceCreditMemo.FILTER.SetFilter("No.", ServiceCreditMemoNo);
        ServiceCreditMemo."Customer No.".SetValue(CustomerNo);
    end;

    local procedure CreateServiceCreditMemoLine(var ServiceCreditMemo: TestPage "Service Credit Memo"; Type: Enum "Service Line Type"; No: Code[20])
    begin
        ServiceCreditMemo.ServLines.Type.SetValue(Type);
        ServiceCreditMemo.ServLines."No.".SetValue(No);

        // Take Random Quantity and Unit Price.
        ServiceCreditMemo.ServLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        ServiceCreditMemo.ServLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
        ServiceCreditMemo.ServLines.New();
    end;

    local procedure CreateServiceLine(var ServiceLines: TestPage "Service Lines"; Type: Option; No: Code[20])
    begin
        ServiceLines.Type.SetValue(Type);
        ServiceLines."No.".SetValue(No);

        // Take Random Quantity and Unit Price.
        ServiceLines.Quantity.SetValue(2 * LibraryRandom.RandDec(10, 2));
        ServiceLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
        ServiceLines.New();
    end;

    local procedure CreateServiceInvoiceHeader(var ServiceInvoice: TestPage "Service Invoice"; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceNo: Code[20];
    begin
        ServiceInvoice.OpenNew();
        ServiceInvoice."Customer No.".Activate();
        ServiceInvoiceNo := ServiceInvoice."No.".Value();
        ServiceInvoice.OK().Invoke();
        Commit();

        Clear(ServiceInvoice);
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Invoice));
        ServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceNo);
        ServiceInvoice."Customer No.".SetValue(CustomerNo);
    end;

    local procedure CreateServiceInvoiceLine(var ServiceInvoice: TestPage "Service Invoice"; Type: Enum "Service Line Type"; No: Code[20])
    begin
        ServiceInvoice.ServLines.Type.SetValue(Type);
        ServiceInvoice.ServLines."No.".SetValue(No);

        // Take Random Quantity and Unit Price.
        ServiceInvoice.ServLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        ServiceInvoice.ServLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
        ServiceInvoice.ServLines.New();
    end;

    local procedure CreateServiceOrderHeader(var ServiceOrder: TestPage "Service Order"; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceOrderNo: Code[20];
    begin
        ServiceOrderNo := LibraryService.CreateServiceOrderHeaderUsingPage();
        Commit();

        Clear(ServiceOrder);
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Order));
        ServiceOrder.FILTER.SetFilter("No.", ServiceOrderNo);
        ServiceOrder."Customer No.".SetValue(CustomerNo);
    end;

    local procedure CreateServiceOrderItemLine(var ServiceOrder: TestPage "Service Order")
    begin
        ServiceOrder.ServItemLines.Description.SetValue(ServiceOrder."No.".Value);
        ServiceOrder.ServItemLines.New();
    end;

    local procedure CreateServiceQuoteHeader(var ServiceQuote: TestPage "Service Quote"; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceQuoteNo: Code[20];
    begin
        ServiceQuote.OpenNew();
        ServiceQuote."Customer No.".Activate();
        ServiceQuoteNo := ServiceQuote."No.".Value();
        ServiceQuote.OK().Invoke();
        Commit();

        Clear(ServiceQuote);
        ServiceQuote.OpenEdit();
        ServiceQuote.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Quote));
        ServiceQuote.FILTER.SetFilter("No.", ServiceQuoteNo);
        ServiceQuote."Customer No.".SetValue(CustomerNo);
    end;

    local procedure CreateServiceQuoteItemLine(var ServiceQuote: TestPage "Service Quote")
    begin
        ServiceQuote.ServItemLine.Description.SetValue(ServiceQuote."No.".Value);
        ServiceQuote.ServItemLine.New();
    end;

    local procedure CreateServiceQuoteLine(var ServiceQuoteLines: TestPage "Service Quote Lines"; Type: Option; No: Code[20])
    begin
        ServiceQuoteLines.Type.SetValue(Type);
        ServiceQuoteLines."No.".SetValue(No);

        // Take Random Quantity and Unit Price.
        ServiceQuoteLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        ServiceQuoteLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
        ServiceQuoteLines.New();
    end;

    local procedure CreateAndPostServiceOrderWithInvoiceDiscountAmount(CustomerNo: Code[20]; var InvoiceDiscountAmount: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        CreateServiceOrderHeader(ServiceOrder, CustomerNo);
        CreateServiceOrderItemLine(ServiceOrder);
        DocumentNo2 := ServiceOrder."No.".Value();  // Assign global variable for page handler.
        DocumentType2 := ServiceLine."Document Type"::Order;  // Assign global variable for page handler.
        Commit();
        ServiceOrder.ServItemLines.First();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Statistics.Invoke();
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        InvoiceDiscountAmount := ServiceLine."Inv. Discount Amount";
        ServiceOrder.Post.Invoke();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
    end;

    local procedure FilterServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure FindServiceCreditMemoHeader(PreAssignedNo: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure FindServiceShipmentHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure FindServiceInvoiceHeader(PreAssignedNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure GetAmountRoundingPrecision(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Amount Rounding Precision");
    end;

    local procedure InitVariables()
    begin
        Clear(Type2);
        Clear(DocumentType2);
        No2 := '';
        ItemNo := '';
        GLAccountNo := '';
        ResourceNo := '';
        CostCode := '';
        DocumentNo2 := '';
        CreditLimitLCY := 0;
        UpdateDiscountAmount := false;
        UpdateTotalVAT := false;
    end;

    local procedure LineWithoutAllowInvoiceDisc(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType, DocumentNo);
        repeat
            ServiceLine.Validate("Allow Invoice Disc.", false);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure PostServiceInvoice(ServiceInvoice: TestPage "Service Invoice")
    var
        ServiceHeader: Record "Service Header";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, ServiceInvoice."No.".Value);
        Ship := false;
        Consume := false;
        Invoice := false;
        LibraryService.PostServiceOrder(ServiceHeader, Ship, Consume, Invoice);
    end;

    local procedure UpdateDiscountAmountOrder(ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        InvoiceDiscountAmount: Decimal;
    begin
        Evaluate(InvoiceDiscountAmount, ServiceOrderStatistics."Inv. Discount Amount_General".Value);

        // Take Random for Invoice Discount Amount.
        ServiceOrderStatistics."Inv. Discount Amount_General".SetValue(
          InvoiceDiscountAmount + LibraryRandom.RandDec(5, 2));
    end;

    local procedure UpdateDiscountAmountStatistics(ServiceStatistics: TestPage "Service Statistics")
    var
        InvoiceDiscountAmount: Decimal;
    begin
        Evaluate(InvoiceDiscountAmount, ServiceStatistics."Inv. Discount Amount_General".Value);

        // Take Random for Invoice Discount Amount.
        ServiceStatistics."Inv. Discount Amount_General".SetValue(
          InvoiceDiscountAmount + LibraryRandom.RandDec(5, 2));
    end;

    local procedure UpdateQuantityToShipLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity / 2);  // Dividing by 2 to take partial Qty. to Ship.
        ServiceLine.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceLine.Validate("Qty. to Invoice", ServiceLine.Quantity / 2);  // Dividing by 2 to take partial Qty. to Invoice.
        ServiceLine.Modify(true);
    end;

    local procedure UpdateTotalVATOrderStatistics(ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        TotalInclVAT: Decimal;
    begin
        Evaluate(TotalInclVAT, ServiceOrderStatistics."Total Incl. VAT_General".Value);

        // Take Random for Total Incl. VAT.
        ServiceOrderStatistics."Total Incl. VAT_General".SetValue(TotalInclVAT + LibraryRandom.RandDec(5, 2));
    end;

    local procedure UpdateTotalVATStatistics(ServiceStatistics: TestPage "Service Statistics")
    var
        TotalInclVAT: Decimal;
    begin
        Evaluate(TotalInclVAT, ServiceStatistics."Total Incl. VAT_General".Value);

        // Take Random for Total Incl. VAT.
        ServiceStatistics."Total Incl. VAT_General".SetValue(TotalInclVAT + LibraryRandom.RandDec(5, 2));
    end;

    local procedure VerifyOrderLineItems(ServiceOrderStatistics: TestPage "Service Order Statistics"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        AmountItems: Decimal;
        VATAmountItems: Decimal;
        TotalInclVATItems: Decimal;
        SalesLCYItems: Decimal;
        InvDiscountAmountItems: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        FilterServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindFirst();

        Evaluate(AmountItems, ServiceOrderStatistics.Amount_Items.Value);
        Evaluate(VATAmountItems, ServiceOrderStatistics."VAT Amount_Items".Value);
        Evaluate(TotalInclVATItems, ServiceOrderStatistics."Total Incl. VAT_Items".Value);
        Evaluate(SalesLCYItems, ServiceOrderStatistics."Sales (LCY)_Items".Value);
        Evaluate(InvDiscountAmountItems, ServiceOrderStatistics."Inv. Discount Amount_Items".Value);

        Assert.AreNearlyEqual(
          ServiceLine.Amount + ServiceLine."Inv. Discount Amount", AmountItems, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountItems, ServiceLine.Amount + ServiceLine."Inv. Discount Amount"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountItems, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountItems, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", TotalInclVATItems, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATItems, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYItems, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYItems, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Inv. Discount Amount", InvDiscountAmountItems, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountItems, ServiceLine."Inv. Discount Amount"));
    end;

    local procedure VerifyOrderLineResources(ServiceOrderStatistics: TestPage "Service Order Statistics"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        AmountResources: Decimal;
        VATAmountResources: Decimal;
        TotalInclVATResources: Decimal;
        SalesLCYResources: Decimal;
        InvDiscountAmountResources: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        FilterServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Resource);
        ServiceLine.FindFirst();

        Evaluate(AmountResources, ServiceOrderStatistics.Amount_Resources.Value);
        Evaluate(VATAmountResources, ServiceOrderStatistics."VAT Amount_Resources".Value);
        Evaluate(TotalInclVATResources, ServiceOrderStatistics."Total Incl. VAT_Resources".Value);
        Evaluate(SalesLCYResources, ServiceOrderStatistics."Sales (LCY)_Resources".Value);
        Evaluate(InvDiscountAmountResources, ServiceOrderStatistics."Inv. Discount Amount_Resources".Value);

        Assert.AreNearlyEqual(
          ServiceLine.Amount + ServiceLine."Inv. Discount Amount", AmountResources, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountResources, ServiceLine.Amount + ServiceLine."Inv. Discount Amount"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountResources, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountResources, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", TotalInclVATResources, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATResources, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYResources, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYResources, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Inv. Discount Amount", InvDiscountAmountResources, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountResources, ServiceLine."Inv. Discount Amount"));
    end;

    local procedure VerifyOrderLineCostGLAccount(ServiceOrderStatistics: TestPage "Service Order Statistics"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        AmountIncludingVAT: Decimal;
        Amount: Decimal;
        InvDiscountAmount: Decimal;
        AmountCosts: Decimal;
        VATAmountCosts: Decimal;
        TotalInclVATCosts: Decimal;
        SalesLCYCosts: Decimal;
        InvDiscountAmountCosts: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        FilterServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceLine.SetFilter(Type, '%1|%2', ServiceLine.Type::Cost, ServiceLine.Type::"G/L Account");
        ServiceLine.FindSet();
        repeat
            AmountIncludingVAT += ServiceLine."Amount Including VAT";
            Amount += ServiceLine.Amount;
            InvDiscountAmount += ServiceLine."Inv. Discount Amount";
        until ServiceLine.Next() = 0;

        Evaluate(AmountCosts, ServiceOrderStatistics.Amount_Costs.Value);
        Evaluate(VATAmountCosts, ServiceOrderStatistics."VAT Amount_Costs".Value);
        Evaluate(TotalInclVATCosts, ServiceOrderStatistics."Total Incl. VAT_Costs".Value);
        Evaluate(SalesLCYCosts, ServiceOrderStatistics."Sales (LCY)_Costs".Value);
        Evaluate(InvDiscountAmountCosts, ServiceOrderStatistics."Inv. Discount Amount_Costs".Value);

        Assert.AreNearlyEqual(
          Amount + InvDiscountAmount, AmountCosts, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountCosts, Amount + InvDiscountAmount));
        Assert.AreNearlyEqual(
          AmountIncludingVAT - Amount, VATAmountCosts, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountCosts, AmountIncludingVAT - Amount));
        Assert.AreNearlyEqual(
          AmountIncludingVAT, TotalInclVATCosts, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATCosts, AmountIncludingVAT));
        Assert.AreNearlyEqual(Amount, SalesLCYCosts, AmountRoundingPrecision, StrSubstNo(SalesLCYError, SalesLCYCosts, Amount));
        Assert.AreNearlyEqual(
          InvDiscountAmount, InvDiscountAmountCosts, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountCosts, InvDiscountAmount));
    end;

    local procedure VerifyOrderStatistics(ServiceOrderStatistics: TestPage "Service Order Statistics"; ServiceLine: Record "Service Line")
    var
        AmountGeneral: Decimal;
        VATAmountGeneral: Decimal;
        TotalInclVATGeneral: Decimal;
        SalesLCYGeneral: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        Evaluate(AmountGeneral, ServiceOrderStatistics.Amount_General.Value);
        Evaluate(VATAmountGeneral, ServiceOrderStatistics."VAT Amount_General".Value);
        Evaluate(TotalInclVATGeneral, ServiceOrderStatistics."Total Incl. VAT_General".Value);
        Evaluate(SalesLCYGeneral, ServiceOrderStatistics."Sales (LCY)_General".Value);

        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", AmountGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountGeneral, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountGeneral, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountGeneral, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, TotalInclVATGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATGeneral, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYGeneral, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYGeneral, ServiceLine.Amount));
    end;

    local procedure VerifyOrderStatisticsDetails(ServiceOrderStatistics: TestPage "Service Order Statistics"; ServiceLine: Record "Service Line")
    var
        AmountDetails: Decimal;
        VATAmountDetails: Decimal;
        TotalInclVATDetails: Decimal;
        SalesLCYDetails: Decimal;
        InvDiscountAmountDetails: Decimal;
        AmountRoundingPrecision: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
        AmountIncludingVAT: Decimal;
        SalesLCY: Decimal;
        InvoiceDiscountAmount: Decimal;
        QuantityPer: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        Evaluate(AmountDetails, ServiceOrderStatistics.Amount_Invoicing.Value);
        Evaluate(VATAmountDetails, ServiceOrderStatistics."VAT Amount_Invoicing".Value);
        Evaluate(TotalInclVATDetails, ServiceOrderStatistics."Total Incl. VAT_Invoicing".Value);
        Evaluate(SalesLCYDetails, ServiceOrderStatistics."Sales (LCY)_Invoicing".Value);
        Evaluate(InvDiscountAmountDetails, ServiceOrderStatistics."Inv. Discount Amount_Invoicing".Value);

        QuantityPer := ServiceLine."Qty. to Invoice" / ServiceLine.Quantity;
        Amount := Round((ServiceLine.Amount + ServiceLine."Inv. Discount Amount") * QuantityPer, AmountRoundingPrecision);
        VATAmount := Round((ServiceLine."Amount Including VAT" - ServiceLine.Amount) * QuantityPer, AmountRoundingPrecision);
        AmountIncludingVAT := Round(ServiceLine."Amount Including VAT" * QuantityPer, AmountRoundingPrecision);
        SalesLCY := Round(ServiceLine.Amount * QuantityPer, AmountRoundingPrecision);
        InvoiceDiscountAmount := Round(ServiceLine."Inv. Discount Amount" * QuantityPer, AmountRoundingPrecision);

        Assert.AreNearlyEqual(Amount, AmountDetails, AmountRoundingPrecision, StrSubstNo(AmountError, AmountDetails, Amount));
        Assert.AreNearlyEqual(VATAmount, VATAmountDetails, AmountRoundingPrecision, StrSubstNo(VATAmountError, VATAmountDetails, VATAmount));
        Assert.AreNearlyEqual(
          AmountIncludingVAT, TotalInclVATDetails, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATDetails, AmountIncludingVAT));
        Assert.AreNearlyEqual(SalesLCY, SalesLCYDetails, AmountRoundingPrecision, StrSubstNo(SalesLCYError, SalesLCYDetails, SalesLCY));
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, InvDiscountAmountDetails, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountDetails, InvoiceDiscountAmount));
        ServiceOrderStatistics.Quantity_Consuming.AssertEquals(ServiceLine."Qty. to Consume");
    end;

    local procedure VerifyOrderStatisticsGeneral(ServiceOrderStatistics: TestPage "Service Order Statistics"; ServiceLine: Record "Service Line")
    var
        AmountGeneral: Decimal;
        VATAmountGeneral: Decimal;
        TotalInclVATGeneral: Decimal;
        SalesLCYGeneral: Decimal;
        InvDiscountAmountGeneral: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        Evaluate(AmountGeneral, ServiceOrderStatistics.Amount_General.Value);
        Evaluate(VATAmountGeneral, ServiceOrderStatistics."VAT Amount_General".Value);
        Evaluate(TotalInclVATGeneral, ServiceOrderStatistics."Total Incl. VAT_General".Value);
        Evaluate(SalesLCYGeneral, ServiceOrderStatistics."Sales (LCY)_General".Value);
        Evaluate(InvDiscountAmountGeneral, ServiceOrderStatistics."Inv. Discount Amount_General".Value);

        Assert.AreNearlyEqual(
          ServiceLine.Amount + ServiceLine."Inv. Discount Amount", AmountGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountGeneral, ServiceLine.Amount + ServiceLine."Inv. Discount Amount"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountGeneral, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountGeneral, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", TotalInclVATGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATGeneral, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYGeneral, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYGeneral, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Inv. Discount Amount", InvDiscountAmountGeneral, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountGeneral, ServiceLine."Inv. Discount Amount"));
    end;

    local procedure VerifyOrderStatisticsProfit(ServiceOrderStatistics: TestPage "Service Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(ServiceOrderStatistics.Original_ProfitLCY_Gen.Value);
        LibraryVariableStorage.Enqueue(ServiceOrderStatistics.Original_ProfitPct_Gen.Value);
        LibraryVariableStorage.Enqueue(ServiceOrderStatistics.Adj_ProfitLCY_Gen.Value);
        LibraryVariableStorage.Enqueue(ServiceOrderStatistics.Adj_ProfitPct_Gen.Value);
    end;

    local procedure VerifyOrderStatisticsShipping(ServiceOrderStatistics: TestPage "Service Order Statistics"; ServiceLine: Record "Service Line")
    var
        AmountShipping: Decimal;
        VATAmountShipping: Decimal;
        TotalInclVATShipping: Decimal;
        SalesLCYShipping: Decimal;
        InvDiscountAmountShipping: Decimal;
        AmountRoundingPrecision: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
        AmountIncludingVAT: Decimal;
        SalesLCY: Decimal;
        InvoiceDiscountAmount: Decimal;
        QuantityPer: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        Evaluate(AmountShipping, ServiceOrderStatistics.Amount_Shipping.Value);
        Evaluate(VATAmountShipping, ServiceOrderStatistics."VAT Amount_Shipping".Value);
        Evaluate(TotalInclVATShipping, ServiceOrderStatistics."Total Incl. VAT_Shipping".Value);
        Evaluate(SalesLCYShipping, ServiceOrderStatistics."Sales (LCY)_Shipping".Value);
        Evaluate(InvDiscountAmountShipping, ServiceOrderStatistics."Inv. Discount Amount_Shipping".Value);

        QuantityPer := ServiceLine."Qty. to Ship" / ServiceLine.Quantity;
        Amount := Round((ServiceLine.Amount + ServiceLine."Inv. Discount Amount") * QuantityPer, AmountRoundingPrecision);
        VATAmount := Round((ServiceLine."Amount Including VAT" - ServiceLine.Amount) * QuantityPer, AmountRoundingPrecision);
        AmountIncludingVAT := Round(ServiceLine."Amount Including VAT" * QuantityPer, AmountRoundingPrecision);
        SalesLCY := Round(ServiceLine.Amount * QuantityPer, AmountRoundingPrecision);
        InvoiceDiscountAmount := Round(ServiceLine."Inv. Discount Amount" * QuantityPer, AmountRoundingPrecision);

        Assert.AreNearlyEqual(Amount, AmountShipping, AmountRoundingPrecision, StrSubstNo(AmountError, AmountShipping, Amount));
        Assert.AreNearlyEqual(
          VATAmount, VATAmountShipping, AmountRoundingPrecision, StrSubstNo(VATAmountError, VATAmountShipping, VATAmount));
        Assert.AreNearlyEqual(
          AmountIncludingVAT, TotalInclVATShipping, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATShipping, AmountIncludingVAT));
        Assert.AreNearlyEqual(SalesLCY, SalesLCYShipping, AmountRoundingPrecision, StrSubstNo(SalesLCYError, SalesLCYShipping, SalesLCY));
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, InvDiscountAmountShipping, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountShipping, InvoiceDiscountAmount));
    end;

    local procedure VerifyServiceOrderVATLine(VATAmountLines: TestPage "VAT Amount Lines"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        VATBase: Decimal;
        VATAmount: Decimal;
        AmountIncludingVAT: Decimal;
        VATBase2: Decimal;
        VATAmount2: Decimal;
        AmountIncludingVAT2: Decimal;
        VATBase3: Decimal;
        VATAmount3: Decimal;
        AmountIncludingVAT3: Decimal;
        QuantityPer: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceLine.CalcSums("Amount Including VAT", Amount, "VAT Base Amount");

        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        VATAmountLines.First();
        repeat
            Evaluate(VATBase, VATAmountLines."VAT Base".Value);
            Evaluate(VATAmount, VATAmountLines."VAT Amount".Value);
            Evaluate(AmountIncludingVAT, VATAmountLines."Amount Including VAT".Value);
            VATBase2 += VATBase;
            VATAmount2 += VATAmount;
            AmountIncludingVAT2 += AmountIncludingVAT;
        until not VATAmountLines.Next();

        QuantityPer := ServiceLine."Qty. to Ship" / ServiceLine.Quantity;
        VATBase3 := Round(ServiceLine."VAT Base Amount" * QuantityPer, AmountRoundingPrecision);
        VATAmount3 := Round((ServiceLine."Amount Including VAT" - ServiceLine.Amount) * QuantityPer, AmountRoundingPrecision);
        AmountIncludingVAT3 := Round(ServiceLine."Amount Including VAT" * QuantityPer, AmountRoundingPrecision);

        Assert.AreNearlyEqual(VATBase3, VATBase2, AmountRoundingPrecision, StrSubstNo(VATBaseAmountError, VATBase2, VATBase3));
        Assert.AreNearlyEqual(VATAmount3, VATAmount2, AmountRoundingPrecision, StrSubstNo(VATAmountError, VATAmount2, VATAmount3));
        Assert.AreNearlyEqual(
          AmountIncludingVAT3, AmountIncludingVAT2, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountIncludingVAT2, AmountIncludingVAT3));
    end;

    local procedure VerifyServiceLineItems(ServiceStatistics: TestPage "Service Statistics"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        AmountItems: Decimal;
        VATAmountItems: Decimal;
        TotalInclVATItems: Decimal;
        SalesLCYItems: Decimal;
        InvDiscountAmountItems: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        FilterServiceLine(ServiceLine, DocumentType, DocumentNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindFirst();

        Evaluate(AmountItems, ServiceStatistics.Amount_Items.Value);
        Evaluate(VATAmountItems, ServiceStatistics."VAT Amount_Items".Value);
        Evaluate(TotalInclVATItems, ServiceStatistics."Total Incl. VAT_Items".Value);
        Evaluate(SalesLCYItems, ServiceStatistics."Sales (LCY)_Items".Value);
        Evaluate(InvDiscountAmountItems, ServiceStatistics."Inv. Discount Amount_Items".Value);

        Assert.AreNearlyEqual(
          ServiceLine.Amount + ServiceLine."Inv. Discount Amount", AmountItems, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountItems, ServiceLine.Amount + ServiceLine."Inv. Discount Amount"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountItems, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountItems, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", TotalInclVATItems, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATItems, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYItems, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYItems, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Inv. Discount Amount", InvDiscountAmountItems, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountItems, ServiceLine."Inv. Discount Amount"));
    end;

    local procedure VerifyServiceLineResources(ServiceStatistics: TestPage "Service Statistics"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        AmountResources: Decimal;
        VATAmountResources: Decimal;
        TotalInclVATResources: Decimal;
        SalesLCYResources: Decimal;
        InvDiscountAmountResources: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        FilterServiceLine(ServiceLine, DocumentType, DocumentNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Resource);
        ServiceLine.FindFirst();

        Evaluate(AmountResources, ServiceStatistics.Amount_Resources.Value);
        Evaluate(VATAmountResources, ServiceStatistics."VAT Amount_Resources".Value);
        Evaluate(TotalInclVATResources, ServiceStatistics."Total Incl. VAT_Resources".Value);
        Evaluate(SalesLCYResources, ServiceStatistics."Sales (LCY)_Resources".Value);
        Evaluate(InvDiscountAmountResources, ServiceStatistics."Inv. Discount Amount_Resources".Value);

        Assert.AreNearlyEqual(
          ServiceLine.Amount + ServiceLine."Inv. Discount Amount", AmountResources, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountResources, ServiceLine.Amount + ServiceLine."Inv. Discount Amount"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountResources, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountResources, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", TotalInclVATResources, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATResources, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYResources, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYResources, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Inv. Discount Amount", InvDiscountAmountResources, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountResources, ServiceLine."Inv. Discount Amount"));
    end;

    local procedure VerifyServiceLineCostGLAccount(ServiceStatistics: TestPage "Service Statistics"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        AmountIncludingVAT: Decimal;
        Amount: Decimal;
        InvDiscountAmount: Decimal;
        AmountCosts: Decimal;
        VATAmountCosts: Decimal;
        TotalInclVATCosts: Decimal;
        SalesLCYCosts: Decimal;
        InvDiscountAmountCosts: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        FilterServiceLine(ServiceLine, DocumentType, DocumentNo);
        ServiceLine.SetFilter(Type, '%1|%2', ServiceLine.Type::Cost, ServiceLine.Type::"G/L Account");
        ServiceLine.FindSet();
        repeat
            AmountIncludingVAT += ServiceLine."Amount Including VAT";
            Amount += ServiceLine.Amount;
            InvDiscountAmount += ServiceLine."Inv. Discount Amount";
        until ServiceLine.Next() = 0;

        Evaluate(AmountCosts, ServiceStatistics.Amount_Costs.Value);
        Evaluate(VATAmountCosts, ServiceStatistics."VAT Amount_Costs".Value);
        Evaluate(TotalInclVATCosts, ServiceStatistics."Total Incl. VAT_Costs".Value);
        Evaluate(SalesLCYCosts, ServiceStatistics."Sales (LCY)_Costs".Value);
        Evaluate(InvDiscountAmountCosts, ServiceStatistics."Inv. Discount Amount_Costs".Value);

        Assert.AreNearlyEqual(
          Amount + InvDiscountAmount, AmountCosts, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountCosts, Amount + InvDiscountAmount));
        Assert.AreNearlyEqual(
          AmountIncludingVAT - Amount, VATAmountCosts, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountCosts, AmountIncludingVAT - Amount));
        Assert.AreNearlyEqual(
          AmountIncludingVAT, TotalInclVATCosts, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATCosts, AmountIncludingVAT));
        Assert.AreNearlyEqual(Amount, SalesLCYCosts, AmountRoundingPrecision, StrSubstNo(SalesLCYError, SalesLCYCosts, Amount));
        Assert.AreNearlyEqual(
          InvDiscountAmount, InvDiscountAmountCosts, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountCosts, InvDiscountAmount));
    end;

    local procedure VerifyServiceStatistics(ServiceStatistics: TestPage "Service Statistics"; ServiceLine: Record "Service Line")
    var
        AmountGeneral: Decimal;
        VATAmountGeneral: Decimal;
        TotalInclVATGeneral: Decimal;
        SalesLCYGeneral: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        Evaluate(AmountGeneral, ServiceStatistics.Amount_General.Value);
        Evaluate(VATAmountGeneral, ServiceStatistics."VAT Amount_General".Value);
        Evaluate(TotalInclVATGeneral, ServiceStatistics."Total Incl. VAT_General".Value);
        Evaluate(SalesLCYGeneral, ServiceStatistics."Sales (LCY)_General".Value);

        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", AmountGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountGeneral, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountGeneral, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountGeneral, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, TotalInclVATGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATGeneral, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYGeneral, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYGeneral, ServiceLine.Amount));
    end;

    local procedure VerifyServiceStatisticsGeneral(ServiceStatistics: TestPage "Service Statistics"; ServiceLine: Record "Service Line")
    var
        AmountGeneral: Decimal;
        VATAmountGeneral: Decimal;
        TotalInclVATGeneral: Decimal;
        SalesLCYGeneral: Decimal;
        InvDiscountAmountGeneral: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        Evaluate(AmountGeneral, ServiceStatistics.Amount_General.Value);
        Evaluate(VATAmountGeneral, ServiceStatistics."VAT Amount_General".Value);
        Evaluate(TotalInclVATGeneral, ServiceStatistics."Total Incl. VAT_General".Value);
        Evaluate(SalesLCYGeneral, ServiceStatistics."Sales (LCY)_General".Value);
        Evaluate(InvDiscountAmountGeneral, ServiceStatistics."Inv. Discount Amount_General".Value);

        Assert.AreNearlyEqual(
          ServiceLine.Amount + ServiceLine."Inv. Discount Amount", AmountGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, AmountGeneral, ServiceLine.Amount + ServiceLine."Inv. Discount Amount"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, VATAmountGeneral, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, VATAmountGeneral, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", TotalInclVATGeneral, AmountRoundingPrecision,
          StrSubstNo(AmountError, TotalInclVATGeneral, ServiceLine."Amount Including VAT"));
        Assert.AreNearlyEqual(
          ServiceLine.Amount, SalesLCYGeneral, AmountRoundingPrecision,
          StrSubstNo(SalesLCYError, SalesLCYGeneral, ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Inv. Discount Amount", InvDiscountAmountGeneral, AmountRoundingPrecision,
          StrSubstNo(InvoiceDiscountAmountError, InvDiscountAmountGeneral, ServiceLine."Inv. Discount Amount"));
    end;

    local procedure VerifyServiceStatisticsVATLine(ServiceStatistics: TestPage "Service Statistics"; ServiceLine: Record "Service Line")
    var
        StatisticsVATBase: Decimal;
        StatisticsVATAmount: Decimal;
        StatisticsAmountIncludingVAT: Decimal;
        StatisticsVATBase2: Decimal;
        StatisticsVATAmount2: Decimal;
        StatisticsAmountIncludingVAT2: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := 10 * GetAmountRoundingPrecision();  // Using multiplication of 10 for rounding.
        ServiceStatistics.SubForm.First();
        repeat
            Evaluate(StatisticsVATBase, ServiceStatistics.SubForm."VAT Base".Value);
            Evaluate(StatisticsVATAmount, ServiceStatistics.SubForm."VAT Amount".Value);
            Evaluate(StatisticsAmountIncludingVAT, ServiceStatistics.SubForm."Amount Including VAT".Value);
            StatisticsVATBase2 += StatisticsVATBase;
            StatisticsVATAmount2 += StatisticsVATAmount;
            StatisticsAmountIncludingVAT2 += StatisticsAmountIncludingVAT;
        until not ServiceStatistics.SubForm.Next();

        Assert.AreNearlyEqual(
          ServiceLine."VAT Base Amount", StatisticsVATBase2, AmountRoundingPrecision,
          StrSubstNo(VATBaseAmountError, StatisticsVATBase2, ServiceLine."VAT Base Amount"));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT" - ServiceLine.Amount, StatisticsVATAmount2, AmountRoundingPrecision,
          StrSubstNo(VATAmountError, StatisticsVATAmount2, ServiceLine."Amount Including VAT" - ServiceLine.Amount));
        Assert.AreNearlyEqual(
          ServiceLine."Amount Including VAT", StatisticsAmountIncludingVAT2, AmountRoundingPrecision,
          StrSubstNo(AmountError, StatisticsAmountIncludingVAT2, ServiceLine."Amount Including VAT"));
    end;

    local procedure VerifyServiceLineInvoiceDiscountAmount(DocumentNo: Code[20]; ExpectedInvoiceDiscountAmount: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        Assert.RecordCount(ServiceLine, 1);
        Assert.AreEqual(ExpectedInvoiceDiscountAmount, ServiceLine."Inv. Discount Amount", InvoiceDiscountAmountErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeDiscountOrderPostHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateDiscountAmount then begin
            UpdateDiscountAmountOrder(ServiceOrderStatistics);
            ServiceOrderStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsDetails(ServiceOrderStatistics, ServiceLine);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_Shipping".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeDiscountOrderShipHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateDiscountAmount then begin
            UpdateDiscountAmountOrder(ServiceOrderStatistics);
            ServiceOrderStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsShipping(ServiceOrderStatistics, ServiceLine);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_Shipping".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeDiscountOrderPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateDiscountAmount then begin
            UpdateDiscountAmountOrder(ServiceOrderStatistics);
            ServiceOrderStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsGeneral(ServiceOrderStatistics, ServiceLine);
        VerifyOrderLineItems(ServiceOrderStatistics, DocumentNo2);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_General".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeDiscountPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateDiscountAmount then begin
            UpdateDiscountAmountStatistics(ServiceStatistics);
            ServiceStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyServiceStatisticsGeneral(ServiceStatistics, ServiceLine);
        VerifyServiceStatisticsVATLine(ServiceStatistics, ServiceLine);
        VerifyServiceLineItems(ServiceStatistics, DocumentType2, DocumentNo2);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeTotalVATOrderPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateTotalVAT then begin
            UpdateTotalVATOrderStatistics(ServiceOrderStatistics);
            ServiceOrderStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsGeneral(ServiceOrderStatistics, ServiceLine);
        VerifyOrderLineItems(ServiceOrderStatistics, DocumentNo2);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_General".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeTotalVATOrderShipHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateTotalVAT then begin
            UpdateTotalVATOrderStatistics(ServiceOrderStatistics);
            ServiceOrderStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsShipping(ServiceOrderStatistics, ServiceLine);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_Shipping".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeTotalVATOrderPostHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateTotalVAT then begin
            UpdateTotalVATOrderStatistics(ServiceOrderStatistics);
            ServiceOrderStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsDetails(ServiceOrderStatistics, ServiceLine);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_Shipping".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeTotalVATPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        if not UpdateTotalVAT then begin
            UpdateTotalVATStatistics(ServiceStatistics);
            ServiceStatistics.OK().Invoke();
            exit;
        end;

        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyServiceStatisticsGeneral(ServiceStatistics, ServiceLine);
        VerifyServiceStatisticsVATLine(ServiceStatistics, ServiceLine);
        VerifyServiceLineItems(ServiceStatistics, DocumentType2, DocumentNo2);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreditLimitLCYPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    begin
        ServiceOrderStatistics."Credit Limit (LCY)_Customer".AssertEquals(CreditLimitLCY);
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentCreditLimitPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    begin
        ServiceStatistics."Credit Limit (LCY)".AssertEquals(CreditLimitLCY);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentGLAccountPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyServiceStatisticsGeneral(ServiceStatistics, ServiceLine);
        VerifyServiceStatisticsVATLine(ServiceStatistics, ServiceLine);
        VerifyServiceLineCostGLAccount(ServiceStatistics, DocumentType2, DocumentNo2);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentDiscountPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        ServiceLine.CalcSums("Amount Including VAT", Amount, "Inv. Discount Amount", "VAT Base Amount");
        VerifyServiceStatisticsGeneral(ServiceStatistics, ServiceLine);

        VerifyServiceStatisticsVATLine(ServiceStatistics, ServiceLine);
        VerifyServiceLineItems(ServiceStatistics, DocumentType2, DocumentNo2);
        VerifyServiceLineResources(ServiceStatistics, DocumentType2, DocumentNo2);
        VerifyServiceLineCostGLAccount(ServiceStatistics, DocumentType2, DocumentNo2);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentItemPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyServiceStatisticsGeneral(ServiceStatistics, ServiceLine);
        VerifyServiceStatisticsVATLine(ServiceStatistics, ServiceLine);
        VerifyServiceLineItems(ServiceStatistics, DocumentType2, DocumentNo2);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentResourcePageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyServiceStatisticsGeneral(ServiceStatistics, ServiceLine);
        VerifyServiceStatisticsVATLine(ServiceStatistics, ServiceLine);
        VerifyServiceLineResources(ServiceStatistics, DocumentType2, DocumentNo2);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentWithVATPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        ServiceLine.CalcSums("Amount Including VAT", Amount, "VAT Base Amount");
        VerifyServiceStatistics(ServiceStatistics, ServiceLine);
        VerifyServiceStatisticsVATLine(ServiceStatistics, ServiceLine);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderGLAccountPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsGeneral(ServiceOrderStatistics, ServiceLine);
        VerifyOrderLineCostGLAccount(ServiceOrderStatistics, DocumentNo2);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_General".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderItemPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsGeneral(ServiceOrderStatistics, ServiceLine);
        VerifyOrderLineItems(ServiceOrderStatistics, DocumentNo2);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_General".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderInvoiceDiscountHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        ServiceLine.CalcSums("Amount Including VAT", Amount, "Inv. Discount Amount", "VAT Base Amount");
        VerifyOrderStatisticsGeneral(ServiceOrderStatistics, ServiceLine);
        VerifyOrderLineItems(ServiceOrderStatistics, DocumentNo2);
        VerifyOrderLineResources(ServiceOrderStatistics, DocumentNo2);
        VerifyOrderLineCostGLAccount(ServiceOrderStatistics, DocumentNo2);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_General".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderResourcePageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsGeneral(ServiceOrderStatistics, ServiceLine);
        VerifyOrderLineResources(ServiceOrderStatistics, DocumentNo2);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_General".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderWithVATPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        ServiceLine.CalcSums("Amount Including VAT", Amount, "VAT Base Amount");
        VerifyOrderStatistics(ServiceOrderStatistics, ServiceLine);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_General".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatNegativeProfitPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    begin
        VerifyOrderStatisticsProfit(ServiceOrderStatistics);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToInvoicePageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsDetails(ServiceOrderStatistics, ServiceLine);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_Shipping".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToShipPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, DocumentType2, DocumentNo2);
        VerifyOrderStatisticsShipping(ServiceOrderStatistics, ServiceLine);

        // Verify VAT Amount Line on Page handler.
        ServiceOrderStatistics."No. of VAT Lines_Shipping".DrillDown();
        ServiceOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuoteLinesPageHandler(var ServiceQuoteLines: TestPage "Service Quote Lines")
    begin
        CreateServiceQuoteLine(ServiceQuoteLines, Type2, No2);
        ServiceQuoteLines.CalculateInvoiceDiscount.Invoke();
        ServiceQuoteLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuoteLinesMultiplePageHandler(var ServiceQuoteLines: TestPage "Service Quote Lines")
    begin
        CreateServiceQuoteLine(ServiceQuoteLines, Type2::Item, ItemNo);
        CreateServiceQuoteLine(ServiceQuoteLines, Type2::"G/L Account", GLAccountNo);
        CreateServiceQuoteLine(ServiceQuoteLines, Type2::Resource, ResourceNo);
        CreateServiceQuoteLine(ServiceQuoteLines, Type2::Cost, CostCode);
        ServiceQuoteLines.CalculateInvoiceDiscount.Invoke();
        ServiceQuoteLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        CreateServiceLine(ServiceLines, Type2, No2);
        ServiceLines."Calculate Invoice Discount".Invoke();
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesMultiPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        CreateServiceLine(ServiceLines, Type2::Item, ItemNo);
        CreateServiceLine(ServiceLines, Type2::"G/L Account", GLAccountNo);
        CreateServiceLine(ServiceLines, Type2::Resource, ResourceNo);
        CreateServiceLine(ServiceLines, Type2::Cost, CostCode);
        ServiceLines."Calculate Invoice Discount".Invoke();
        ServiceLines.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3;  // For Ship and Invoice.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ShipStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;  // For Ship.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesPageHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        // Verify VAT Amount Line.

        VerifyServiceOrderVATLine(VATAmountLines, DocumentNo2);
        VATAmountLines.OK().Invoke();
    end;
}


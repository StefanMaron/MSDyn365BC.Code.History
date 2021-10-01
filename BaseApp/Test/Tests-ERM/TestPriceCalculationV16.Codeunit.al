codeunit 134159 "Test Price Calculation - V16"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Lowest Price]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        ResType: Option Resource,"Group(Resource)",All;
        IsInitialized: Boolean;
        AllowLineDiscErr: Label 'Allow Line Disc. must have a value in Sales Line';
        PickedWrongMinQtyErr: Label 'The quantity in the line is below the minimum quantity of the picked price list line.';
        CampaignActivatedMsg: Label 'Campaign %1 is now activated.';
        GetPriceOutOfDateErr: Label 'The selected price line is not valid on the document date %1.',
            Comment = '%1 - a date value';
        GetPriceFieldMismatchErr: Label 'The %1 in the selected price line must be %2.',
            Comment = '%1 - a field caption, %2 - a value of the field';

    [Test]
    procedure T001_SalesLineAddsActivatedCampaignOnHeaderAsSource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, False);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is 'HdrCmp'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Campaign No.", Campaign[1]."No.");
        SalesHeader.Modify(true);
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'HdrCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[1]."No.", 1);
    end;

    [Test]
    procedure T002_SalesLineAddsActivatedCustomerCampaignAsSource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, False);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is <blank>
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'CustCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[2]."No.", 2);
        VerifyCampaignSource(SalesLinePrice, Campaign[3]."No.", 2);
    end;

    [Test]
    procedure T003_SalesLineAddsActivatedContactCampaignAsSource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has none activated Campaigns, "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, True);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is <blank>
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'ContCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[4]."No.", 2);
        VerifyCampaignSource(SalesLinePrice, Campaign[5]."No.", 2);
    end;

    [Test]
    procedure T010_SalesLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Line, where 'Posting Date' is <blank>, while WorkDate is '250120'
        SalesLine."Posting Date" := 0D;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with SalesLine, no Header set
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T011_SalesLinePriceCopyToBufferWithoutHeader()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Line, where 'Posting Date' is '300120', while WorkDate is '250120'
        SalesLine."Posting Date" := WorkDate() + 5;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with SalesLine, no Header set
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesLine."Posting Date");
    end;

    [Test]
    procedure T012_SalesLinePriceCopyToBufferWithHeaderBlankNo()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Header, where "Document Type" is Invoice, "No." is <blank>, "Posting Date" is '300120', "Order Date" is '290120'
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := '';
        SalesHeader."Posting Date" := WorkDate() + 5;
        SalesHeader."Order Date" := SalesHeader."Posting Date" - 1;

        // [GIVEN] Sales Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        SalesLine."Posting Date" := SalesHeader."Posting Date" + 1;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with SalesLine and Header
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '310120' (from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesLine."Posting Date");
    end;

    [Test]
    procedure T013_SalesLinePriceCopyToBufferWithHeaderInvoice()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Header, where "Document Type" is Invoice, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := LibraryRandom.RandText(20);
        SalesHeader."Posting Date" := WorkDate() + 5;
        SalesHeader."Order Date" := SalesHeader."Posting Date" - 1;

        // [GIVEN] Sales Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        SalesLine."Posting Date" := SalesHeader."Posting Date" + 1;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with SalesLine and Header
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120' (from Header."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesHeader."Posting Date");
    end;

    [Test]
    procedure T014_SalesLinePriceCopyToBufferWithHeaderOrder()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Header, where "Document Type" is Order, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryRandom.RandText(20);
        SalesHeader."Posting Date" := WorkDate() + 5;
        SalesHeader."Order Date" := SalesHeader."Posting Date" - 1;
        // [GIVEN] Sales Line, where 'Order Date' is '310120', while WorkDate is '250120'
        SalesLine."Posting Date" := SalesHeader."Posting Date" + 1;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with SalesLine and Header
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '290120' (from Header."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesHeader."Order Date");
    end;

    [Test]
    procedure T015_ServiceLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Line, where 'Posting Date' is <blank>, while WorkDate is '250120'
        ServiceLine."Posting Date" := 0D;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine, no Header set
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T016_ServiceLinePriceCopyToBufferWithoutHeader()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Line, where 'Posting Date' is '300120', while WorkDate is '250120'
        ServiceLine."Posting Date" := WorkDate() + 5;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine, no Header set
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceLine."Posting Date");
    end;

    [Test]
    procedure T017_ServiceLinePriceCopyToBufferWithHeaderBlankNo()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Header, where "Document Type" is Invoice, "No." is <blank>, "Posting Date" is '300120', "Order Date" is '290120'
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader."No." := '';
        ServiceHeader."Posting Date" := WorkDate() + 5;
        ServiceHeader."Order Date" := ServiceHeader."Posting Date" - 1;

        // [GIVEN] Service Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        ServiceLine."Posting Date" := ServiceHeader."Posting Date" + 1;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine and Header
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '310120' (from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceLine."Posting Date");
    end;

    [Test]
    procedure T018_ServiceLinePriceCopyToBufferWithHeaderInvoice()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Header, where "Document Type" is Invoice, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader."No." := LibraryRandom.RandText(20);
        ServiceHeader."Posting Date" := WorkDate() + 5;
        ServiceHeader."Order Date" := ServiceHeader."Posting Date" - 1;

        // [GIVEN] Service Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        ServiceLine."Posting Date" := ServiceHeader."Posting Date" + 1;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine and Header
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120' (from Header."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceHeader."Posting Date");
    end;

    [Test]
    procedure T019_ServiceLinePriceCopyToBufferWithHeaderOrder()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Header, where "Document Type" is Order, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."No." := LibraryRandom.RandText(20);
        ServiceHeader."Posting Date" := WorkDate() + 5;
        ServiceHeader."Order Date" := ServiceHeader."Posting Date" - 1;
        // [GIVEN] Service Line, where 'Order Date' is '310120', while WorkDate is '250120'
        ServiceLine."Posting Date" := ServiceHeader."Posting Date" + 1;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine and Header
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '290120' (from Header."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceHeader."Order Date");
    end;

    [Test]
    procedure T020_PurchaseLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Purchase]
        Initialize();
        // [GIVEN] Purchase Line, while WorkDate is '250120'
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with PurchaseLine, no Header set
        LineWithPrice := PurchaseLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, PurchaseLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T021_PurchaseLinePriceCopyToBufferWithHeaderInvoice()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Purchase]
        Initialize();
        // [GIVEN] Purchase Header, where "Document Type" is Invoice, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader."No." := LibraryRandom.RandText(20);
        PurchaseHeader."Posting Date" := WorkDate() + 5;
        PurchaseHeader."Order Date" := PurchaseHeader."Posting Date" - 1;

        // [GIVEN] Purchase Line, while WorkDate is '250120'
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with PurchaseLine and Header
        LineWithPrice := PurchaseLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, PurchaseHeader, PurchaseLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120' (from Header."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", PurchaseHeader."Posting Date");
    end;

    [Test]
    procedure T022_PurchaseLinePriceCopyToBufferWithHeaderOrder()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Purchase]
        Initialize();
        // [GIVEN] Purchase Header, where "Document Type" is Order, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryRandom.RandText(20);
        PurchaseHeader."Posting Date" := WorkDate() + 5;
        PurchaseHeader."Order Date" := PurchaseHeader."Posting Date" - 1;
        // [GIVEN] Purchase Line, while WorkDate is '250120'
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with PurchaseLine and Header
        LineWithPrice := PurchaseLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, PurchaseHeader, PurchaseLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '290120' (from Header."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", PurchaseHeader."Order Date");
    end;

    [Test]
    procedure T025_ItemJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Item Journal]
        Initialize();
        // [GIVEN] Item Journal Line, while WorkDate is '250120'
        ItemJournalLine.Type := ItemJournalLine.Type::Resource;
        ItemJournalLine."Item No." := LibraryInventory.CreateItemNo();

        // [GIVEN] Initialize LineWithPrice with ItemJournalLine
        LineWithPrice := ItemJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ItemJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T026_ItemJournalLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Item Journal]
        Initialize();
        // [GIVEN] Item Journal Line, where "Posting Date" is 300120, while WorkDate is '250120'
        ItemJournalLine."Posting Date" := WorkDate() + 5;
        ItemJournalLine."Item No." := LibraryInventory.CreateItemNo();

        // [GIVEN] Initialize LineWithPrice with ItemJournalLine
        LineWithPrice := ItemJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ItemJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from ItemJournalLine."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ItemJournalLine."Posting Date");
    end;

    [Test]
    procedure T027_StandardItemJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StdItemJnlLinePrice: Codeunit "Std. Item Jnl. Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Standard Item Journal]
        Initialize();
        // [GIVEN] Item Journal Line, while WorkDate is '250120'
        StandardItemJournalLine."Item No." := LibraryInventory.CreateItemNo();

        // [GIVEN] Initialize LineWithPrice with StandardItemJournalLine
        LineWithPrice := StdItemJnlLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, StandardItemJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T028_JobJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Journal]
        Initialize();
        // [GIVEN] Job Journal Line, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobJournalLine."Job No." := Job."No.";
        JobJournalLine.Type := JobJournalLine.Type::"G/L Account";
        JobJournalLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobJournalLine
        LineWithPrice := JobJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T029_JobJournalLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Journal]
        Initialize();
        // [GIVEN] Job Journal Line, where "Posting Date" is 300120, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobJournalLine."Job No." := Job."No.";
        JobJournalLine."Posting Date" := WorkDate() + 5;
        JobJournalLine.Type := JobJournalLine.Type::"G/L Account";
        JobJournalLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobJournalLine
        LineWithPrice := JobJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from JobJournalLine."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", JobJournalLine."Posting Date");
    end;

    [Test]
    procedure T030_JobPlanningLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Planning]
        Initialize();
        // [GIVEN] Job Planning Line, where "Planning Date" is <blank>, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine.Type := JobPlanningLine.Type::"G/L Account";
        JobPlanningLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobPlanningLine
        LineWithPrice := JobPlanningLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobPlanningLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T031_JobPlanningLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Planning]
        Initialize();
        // [GIVEN] Job Planning Line, where "Planning Date" is 300120, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine."Planning Date" := WorkDate() + 5;
        JobPlanningLine.Type := JobPlanningLine.Type::"G/L Account";
        JobPlanningLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobPlanningLine
        LineWithPrice := JobPlanningLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobPlanningLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from JobPlanningLine."Planning Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", JobPlanningLine."Planning Date");
    end;

    [Test]
    procedure T032_RequisitionLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        RequisitionLine: Record "Requisition Line";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Requisition Line]
        Initialize();
        // [GIVEN] Requisition Line, where "Order Date" is <blank>, while WorkDate is '250120'
        RequisitionLine.Type := RequisitionLine.Type::"G/L Account";
        RequisitionLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with RequisitionLine
        LineWithPrice := RequisitionLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, RequisitionLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T033_RequisitionLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        RequisitionLine: Record "Requisition Line";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Requisition Line]
        Initialize();
        // [GIVEN] Requisition Line, where "Order Date" is 300120, while WorkDate is '250120'
        RequisitionLine."Order Date" := WorkDate() + 5;
        RequisitionLine.Type := RequisitionLine.Type::"G/L Account";
        RequisitionLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with RequisitionLine
        LineWithPrice := RequisitionLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, RequisitionLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from RequisitionLine."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", RequisitionLine."Order Date");
    end;

    [Test]
    procedure T034_ResJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ResJournalLine: Record "Res. Journal Line";
        ResJournalLinePrice: Codeunit "Res. Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Resource Journal]
        Initialize();
        // [GIVEN] Res. Journal Line, where "Posting Date" is <blank>, while WorkDate is '250120'
        ResJournalLine."Resource No." := LibraryResource.CreateResourceNo();

        // [GIVEN] Initialize LineWithPrice with ResJournalLine
        LineWithPrice := ResJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ResJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T035_ResJournalLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        ResJournalLine: Record "Res. Journal Line";
        ResJournalLinePrice: Codeunit "Res. Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Resource Journal]
        Initialize();
        // [GIVEN] Res. Journal Line, where "Posting Date" is 300120, while WorkDate is '250120'
        ResJournalLine."Posting Date" := WorkDate() + 5;
        ResJournalLine."Resource No." := LibraryResource.CreateResourceNo();

        // [GIVEN] Initialize LineWithPrice with ResJournalLine
        LineWithPrice := ResJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ResJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from ResJournalLine."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ResJournalLine."Posting Date");
    end;

    [Test]
    procedure T036_JobJournalLinePriceCopyToBufferWithTimeSheetDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Journal] [Time Sheet]
        Initialize();
        // [GIVEN] Job Journal Line, where "Posting Date" is 300120, "Time Sheet Date" is 010220,, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobJournalLine."Job No." := Job."No.";
        JobJournalLine."Posting Date" := WorkDate() + 5;
        JobJournalLine."Time Sheet Date" := WorkDate() + 6;
        JobJournalLine.Type := JobJournalLine.Type::"G/L Account";
        JobJournalLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobJournalLine
        LineWithPrice := JobJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '010220'(from JobJournalLine."Time Sheet Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", JobJournalLine."Time Sheet Date");
    end;

    [Test]
    procedure T037_ResJournalLinePriceCopyToBufferWithTimeSheetDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        ResJournalLine: Record "Res. Journal Line";
        ResJournalLinePrice: Codeunit "Res. Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Resource Journal] [Time Sheet]
        Initialize();
        // [GIVEN] Res. Journal Line, where "Posting Date" is 300120, "Time Sheet Date" is 010220, while WorkDate is '250120'
        ResJournalLine."Posting Date" := WorkDate() + 5;
        ResJournalLine."Time Sheet Date" := WorkDate() + 6;
        ResJournalLine."Resource No." := LibraryResource.CreateResourceNo();

        // [GIVEN] Initialize LineWithPrice with ResJournalLine
        LineWithPrice := ResJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ResJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '010220'(from ResJournalLine."Time Sheet Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ResJournalLine."Time Sheet Date");
    end;

#if not CLEAN19
    [Test]
    procedure T050_ApplyDiscountSalesLineCalculateDiscIfAllowLineDiscFalseV15()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculation: interface "Price Calculation";
        LineWithPrice: Interface "Line With Price";
        ExpectedDiscount: Decimal;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount] [UT] [V15]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line even if "Allow Line Disc." is false.
        Initialize();
        // [GIVEN] "Sales Line discount" record for Customer and Item 'X': 15%
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(SalesLineDiscount, Customer."No.", Item, ExpectedDiscount);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price" 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Allow Line Disc." := false;
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Lowest Price",
            PriceCalculationSetup.Type::Sale, PriceCalculationSetup."Asset Type"::" ",
            "Price Calculation Handler"::"Business Central (Version 15.0)", true);

        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine(PriceCalculationSetup.Type::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
        PriceCalculation.ApplyDiscount();

        // [THEN] Line, where "Line Discount %" is 15%
        PriceCalculation.GetLine(Line);
        SalesLine := Line;
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;
#endif

    [Test]
    procedure T051_ApplyDiscountSalesLineCalculateDiscIfAllowLineDiscFalseV16()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculation: interface "Price Calculation";
        LineWithPrice: Interface "Line With Price";
        ExpectedDiscount: Decimal;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount] [UT]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line even if "Allow Line Disc." is false.
        Initialize();
        // [GIVEN] "Sales Line discount" record for Customer and Item 'X': 15%
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(PriceListLine, "Price Source Type"::Customer, Customer."No.", Item, ExpectedDiscount);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price" 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Allow Line Disc." := false;
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Lowest Price",
            PriceCalculationSetup.Type::Sale, PriceCalculationSetup."Asset Type"::" ",
            "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine(PriceCalculationSetup.Type::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
        PriceCalculation.ApplyDiscount();

        // [THEN] Line, where "Line Discount %" is 15%
        PriceCalculation.GetLine(Line);
        SalesLine := Line;
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T060_CalcBestAmountPicksBestPriceOfTwoBestFirst()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        PriceSourceList: codeunit "Price Source List";
    begin
        // [FEATURE] [UT]
        // [GIVEN] Buffer where Quantity = 1, "Currency Code" = <blank>
        MockBuffer("Price Type"::Sale, '', 1, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is blank, "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 15);
        // [GIVEN] 'Draft' Price line #3, where "Currency Code" is blank, "Unit Price" is 9 (best of 3)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 9);
        TempPriceListLine.Status := TempPriceListLine.Status::Draft;
        TempPriceListLine.Modify();

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #1 is picked
        TempPriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure T061_CalcBestAmountPicksBestPriceOfTwoBestSecond()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        PriceSourceList: codeunit "Price Source List";
    begin
        // [FEATURE] [UT]
        // [GIVEN] Buffer where Quantity = 1, "Currency Code" = <blank>
        MockBuffer("Price Type"::Sale, '', 1, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 15 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 15);
        // [GIVEN] Price line #2, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] 'Inactive' Price line #3, where "Currency Code" is blank, "Unit Price" is 9 (best of 3)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 9);
        TempPriceListLine.Status := TempPriceListLine.Status::Inactive;
        TempPriceListLine.Modify();

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T062_CalcBestAmountWorsePriceButFilledCurrencyCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T063_CalcBestAmountAmongPricesWhereFilledCurrencyCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 16 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 16);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T064_CalcBestAmountAmongPricesWhereFilledCurrencyCodeOrVariantCodeSecond()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 16 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 16);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T065_CalcBestAmountAmongPricesWhereFilledCurrencyCodeOrVariantCodeThird()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 11 (is better that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 11);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #3 is picked
        TempPriceListLine.TestField("Line No.", 30000);
    end;

    [Test]
    procedure T066_CalcBestAmountAmongPricesWhereFilledCurrencyCodeAndVariantCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 14 (is better that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 14);
        // [GIVEN] Price line #4, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 20 (is worse of all price lines)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, VariantCode, 20);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #4 is picked
        TempPriceListLine.TestField("Line No.", 40000);
    end;

    [Test]
    procedure T067_CalcBestAmountAmongPricesWhereFilledCurrencyCodeAndVariantCodeOfTwo()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, VariantCode, 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 14 (is better that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 14);
        // [GIVEN] Price line #4, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 20 (is worse of all price lines)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, VariantCode, 20);
        // [GIVEN] Price line #5, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 7 (the best)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 7);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #1 is picked
        TempPriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure T070_JobPlanningLineTakeZeroJobItemDiscountOverItemDiscount()
    var
        Customer: Record Customer;
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: array[2] of Record "Price List Line";
        PriceListHeader: array[2] of Record "Price List Header";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Item 'I' Discount '1%' for Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Customer, Customer."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Discount, "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Status := PriceListLine[1].Status::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Job 'J', where "Bill-to Customer No." is 'C', Item 'I' "Unit Price" is 'X', Discount is '0%' for Customer 'C'
        LibraryJob.CreateJob(Job);
        Job.Validate("Bill-to Customer No.", Customer."No.");
        Job.Modify();
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Any, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2]."Line Discount %" := 0;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        // [GIVEN] Job Planning Line, wheer Job 'J', Customer 'C'
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.validate(Type, JobPlanningLine.Type::Item);
        // [WHEN] Enter Item 'I' in the Job Planning Line
        JobPlanningLine.Validate("No.", Item."No.");
        // [THEN] "Unit Price" is 'X', "Line Discount" is 0
        JobPlanningLine.TestField("Unit Price", PriceListLine[2]."Unit Price");
        JobPlanningLine.TestField("Line Discount %", 0);
    end;

    [Test]
    procedure T071_JobPlanningLineTakeZeroJobItemPriceOverItemPrice()
    var
        Customer: Record Customer;
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: array[2] of Record "Price List Line";
        PriceListHeader: array[2] of Record "Price List Header";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Item 'I' Price '100.00' for Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Customer, Customer."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Status := PriceListLine[1].Status::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Job 'J', where "Bill-to Customer No." is 'C', Item 'I' "Unit Price" is 0.00, Discount is '1%' for Customer 'C'
        LibraryJob.CreateJob(Job);
        Job.Validate("Bill-to Customer No.", Customer."No.");
        Job.Modify();
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Any, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2]."Unit Price" := 0;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        // [GIVEN] Job Planning Line, wheer Job 'J', Customer 'C'
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.validate(Type, JobPlanningLine.Type::Item);
        // [WHEN] Enter Item 'I' in the Job Planning Line
        JobPlanningLine.Validate("No.", Item."No.");
        // [THEN] "Unit Price" is 0.00, "Line Discount" is 1%
        JobPlanningLine.TestField("Unit Price", 0);
        JobPlanningLine.TestField("Line Discount %", PriceListLine[2]."Line Discount %");
    end;

    [Test]
    procedure T080_ConvertVATNormalExclVATToNormalInclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceInclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' and Item 'I' with VAT posting setup, where "VAT Calculation Type"::"Normal VAT"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'No', "Unit Price" is 100, "VAT %" is 20
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := false;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceInclVAT := Round(PriceListLine."Unit Price" * (100 + VATPostingSetup."VAT %") / 100, 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'Yes'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 120
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceInclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price incl VAT');
    end;

    [Test]
    procedure T081_ConvertVATNormalInclVATToNormalExclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' and Item 'I' with VAT posting setup, where "VAT Calculation Type"::"Normal VAT"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'Yes', "Unit Price" is 120, "VAT %" is 20
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := true;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT := Round(PriceListLine."Unit Price" * 100 / (100 + VATPostingSetup."VAT %"), 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'No'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T082_ConvertVATNormalExclVATToRevChargeInclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RevChVATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' with "Reverce Charge VAT" setup, and Item 'I' with "Normal VAT" setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        CreateRevChargeVATPostingSetup(VATPostingSetup, RevChVATPostingSetup);
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(RevChVATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'No', "Unit Price" is 100, "Normal VAT" setup
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := false;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT := Round(PriceListLine."Unit Price", 0.01);
        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'Yes'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(
            ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T083_ConvertVATNormalInclVATToRevChargeExclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RevChVATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' with "Reverce Charge VAT" setup, and Item 'I' with "Normal VAT" setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        CreateRevChargeVATPostingSetup(VATPostingSetup, RevChVATPostingSetup);
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(RevChVATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'Yes', "Unit Price" is 125, "Normal VAT" setup
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := true;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT := Round(PriceListLine."Unit Price" * 100 / (100 + VATPostingSetup."VAT %"), 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'No'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T084_ConvertVATNormalInclVATToRevChargeInclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        RevChVATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' with "Reverce Charge VAT" setup, and Item 'I' with "Normal VAT" setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        CreateRevChargeVATPostingSetup(VATPostingSetup, RevChVATPostingSetup);
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(RevChVATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'Yes', "Unit Price" is 125, "Normal VAT" setup
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := true;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT :=
            Round(PriceListLine."Unit Price" * 100 / (100 + VATPostingSetup."VAT %"), 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'Yes'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T110_ApplyDiscountSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        ExpectedDiscount: Decimal;
        Header: Variant;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'B' - default
        with PriceCalculationSetup[5] do begin
            DeleteAll();
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", "Price Calculation Handler"::Test, false);
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        end;
        // [GIVEN] Two "Sales Line discount" records for Item 'X': 15% and 14.99%
        PriceListLine.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(PriceListLine, "Price Source Type"::Customer, Customer."No.", Item, ExpectedDiscount - 0.01);
        CreateCustomerItemDiscount(PriceListLine, "Price Source Type"::"All Customers", '', Item, ExpectedDiscount);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price" 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        SalesLine := Line;

        // [THEN] Line, where "Line Discount %" is 15%
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T111_ApplyPriceSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        ExpectedPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] ApplyPrice() updates 'Unit Price' in sales line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'B' - default
        with PriceCalculationSetup[5] do begin
            DeleteAll();
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", "Price Calculation Handler"::Test, false);
            LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], Method::"Lowest Price", Type::Sale, "Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        end;

        // [GIVEN] Item 'X', where "Unit Price" is 100
        ExpectedPrice := LibraryRandom.RandDec(1000, 2);
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := ExpectedPrice + 0.02;
        Item.Modify();
        // [GIVEN] Sales prices for Item 'X': 99.99 and 99.98
        LibrarySales.CreateCustomer(Customer);
        PriceListLine.DeleteAll();
        CreateCustomerItemPrice(PriceListLine, "Price Source Type"::Customer, Customer."No.", Item, ExpectedPrice);
        CreateCustomerItemPrice(PriceListLine, "Price Source Type"::"All Customers", '', Item, ExpectedPrice + 0.01);

        // [GIVEN] Invoice, where "Price Calculation Method" is not defined 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Unit Price" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Quantity := 1;
        SalesLine.Modify(true);

        // [WHEN] ApplyPrice for the sales line
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
        SalesLine.ApplyPrice(SalesLine.FieldNo(Quantity), PriceCalculation);

        // [THEN] Line, where "Unit Price" is 99.98, "Price Calculation Method" is 'Lowest Price'
        SalesLine.TestField("Unit Price", ExpectedPrice);
        // SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
    end;

    [Test]
    procedure T112_ApplyPriceFromItemCardSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] ApplyPrice() updates 'Unit Price' in sales line with Item's "Unit Price" if no prices set.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Item 'X', where "Unit Price" is 100 and there is no sales prices for Item 'X'
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();
        // [GIVEN] Invoice, where "Price Calculation Method" is not defined 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        // [GIVEN] with one line, where "Type" is 'Item'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Set "No." as 'X' in the sales line
        SalesLine.Validate("No.", Item."No.");

        // [THEN] Line, where "Unit Price" is 100, "Price Calculation Method" is 'Lowest Price'
        SalesLine.TestField("Unit Price", Item."Unit Price");
        //SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T122_ApplyPriceFromItemCardServiceLine()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service] [Price]
        // [SCENARIO] ApplyPrice() updates 'Unit Price' in sales line with Item's "Unit Price" if no prices set.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Item 'X', where "Unit Price" is 100 and there is no sales prices for Item 'X'
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();
        // [GIVEN] Order, where "Price Calculation Method" is not defined 
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // [GIVEN] with one line, where "Type" is 'Item'
        // [WHEN] Set "No." as 'X' in the sales line
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [THEN] Line, where "Unit Price" is 100, "Price Calculation Method" is 'Lowest Price'
        ServiceLine.TestField("Unit Price", Item."Unit Price");
        //SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T132_ApplyPriceFromItemCardPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Price]
        // [SCENARIO] ApplyPrice() updates 'Direct Unit Cost' in sales line with Item's "Last Direct Cost" if no prices set.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Item 'X', where "Last Direct Cost" is 100 and there is no sales prices for Item 'X'
        LibraryInventory.CreateItem(Item);
        Item."Last Direct Cost" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();
        // [GIVEN] Invoice, where "Price Calculation Method" is not defined 
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        // [GIVEN] with one line, where "Type" is 'Item'
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        // [WHEN] Set "No." as 'X' in the sales line
        PurchaseLine.Validate("No.", Item."No.");

        // [THEN] Line, where "Direct Unit Cost" is 100, "Price Calculation Method" is 'Lowest Price'
        PurchaseLine.TestField("Direct Unit Cost", Item."Last Direct Cost");
        //SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T160_ApplyDiscountSalesLineIfNoPriceNoLineDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is 0 in sales line if Customer does not allow discount and no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] No price list lines with for Item 'I'
        RemovePricesForItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 0, "Allow Line Disc." is No
        VerifyLineDiscount(SalesLine, 0);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T161_ApplyDiscountSalesLineIfNoPriceButLineDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is set in sales line if Customer allows discount, but no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] No price list lines with for Item 'I'
        RemovePricesForItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C, "Line Discount %" is 'X'
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 'X', "Allow Line Disc." is Yes
        VerifyLineDiscount(SalesLine, PriceListLine."Line Discount %");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T162_ApplyDiscountSalesLineIfPriceDoesNotAllowLineDiscAndNotAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is 0 in sales line if Customer does not allow discount and found price line does not allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Alloe Line Disc." is 'No'
        CreatePriceLine(PriceListLine, Customer, Item, False);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 0, "Allow Line Disc." is No
        VerifyLineDiscount(SalesLine, 0);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T163_ApplyDiscountSalesLineIfPriceDoesNotAllowLineDiscButDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is 0 in sales line if Customer allows discount, but the found price line does not allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is 'No'
        CreatePriceLine(PriceListLine, Customer, Item, False);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 0, "Allow Line Disc." is No
        VerifyLineDiscount(SalesLine, 0);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T164_ApplyDiscountSalesLineIfPriceAllowsLineDiscButDiscNotAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is set in sales line if Customer does not allow discount, but the found price line allows it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is 'Yes'
        CreatePriceLine(PriceListLine, Customer, Item, true);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 'X', "Allow Line Disc." is Yes
        VerifyLineDiscount(SalesLine, PriceListLineDisc."Line Discount %");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T165_ApplyDiscountSalesLineIfPriceAllowsLineDiscAndDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is set in sales line if Customer does allow discount and the found price line allows it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is 'Yes'
        CreatePriceLine(PriceListLine, Customer, Item, true);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 'X', "Allow Line Disc." is Yes
        VerifyLineDiscount(SalesLine, PriceListLineDisc."Line Discount %");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLineDiscountModalPageHandler')]
    procedure T170_PickDiscountSalesLineIfNoPriceLineDiscButAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] Cannot pick Discount for the sales line if Customer allows discount and no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] No price list lines with for Item 'I'
        RemovePricesForItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] PickDiscount
        SalesLine.PickDiscount();

        // [THEN] Error message: 'Allow Line Disc. must be equal to Yes'
        VerifyLineDiscount(SalesLine, PriceListLine."Line Discount %");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T171_PickPriceSalesLineBelowMinQuantity()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if minimal quantity in the price line below the quantity in the sales line.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 10
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Minimum Quantity" := 10;
        PriceListLine.Modify();
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I', where Quantity is 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "Qunatity is below Minimal Qty"
        Assert.ExpectedError(PickedWrongMinQtyErr);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T172_PickPriceSalesLineWithNotAllowedLineDiscount()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Picked price line with not allowed discount makes previously calculated discount zero.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I', where Quantity is 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        VerifyLineDiscount(SalesLine, PriceListLineDisc."Line Discount %");
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is No
        CreatePriceLine(PriceListLine, Customer, Item, false);

        // [WHEN] PickPrice
        SalesLine.PickPrice();

        // [THEN] "Line Discount %" is 0
        VerifyLineDiscount(SalesLine, 0);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLineDiscountModalPageHandler')]
    procedure T173_PickDiscountSalesLineIfNoPriceNoLineDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] Cannot pick Discount for the sales line if Customer does not allow discount and no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] One price list line for Item 'I', where Amount Type is 'Price'
        RemovePricesForItem(Item);
        CreatePriceLine(PriceListLine, Customer, Item, false);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] PickDiscount
        asserterror SalesLine.PickDiscount();

        // [THEN] Error message: 'Allow Line Disc. must have a value in Sales Line'
        Assert.ExpectedError(AllowLineDiscErr);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLineModalPageHandler')]
    procedure T174_PickPriceSalesLineOfTwoPriceLinesAmountTypeAny()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListHeader: array[3] of Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
        ExpectedUnitPrice: array[2] of Decimal;
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [Sales] [Price] [UI]
        // [SCENARIO] While picking prices "Get Price Lines" page shows lines with "Amount Type" 'Any'
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] One price list line for Item 'I', where Amount Type is 'Price', "Unit Price" is 'P1'
        RemovePricesForItem(Item);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[1], PriceListHeader[1]."Price Type"::Sale, PriceListHeader[1]."Source Type"::Customer, Customer."No.");
        PriceListLine."Price List Code" := PriceListHeader[1].Code;
        CreatePriceLine(PriceListLine, Customer, Item, false);
        ExpectedUnitPrice[1] := PriceListLine."Unit Price";
        ExpectedUnitPrice[2] := 10 * ExpectedUnitPrice[1];
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C, "Line Discount %" is 'D1'
        CreateDiscountLine(PriceListLine, Customer, Item);
        ExpectedDiscount := PriceListLine."Line Discount %";

        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        // [GIVEN] Sales Line, where "Unit Price" is 'P1', "Line Discount %" is 0, as "Allow Line Disc." is 'No'
        SalesLine.TestField("Unit Price", ExpectedUnitPrice[1]);
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", 0);

        // [GIVEN] Added price list line for Item 'I', where Amount Type is 'Any', "Unit Price" is 'P2', "Line Discount %" is 'D2'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], PriceListHeader[2]."Price Type"::Sale, PriceListHeader[2]."Source Type"::Customer, Customer."No.");
        PriceListLine."Price List Code" := PriceListHeader[2].Code;
        CreatePriceLine(PriceListLine, Customer, Item, true);
        PriceListLine."Unit Price" := ExpectedUnitPrice[2];
        PriceListLine."Line Discount %" := ExpectedDiscount + 0.01; // just a better discount
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Any;
        PriceListLine.Modify();

        // [GIVEN] Added price list line for Item 'I', where Amount Type is 'Price', "Unit Price" is 'P3'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[3], PriceListHeader[3]."Price Type"::Sale, PriceListHeader[3]."Source Type"::Customer, Customer."No.");
        PriceListLine."Price List Code" := PriceListHeader[2].Code;
        CreatePriceLine(PriceListLine, Customer, Item, true);
        PriceListLine."Unit Price" := ExpectedUnitPrice[2] + 100.0;
        PriceListLine.Modify();

        // [WHEN] PickPrice with "Amount Type" 'Any'
        LibraryVariableStorage.Enqueue(PriceListHeader[2].Code); // for GetPriceLineModalPageHandler
        SalesLine.PickPrice();

        // [THEN] Sales Line, where "Unit Price" is 'P2', "Line Discount %" is '0', "Allow Line Disc." is Yes
        SalesLine.TestField("Unit Price", ExpectedUnitPrice[2]);
        SalesLine.TestField("Allow Line Disc.", true);
        SalesLine.TestField("Line Discount %", 0);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T175_CardPriceRestoredInSalesLineBelowMinQuantity()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price] [Minimum Quantity]
        // [SCENARIO] Price is taken from the Item card if the Quantity is below "Minimum Quantity" of the price list line
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I', where "Unit Price" is 'X'
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item.Modify();

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 10, "Unit Price" is 'Y'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Minimum Quantity" := 5 + LibraryRandom.RandInt(100);
        PriceListLine.Modify();
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I', where Quantity is 10, giving "Unit Price" as 'Y'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", PriceListLine."Minimum Quantity");
        Assert.AreEqual(PriceListLine."Unit Price", SalesLine."Unit Price", 'Unit Price in Sales Line for Minimum Quantity');

        // [WHEN] Change Quantity in Sales Line to 9 (below "Minimum Quantity")
        SalesLine.Validate(Quantity, SalesLine.Quantity - 1);

        // [THEN] Sales Line, where "Unit Price" is 'X' (from the Item card)
        SalesLine.TestField("Unit Price", Item."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T176_PickPriceSalesLineOutOfDateStartindDate()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if "Starting Date" is later than "Order Date".
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales Order for Customer 'C' selling Item 'I', where "Order Date" is '010120'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Starting Date" is 020120, "Ending Date" is 0D
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Starting Date" := SalesHeader."Order Date" + 1;
        PriceListLine."Ending Date" := 0D;
        PriceListLine.Modify();

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "The selected price line is not valid..."
        Assert.ExpectedError(StrSubstNo(GetPriceOutOfDateErr, SalesHeader."Order Date"));
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T177_PickPriceSalesLineWrongUnitOfMeasure()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemUnitofMeasure: array[2] of Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        UnitofMeasure: array[2] of Record "Unit of Measure";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if "Unit of Measure" does not match.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I' with twou unit of measures 'PCS' and 'BOX'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure[1]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure[1], Item."No.", UnitofMeasure[1].Code, 1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure[2]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure[1], Item."No.", UnitofMeasure[2].Code, 5);

        // [GIVEN] Sales Order for Customer 'C' selling , where "Order Date" is '100120'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // [GIVEN] Sales Line, whre Item 'I' and "Unit Of Measure" 'PCS'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit of Measure", UnitofMeasure[1].Code);
        SalesLine.Modify();
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Unit Of Measure Code" 'BOX'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Unit of Measure Code" := UnitofMeasure[2].Code;
        PriceListLine.Modify();

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "The Unit of Measure Code in the selected price line must be PCS."
        Assert.ExpectedError(
            StrSubstNo(GetPriceFieldMismatchErr,
            PriceListLine.FieldCaption("Unit of Measure Code"), SalesLine."Unit of Measure Code"));
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T178_PickPriceSalesLineWrongCurrencyCode()
    var
        Customer: Record Customer;
        Item: Record Item;
        Currency: array[2] of Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if "Currency Code" does not match.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        Currency[1].Code := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.CreateCurrency(Currency[2]);

        // [GIVEN] Sales Order for Customer 'C' selling , where "Order Date" is '100120', "Currency Code" 'USD'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Currency Code", Currency[1].Code);
        SalesHeader.Modify();
        // [GIVEN] Sales Line, whrere Item 'I' and "Currency Code" 'USD'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Currency Code" 'EUR'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Currency Code" := Currency[2].Code;
        PriceListLine.Modify();

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "The Currency Code in the selected price line must be USD."
        Assert.ExpectedError(
            StrSubstNo(GetPriceFieldMismatchErr,
            PriceListLine.FieldCaption("Currency Code"), SalesLine."Currency Code"));
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPurchPriceLinePriceModalPageHandler')]
    procedure T180_PickPricePurchLineBelowMinQuantity()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Price]
        // [SCENARIO] Cannot pick price line for the Purchase line if minimal quantity in the price line below the quantity in the Purchase line.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 10
        CreatePriceLine(PriceListLine, Vendor, Item, false);
        PriceListLine."Minimum Quantity" := 10;
        PriceListLine.Modify();
        // [GIVEN] Purchase Invoice for Vendor 'V' selling Item 'I', where Quantity is 1
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [WHEN] PickPrice
        asserterror PurchaseLine.PickPrice();

        // [THEN] Error message: "Quantity is below Minimal Qty"
        Assert.ExpectedError(PickedWrongMinQtyErr);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPurchPriceLineDiscountModalPageHandler')]
    procedure T181_PickDiscountPurchLine()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: Array[5] of Record "Price Calculation Setup";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Discount] [UI]
        // [SCENARIO 381378] Get Price Line page shows product columns if the item has Item Discount Group set.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Item 'I', where "Item Disc. Group" is 'IDG'
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        item.Modify();

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 0
        CreateDiscountLine(PriceListLine, Vendor, Item, false);
        // [GIVEN] Purchase Invoice for Vendor 'V' selling Item 'I', where Quantity is 1
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [WHEN] PickDiscount
        PurchaseLine.PickDiscount();

        // [THEN] "Asset Type" and "Asset No." are visible in the "Get Price Line" page
        // verified in GetPurchPriceLineDiscountModalPageHandler
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure T190_ActivateCampaignIfPriceExists()
    var
        Customer: Record Customer;
        Campaign: Record Campaign;
        CampaignTargetGr: Record "Campaign Target Group";
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        PriceListLine: Record "Price List Line";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        OldHandler: enum "Price Calculation Handler";
        Msg: Text;
    begin
        // [FEATURE] [Sales] [Campaign]
        // [SCENARIO] Activate campaign if price list lines for the campaign do exist.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Campaign 'C' 
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentHeader.Validate("Campaign No.", Campaign."No.");
        SegmentHeader.Validate("Campaign Target", true);
        SegmentHeader.Modify();
        // [GIVEN] Price List Line for Campaign 'C'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Campaign, Campaign."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        // [WHEN] Activate Campaign 'C'
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);

        // [THEN] Campaign C is activated (CampaignTargetGr added)
        CampaignTargetGr.SetRange("Campaign No.", Campaign."No.");
        Assert.RecordIsNotEmpty(CampaignTargetGr);
        // [THEN] Message: 'Campaign C is activated'.
        Msg := LibraryVariableStorage.DequeueText(); // from MessageHandler
        Assert.AreEqual(StrSubstNo(CampaignActivatedMsg, Campaign."No."), Msg, 'Wrong message.');

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T191_ActivateCampaignIfPriceDoesNotExist()
    var
        Customer: Record Customer;
        Campaign: Record Campaign;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        PriceListLine: Record "Price List Line";
        CampaignTargetGr: Record "Campaign Target Group";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        OldHandler: enum "Price Calculation Handler";
        Msg: Text;
    begin
        // [FEATURE] [Sales] [Campaign]
        // [SCENARIO] Activate campaign is stopped if price list lines for the campaign do not exist.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Campaign 'C' 
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentHeader.Validate("Campaign No.", Campaign."No.");
        SegmentHeader.Validate("Campaign Target", true);
        SegmentHeader.Modify();
        // [GIVEN] Price List Line for Campaign 'C' does not exist
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::Campaign);
        PriceListLine.SetRange("Source No.", Campaign."No.");
        PriceListLine.DeleteAll();

        // [WHEN] Activate Campaign 'C' and answer 'No' on confirmation
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);

        // [THEN] Campaign C is not activated (CampaignTargetGr don't exist)
        CampaignTargetGr.SetRange("Campaign No.", Campaign."No.");
        Assert.RecordIsEmpty(CampaignTargetGr);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T200_PostedArchivedSalesDocumentsContainPriceCalcMethod()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        CopiedSalesHeader: Record "Sales Header";
        CopiedSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
        OldHandler: enum "Price Calculation Handler";
        SalesDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
        InvoiceDocNo: Code[20];
        OrderNo: Code[20];
        LineNo: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Price Calculation Method during posting is populated to posted and archived documents and copied back.
        Initialize();
        SalesHeaderArchive.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C'
        CreatePriceLine(PriceListLine, Customer, Item, False);
        // [GIVEN] Sales Order for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // [GIVEN] Calculate price, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        SalesLine."Price Calculation Method" := SalesLine."Price Calculation Method"::"Test Price";
        SalesLine.Modify();
        // [GIVEN] Enable "Archive Orders"
        LibrarySales.SetArchiveOrders(true);

        // [WHEN] Post Sales Order
        OrderNo := SalesHeader."No.";
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Commit();

        // [THEN] Posted Sales Invoice, Method is 'Test' in line, 'Lowest Price' in header
        SalesInvoiceHeader.Get(InvoiceDocNo);
        SalesInvoiceHeader.TestField("Price Calculation Method", SalesHeader."Price Calculation Method");
        SalesInvoiceLine.SetRange("Document No.", InvoiceDocNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method");
        // [THEN] Posted Sales Shipment, Method is 'Test' in line, 'Lowest Price' in header
        SalesShipmentHeader.Get(FindShipmentHeaderNo(OrderNo));
        SalesShipmentHeader.TestField("Price Calculation Method", SalesShipmentHeader."Price Calculation Method");
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method");
        // [THEN] Sales Order Archive, Method is 'Test' in line, 'Lowest Price' in header
        SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
        SalesHeaderArchive.SetRange("No.", OrderNo);
        SalesHeaderArchive.FindLast();
        SalesHeaderArchive.TestField("Price Calculation Method", SalesHeaderArchive."Price Calculation Method");
        SalesLineArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesLineArchive.SetRange("Document No.", OrderNo);
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("Price Calculation Method", SalesLine."Price Calculation Method");

        // [WHEN] Copy archived order as new order
        LibrarySales.CreateSalesHeader(CopiedSalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CopySalesDoc("Sales Document Type From"::"Arch. Order", OrderNo, CopiedSalesHeader);
        // [THEN] New Order, where Method is 'Test' in line, 'Lowest Price' in header 
        CopiedSalesHeader.Find();
        CopiedSalesHeader.TestField("Price Calculation Method", SalesHeader."Price Calculation Method");
        CopiedSalesLine.SetRange("Document Type", CopiedSalesHeader."Document Type");
        CopiedSalesLine.SetRange("Document No.", CopiedSalesHeader."No.");
        CopiedSalesLine.FindLast();
        CopiedSalesLine.TestField("Price Calculation Method", SalesLineArchive."Price Calculation Method");
        LineNo := CopiedSalesLine."Line No.";

        // [WHEN] Copy line from invoice to order
        CopySalesLinesToDoc("Sales Document Type From"::"Posted Invoice", SalesInvoiceLine, CopiedSalesHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedSalesLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedSalesLine.FindLast();
        CopiedSalesLine.TestField("Price Calculation Method", SalesInvoiceLine."Price Calculation Method");
        LineNo := CopiedSalesLine."Line No.";

        // [WHEN] Copy line from shipment to order
        CopySalesLinesToDoc("Sales Document Type From"::"Posted Shipment", SalesShipmentLine, CopiedSalesHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedSalesLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedSalesLine.FindLast();
        CopiedSalesLine.TestField("Price Calculation Method", SalesShipmentLine."Price Calculation Method");

        LibraryNotificationMgt.RecallNotificationsForRecord(CopiedSalesHeader);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T202_PostedArchivedPurchDocumentsContainPriceCalcMethod()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        CopiedPurchaseHeader: Record "Purchase Header";
        CopiedPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseLineArchive: Record "Purchase Line Archive";
        OldHandler: enum "Price Calculation Handler";
        CrMemoDocNo: Code[20];
        OrderNo: Code[20];
        LineNo: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Price Calculation Method during posting is populated to posted and archived documents and copied back.
        Initialize();
        PurchaseHeaderArchive.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'V'
        CreatePriceLine(PriceListLine, Vendor, Item, False);
        // [GIVEN] Purchase Order for Vendor 'V' selling Item 'I'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        // [GIVEN] Calculate price, by validating Quantity
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method"::"Lowest Price");
        PurchaseLine."Price Calculation Method" := PurchaseLine."Price Calculation Method"::"Test Price";
        PurchaseLine.Modify();
        // [GIVEN] Enable "Archive Orders"
        LibraryPurchase.SetArchiveReturnOrders(true);

        // [WHEN] Post Purchase Order
        OrderNo := PurchaseHeader."No.";
        CrMemoDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Commit();

        // [THEN] Posted Purchase CrMemo, Method is 'Test' in line, 'Lowest Price' in header
        PurchCrMemoHeader.Get(CrMemoDocNo);
        PurchCrMemoHeader.TestField("Price Calculation Method", PurchaseHeader."Price Calculation Method");
        PurchCrMemoLine.SetRange("Document No.", CrMemoDocNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method");
        // [THEN] Posted Return Shipment, Method is 'Test' in line, 'Lowest Price' in header
        ReturnShipmentHeader.Get(FindReturnShipmentHeaderNo(OrderNo));
        ReturnShipmentHeader.TestField("Price Calculation Method", ReturnShipmentHeader."Price Calculation Method");
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");
        ReturnShipmentLine.FindFirst();
        ReturnShipmentLine.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method");
        // [THEN] Purchase Order Archive, Method is 'Test' in line, 'Lowest Price' in header
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type"::"Return Order");
        PurchaseHeaderArchive.SetRange("No.", OrderNo);
        PurchaseHeaderArchive.FindLast();
        PurchaseHeaderArchive.TestField("Price Calculation Method", PurchaseHeaderArchive."Price Calculation Method");
        PurchaseLineArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type");
        PurchaseLineArchive.SetRange("Document No.", OrderNo);
        PurchaseLineArchive.FindFirst();
        PurchaseLineArchive.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method");

        // [WHEN] Copy archived order as new order
        LibraryPurchase.CreatePurchHeader(CopiedPurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CopyPurchaseDoc("Purchase Document Type From"::"Arch. Return Order", OrderNo, CopiedPurchaseHeader);
        // [THEN] New Order, where Method is 'Test' in line, 'Lowest Price' in header 
        CopiedPurchaseHeader.Find();
        CopiedPurchaseHeader.TestField("Price Calculation Method", PurchaseHeader."Price Calculation Method");
        CopiedPurchaseLine.SetRange("Document Type", CopiedPurchaseHeader."Document Type");
        CopiedPurchaseLine.SetRange("Document No.", CopiedPurchaseHeader."No.");
        CopiedPurchaseLine.FindLast();
        CopiedPurchaseLine.TestField("Price Calculation Method", PurchaseLineArchive."Price Calculation Method");
        LineNo := CopiedPurchaseLine."Line No.";

        // [WHEN] Copy line from credit memo to order
        CopyPurchLinesToDoc("Purchase Document Type From"::"Posted Credit Memo", PurchCrMemoLine, CopiedPurchaseHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedPurchaseLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedPurchaseLine.FindLast();
        CopiedPurchaseLine.TestField("Price Calculation Method", PurchCrMemoLine."Price Calculation Method");
        LineNo := CopiedPurchaseLine."Line No.";

        // [WHEN] Copy line from return shipment to order
        CopyPurchLinesToDoc("Purchase Document Type From"::"Posted Return Shipment", ReturnShipmentLine, CopiedPurchaseHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedPurchaseLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedPurchaseLine.FindLast();
        CopiedPurchaseLine.TestField("Price Calculation Method", ReturnShipmentLine."Price Calculation Method");

        LibraryNotificationMgt.RecallNotificationsForRecord(CopiedPurchaseHeader);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T203_PostedServiceCrMemoContainsPriceCalcMethod()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Price Calculation Method during posting is populated to posted Service Credit Memo documents.
        Initialize();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Create Service Credit Memo - Service Header, one Service Line with Type as Resource, "Price Calculation Method" is 'Lowest Price'
        Initialize;
        CreateServiceDocumentWithResource(
            ServiceHeader, ServiceLine, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo);
        ServiceLine.TestField("Price Calculation Method", ServiceLine."Price Calculation Method"::"Lowest Price");

        // [WHEN] Post Service Credit Memo
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check that the posted Service Credit Memo Header has "Price Calculation Method" as 'Lowest Price'
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        ServiceCrMemoHeader.TestField("Price Calculation Method", ServiceCrMemoHeader."Price Calculation Method"::"Lowest Price");
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.FindFirst();
        ServiceCrMemoLine.TestField("Price Calculation Method", ServiceCrMemoLine."Price Calculation Method"::"Lowest Price");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T204_PostedServiceInvoiceContainsPriceCalcMethod()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Price Calculation Method during posting is populated to posted Service Invoice/Shipment documents.
        Initialize();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Create Service Order - Service Header, one Service Line with Type as Resource, "Price Calculation Method" is 'Lowest Price'
        Initialize;
        CreateServiceOrderWithResource(ServiceHeader, ServiceLine, LibrarySales.CreateCustomerNo);
        ServiceLine.TestField("Price Calculation Method", ServiceLine."Price Calculation Method"::"Lowest Price");

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Invoice Header has "Price Calculation Method" as 'Lowest Price'
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Price Calculation Method", ServiceInvoiceHeader."Price Calculation Method"::"Lowest Price");
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("Price Calculation Method", ServiceInvoiceLine."Price Calculation Method"::"Lowest Price");
        // [THEN] Posted Service Shipment Header has "Price Calculation Method" as 'Lowest Price'
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        ServiceShipmentHeader.TestField("Price Calculation Method", ServiceShipmentHeader."Price Calculation Method"::"Lowest Price");
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindFirst();
        ServiceShipmentLine.TestField("Price Calculation Method", ServiceShipmentLine."Price Calculation Method"::"Lowest Price");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T210_SalesLineMinQtyPriceForGLAccount()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [G/L Account] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A' 
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price list line for G/L Account 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        GLAccount."No." := LibraryERM.CreateGLAccountWithSalesSetup();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Order for customer 'A' with one line with "Type" = 'G/L Account' and "No." = 'X', "Quantity" = 1
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::"G/L Account", GLAccount."No.", 1);
        // [GIVEN] Sales Line, where "Unit Price" is 0
        SalesLine.TestField("Unit Price", 0);

        // [WHEN] Change "Quantity" to 10
        SalesLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Sales Line, where "Unit Price" is 50 (from Price line)
        SalesLine.TestField("Unit Price", PriceListLine."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T211_ServiceLineMinQtyPriceForGLAccount()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        GLAccount: Record "G/L Account";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service] [G/L Account] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A' 
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price list line for G/L Account 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        GLAccount."No." := LibraryERM.CreateGLAccountWithSalesSetup();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Service Order for customer 'A' with one line with "Type" = 'G/L Account' and "No." = 'X', "Quantity" = 1
        LibraryService.CreateServiceHeader(ServiceHeader, "Sales Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, "Service Line Type"::"G/L Account", GLAccount."No.");
        // [GIVEN] Service Line, where "Unit Price" is 0
        ServiceLine.TestField("Unit Price", 0);

        // [WHEN] Change "Quantity" to 10
        ServiceLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Service Line, where "Unit Price" is 50 (from Price line)
        ServiceLine.TestField("Unit Price", PriceListLine."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T212_PurchaseLineMinQtyPriceForGLAccount()
    var
        PriceListLine: Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [G/L Account] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Price list line for G/L Account 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        GLAccount."No." := LibraryERM.CreateGLAccountWithSalesSetup();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        ;
        PriceListLine."Unit Cost" := PriceListLine."Direct Unit Cost" / 4;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
        // [GIVEN] Order for Vendor 'V', with one line, where "Type" is 'G/L Account', "No." is 'X'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        // [GIVEN] Purchase Line, where "Direct Unit Cost" is 0
        PurchaseLine.TestField("Direct Unit Cost", 0);

        // [WHEN] Change "Quantity" to 10
        PurchaseLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Purchase Line, where "Direct Unit Price" is 50 (from Price line)
        PurchaseLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T240_SalesLineGetsCustomerSourcesForResource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempPriceSource: Record "Price Source" temporary;
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, False);
        // [GIVEN] Customer 'A', where "Customer Discount Group" is 'CDG', "Customer Price Group" is 'CPG'
        SetGroupsOnCustomer(Customer, CustomerDiscountGroup, CustomerPriceGroup);

        // [GIVEN] Invoice for customer 'A' with 'Campaign No.' = 'HdrCmp'.
        // [GIVEN] Invoice has one line with "Type" = 'Resource' and "No." = 'X'.
        CreateSalesInvoiceWithResource(SalesHeader, SalesLine, Customer."No.");
        SalesHeader.Validate("Campaign No.", Campaign[1]."No.");
        SalesHeader.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains: All Jobs, All Customers, Customer 'A', 'CPG', 'CDG', Contact 'C', Campaign 'HdrCmp'
        GetSources(SalesLinePrice, TempPriceSource);
        VerifySaleResourceSources(TempPriceSource, Customer, Contact);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Campaign);
        TempPriceSource.SetRange("Source No.", Campaign[1]."No.");
        Assert.RecordCount(TempPriceSource, 1);
    end;

    [Test]
    procedure T241_ServiceLineGetsCustomerSourcesForResource()
    var
        Campaign: Array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempPriceSource: Record "Price Source" temporary;
        ServiceLinePrice: Codeunit "Service Line - Price";
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, False);
        // [GIVEN] Customer 'A', where "Customer Discount Group" is 'CDG', "Customer Price Group" is 'CPG'
        SetGroupsOnCustomer(Customer, CustomerDiscountGroup, CustomerPriceGroup);

        // [GIVEN] Invoice for customer 'A'.
        // [GIVEN] Invoice has one line with "Type" = 'Resource' and "No." = 'X'.
        CreateServiceDocumentWithResource(
            ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] SetLine()
        ServiceLinePrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [THEN] List of sources contains: All Jobs, All Customers, Customer 'A', 'CPG', 'CDG', Contact 'C', but no Campaign
        GetSources(ServiceLinePrice, TempPriceSource);
        VerifySaleResourceSources(TempPriceSource, Customer, Contact);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Campaign);
        Assert.RecordIsEmpty(TempPriceSource);
    end;

    [Test]
    procedure T242_PurchaseLineGetsVendorSourcesForResource()
    var
        Campaign: Record Campaign;
        Contact: Record Contact;
        Resource: Record Resource;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPriceSource: Record "Price Source" temporary;
        Vendor: Record Vendor;
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
    begin
        // [FEATURE] [Purchase] [Resource] [UT]
        Initialize();
        // [GIVEN] Vendor 'V', where "Primary Contact No." is 'C'
        CreateVendorWithContactAndCampaign(Vendor, Contact, Campaign);

        // [GIVEN] Invoice for Vendor 'V', where 'Campaign No.' is 'HdrCmp'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Campaign No.", Campaign."No.");
        PurchaseHeader.Modify(true);
        // [GIVEN] with one line, where "Type" is 'Resource', "No." is 'X'
        LibraryResource.CreateResource(Resource, '');
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Type := PurchaseLine.Type::Resource;
        PurchaseLine."No." := Resource."No.";
        PurchaseLine.Modify(true);

        // [WHEN] SetLine()
        PurchaseLinePrice.SetLine("Price Type"::Sale, PurchaseHeader, PurchaseLine);

        // [THEN] List of sources contains: All Vendors, Vendor 'V', Contact 'C', Campaign 'HdrCmp', No 'All Jobs'
        GetSources(PurchaseLinePrice, TempPriceSource);
        VerifyPurchaseResourceSources(TempPriceSource, Vendor, Contact);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Campaign);
        TempPriceSource.SetRange("Source No.", Campaign."No.");
        Assert.RecordCount(TempPriceSource, 1);
    end;

    [Test]
    procedure T245_SalesLineMinQtyPriceForResource()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A' 
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Resource 'X', where "Unit Price" is '100'
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");
        Resource."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        // [GIVEN] Price list line for Resource 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Unit Price" := Resource."Unit Price" / 2;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Order for customer 'A' with one line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Resource, Resource."No.", 1);
        // [GIVEN] Sales Line, where "Unit Price" is 100 (from Resource card)
        SalesLine.TestField("Unit Price", Resource."Unit Price");

        // [WHEN] Change "Quantity" to 10
        SalesLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Sales Line, where "Unit Price" is 50 (from Price line)
        SalesLine.TestField("Unit Price", PriceListLine."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T246_ServiceLineMinQtyPriceForResource()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A' 
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Resource 'X', where "Unit Price" is '100'
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");
        Resource."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        // [GIVEN] Price list line for Resource 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Unit Price" := Resource."Unit Price" / 2;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Service Order for customer 'A' with one line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1
        LibraryService.CreateServiceHeader(ServiceHeader, "Sales Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, "Service Line Type"::Resource, Resource."No.");
        // [GIVEN] Service Line, where "Unit Price" is 100 (from Resource card)
        ServiceLine.TestField("Unit Price", Resource."Unit Price");

        // [WHEN] Change "Quantity" to 10
        ServiceLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Service Line, where "Unit Price" is 50 (from Price line)
        ServiceLine.TestField("Unit Price", PriceListLine."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T247_PurchaseLineMinQtyPriceForResource()
    var
        PriceListLine: Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        Vendor: Record Vendor;
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Resource] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Resource 'X', where "Unit Cost" is '100'
        LibraryResource.CreateResource(Resource, Vendor."VAT Bus. Posting Group");
        Resource."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        // [GIVEN] Price list line for Resource 'X', where "Minimum Quantity" is 10, "Direct Unit Price" is 50
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Direct Unit Cost" := Resource."Direct Unit Cost" / 2;
        PriceListLine."Unit Cost" := Resource."Direct Unit Cost" / 4;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
        // [GIVEN] Order for Vendor 'V', with one line, where "Type" is 'Resource', "No." is 'X'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", 1);
        // [GIVEN] Purchase Line, where "Direct Unit Cost" is 100 (from Resource card)
        PurchaseLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");

        // [WHEN] Change "Quantity" to 10
        PurchaseLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Purchase Line, where "Direct Unit Price" is 50 (from Price line)
        PurchaseLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T250_ResourceCostNoPriceLine()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource card
        ResJournalLine.TestField("Unit Cost", Resource."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
    end;

    [Test]
    procedure T251_ResourceCostResPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, Resource."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T252_ResourceCostResGroupPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T253_ResourceCostResAllPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource All Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T254_ResourceCostResAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    procedure T255_ResourceCostResAllAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, '', WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine[2]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine[2]."Direct Unit Cost");
    end;

    [Test]
    procedure T256_ResourceCostResAndResGrAndResAllPriceLines()
    var
        PriceListLine: array[3] of Record "Price List Line";
        WTPriceListLine: array[3] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[3], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[3], "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    procedure T260_ResWorkTypeCostNoPriceLine()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource card
        ResJournalLine.TestField("Unit Cost", Resource."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
    end;

    [Test]
    procedure T261_ResWorkTypeCostResPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, Resource."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);


        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T262_ResWorkTypeCostResGroupPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T263_ResWorkTypeCostResAllPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource All Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T264_ResWorkTypeCostResAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    procedure T265_ResWorkTypeCostResAllAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, '', WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine[2]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine[2]."Direct Unit Cost");
    end;

    [Test]
    procedure T266_ResWorkTypeCostResAndResGrAndResAllPriceLines()
    var
        PriceListLine: array[3] of Record "Price List Line";
        WTPriceListLine: array[3] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[3], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[3], "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ResPriceListReportHandler')]
    procedure T270_ResPriceListReport()
    var
        Resource: Record Resource;
        PriceListLine: Record "Price List Line";
        WorkType: array[2] of Record "Work Type";
        ResPriceList: Report "Res. Price List";
    begin
        // [SCENARIO] Test and verify "Res. Price List" Report.
        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Create Resource, Work Type and Resource Price.
        CreateResource(Resource);
        LibraryResource.CreateWorkType(WorkType[1]);
        LibraryResource.CreateWorkType(WorkType[2]);
        CreateResourcePrice(PriceListLine, Resource."No.", WorkType[2].Code);

        // [WHEN] Run the "Res. Price List" Report.
        Commit();
        Clear(ResPriceList);
        Resource.SetRange("No.", Resource."No.");
        ResPriceList.SetTableView(Resource);
        ResPriceList.Run;

        // [THEN] Verify values on "Res. Price List" Report.
        VerifyResPriceList(PriceListLine, Resource."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ResPriceListReportHandler')]
    procedure T271_ResPriceListWithCurrency()
    var
        Resource: Record Resource;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ValueVar: Variant;
        ActualUnitPrice: Decimal;
    begin
        // [SCENARIO] Test and verify "Res. Price List" Report with Currency.
        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Create Resource, Currency and Currency Exchange Rate.
        CreateResource(Resource);
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code);

        // [GIVEN] Calculation for Actual Unit Price is taken from Report.
        ActualUnitPrice :=
          Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate, Currency.Code, Resource."Unit Price",
              CurrencyExchangeRate.ExchangeRate(WorkDate, Currency.Code)),
            Currency."Unit-Amount Rounding Precision");

        // [WHEN] Run the "Res. Price List" Report with Currency.
        RunResPriceListReport(Resource."No.", Currency.Code);

        // [THEN] Verify values on "Res. Price List" Report with Currency.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Resource', Resource."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow, 'find element with the resource no');

        LibraryReportDataset.FindCurrentRowValue('UnitPrice_Resource', ValueVar);
        Assert.AreNearlyEqual(
            ActualUnitPrice, ValueVar, Currency."Unit-Amount Rounding Precision", 'Resource."Unit Price"');
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangesHandler,MessageHandler')]
    procedure T280_ImplementResourceStandardCostChanges()
    var
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        NewStdCost: Decimal;
    begin
        Initialize();
        // [GIVEN] Resource, where "Direct Unit Cost" is 100
        LibraryResource.CreateResource(Resource, '');

        // [GIVEN] Active purchase Price List Line for Resource, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Jobs", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine.Validate("Direct Unit Cost", Resource."Direct Unit Cost" + 1);
        PriceListLine.Validate("Unit Cost", Resource."Direct Unit Cost");
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();

        // [WHEN] Implement Standard Cost Change, where "New Standard Cost" is 111
        NewStdCost := Resource."Direct Unit Cost" + LibraryRandom.RandDec(100, 2);
        ImplementStandardCostChanges(Resource, Resource."Direct Unit Cost", NewStdCost);

        // [THEN] Price List line is updated: "Direct Unit Cost" is 100, "Unit Cost" is 111 
        PriceListLine.Find();
        PriceListLine.TestField(Status, "Price Status"::Active);
        PriceListLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
        PriceListLine.TestField("Unit Cost", NewStdCost);
    end;

    [Test]
    procedure T290_InvtReceiptLineFindPrice()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        BaseUOM: Record "Unit of Measure";
        UOM: Record "Unit of Measure";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        DimensionValue: Record "Dimension Value";
        PriceListLine: array[3] of Record "Price List Line";
        VendNo: code[20];
    begin
        Initialize();
        LibraryPriceCalculation.SetMethodInPurchSetup();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Item 'I', where "Base Unit of Measure" is 'PCS'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", UOM.Code, 5);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUnitofMeasure.Code);
        Item.Modify();
        // [GIVEN] Purchase Prices, where "All Vendors", Item 'I':  
        // [GiVEN] UOM is 'PCS', "Minimal Quantity" is 0, "Direct Unit Cost" is 100
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Validate("Unit of Measure Code", ItemUnitofMeasure.Code);
        PriceListLine[1]."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GiVEN] UOM is 'PCS', "Minimum Quantity" is 100, "Direct Unit Cost" is 80
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[2], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine[2].Validate("Unit of Measure Code", ItemUnitofMeasure.Code);
        PriceListLine[2]."Minimum Quantity" := 100;
        PriceListLine[2]."Direct Unit Cost" := Round(PriceListLine[1]."Direct Unit Cost" * 0.8, 0.01);
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();
        // [GiVEN] UOM is 'BOX', "Minimal Quantity" is 0, "Direct Unit Cost" is 75
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[3], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine[3].Validate("Unit of Measure Code", UOM.Code);
        PriceListLine[3]."Direct Unit Cost" := Round(PriceListLine[1]."Direct Unit Cost" * 0.75, 0.01);
        PriceListLine[3].Status := "Price Status"::Active;
        PriceListLine[3].Modify();

        // [WHEN] Inventory receipt document line, where 'Item No.' is 'I'
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentLine.Init();
        InvtDocumentLine."Line No." := 10000;
        InvtDocumentLine.Validate("Document Type", InvtDocumentLine."Document Type"::Receipt);
        InvtDocumentLine.Validate("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.Validate("Item No.", Item."No.");
        InvtDocumentLine.Insert();
        // [THEN] Line, where "Unit Amount" is 100
        InvtDocumentLine.TestField("Unit Amount", PriceListLine[1]."Direct Unit Cost");

        // [WHEN] Set Quantity as 100 in the line
        InvtDocumentLine.Validate(Quantity, 100);
        // [THEN] Line, where "Unit Amount" is 80
        InvtDocumentLine.TestField("Unit Amount", PriceListLine[2]."Direct Unit Cost");

        // [WHEN] UOM is 'BOX' in the line
        InvtDocumentLine.Validate("Unit of Measure Code", UOM.Code);
        // [THEN] Line, where "Unit Amount" is 75
        InvtDocumentLine.TestField("Unit Amount", PriceListLine[3]."Direct Unit Cost");
    end;

    [Test]
    procedure T291_InvtReceiptLineUOMPriceBlankUOM()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Location: Record Location;
        BaseUOM: Record "Unit of Measure";
        UOM: Record "Unit of Measure";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        DimensionValue: Record "Dimension Value";
        PriceListLine: Record "Price List Line";
        VendNo: code[20];
    begin
        Initialize();
        LibraryPriceCalculation.SetMethodInPurchSetup();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Item 'I', where "Base Unit of Measure" is 'PCS', 'BOX' is 5 'PCS'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", UOM.Code, 5);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUnitofMeasure.Code);
        Item.Modify();
        // [GIVEN] Purchase Price, where "All Vendors", Item 'I', UOM is <blank>, "Minimal Quantity" is 0, "Direct Unit Cost" is 100
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Unit of Measure Code", '');
        PriceListLine."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();

        // [GIVEN] Inventory receipt document line, where 'Item No.' is 'I'
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentLine.Init();
        InvtDocumentLine."Line No." := 10000;
        InvtDocumentLine.Validate("Document Type", InvtDocumentLine."Document Type"::Receipt);
        InvtDocumentLine.Validate("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.Validate("Item No.", Item."No.");
        InvtDocumentLine.Insert();

        // [WHEN] UOM is 'BOX' in the line
        InvtDocumentLine.Validate("Unit of Measure Code", UOM.Code);
        // [THEN] Line, where "Unit Amount" is 500
        InvtDocumentLine.TestField("Unit Amount", PriceListLine."Direct Unit Cost" * 5);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Price Calculation - V16");
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Price Calculation - V16");
        LibraryERMCountryData.CreateVATData();
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Price Calculation - V16");
    end;

    local procedure AddPriceLine(var TempPriceListLine: Record "Price List Line" temporary; PriceType: Enum "Price Type"; CurrencyCode: code[10]; VarianCode: Code[10]; Price: Decimal)
    begin
        TempPriceListLine.Init();
        TempPriceListLine."Line No." += 10000;
        TempPriceListLine."Price Type" := PriceType;
        TempPriceListLine.Status := TempPriceListLine.Status::Active;
        TempPriceListLine."Currency Code" := CurrencyCode;
        TempPriceListLine."Variant Code" := VarianCode;
        TempPriceListLine."Unit Price" := Price;
        TempPriceListLine.Insert(true);
    end;

    local procedure CopyPurchLinesToDoc(PurchDocType: Enum "Purchase Document Type From"; DocumentLine: Variant; var ToPurchaseHeader: Record "Purchase Header")
    var
        FromReturnShipmentLine: Record "Return Shipment Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        case PurchDocType of
            "Purchase Document Type From"::"Posted Invoice":
                begin
                    FromPurchInvLine := DocumentLine;
                    FromPurchInvLine.SetRecFilter();
                end;
            "Purchase Document Type From"::"Posted Return Shipment":
                begin
                    FromReturnShipmentLine := DocumentLine;
                    FromReturnShipmentLine.SetRecFilter();
                end;
            "Purchase Document Type From"::"Posted Credit Memo":
                begin
                    FromPurchCrMemoLine := DocumentLine;
                    FromPurchCrMemoLine.SetRecFilter();
                end;
            "Purchase Document Type From"::"Posted Receipt":
                begin
                    FromPurchRcptLine := DocumentLine;
                    FromPurchRcptLine.SetRecFilter();
                end;
            else
                Error('Not supported Purchase doc type');
        end;
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopyPurchaseLinesToDoc(
            PurchDocType.AsInteger(), ToPurchaseHeader,
            FromPurchRcptLine, FromPurchInvLine, FromReturnShipmentLine, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyPurchaseDoc(PurchDocType: Enum "Purchase Document Type From"; FromDocNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.SetArchDocVal(1, 1);
        CopyDocMgt.CopyPurchDoc(PurchDocType, FromDocNo, ToPurchaseHeader);
    end;

    local procedure CopySalesLinesToDoc(SalesDocType: Enum "Sales Document Type From"; DocumentLine: Variant; var ToSalesHeader: Record "Sales Header")
    var
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        case SalesDocType of
            "Sales Document Type From"::"Posted Shipment":
                begin
                    FromSalesShptLine := DocumentLine;
                    FromSalesShptLine.SetRecFilter();
                end;
            "Sales Document Type From"::"Posted Invoice":
                begin
                    FromSalesInvLine := DocumentLine;
                    FromSalesInvLine.SetRecFilter();
                end;
            "Sales Document Type From"::"Posted Return Receipt":
                begin
                    FromReturnRcptLine := DocumentLine;
                    FromReturnRcptLine.SetRecFilter();
                end;
            "Sales Document Type From"::"Posted Credit Memo":
                begin
                    FromSalesCrMemoLine := DocumentLine;
                    FromSalesCrMemoLine.SetRecFilter();
                end;
            else
                Error('Not supported sales doc type');
        end;
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopySalesLinesToDoc(
            SalesDocType.AsInteger(), ToSalesHeader,
            FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopySalesDoc(SalesDocType: Enum "Sales Document Type From"; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.SetArchDocVal(1, 1);
        CopyDocMgt.CopySalesDoc(SalesDocType, FromDocNo, ToSalesHeader);
    end;

    local procedure CreateCustomerAllowingLineDisc(var Customer: Record Customer; AllowLineDisc: Boolean)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Allow Line Disc." := AllowLineDisc;
        Customer.Modify();
    end;

    local procedure CreateCustomerItemDiscount(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; CustomerCode: Code[20]; Item: Record Item; Discount: Decimal)
    begin
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', SourceType, CustomerCode, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Starting Date", WorkDate);
        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Line Discount %", Discount);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);
    end;

    local procedure CreateCustomerItemPrice(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; CustomerCode: Code[20]; Item: Record Item; Price: Decimal)
    begin
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', SourceType, CustomerCode, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Starting Date", WorkDate);
        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Unit Price", Price);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);
    end;

#if not CLEAN19
    local procedure CreateCustomerItemDiscount(var SalesLineDiscount: Record "Sales Line Discount"; CustomerCode: Code[20]; Item: Record Item; Discount: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer, CustomerCode,
            WorkDate, '', '', Item."Base Unit of Measure", 0);
        SalesLineDiscount.Validate("Line Discount %", Discount);
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateAllCustomerItemDiscount(var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item; Discount: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::"All Customers", '',
            WorkDate, '', '', Item."Base Unit of Measure", 0);
        SalesLineDiscount.Validate("Line Discount %", Discount);
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateCustomerItemPrice(var SalesPrice: Record "Sales Price"; CustomerCode: Code[20]; Item: Record Item; Price: Decimal)
    begin
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, CustomerCode, WorkDate, '', '', Item."Base Unit of Measure", 0, Price);
    end;
#endif

    local procedure CreateDiscountLine(var PriceListLine: Record "Price List Line"; Customer: Record Customer; Item: Record Item)
    begin
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreateCustomerWithContactAndActivatedCampaigns(var Customer: Record Customer; var Contact: Record Contact; var Campaign: Array[5] of Record Campaign; SkipCustomerCampaign: Boolean)
    var
        CampaignTargetGr: Record "Campaign Target Group";
        i: Integer;
    begin
        LibraryMarketing.CreateCampaign(Campaign[1]);

        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        if not SkipCustomerCampaign then begin

            CampaignTargetGr.Init();
            CampaignTargetGr.Type := CampaignTargetGr.Type::Customer;
            CampaignTargetGr."No." := Customer."No.";
            for i := 2 to 3 do begin
                LibraryMarketing.CreateCampaign(Campaign[i]);
                CampaignTargetGr."Campaign No." := Campaign[i]."No.";
                CampaignTargetGr.Insert();
            end;
        end;

        CampaignTargetGr.Init();
        CampaignTargetGr.Type := CampaignTargetGr.Type::Contact;
        CampaignTargetGr."No." := Contact."No.";
        for i := 4 to 5 do begin
            LibraryMarketing.CreateCampaign(Campaign[i]);
            CampaignTargetGr."Campaign No." := Campaign[i]."No.";
            CampaignTargetGr.Insert();
        end;
    end;

    local procedure CreateVendorWithContactAndCampaign(var Vendor: Record Vendor; var Contact: Record Contact; var Campaign: Record Campaign)
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryMarketing.CreateCompanyContact(Contact);
        Vendor."Primary Contact No." := Contact."No.";
        Vendor.Modify();
    end;

    local procedure CreatePriceLine(var PriceListLine: Record "Price List Line"; Customer: Record Customer; Item: Record Item; AllowLineDisc: Boolean)
    begin
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Allow Line Disc." := AllowLineDisc;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreatePriceLine(var PriceListLine: Record "Price List Line"; Vendor: Record Vendor; Item: Record Item; AllowLineDisc: Boolean)
    begin
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Vendor, Vendor."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Allow Line Disc." := AllowLineDisc;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreateDiscountLine(var PriceListLine: Record "Price List Line"; Vendor: Record Vendor; Item: Record Item; AllowLineDisc: Boolean)
    begin
        LibraryPriceCalculation.CreatePurchDiscountLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Vendor, Vendor."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        // Create Currency Exchange Rate with Exchange Rate Amount, Relational Exch. Rate Amount as Random values.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount is always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount",
          LibraryRandom.RandDec(10, 2) + CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateResource(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Resource: Record Resource;
    begin
        LibraryResource.CreateResource(Resource, VATBusPostingGroup);
        Resource.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateResourcePrice(var PriceListLine: Record "Price List Line"; ResourceNo: Code[20]; WorkTypeCode: Code[10])
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader."Price Type" := "Price Type"::Sale;
        PriceListHeader."Source Type" := "Price Source Type"::"All Jobs";
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, ResourceNo);
        PriceListLine.Validate("Work Type Code", WorkTypeCode);
        PriceListLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;


    local procedure CreateResourceWithGroup(var Resource: Record Resource; var ResourceGroup: Record "Resource Group")
    begin
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryResource.CreateResource(Resource, '');
        Resource."Direct Unit Cost" := LibraryRandom.RandDec(100, 2);
        Resource."Unit Cost" := Round(Resource."Unit Cost" * 1.5);
        Resource."Resource Group No." := ResourceGroup."No.";
        Resource.Modify();
    end;

    local procedure CreateResourcePurchPriceLine(var PriceListLine: Record "Price List Line"; AssetType: Enum "Price Asset Type"; AssetNo: Code[20]; WorkTypeCode: Code[10])
    var
        myInt: Integer;
    begin
        LibraryPriceCalculation.CreatePurchPriceLine(PriceListLine, '', "Price Source Type"::"All Jobs", '', AssetType, AssetNo);
        PriceListLine."Work Type Code" := WorkTypeCode;
        PriceListLine."Direct Unit Cost" := LibraryRandom.RandDec(100, 2);
        PriceListLine."Unit Cost" := Round(PriceListLine."Direct Unit Cost" * 1.3);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreateSalesInvoiceWithResource(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ResourceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        ResourceNo := CreateResource(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATBusPostingGroupOnCustomer(CustomerNo, VATPostingSetup."VAT Bus. Posting Group");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResourceNo, LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreateServiceDocumentWithResource(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ServiceDocType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
        ResourceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        ResourceNo := CreateResource(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATBusPostingGroupOnCustomer(CustomerNo, VATPostingSetup."VAT Bus. Posting Group");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceDocType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);

        CustomerPostingGroup.Get(ServiceHeader."Customer Posting Group");
        UpdateVATProdPostingGroupOnInvRoundingAccount(CustomerPostingGroup.GetInvRoundingAccount(), VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateServiceOrderWithResource(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; CustomerNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        ResourceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        ResourceNo := CreateResource(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATBusPostingGroupOnCustomer(CustomerNo, VATPostingSetup."VAT Bus. Posting Group");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);

        CustomerPostingGroup.Get(ServiceHeader."Customer Posting Group");
        UpdateVATProdPostingGroupOnInvRoundingAccount(CustomerPostingGroup.GetInvRoundingAccount(), VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateResource(var Resource: Record Resource)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // Use Random because value is not important.
        Resource.Validate(Capacity, LibraryRandom.RandDec(10, 2));
        Resource.Modify(true);
    end;

    local procedure CreateRevChargeVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; var RevChVATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        RevChVATPostingSetup := VATPostingSetup;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        RevChVATPostingSetup."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        RevChVATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT";
        RevChVATPostingSetup."VAT %" += 5;
        RevChVATPostingSetup.Insert();
    end;

    local procedure FindReturnShipmentHeaderNo(OrderNo: Code[20]): Code[20]
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader.SetRange("Return Order No.", OrderNo);
        ReturnShipmentHeader.FindFirst;
        exit(ReturnShipmentHeader."No.");
    end;

    local procedure FindServiceCreditMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PreAssignedNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst;
    end;

    local procedure FindServiceInvoiceFromOrder(var ServiceInvoiceHeader: Record "Service Invoice Header"; OrderNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst;
    end;

    local procedure FindServiceShipmentHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; OrderNo: Code[20])
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst;
    end;

    local procedure FindShipmentHeaderNo(OrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst;
        exit(SalesShipmentHeader."No.");
    end;

    local procedure RemovePricesForItem(Item: Record Item)
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", Item."No.");
        PriceListLine.DeleteAll();
    end;

    local procedure SetGroupsOnCustomer(var Customer: Record Customer; var CustomerDiscountGroup: Record "Customer Discount Group"; var CustomerPriceGroup: Record "Customer Price Group")
    begin
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer."Customer Price Group" := CustomerPriceGroup.Code;
        Customer.Modify();
    end;

    local procedure MockBuffer(PriceType: enum "Price Type"; CurrencyCode: Code[10]; CurrencyFactor: Decimal; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.")
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        DummyPriceSourceList: Codeunit "Price Source List";
    begin
        PriceCalculationBuffer.Init();
        PriceCalculationBuffer."Price Type" := PriceType;
        PriceCalculationBuffer."Qty. per Unit of Measure" := 1;
        PriceCalculationBuffer.Quantity := 1;
        PriceCalculationBuffer."Currency Code" := CurrencyCode;
        PriceCalculationBuffer."Currency Factor" := CurrencyFactor;
        PriceCalculationBufferMgt.Set(PriceCalculationBuffer, DummyPriceSourceList);
    end;

    local procedure GetSources(PurchaseLinePrice: Codeunit "Purchase Line - Price"; var TempPriceSource: Record "Price Source" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        PurchaseLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        exit(PriceCalculationBufferMgt.GetSources(TempPriceSource));
    end;

    local procedure GetSources(SalesLinePrice: Codeunit "Sales Line - Price"; var TempPriceSource: Record "Price Source" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        SalesLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        exit(PriceCalculationBufferMgt.GetSources(TempPriceSource));
    end;

    local procedure GetSources(ServiceLinePrice: Codeunit "Service Line - Price"; var TempPriceSource: Record "Price Source" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        ServiceLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        exit(PriceCalculationBufferMgt.GetSources(TempPriceSource));
    end;

    local procedure RunResPriceListReport(No: Code[20]; CurrencyCode: Code[10])
    var
        Resource: Record Resource;
        ResPriceList: Report "Res. Price List";
    begin
        Commit();
        Clear(ResPriceList);
        Resource.SetRange("No.", No);
        ResPriceList.SetTableView(Resource);
        ResPriceList.InitializeRequest(WorkDate(), "Job Price Source Type"::"All Jobs", '', CurrencyCode);
        ResPriceList.Run;
    end;

    local procedure UpdateVATBusPostingGroupOnCustomer(CustomerNo: Code[20]; VATBusPostingGroup: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure UpdateVATProdPostingGroupOnInvRoundingAccount(InvRoundingAccountCode: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(InvRoundingAccountCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure VerifyCampaignSource(SalesLinePrice: Codeunit "Sales Line - Price"; CampaignNo: code[20]; ExpectedCount: Integer)
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        TempPriceSource: Record "Price Source" temporary;
    begin
        SalesLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        PriceCalculationBufferMgt.GetSources(TempPriceSource);
        TempPriceSource.SetRange("Source Type", TempPriceSource."Source Type"::Campaign);
        Assert.RecordCount(TempPriceSource, ExpectedCount);
        TempPriceSource.SetRange("Source No.", CampaignNo);
        TempPriceSource.FindFirst();
    end;

    local procedure VerifyLineDiscount(var SalesLine: Record "Sales Line"; LineDisc: Decimal)
    begin
        SalesLine.TestField("Line Discount %", LineDisc);
        SalesLine.TestField("Allow Line Disc.", LineDisc > 0);
    end;

    local procedure VerifyPurchaseResourceSources(var TempPriceSource: Record "Price Source" temporary; Vendor: Record Vendor; Contact: Record Contact)
    begin
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Jobs");
        Assert.RecordIsEmpty(TempPriceSource);

        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Vendors");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Vendor);
        TempPriceSource.SetRange("Source No.", Vendor."No.");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Contact);
        TempPriceSource.SetRange("Source No.", Contact."No.");
        Assert.RecordCount(TempPriceSource, 1);
    end;

    local procedure VerifySaleResourceSources(var TempPriceSource: Record "Price Source" temporary; Customer: Record Customer; Contact: Record Contact)
    begin
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Jobs");
        Assert.RecordCount(TempPriceSource, 1);

        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Customers");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Customer);
        TempPriceSource.SetRange("Source No.", Customer."No.");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"Customer Disc. Group");
        TempPriceSource.SetRange("Source No.", Customer."Customer Disc. Group");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"Customer Price Group");
        TempPriceSource.SetRange("Source No.", Customer."Customer Price Group");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Contact);
        TempPriceSource.SetRange("Source No.", Contact."No.");
        Assert.RecordCount(TempPriceSource, 1);
    end;

    local procedure VerifyResPriceList(PriceListLine: Record "Price List Line"; ResourceUnitPrice: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Resource', PriceListLine."Asset No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow, 'find element with the work type code');
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_Resource', ResourceUnitPrice);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('No_Resource', PriceListLine."Asset No.");
        LibraryReportDataset.SetRange('WorkTypeCode_ResPrice', PriceListLine."Work Type Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow, 'find element with the work type code');
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_ResPrice', PriceListLine."Unit Price");
    end;

    local procedure CreateStandardCostWorksheet(var StandardCostWorksheetPage: TestPage "Standard Cost Worksheet"; ResourceNo: Code[20]; StandardCost: Decimal; NewStandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        StandardCostWorksheetPage.Type.SetValue(StandardCostWorksheet.Type::Resource);
        StandardCostWorksheetPage."No.".SetValue(ResourceNo);
        StandardCostWorksheetPage."Standard Cost".SetValue(StandardCost);
        StandardCostWorksheetPage."New Standard Cost".SetValue(NewStandardCost);
        StandardCostWorksheetPage.Next;
    end;

    local procedure ImplementStandardCostChanges(Resource: Record Resource; StandardCost: Decimal; NewStandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        StandardCostWorksheetPage: TestPage "Standard Cost Worksheet";
    begin
        StandardCostWorksheet.DeleteAll();
        StandardCostWorksheetPage.OpenEdit;
        CreateStandardCostWorksheet(StandardCostWorksheetPage, Resource."No.", StandardCost, NewStandardCost);
        Commit();  // Commit Required due to Run Modal.
        StandardCostWorksheetPage."&Implement Standard Cost Changes".Invoke;
    end;

    [RequestPageHandler]
    procedure ImplementStandardCostChangesHandler(var ImplementStandardCostChange: TestRequestPage "Implement Standard Cost Change")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalTemplate.SetValue(ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalBatchName.SetValue(ItemJournalBatch.Name);
        ImplementStandardCostChange.OK.Invoke;
    end;

    [ModalPageHandler]
    procedure GetPriceLinePriceModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(false, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(true, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(false, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(false, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        GetPriceLine.First();
        GetPriceLine.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure GetPurchPriceLinePriceModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(false, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(false, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(true, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(false, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        // Asset Type/No visible as the asset list contains (All items) asset
        Assert.AreEqual(true, GetPriceLine."Asset Type".Visible(), 'Asset Type.Visible');
        Assert.AreEqual(true, GetPriceLine."Asset No.".Visible(), 'Asset No.Visible');
        GetPriceLine.First();
        GetPriceLine.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure GetPurchPriceLineDiscountModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(false, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(false, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(false, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(true, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        // Asset Type/No visible as the asset list is more than one asset
        Assert.AreEqual(true, GetPriceLine."Asset Type".Visible(), 'Asset Type.Visible');
        Assert.AreEqual(true, GetPriceLine."Asset No.".Visible(), 'Asset No.Visible');
        GetPriceLine.First();
        GetPriceLine.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure GetPriceLineDiscountModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(true, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(false, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(false, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(false, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        GetPriceLine.First();
        GetPriceLine.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure GetPriceLineModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    var
        PriceListCode: Text;
    begin
        PriceListCode := LibraryVariableStorage.DequeueText();
        GetPriceLine.Filter.SetFilter("Price List Code", PriceListCode);
        GetPriceLine.First();
        GetPriceLine."Allow Line Disc.".AssertEquals(Format(true));
        Assert.AreNotEqual(0, GetPriceLine."Line Discount %".AsDecimal(), 'Line Discount % in GetPriceLine');
        GetPriceLine.OK.Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text)
    begin
        LibraryVariableStorage.Enqueue(Msg);
    end;

    [RequestPageHandler]
    procedure ResPriceListReportHandler(var ResPriceList: TestRequestPage "Res. Price List")
    begin
        ResPriceList.Handler.SetValue("Price Calculation Handler"::"Business Central (Version 16.0)");
        ResPriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}
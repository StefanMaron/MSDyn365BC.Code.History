codeunit 134347 "ERM Document Line Tracking"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Document Line Tracking]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        SalesOrderLinesTxt: Label 'Sales Order Lines';
        ArchivedSalesOrderLinesTxt: Label 'Archived Sales Order Lines';
        PostedSalesShipmentLinesTxt: Label 'Posted Sales Shipment Lines';
        PostedSalesInvoiceLinesTxt: Label 'Posted Sales Invoice Lines';
        PurchaseOrderLinesTxt: Label 'Purchase Order Lines';
        ArchivedPurchaseOrderLinesTxt: Label 'Archived Purchase Order Lines';
        PostedPurchaseReceiptLinesTxt: Label 'Posted Purchase Receipt Lines';
        PostedPurchaseInvoiceLinesTxt: Label 'Posted Purchase Invoice Lines';
        BlanketSalesOrderLinesTxt: Label 'Blanket Sales Order Lines';
        ArchivedBlanketSalesOrderLinesTxt: Label 'Archived Blanket Sales Order Lines';
        BlanketPurchaseOrderLinesTxt: Label 'Blanket Purchase Order Lines';
        ArchivedBlanketPurchaseOrderLinesTxt: Label 'Archived Blanket Purchase Order Lines';
        SalesReturnOrderLinesTxt: Label 'Sales Return Order Lines';
        ArchivedSalesReturnOrderLinesTxt: Label 'Archived Sales Return Order Lines';
        PostedReturnReceiptLinesTxt: Label 'Posted Return Receipt Lines';
        PostedSalesCreditMemoLinesTxt: Label 'Posted Sales Credit Memo Lines';
        PurchaseReturnOrderLinesTxt: Label 'Purchase Return Order Lines';
        ArchivedPurchaseReturnOrderLinesTxt: Label 'Archived Purchase Return Order Lines';
        PostedReturnShipmentLinesTxt: Label 'Posted Return Shipment Lines';
        PostedPurchaseCreditMemoLinesTxt: Label 'Posted Purchase Credit Memo Lines';
        VerifyDocumentRef: Option SalesOrder,PurchaseOrder,BlanketSalesOrder,BlanketPurchaseOrder,SalesShipment,PurchaseReceipt,SalesInvoice,PurchaseInvoice,SalesReturnOrder,PurchaseReturnOrder,SalesCreditMemo,PurchaseCreditMemo,ReturnReceipt,ReturnShipment;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Purchase Order] [Order]
        // [SCENARIO 315523] Document Line Tracking opened from Purchase Order

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" opened for "Item1" and "Item2" of Purchase Order
        FindFirstLastPurchaseLines(OrderNo, PurchaseHeader."Document Type"::Order, PurchaseLine);
        OpenDocumentLineTrackingForPurchaseLines(PurchaseLine, VerifyDocumentRef::PurchaseOrder);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromBlanketPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Blanket Purchase Order] [Blanket Order]
        // [SCENARIO 315523] Document Line Tracking opened from Blanked Purchase Order

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Blanket Purchase Order
        FindFirstLastPurchaseLines(BlanketOrderNo, PurchaseHeader."Document Type"::"Blanket Order", PurchaseLine);
        OpenDocumentLineTrackingForPurchaseLines(PurchaseLine, VerifyDocumentRef::BlanketPurchaseOrder);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedPurchaseReceipt()
    var
        PurchRcptLine: array[2] of Record "Purch. Rcpt. Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Purchase Receipt] [Posted Receipt]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Purchase Release

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Posted Purchase Receipt
        FindFirstLastPurchaseReceiptLines(OrderNo, PurchRcptLine);
        OpenDocumentLineTrackingForPurchaseReceiptLines(PurchRcptLine, VerifyDocumentRef::PurchaseReceipt);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedPurchaseInvoice()
    var
        PurchInvLine: array[2] of Record "Purch. Inv. Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Purchase Invoice] [Posted Invoice]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Purchase Invoice

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order "PO" from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Posted Purchase Invoice
        FindFirstLastPurchaseInvoiceLinesFromOrderNo(OrderNo, PurchInvLine);
        OpenDocumentLineTrackingForPurchaseInvoiceLines(PurchInvLine, VerifyDocumentRef::PurchaseInvoice);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Purchase Retun Order] [Return Order]
        // [SCENARIO 315523] Document Line Tracking opened from Purchase Return Order

        // [GIVEN] Create Purchase Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Purchase Return partially
        CreateArchivePostPurchaseReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Purchase Return Order
        FindFirstLastPurchaseLines(ReturnOrderNo, PurchaseHeader."Document Type"::"Return Order", PurchaseLine);
        OpenDocumentLineTrackingForPurchaseLines(PurchaseLine, VerifyDocumentRef::PurchaseReturnOrder);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseReturnShipmentOrder()
    var
        ReturnShipmentLine: array[2] of Record "Return Shipment Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Return Shipment] [Return Shipment]
        // [SCENARIO 315523] Document Line Tracking opened from Purchase Return Shipment

        // [GIVEN] Create Purchase Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Purchase Return partially
        CreateArchivePostPurchaseReturnOrder(ReturnOrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" from Posted Purchase Return Shipment
        FindFirstLastPurchaseReturnShipmentLines(ReturnOrderNo, ReturnShipmentLine);
        OpenDocumentLineTrackingForPurchaseReturnShipmentLines(ReturnShipmentLine, VerifyDocumentRef::ReturnShipment);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseCreditMemoOrder()
    var
        PurchCrMemoLine: array[2] of Record "Purch. Cr. Memo Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Purchase Credit Memo] [Posted Credit Memo]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Purchase Credit Memo

        // [GIVEN] Create Purchase Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Purchase Return partially
        CreateArchivePostPurchaseReturnOrder(ReturnOrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" from Posted Purchase Credit Memo
        FindFirstLastPurchaseCreditMemoLines(ReturnOrderNo, PurchCrMemoLine);
        OpenDocumentLineTrackingForPurchaseCreditMemoLines(PurchCrMemoLine, VerifyDocumentRef::PurchaseCreditMemo);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('EmptyDocumentLineTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseInvoicePostedStandalone()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: array[2] of Record "Purch. Inv. Line";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Purchase Invoice] [Posted Purchase Invoice] [Invoice] [Posted Invoice]
        // [SCENARIO 315523] Open Document Line Tracking from standalone Posted Purchase Invoice showing blank page

        // [GIVEN] Purchase Invoice "PI" with two lines for "Item1" and "Item2" with different quantity of 10 and 20
        CreatePurchaseHeaderWithTwoLines(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] "PI" posted
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] "Page" is opened for "Item1" and "Item2" of Posted Purchase Invoice
        FindFirstLastPurchaseInvoiceLines(PostedInvoiceNo, PurchInvLine);
        OpenDocumentLineTrackingForPurchaseInvoiceLinesWithNoEnqueue(PurchInvLine, VerifyDocumentRef::PurchaseInvoice);

        // [THEN] Verify "Page" is blank with no header and no lines
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Sales Order] [Order]
        // [SCENARIO 315523] Document Line Tracking opened from Sales Order

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Sales Order
        FindFirstLastSalesLines(OrderNo, SalesHeader."Document Type"::Order, SalesLine);
        OpenDocumentLineTrackingForSalesLines(SalesLine, VerifyDocumentRef::SalesOrder);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty;

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromBlanketSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Blanket Sales Order] [Blanket Order]
        // [SCENARIO 315523] Document Line Tracking opened from Blanket Sales Order

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Blanket Sales Order
        FindFirstLastSalesLines(BlanketOrderNo, SalesHeader."Document Type"::"Blanket Order", SalesLine);
        OpenDocumentLineTrackingForSalesLines(SalesLine, VerifyDocumentRef::BlanketSalesOrder);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty;

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedSalesInvoice()
    var
        SalesInvoiceLine: array[2] of Record "Sales Invoice Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Sales Invoice] [Invoice] [Posted Invoice]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Sales Invoice

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" from Posted Sales Invoice
        FindFirstLastSalesInvoiceLinesFromOrderNo(OrderNo, SalesInvoiceLine);
        OpenDocumentLineTrackingForSalesInvoiceLines(SalesInvoiceLine, VerifyDocumentRef::SalesInvoice);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty;

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedSalesShipment()
    var
        SalesShipmentLine: array[2] of Record "Sales Shipment Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Sales Shipment] [Posted Shipment]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Sales Shipment

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" for Posted Sales Shipment
        FindFirstLastSalesShipmentLines(OrderNo, SalesShipmentLine);
        OpenDocumentLineTrackingForSalesShipmentLines(SalesShipmentLine, VerifyDocumentRef::SalesShipment);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty;

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Sales Retun Order] [Return Order]
        // [SCENARIO 315523] Document Line Tracking opened from Sales Return Order

        // [GIVEN] Create Sales Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Sales Return partially
        CreateArchivePostSalesReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Sales Return Order
        FindFirstLastSalesLines(ReturnOrderNo, SalesHeader."Document Type"::"Return Order", SalesLine);
        OpenDocumentLineTrackingForSalesLines(SalesLine, VerifyDocumentRef::SalesReturnOrder);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedReturnReceipt()
    var
        ReturnReceiptLine: array[2] of Record "Return Receipt Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Return Receipt] [Return Receipt]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Return Receipt

        // [GIVEN] Create Sales Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Sales Return partially
        CreateArchivePostSalesReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Posted Return Receipt
        FindFirstLastSalesReturnReceiptLines(ReturnOrderNo, ReturnReceiptLine);
        OpenDocumentLineTrackingForSalesReturnReceiptLines(ReturnReceiptLine, VerifyDocumentRef::ReturnReceipt);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedSalesCreditMemo()
    var
        SalesCrMemoLine: array[2] of Record "Sales Cr.Memo Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Sales Credit Memo] [Posted Credit Memo]
        // [SCENARIO 315523] Show Document Line Tracking from partially posted Sales Return Order showing all line related information

        // [GIVEN] Create Sales Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Sales Return partially
        CreateArchivePostSalesReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking "Page" is opened for "Item1" and "Item2" of Posted Sales Credit Memo
        FindFirstLastSalesCreditMemoLines(ReturnOrderNo, SalesCrMemoLine);
        OpenDocumentLineTrackingForSalesCreditMemoLines(SalesCrMemoLine, VerifyDocumentRef::SalesCreditMemo);

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('EmptyDocumentLineTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromSalesInvoicePostedStandalone()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: array[2] of Record "Sales Invoice Line";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Sales Invoice] [Posted Sales Invoice] [Invoice] [Posted Invoice]
        // [SCENARIO 315523] Open Document Line Tracking from standalone Posted Sales Invoice showing blank page

        // [GIVEN] Sales Invoice "SI" with two lines for "Item1" and "Item2"
        CreateSalesHeaderWithTwoLines(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] "SI" posted
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Document Line Tracking "Page" is opened for "Item1" and "Item2" of Posted Purchase Invoice
        FindFirstLastSalesInvoiceLines(PostedInvoiceNo, SalesInvoiceLine);
        OpenDocumentLineTrackingForSalesInvoiceLinesWithNoEnqueue(SalesInvoiceLine, VerifyDocumentRef::SalesInvoice);

        // [THEN] Verify "Page" is blank with no header and no lines
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure CreateArchivePostPurchaseOrder(var BlanketOrderNo: Code[20]; var OrderNo: Code[20])
    var
        PurchaseHeaderBlanketOrder: Record "Purchase Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreatePurchaseHeaderWithTwoLines(PurchaseHeaderBlanketOrder, PurchaseHeaderBlanketOrder."Document Type"::"Blanket Order");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeaderBlanketOrder);

        PurchaseHeaderOrder.Get(
          PurchaseHeaderOrder."Document Type"::Order,
          LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeaderBlanketOrder));
        ArchiveManagement.ArchivePurchDocument(PurchaseHeaderOrder);

        FindFirstLastPurchaseLines(PurchaseHeaderOrder."No.", PurchaseHeaderOrder."Document Type", PurchaseLine);
        ReducePurchaseOrderLinesForPartialPosting(PurchaseLine, VerifyDocumentRef::PurchaseOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);

        OrderNo := PurchaseHeaderOrder."No.";
        BlanketOrderNo := PurchaseHeaderBlanketOrder."No.";
    end;

    local procedure CreateArchivePostPurchaseReturnOrder(var ReturnOrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreatePurchaseHeaderWithTwoLines(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        FindFirstLastPurchaseLines(PurchaseHeader."No.", PurchaseHeader."Document Type", PurchaseLine);
        ReducePurchaseOrderLinesForPartialPosting(PurchaseLine, VerifyDocumentRef::PurchaseReturnOrder);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ReturnOrderNo := PurchaseHeader."No.";
    end;

    local procedure CreateArchivePostSalesOrder(var BlanketOrderNo: Code[20]; var OrderNo: Code[20])
    var
        SalesHeaderBlanketOrder: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreateSalesHeaderWithTwoLines(SalesHeaderBlanketOrder, SalesHeaderBlanketOrder."Document Type"::"Blanket Order");
        ArchiveManagement.ArchiveSalesDocument(SalesHeaderBlanketOrder);

        SalesHeaderOrder.Get(
          SalesHeaderOrder."Document Type"::Order, LibrarySales.BlanketSalesOrderMakeOrder(SalesHeaderBlanketOrder));
        ArchiveManagement.ArchiveSalesDocument(SalesHeaderOrder);

        FindFirstLastSalesLines(SalesHeaderOrder."No.", SalesHeaderOrder."Document Type", SalesLine);
        ReduceSalesOrderLinesForPartialPosting(SalesLine, VerifyDocumentRef::SalesOrder);

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        OrderNo := SalesHeaderOrder."No.";
        BlanketOrderNo := SalesHeaderBlanketOrder."No.";
    end;

    local procedure CreateArchivePostSalesReturnOrder(var ReturnOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreateSalesHeaderWithTwoLines(SalesHeader, SalesHeader."Document Type"::"Return Order");
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        FindFirstLastSalesLines(SalesHeader."No.", SalesHeader."Document Type", SalesLine);
        ReduceSalesOrderLinesForPartialPosting(SalesLine, VerifyDocumentRef::SalesReturnOrder);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnOrderNo := SalesHeader."No.";
    end;

    local procedure CreatePurchaseHeaderWithTwoLines(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
    end;

    local procedure CreateSalesHeaderWithTwoLines(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
    end;

    local procedure FindFirstLastPurchaseLines(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; var PurchaseLine: array[2] of Record "Purchase Line")
    begin
        PurchaseLine[1].SetRange("Document No.", DocumentNo);
        PurchaseLine[1].SetRange("Document Type", DocumentType);
        PurchaseLine[1].FindFirst;

        PurchaseLine[2].SetRange("Document No.", DocumentNo);
        PurchaseLine[2].SetRange("Document Type", DocumentType);
        PurchaseLine[2].FindLast;
    end;

    local procedure FindFirstLastPurchaseReceiptLines(DocumentNo: Code[20]; var PurchRcptLine: array[2] of Record "Purch. Rcpt. Line")
    begin
        PurchRcptLine[1].SetRange("Order No.", DocumentNo);
        PurchRcptLine[1].FindFirst;

        PurchRcptLine[2].SetRange("Order No.", DocumentNo);
        PurchRcptLine[2].FindLast;
    end;

    local procedure FindFirstLastPurchaseInvoiceLines(DocumentNo: Code[20]; var PurchInvLine: array[2] of Record "Purch. Inv. Line")
    begin
        PurchInvLine[1].SetRange("Document No.", DocumentNo);
        PurchInvLine[1].FindFirst;

        PurchInvLine[2].SetRange("Document No.", DocumentNo);
        PurchInvLine[2].FindLast;
    end;

    local procedure FindFirstLastPurchaseInvoiceLinesFromOrderNo(DocumentNo: Code[20]; var PurchInvLine: array[2] of Record "Purch. Inv. Line")
    begin
        PurchInvLine[1].SetRange("Order No.", DocumentNo);
        PurchInvLine[1].FindFirst;

        PurchInvLine[2].SetRange("Order No.", DocumentNo);
        PurchInvLine[2].FindLast;
    end;

    local procedure FindFirstLastPurchaseReturnShipmentLines(DocumentNo: Code[20]; var ReturnShipmentLine: array[2] of Record "Return Shipment Line")
    begin
        ReturnShipmentLine[1].SetRange("Return Order No.", DocumentNo);
        ReturnShipmentLine[1].FindFirst;

        ReturnShipmentLine[2].SetRange("Return Order No.", DocumentNo);
        ReturnShipmentLine[2].FindLast;
    end;

    local procedure FindFirstLastPurchaseCreditMemoLines(DocumentNo: Code[20]; var PurchCrMemoLine: array[2] of Record "Purch. Cr. Memo Line")
    begin
        PurchCrMemoLine[1].SetRange("Order No.", DocumentNo);
        PurchCrMemoLine[1].FindFirst;

        PurchCrMemoLine[2].SetRange("Order No.", DocumentNo);
        PurchCrMemoLine[2].FindLast;
    end;

    local procedure FindFirstLastSalesLines(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; var SalesLine: array[2] of Record "Sales Line")
    begin
        SalesLine[1].SetRange("Document No.", DocumentNo);
        SalesLine[1].SetRange("Document Type", DocumentType);
        SalesLine[1].FindFirst;

        SalesLine[2].SetRange("Document No.", DocumentNo);
        SalesLine[2].SetRange("Document Type", DocumentType);
        SalesLine[2].FindLast;
    end;

    local procedure FindFirstLastSalesInvoiceLines(DocumentNo: Code[20]; var SalesInvoiceLine: array[2] of Record "Sales Invoice Line")
    begin
        SalesInvoiceLine[1].SetRange("Document No.", DocumentNo);
        SalesInvoiceLine[1].FindFirst;

        SalesInvoiceLine[2].SetRange("Document No.", DocumentNo);
        SalesInvoiceLine[2].FindLast;
    end;

    local procedure FindFirstLastSalesInvoiceLinesFromOrderNo(DocumentNo: Code[20]; var SalesInvoiceLine: array[2] of Record "Sales Invoice Line")
    begin
        SalesInvoiceLine[1].SetRange("Order No.", DocumentNo);
        SalesInvoiceLine[1].FindFirst;

        SalesInvoiceLine[2].SetRange("Order No.", DocumentNo);
        SalesInvoiceLine[2].FindLast;
    end;

    local procedure FindFirstLastSalesShipmentLines(DocumentNo: Code[20]; var SalesShipmentLine: array[2] of Record "Sales Shipment Line")
    begin
        SalesShipmentLine[1].SetRange("Order No.", DocumentNo);
        SalesShipmentLine[1].FindFirst;

        SalesShipmentLine[2].SetRange("Order No.", DocumentNo);
        SalesShipmentLine[2].FindLast;
    end;

    local procedure FindFirstLastSalesReturnReceiptLines(DocumentNo: Code[20]; var ReturnReceiptLine: array[2] of Record "Return Receipt Line")
    begin
        ReturnReceiptLine[1].SetRange("Return Order No.", DocumentNo);
        ReturnReceiptLine[1].FindFirst;

        ReturnReceiptLine[2].SetRange("Return Order No.", DocumentNo);
        ReturnReceiptLine[2].FindLast;
    end;

    local procedure FindFirstLastSalesCreditMemoLines(DocumentNo: Code[20]; var SalesCrMemoLine: array[2] of Record "Sales Cr.Memo Line")
    begin
        SalesCrMemoLine[1].SetRange("Order No.", DocumentNo);
        SalesCrMemoLine[1].FindFirst;

        SalesCrMemoLine[2].SetRange("Order No.", DocumentNo);
        SalesCrMemoLine[2].FindLast;
    end;

    local procedure ReducePurchaseOrderLinesForPartialPosting(var PurchaseLine: array[2] of Record "Purchase Line"; VerifyDocument: Option)
    begin
        case VerifyDocument of
            VerifyDocumentRef::PurchaseOrder:
                begin
                    UpdatePurchaseLineQuantityToReceipt(PurchaseLine[1]);
                    UpdatePurchaseLineQuantityToReceipt(PurchaseLine[2]);
                end;
            VerifyDocumentRef::PurchaseReturnOrder:
                begin
                    UpdatePurchaseLineReturnQtyToShip(PurchaseLine[1]);
                    UpdatePurchaseLineReturnQtyToShip(PurchaseLine[2]);
                end;
        end;
    end;

    local procedure ReduceSalesOrderLinesForPartialPosting(var SalesLine: array[2] of Record "Sales Line"; VerifyDocument: Option)
    begin
        case VerifyDocument of
            VerifyDocumentRef::SalesOrder:
                begin
                    UpdateSalesLineQuantityToShip(SalesLine[1]);
                    UpdateSalesLineQuantityToShip(SalesLine[2]);
                end;
            VerifyDocumentRef::SalesReturnOrder:
                begin
                    UpdateSalesLineReturnQtyToReceipt(SalesLine[1]);
                    UpdateSalesLineReturnQtyToReceipt(SalesLine[2]);
                end;
        end;
    end;

    local procedure UpdatePurchaseLineQuantityToReceipt(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineReturnQtyToShip(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesLineQuantityToShip(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesLineReturnQtyToReceipt(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
    end;

    local procedure OpenDocumentLineTrackingForPurchaseLines(PurchaseLine: array[2] of Record "Purchase Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchaseLine) do
            with PurchaseLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseReceiptLines(PurchRcptLine: array[2] of Record "Purch. Rcpt. Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchRcptLine) do
            with PurchRcptLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseInvoiceLines(PurchInvLine: array[2] of Record "Purch. Inv. Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchInvLine) do
            with PurchInvLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseInvoiceLinesWithNoEnqueue(PurchInvLine: array[2] of Record "Purch. Inv. Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchInvLine) do
            with PurchInvLine[Index] do begin
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseReturnShipmentLines(ReturnShipmentLine: array[2] of Record "Return Shipment Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(ReturnShipmentLine) do
            with ReturnShipmentLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(VerifyDocument, "Document No.", "Line No.", "Return Order No.", "Return Order Line No.", '', 0);
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseCreditMemoLines(PurchCrMemoLine: array[2] of Record "Purch. Cr. Memo Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchCrMemoLine) do
            with PurchCrMemoLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForSalesLines(SalesLine: array[2] of Record "Sales Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesLine) do
            with SalesLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.", '', 0);
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForSalesShipmentLines(SalesShipmentLine: array[2] of Record "Sales Shipment Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesShipmentLine) do
            with SalesShipmentLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForSalesInvoiceLines(SalesInvoiceLine: array[2] of Record "Sales Invoice Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesInvoiceLine) do
            with SalesInvoiceLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForSalesInvoiceLinesWithNoEnqueue(SalesInvoiceLine: array[2] of Record "Sales Invoice Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesInvoiceLine) do
            with SalesInvoiceLine[Index] do begin
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForSalesReturnReceiptLines(ReturnReceiptLine: array[2] of Record "Return Receipt Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(ReturnReceiptLine) do
            with ReturnReceiptLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Return Order No.", "Return Order Line No.", '', 0);
                DocumentLineTracking.Run;
            end;
    end;

    local procedure OpenDocumentLineTrackingForSalesCreditMemoLines(SalesCrMemoLine: array[2] of Record "Sales Cr.Memo Line"; VerifyDocument: Option)
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesCrMemoLine) do
            with SalesCrMemoLine[Index] do begin
                EnqueueLineValues(VerifyDocument, "Line No.", "No.", Quantity, Description, "Unit of Measure Code");
                DocumentLineTracking.SetDoc(
                  VerifyDocument, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.",
                  "Order No.", "Order Line No.");
                DocumentLineTracking.Run;
            end;
    end;

    local procedure EnqueueLineValues(VerifyDocument: Option; LineNo: Integer; No: Code[20]; Quantity: Decimal; Description: Text; UoMCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(VerifyDocument);
        LibraryVariableStorage.Enqueue(LineNo);
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Description);
        LibraryVariableStorage.Enqueue(UoMCode);
    end;

    local procedure VerifyDocumentLineTrackingForPurchaseOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, BlanketPurchaseOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedBlanketPurchaseOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PurchaseOrderLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedPurchaseOrderLinesTxt, 1, 4);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedPurchaseReceiptLinesTxt, 1, 5);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedPurchaseInvoiceLinesTxt, 1, 6);
    end;

    local procedure VerifyDocumentLineTrackingForPurchaseReturnOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PurchaseReturnOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedPurchaseReturnOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedReturnShipmentLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedPurchaseCreditMemoLinesTxt, 1, 4);
    end;

    local procedure VerifyDocumentLineTrackingForSalesOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, BlanketSalesOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedBlanketSalesOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, SalesOrderLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedSalesOrderLinesTxt, 1, 4);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedSalesShipmentLinesTxt, 1, 5);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedSalesInvoiceLinesTxt, 1, 6);
    end;

    local procedure VerifyDocumentLineTrackingForSalesReturnOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, SalesReturnOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedSalesReturnOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedReturnReceiptLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedSalesCreditMemoLinesTxt, 1, 4);
    end;

    local procedure VerifyDocumentLineTrackingHeader(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        DocumentLineTracking.SourceDocLineNo.AssertEquals(LibraryVariableStorage.DequeueText);
        DocumentLineTracking.DocLineNo.AssertEquals(LibraryVariableStorage.DequeueText);
        DocumentLineTracking.DocLineQuantity.AssertEquals(LibraryVariableStorage.DequeueInteger);
        DocumentLineTracking.DocLineDescription.AssertEquals(LibraryVariableStorage.DequeueText);
        DocumentLineTracking.DocLineUnit.AssertEquals(LibraryVariableStorage.DequeueText);
    end;

    local procedure VerifyDocumentLineTrackingLine(var DocumentLineTracking: TestPage "Document Line Tracking"; TableNameValue: Text; ExpectedCount: Integer; EntryNo: Integer)
    begin
        DocumentLineTracking.GotoKey(EntryNo);
        DocumentLineTracking."Table Name".AssertEquals(TableNameValue);
        DocumentLineTracking."No. of Records".AssertEquals(ExpectedCount);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DocumentLineTrackingPageHandler(var DocumentLineTracking: TestPage "Document Line Tracking")
    var
        VerifyDocument: Option;
    begin
        VerifyDocument := LibraryVariableStorage.DequeueInteger;
        VerifyDocumentLineTrackingHeader(DocumentLineTracking);
        case VerifyDocument of
            VerifyDocumentRef::PurchaseOrder, VerifyDocumentRef::BlanketPurchaseOrder,
          VerifyDocumentRef::PurchaseInvoice, VerifyDocumentRef::PurchaseReceipt:
                VerifyDocumentLineTrackingForPurchaseOrder(DocumentLineTracking);
            VerifyDocumentRef::PurchaseReturnOrder, VerifyDocumentRef::ReturnShipment,
          VerifyDocumentRef::PurchaseCreditMemo:
                VerifyDocumentLineTrackingForPurchaseReturnOrder(DocumentLineTracking);
            VerifyDocumentRef::SalesOrder, VerifyDocumentRef::BlanketSalesOrder,
          VerifyDocumentRef::SalesInvoice, VerifyDocumentRef::SalesShipment:
                VerifyDocumentLineTrackingForSalesOrder(DocumentLineTracking);
            VerifyDocumentRef::SalesReturnOrder, VerifyDocumentRef::ReturnReceipt,
          VerifyDocumentRef::SalesCreditMemo:
                VerifyDocumentLineTrackingForSalesReturnOrder(DocumentLineTracking);
        end;
        DocumentLineTracking.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EmptyDocumentLineTrackingPageHandler(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        DocumentLineTracking.SourceDocLineNo.AssertEquals('');
        DocumentLineTracking.DocLineNo.AssertEquals('');
        DocumentLineTracking.DocLineQuantity.AssertEquals('');
        DocumentLineTracking.DocLineDescription.AssertEquals('');
        DocumentLineTracking.DocLineUnit.AssertEquals('');
        Assert.IsFalse(DocumentLineTracking.First, 'Expecting blank Document Line Tracking page');
        DocumentLineTracking.Close;
    end;
}


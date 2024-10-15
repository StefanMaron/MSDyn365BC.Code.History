codeunit 144102 "SCM Inventory reports"
{
    // // [FEATURE] [SCM] [Report]

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        StdRepMgt: Codeunit "Local Report Management";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TotalingValueIncorrectErr: Label 'Calculated totaling value is incorrect';

    [Test]
    [Scope('OnPrem')]
    procedure UnpostedTorg16VerifySignatureTotals()
    begin
        // Unposted TORG-16. Verify Total and Document Signatures
        CreatePostItemShptDocument(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostedTorg16VerifySignatureTotals()
    begin
        // Posted TORG-16. Verify Total and Document Signatures
        CreatePostItemShptDocument(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg1VerifyTotals()
    var
        TotalQtys: array[5] of Decimal;
    begin
        // Torg-1 Report. Partially Posted Purch. Order.
        RunUnpostedTorg1Report(CreatePartialPostPurchDoc(TotalQtys), true, '', WorkDate, '');
        VerifyTorg1Totals(TotalQtys);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderTorg2VerifyAmountTotals()
    var
        PurchaseHeader: Record "Purchase Header";
        TotalQtys: array[5] of Decimal;
    begin
        // Torg-1 Report. Partially Posted Purch. Order.
        RunReceiptDeviationsTorg2Report(
          CreatePartialPostPurchDoc(TotalQtys), '', WorkDate, '', DATABASE::"Purchase Header", PurchaseHeader."Document Type"::Order.AsInteger());
        VerifyTorg2Totals(100, 95, TotalQtys);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReceiptTorg2VerifyAmountTotal()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        TotalQtys: array[5] of Decimal;
    begin
        // Torg-1 Report. Print from Item Receipt Document
        RunReceiptDeviationsTorg2Report(
          CreateInvtReceiptDocument(TotalQtys),
          '', WorkDate, '', DATABASE::"Invt. Document Header", InvtDocumentHeader."Document Type"::Receipt.AsInteger());
        VerifyTorg2Totals(100, 136, TotalQtys);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostedItemReceiptTorg2VerifyAmountTotal()
    var
        TotalQtys: array[5] of Decimal;
    begin
        // Torg-1 Report. Print from Posted Item Receipt Document.
        RunReceiptDeviationsTorg2Report(
          PostItemDocument(CreateInvtReceiptDocument(TotalQtys)), '', WorkDate, '', DATABASE::"Invt. Receipt Header", 0);
        VerifyTorg2Totals(100, 136, TotalQtys);
    end;

    [Test]
    [HandlerFunctions('ItemWriteOffActTORG16RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Torg16CanBePrintedFromItemShipment()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtShipment: TestPage "Invt. Shipment";
    begin
        // [FEATURE] [Shipment]
        // [SCENARIO 201939] Torg-16 write off act report should be started when Print button is pushed on Item Shipment page.
        Initialize;

        // [GIVEN] Item shipment document.
        MockInvtDocHeader(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment);

        // [GIVEN] Item Shipment page is opened.
        InvtShipment.OpenEdit;
        InvtShipment.GotoRecord(InvtDocumentHeader);

        // [WHEN] Push "Print" on the page ribbon.
        LibraryVariableStorage.Enqueue(InvtDocumentHeader."No.");
        InvtShipment.Print.Invoke();

        // [THEN] TORG-16 report is invoked.
        // Verification is done in ItemWriteOffActTORG16RequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('ReportSelectionPrintPageHandler,CancelPrintActItemsReceiptM7RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListOfReportsIsInvokedWhenItemReceiptIsPrinted()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        ReportSelections: Record "Report Selections";
        InvtReceipt: TestPage "Invt. Receipt";
    begin
        // [FEATURE] [Receipt]
        // [SCENARIO 201939] List of reports defined in Report Selections should be shown when Print button is pushed on Item Receipt page.
        Initialize;

        // [GIVEN] Item receipt document.
        MockInvtDocHeader(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt);

        // [GIVEN] Item Receipt page is opened.
        InvtReceipt.OpenEdit;
        InvtReceipt.GotoRecord(InvtDocumentHeader);

        // [WHEN] Push "Print" on the page ribbon.
        EnqueueReportsNos(ReportSelections.Usage::"Inventory Receipt");
        InvtReceipt.Print.Invoke;

        // [THEN] List of reports set for an item receipt is shown.
        // Verification is done in ReportSelectionPrintPageHandler
    end;

    [Test]
    [HandlerFunctions('ReportSelectionPrintPageHandler,CancelPrintPostedFacturaInvoiceARequestPageHandler,CancelPrintPostedInvShipmentTORG12RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListOfReportsIsInvokedWhenPostedSalesInvoiceIsPrinted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportSelections: Record "Report Selections";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 201939] List of reports defined in Report Selections should be shown when Print button is pushed on Posted Sales Invoice page for non-corrective invoice.
        Initialize;

        // [GIVEN] Posted sales invoice of non-corrective type.
        MockPostedSalesInvHeader(SalesInvoiceHeader, false, SalesInvoiceHeader."Corrective Doc. Type"::" ");

        // [GIVEN] Posted Sales Invoice page is opened.
        PostedSalesInvoice.OpenView;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // [WHEN] Push "Print" on the page ribbon.
        EnqueueReportsNos(ReportSelections.Usage::"S.Invoice");
        PostedSalesInvoice.Print.Invoke;

        // [THEN] List of reports set for a posted sales invoice is shown.
        // Verification is done in ReportSelectionPrintPageHandler
    end;

    [Test]
    [HandlerFunctions('PstdSalesCorrFactInvRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListOfReportsIsInvokedWhenPostedCorrSalesInvoiceIsPrinted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 201939] Corrective invoice report should be started when Print button is pushed on Posted Sales Invoice page for corrective invoice.
        Initialize;

        // [GIVEN] Posted sales invoice of corrective type.
        MockPostedSalesInvHeader(SalesInvoiceHeader, true, SalesInvoiceHeader."Corrective Doc. Type"::Correction);

        // [GIVEN] Posted Sales Invoice page is opened.
        PostedSalesInvoice.OpenView;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // [WHEN] Push "Print" on the page ribbon.
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
        PostedSalesInvoice.Print.Invoke;

        // [THEN] Corrective sales invoice report is invoked.
        // Verification is done in PstdSalesCorrFactInvRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('ReportSelectionPrintPageHandlerTORG2Only,VerifyAndCancelTORG2RequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderTorg2IsPrintedFromPurchaseOrderList()
    var
        PurchaseHeader: Record "Purchase Header";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Purchase] [Order] [UI] [TORG2]
        // [SCENARIO 221850] report "Receipt Deviations TORG-2" is printed for Purchase Order
        Initialize;

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);

        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(PurchaseHeader."Document Type");

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Order");
        ReportSelections.ModifyAll(Default, false);
        ReportSelections.SetRange("Report ID", REPORT::"Receipt Deviations TORG-2");
        ReportSelections.FindFirst;
        ReportSelections.Validate("Excel Export", true);
        ReportSelections.Validate(Default, true);
        ReportSelections.Modify(true);

        // [WHEN] Purchase Order PrintRecords function is called
        PurchaseHeader.SetRecFilter;
        PurchaseHeader.PrintRecords(true);

        // [THEN] report "Receipt Deviations TORG-2" is invoked
        // Verification is done in VerifyAndCancelTORG2RequestPageHandler

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnpostedTorg16WithItemTrackingLinesApplToEntry()
    var
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ReservationEntry: Record "Reservation Entry";
        I: Integer;
    begin
        // [FEATURE] [Shipment] [Applies-to Entry] [Item Tracking] [UT]
        // [SCENARIO 347001] Unposted TORG-16 report fills Invoice Date based on the Item Tracking Lines "Appl.-to Item Entry"

        // [GIVEN] Item Ledger Entry "ILE1" with "Posting Date" = 01.01.2020 and "Document No." = "DOC01"
        // [GIVEN] Item Ledger Entry "ILE2" with "Posting Date" = 10.01.2020 and "Document No." = "DOC02"
        for I := 1 to ArrayLen(ItemLedgerEntry) do
            MockItemLedgerEntry(
              ItemLedgerEntry[I], LibraryRandom.RandDateFromInRange(WorkDate, 10 * (I - 1), 10 * I),
              LibraryUtility.GenerateGUID, 0, LibraryUtility.GenerateGUID);

        // [GIVEN] Item Shipment with an Item Shipment Line
        MockInvtDocHeader(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment);
        MockInvtDocLine(InvtDocumentLine, InvtDocumentHeader);

        // [GIVEN] Item Tracking Line for the Item Shipment Line with "Appl.-to Item Entry" = "ILE1"
        // [GIVEN] Item Tracking Line for the Item Shipment Line with "Appl.-to Item Entry" = "ILE2"
        for I := 1 to ArrayLen(ItemLedgerEntry) do
            MockReservationEntry(ReservationEntry, InvtDocumentLine, ItemLedgerEntry[I]."Entry No.");

        // [WHEN] Run Unposted TORG-16 report for the Item Shipment
        RunUnpostedTorg16Report(InvtDocumentHeader."No.", '', '', WorkDate, '');

        // [THEN] "DeliveryDate" and "InvoiceDate" = 01.01.2020 and "InvoiceID" = "DOC01" on the first row of the report
        // [THEN] "DeliveryDate" and "InvoiceDate" = 10.01.2020 and "InvoiceID" = "DOC02" on the second row of the report
        LibraryReportValidation.OpenExcelFile;
        for I := 1 to ArrayLen(ItemLedgerEntry) do begin
            LibraryReportValidation.VerifyCellValue(26 + I - 1, 1, Format(ItemLedgerEntry[I]."Posting Date", 0, 1));
            LibraryReportValidation.VerifyCellValue(26 + I - 1, 20, ItemLedgerEntry[I]."Document No.");
            LibraryReportValidation.VerifyCellValue(26 + I - 1, 33, Format(ItemLedgerEntry[I]."Posting Date", 0, 1));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedTorg16WithItemTrackingLinesApplToEntry()
    var
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        PostedShipmentItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        InvtShipmentHeader: Record "Invt. Shipment Header";
        InvtShipmentLine: Record "Invt. Shipment Line";
        I: Integer;
    begin
        // [FEATURE] [Shipment] [Applies-to Entry] [Item Tracking] [UT]
        // [SCENARIO 347001] Posted TORG-16 report fills Invoice Date based on the Item Tracking Lines "Appl.-to Item Entry"

        // [GIVEN] Item Ledger Entry "ILE1" with "Posting Date" = 01.01.2020 and "Document No." = "DOC01"
        // [GIVEN] Item Ledger Entry "ILE2" with "Posting Date" = 10.01.2020 and "Document No." = "DOC02"
        for I := 1 to ArrayLen(ItemLedgerEntry) do
            MockItemLedgerEntry(
              ItemLedgerEntry[I], LibraryRandom.RandDateFromInRange(WorkDate, 10 * (I - 1), 10 * I),
              LibraryUtility.GenerateGUID, 0, LibraryUtility.GenerateGUID);

        // [GIVEN] Item Shipment with an Item Shipment Line
        MockInvtShipHeader(InvtShipmentHeader);
        MockInvtShipLine(InvtShipmentLine, InvtShipmentHeader);

        // [GIVEN] Posted Item Tracking Line for the Posted Item Shipment Line with "Applies-to Entry" = "ILE1"
        // [GIVEN] Posted Item Tracking Line for the Posted Item Shipment Line with "Applies-to Entry" = "ILE2"
        for I := 1 to ArrayLen(ItemLedgerEntry) do begin
            MockItemLedgerEntry(
              PostedShipmentItemLedgerEntry[I], WorkDate, InvtShipmentHeader."No.",
              ItemLedgerEntry[I]."Entry No.", ItemLedgerEntry[I]."Lot No.");
            MockValueEntryWithRelation(InvtShipmentLine, PostedShipmentItemLedgerEntry[I]."Entry No.")
        end;

        // [WHEN] Run Posted TORG-16 report for the Item Shipment
        RunPostedTorg16Report(InvtShipmentHeader."No.", '', '', WorkDate, '');

        // [THEN] "DeliveryDate" and "InvoiceDate" = 01.01.2020 and "InvoiceID" = "DOC01" on the first row of the report
        // [THEN] "DeliveryDate" and "InvoiceDate" = 10.01.2020 and "InvoiceID" = "DOC02" on the second row of the report
        LibraryReportValidation.OpenExcelFile;
        for I := 1 to ArrayLen(ItemLedgerEntry) do begin
            LibraryReportValidation.VerifyCellValue(26 + I - 1, 1, Format(ItemLedgerEntry[I]."Posting Date", 0, 1));
            LibraryReportValidation.VerifyCellValue(26 + I - 1, 20, ItemLedgerEntry[I]."Document No.");
            LibraryReportValidation.VerifyCellValue(26 + I - 1, 33, Format(ItemLedgerEntry[I]."Posting Date", 0, 1));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg16LargeItemNo()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        // [SCENARIO 359737] Torg-16 Write Off Act report should be processed with 20-symbols-length Item No.
        Initialize();

        // [GIVEN] Item shipment document and Item Document Line with 20-symbols-length Item No.
        MockInvtDocHeader(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment);
        MockInvtDocLine(InvtDocumentLine, InvtDocumentHeader);
        InvtDocumentLine."Item No." :=
            LibraryUtility.GenerateRandomCode20(InvtDocumentLine.FieldNo("Item No."), DATABASE::"Invt. Document Line");
        InvtDocumentLine.Modify();

        // [WHEN] Run 'Item Write-off act TORG-16' report 
        RunUnpostedTorg16Report(InvtDocumentHeader."No.", '', '', WorkDate(), '');

        // [THEN] Report is created without errors and contains 20-symbols-length Item No.
        LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, InvtDocumentLine."Item No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear;

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        Commit();

        IsInitialized := true;
    end;

    local procedure CreatePostItemShptDocument(PostDocument: Boolean)
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        PostedDocNo: Code[20];
        Members: array[5, 2] of Text;
        TotalQtys: array[5] of Decimal;
    begin
        Initialize;

        TotalQtys[1] := LibraryRandom.RandInt(10);
        CreateInvtDocumentWithLines(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, PostDocument, Members, TotalQtys);

        if PostDocument then begin
            PostedDocNo := PostItemDocument(InvtDocumentHeader."No.");
            RunPostedTorg16Report(PostedDocNo, '', '', WorkDate, '');
        end else
            RunUnpostedTorg16Report(InvtDocumentHeader."No.", '', '', WorkDate, '');

        TotalQtys[1] -= 1;
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(33 + (TotalQtys[1] * 2), 65, StdRepMgt.FormatReportValue(TotalQtys[2], 3));
        LibraryReportValidation.VerifyCellValue(13, 70, Format(WorkDate, 0, 1));
        LibraryReportValidation.VerifyCellValue(17, 57, Format(WorkDate, 0, 1));
        LibraryReportValidation.VerifyCellValue(26, 11, Format(WorkDate, 0, 1));

        // TODO VerifyTorg16EmployeeSignatures(Members, TotalQtys[1]);
    end;

    local procedure CreateInvtReceiptDocument(var TotalAmtQtys: array[5] of Decimal): Code[20]
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        Members: array[5, 2] of Text;
    begin
        Initialize;

        TotalAmtQtys[1] := LibraryRandom.RandInt(100);
        CreateInvtDocumentWithLines(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, false, Members, TotalAmtQtys);
        TotalAmtQtys[4] := TotalAmtQtys[3];
        TotalAmtQtys[5] := 0;
        exit(InvtDocumentHeader."No.");
    end;

    local procedure CreatePartialPostPurchDoc(var TotalQtys: array[5] of Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor);
        PurchaseHeader."Location Code" := CreateLocation;
        PurchaseHeader.Modify(true);

        CreatePurchDocLines(PurchaseHeader, TotalQtys);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateInvtDocumentLine(DocumentNo: Code[20]; DocumentType: Enum "Invt. Doc. Document Type"; PostItemDocument: Boolean; var TotalAmtQtys: array[5] of Decimal)
    var
        InvtDocumentLine: Record "Invt. Document Line";
        RecRef: RecordRef;
    begin
        with InvtDocumentLine do begin
            Init;
            "Document No." := DocumentNo;
            "Document Type" := DocumentType;
            RecRef.GetTable(InvtDocumentLine);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Insert(true);

            Validate("Item No.", LibraryInventory.CreateItemNo);
            Validate(Quantity, LibraryRandom.RandInt(100));
            Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
            Validate("Unit Amount", LibraryRandom.RandDec(100, 2));
            Modify(true);
            TotalAmtQtys[3] += Quantity;
            if PostItemDocument then
                TotalAmtQtys[2] += Amount
            else
                TotalAmtQtys[2] += Quantity * "Unit Cost";
        end;
    end;

    local procedure CreatePurchDocLines(var PurchaseHeader: Record "Purchase Header"; var TotalAmountsQty: array[3] of Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        QtyToReceive: Integer;
        QtyToInvoice: Integer;
        Counter: Integer;
    begin
        for Counter := 1 to LibraryRandom.RandIntInRange(5, 50) do begin
            Qty := LibraryRandom.RandIntInRange(5, 100);
            QtyToReceive := LibraryRandom.RandIntInRange(1, Qty);
            QtyToInvoice := LibraryRandom.RandIntInRange(1, QtyToReceive);
            with PurchaseLine do begin
                LibraryPurchase.CreatePurchaseLine(
                  PurchaseLine, PurchaseHeader, Type::Item, LibraryInventory.CreateItemNo, Qty);
                Validate("Qty. to Receive", QtyToReceive);
                Validate("Qty. to Invoice", QtyToInvoice);
                Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
                Modify(true);
                TotalAmountsQty[2] += Amount;
            end;
            TotalAmountsQty[3] += Qty;
            TotalAmountsQty[4] += Qty - QtyToReceive;
            TotalAmountsQty[5] += QtyToReceive;
        end;
        TotalAmountsQty[1] := Counter;
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure MockInvtDocHeader(var InvtDocumentHeader: Record "Invt. Document Header"; DocType: Enum "Invt. Doc. Document Type")
    begin
        with InvtDocumentHeader do begin
            Init;
            "Document Type" := DocType;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Invt. Document Header");
            Insert;
        end;
    end;

    local procedure MockInvtShipHeader(var InvtShipmentHeader: Record "Invt. Shipment Header")
    begin
        with InvtShipmentHeader do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Invt. Shipment Header");
            Insert;
        end;
    end;

    local procedure MockItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; PostingDate: Date; DocumentNo: Code[20]; AppliesToEntry: Integer; LotNo: Code[50])
    begin
        with ItemLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, FieldNo("Entry No."));
            "Posting Date" := PostingDate;
            "Document No." := DocumentNo;
            "Applies-to Entry" := AppliesToEntry;
            "Lot No." := LotNo;
            Insert;
        end;
    end;

    local procedure MockInvtDocLine(var InvtDocumentLine: Record "Invt. Document Line"; InvtDocumentHeader: Record "Invt. Document Header")
    begin
        with InvtDocumentLine do begin
            Init;
            "Document Type" := InvtDocumentHeader."Document Type";
            "Document No." := InvtDocumentHeader."No.";
            "Line No." := LibraryUtility.GetNewRecNo(InvtDocumentLine, FieldNo("Line No."));
            Insert;
        end;
    end;

    local procedure MockInvtShipLine(var InvtShipmentLine: Record "Invt. Shipment Line"; InvtShipmentHeader: Record "Invt. Shipment Header")
    begin
        with InvtShipmentLine do begin
            Init;
            "Document No." := InvtShipmentHeader."No.";
            "Line No." := LibraryUtility.GetNewRecNo(InvtShipmentLine, FieldNo("Line No."));
            Insert;
        end;
    end;

    local procedure MockValueEntryWithRelation(InvtShipmentLine: Record "Invt. Shipment Line"; ItemEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        with ValueEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, FieldNo("Entry No."));
            "Item Ledger Entry Type" := "Item Ledger Entry Type"::"Negative Adjmt.";
            "Item Ledger Entry No." := ItemEntryNo;
            "Invoiced Quantity" := LibraryRandom.RandDec(10, 2);
            Insert;
        end;

        with ValueEntryRelation do begin
            Init;
            "Value Entry No." := ValueEntry."Entry No.";
            "Source RowId" := InvtShipmentLine.RowID1;
            Insert;
        end;
    end;

    local procedure MockReservationEntry(ReservationEntry: Record "Reservation Entry"; InvtDocumentLine: Record "Invt. Document Line"; AppliesToEntry: Integer)
    begin
        with ReservationEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, FieldNo("Entry No."));
            Positive := (InvtDocumentLine."Document Type" = InvtDocumentLine."Document Type"::Receipt);
            SetSource(
              DATABASE::"Invt. Document Line",
              InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.", InvtDocumentLine."Line No.", '', 0);
            "Appl.-to Item Entry" := AppliesToEntry;
            Insert;
        end;
    end;

    local procedure MockPostedSalesInvHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; IsCorrDoc: Boolean; CorrDocType: Option)
    begin
        with SalesInvoiceHeader do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Sales Invoice Header");
            "Corrective Document" := IsCorrDoc;
            "Corrective Doc. Type" := CorrDocType;
            Insert;
        end;
    end;

    local procedure InsertDocPrintBuffer(TableID: Integer; DocType: Option; DocNo: Code[20])
    var
        DocumentPrintBuffer: Record "Document Print Buffer";
    begin
        with DocumentPrintBuffer do begin
            DeleteAll();

            Init;
            "User ID" := UserId;
            "Table ID" := TableID;
            "Document Type" := DocType;
            "Document No." := DocNo;
            Insert;
        end;
    end;

    local procedure RunUnpostedTorg16Report(ItemDocumentNo: Code[20]; OperationType: Text; OrderNo: Text; OrderDate: Date; WriteOffSource: Text)
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        ItemWriteOffActTorg16: Report "Item Write-off act TORG-16";
        FileName: Text;
    begin
        ItemWriteOffActTorg16.InitializeRequest(
          OperationType, OrderNo, OrderDate, WriteOffSource);
        LibraryReportValidation.SetFileName(ItemDocumentNo);
        FileName := LibraryReportValidation.GetFileName;
        InvtDocumentHeader.SetRange("No.", ItemDocumentNo);
        ItemWriteOffActTorg16.SetTableView(InvtDocumentHeader);
        ItemWriteOffActTorg16.SetFileNameSilent(FileName);
        ItemWriteOffActTorg16.UseRequestPage(false);
        ItemWriteOffActTorg16.Run;
    end;

    local procedure RunPostedTorg16Report(ItemShipmentNo: Code[20]; OperationType: Text; OrderNo: Text; OrderDate: Date; WriteOffSource: Text)
    var
        InvtShipmentHeader: Record "Invt. Shipment Header";
        PostedItemWriteOffActTorg16: Report "Posted Item Write-off TORG-16";
        FileName: Text;
    begin
        PostedItemWriteOffActTorg16.InitializeRequest(
          OperationType, OrderNo, OrderDate, WriteOffSource);
        LibraryReportValidation.SetFileName(ItemShipmentNo);
        FileName := LibraryReportValidation.GetFileName;
        InvtShipmentHeader.SetRange("No.", ItemShipmentNo);
        PostedItemWriteOffActTorg16.SetTableView(InvtShipmentHeader);
        PostedItemWriteOffActTorg16.SetFileNameSilent(FileName);
        PostedItemWriteOffActTorg16.UseRequestPage(false);
        PostedItemWriteOffActTorg16.Run;
    end;

    local procedure RunUnpostedTorg1Report(PurchaseDocNo: Code[20]; ShowActualQty: Boolean; ReportNo: Text; ReportDate: Date; ReportOperationType: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        ItemsReceiptActTORG1: Report "Items Receipt Act TORG-1";
        FileName: Text;
    begin
        ItemsReceiptActTORG1.InitializeRequest(
          ShowActualQty, ReportNo, ReportDate, ReportOperationType);
        LibraryReportValidation.SetFileName(PurchaseDocNo);
        FileName := LibraryReportValidation.GetFileName;
        PurchaseHeader.SetRange("No.", PurchaseDocNo);
        ItemsReceiptActTORG1.SetTableView(PurchaseHeader);
        ItemsReceiptActTORG1.SetFileNameSilent(FileName);
        ItemsReceiptActTORG1.UseRequestPage(false);
        ItemsReceiptActTORG1.Run;
    end;

    local procedure RunReceiptDeviationsTorg2Report(DocumentNo: Code[20]; OrderNo: Text; OrderDate: Date; OperationType: Text; TableId: Integer; DocumentType: Integer)
    var
        ReceiptDeviationsTORG2: Report "Receipt Deviations TORG-2";
        FileName: Text;
    begin
        ReceiptDeviationsTORG2.InitializeRequest(OrderNo, OrderDate, OperationType);
        LibraryReportValidation.SetFileName(DocumentNo);
        FileName := LibraryReportValidation.GetFileName;
        InsertDocPrintBuffer(TableId, DocumentType, DocumentNo);

        Commit();
        ReceiptDeviationsTORG2.SetFileNameSilent(FileName);
        ReceiptDeviationsTORG2.UseRequestPage(false);
        ReceiptDeviationsTORG2.Run;
    end;

    local procedure AddEmployeeSignatures(var Members: array[5, 2] of Text; ItemDocumentNo: Code[20])
    var
        CompanyInfo: Record "Company Information";
        Employee: Record Employee;
        DocSignature: Record "Document Signature";
    begin
        AddDocSignatureEmployee(ItemDocumentNo, Members, 1, DocSignature."Employee Type"::Chairman);
        AddDocSignatureEmployee(ItemDocumentNo, Members, 2, DocSignature."Employee Type"::Member1);
        AddDocSignatureEmployee(ItemDocumentNo, Members, 3, DocSignature."Employee Type"::Member2);
        AddDocSignatureEmployee(ItemDocumentNo, Members, 4, DocSignature."Employee Type"::StoredBy);

        CompanyInfo.Get();
        if not Employee.Get(CompanyInfo."Director No.") then begin
            CreateEmployee(Employee);
            CompanyInfo."Director Name" := Employee."First Name";
            CompanyInfo.Modify(true);
        end;
        Members[5, 1] := Employee.GetJobTitleName();
        Members[5, 2] := CompanyInfo."Director Name";
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        LibraryHumanResource: Codeunit "Library - Human Resource";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Job Title" := LibraryUtility.GenerateRandomCode(6, 5200);
        Employee.Modify(true);
    end;

    local procedure AddDocSignatureEmployee(DocumentNo: Code[20]; var Members: array[5, 2] of Text; MemberId: Integer; EmployeeType: Option Director,Accountant,Cashier,Responsible,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Member1,Member2,Member3,StoredBy)
    var
        DocSignature: Record "Document Signature";
        Employee: Record Employee;
    begin
        CreateEmployee(Employee);
        with DocSignature do begin
            Init;
            "Table ID" := DATABASE::"Invt. Document Header";
            "Document Type" := 1;
            "Document No." := DocumentNo;
            "Employee Type" := EmployeeType;
            "Employee Job Title" := Employee.GetJobTitleName;
            "Employee Name" := Employee.GetFullName;
            Insert(true);
            Members[MemberId, 1] := "Employee Job Title";
            Members[MemberId, 2] := "Employee Name";
        end;
    end;

    local procedure EnqueueReportsNos(DocUsage: Enum "Report Selection Usage")
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do begin
            Ascending(false);
            SetRange(Usage, DocUsage);
            FindSet();
            repeat
                LibraryVariableStorage.Enqueue("Report ID");
            until Next = 0;
        end;
    end;

    local procedure VerifyTorg16EmployeeSignatures(Members: array[5, 2] of Text; Shift: Integer)
    var
        Counter: Integer;
        RowId: Integer;
    begin
        RowId := 39 + Shift * 2;
        for Counter := 1 to 4 do begin
            LibraryReportValidation.VerifyCellValue(RowId, 21, Members[Counter, 1]);
            LibraryReportValidation.VerifyCellValue(RowId, 45, Members[Counter, 2]);
            RowId += 2;
        end;
        LibraryReportValidation.VerifyCellValue(17, 66, Members[5, 1]);
        LibraryReportValidation.VerifyCellValue(19, 71, Members[5, 2]);
    end;

    local procedure VerifyTorg1Totals(TotalAmtQtys: array[5] of Decimal)
    begin
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('CT', StdRepMgt.FormatReportValue(TotalAmtQtys[2], 3));
    end;

    local procedure VerifyTorg2Totals(StartRow: Integer; VerifyColumn: Integer; TotalQtys: array[5] of Decimal)
    var
        TotalAmountExcel: Decimal;
        FieldValue: Decimal;
        "Count": Integer;
        ExcelRowNo: Integer;
        FoundValue: Boolean;
    begin
        Count := TotalQtys[1];
        LibraryReportValidation.OpenExcelFile;
        for ExcelRowNo := StartRow to (StartRow + Count - 1) do begin
            Evaluate(FieldValue, LibraryReportValidation.GetValueAt(FoundValue, ExcelRowNo, VerifyColumn));
            TotalAmountExcel += FieldValue;
        end;

        Assert.AreEqual(TotalQtys[2], TotalAmountExcel, TotalingValueIncorrectErr);
        LibraryReportValidation.VerifyCellValue(91, 40, Format(TotalQtys[3]));
        LibraryReportValidation.VerifyCellValue(92, 40, Format(TotalQtys[4]));
        LibraryReportValidation.VerifyCellValue(93, 40, Format(TotalQtys[5]));
    end;

    local procedure FindPostedItemShpt(ItemDocumentNo: Code[20]): Code[20]
    var
        InvtShipmentHeader: Record "Invt. Shipment Header";
    begin
        InvtShipmentHeader.SetRange("Shipment No.", ItemDocumentNo);
        InvtShipmentHeader.FindFirst;
        exit(InvtShipmentHeader."No.");
    end;

    local procedure FindPostedItemRcpt(ItemDocumentNo: Code[20]): Code[20]
    var
        ItemReceiptHeader: Record "Invt. Receipt Header";
    begin
        ItemReceiptHeader.SetRange("Receipt No.", ItemDocumentNo);
        ItemReceiptHeader.FindFirst;
        exit(ItemReceiptHeader."No.");
    end;

    local procedure CreateInvtDocumentWithLines(var InvtDocumentHeader: Record "Invt. Document Header"; DocumentType: Enum "Invt. Doc. Document Type"; PostItemDocument: Boolean; var Members: array[5, 2] of Text; var TotalAmtQtys: array[5] of Decimal)
    var
        Counter: Integer;
    begin
        with InvtDocumentHeader do begin
            Init;
            "Document Type" := DocumentType;
            "Document Date" := WorkDate;
            "Posting Date" := WorkDate;
            "Location Code" := CreateLocation;
            Insert(true);
        end;
        for Counter := 1 to TotalAmtQtys[1] do
            CreateInvtDocumentLine(InvtDocumentHeader."No.", DocumentType, PostItemDocument, TotalAmtQtys);
        CODEUNIT.Run(CODEUNIT::"Release Invt. Document", InvtDocumentHeader);
        AddEmployeeSignatures(Members, InvtDocumentHeader."No.");
    end;

    local procedure PostItemDocument(DocumentNo: Code[20]) PostedDocumentNo: Code[20]
    var
        InvtDocumentHeader: Record "Invt. Document Header";
    begin
        InvtDocumentHeader.SetRange("No.", DocumentNo);
        InvtDocumentHeader.FindFirst;
        CODEUNIT.Run(CODEUNIT::"Invt. Doc.-Post (Yes/No)", InvtDocumentHeader);
        if InvtDocumentHeader."Document Type" = InvtDocumentHeader."Document Type"::Shipment then
            PostedDocumentNo := FindPostedItemShpt(InvtDocumentHeader."No.")
        else
            PostedDocumentNo := FindPostedItemRcpt(InvtDocumentHeader."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReportSelectionPrintPageHandlerTORG2Only(var ReportSelectionPrint: TestPage "Report Selection - Print")
    begin
        ReportSelectionPrint."Report ID".SetValue(REPORT::"Receipt Deviations TORG-2");
        ReportSelectionPrint.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReportSelectionPrintPageHandler(var ReportSelectionPrint: TestPage "Report Selection - Print")
    begin
        ReportSelectionPrint.Last;
        repeat
            ReportSelectionPrint."Report ID".AssertEquals(LibraryVariableStorage.DequeueInteger);
        until not ReportSelectionPrint.Previous;
        ReportSelectionPrint.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VerifyAndCancelTORG2RequestPageHandler(var ReceiptDeviationsTORG2: TestRequestPage "Receipt Deviations TORG-2")
    var
        DocumentPrintBuffer: Record "Document Print Buffer";
    begin
        DocumentPrintBuffer.SetRange("User ID", UserId);
        DocumentPrintBuffer.SetRange("Document No.", LibraryVariableStorage.DequeueText);
        DocumentPrintBuffer.SetRange("Document Type", LibraryVariableStorage.DequeueInteger);
        Assert.RecordCount(DocumentPrintBuffer, 1);
        ReceiptDeviationsTORG2.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemWriteOffActTORG16RequestPageHandler(var ItemWriteoffactTORG16: TestRequestPage "Item Write-off act TORG-16")
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText, ItemWriteoffactTORG16.InvtDocHeader.GetFilter("No."),
          'TORG-16 report is not invoked correctly.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PstdSalesCorrFactInvRequestPageHandler(var PstdSalesCorrFactInv: TestRequestPage "Pstd. Sales Corr. Fact. Inv.")
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText, PstdSalesCorrFactInv.Header.GetFilter("No."),
          'Corrective invoice report is not invoked correctly.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CancelPrintActItemsReceiptM7RequestPageHandler(var ActItemsReceiptM7: TestRequestPage "Act Items Receipt M-7")
    begin
        ActItemsReceiptM7.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CancelPrintPostedFacturaInvoiceARequestPageHandler(var PostedFacturaInvoiceA: TestRequestPage "Posted Factura-Invoice (A)")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CancelPrintPostedInvShipmentTORG12RequestPageHandler(var PostedInvShipmentTORG12: TestRequestPage "Posted Inv. Shipment TORG-12")
    begin
    end;
}


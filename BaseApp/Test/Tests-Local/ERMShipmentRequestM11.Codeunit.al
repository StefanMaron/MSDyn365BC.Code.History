codeunit 144705 "ERM Shipment Request M-11"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        IncorrectDimValueErr: Label 'Incorrect Dimension Value in %1';

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferOrderDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM11TransferOrder(1);

        LibraryReportValidation.VerifyCellValue(4, 47, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferOrderQuantity()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11TransferOrder(LineQty);

        LibraryReportValidation.VerifyCellValue(23 + LineQty, 50, GetTransferOrderQuantity(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferOrderAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11TransferOrder(LineQty);
        LibraryReportValidation.VerifyCellValue(23 + LineQty, 68, GetTransferOrderAmount(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferShipmentDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM11TransferShipment(1);

        LibraryReportValidation.VerifyCellValue(4, 47, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferShipmentQuantity()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11TransferShipment(LineQty);

        LibraryReportValidation.VerifyCellValue(23 + LineQty, 50, GetTransferShipmentQuantity(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferShipmentAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11TransferShipment(LineQty);

        LibraryReportValidation.VerifyCellValue(23 + LineQty, 68, GetTransferShipmentAmount(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferReceiptDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM11TransferReceipt(1);

        LibraryReportValidation.VerifyCellValue(4, 47, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferReceiptQuantity()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11TransferReceipt(LineQty);

        LibraryReportValidation.VerifyCellValue(23 + LineQty, 50, GetTransferReceiptQuantity(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferReceiptAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11TransferReceipt(LineQty);

        LibraryReportValidation.VerifyCellValue(23 + LineQty, 68, GetTransferReceiptAmount(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_ItemReclassJnlDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM11ItemReclassJnl(1);

        LibraryReportValidation.VerifyCellValue(4, 47, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_ItemReclassJnlQuantity()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11ItemReclassJnl(LineQty);

        LibraryReportValidation.VerifyCellValue(23 + LineQty * 2 - 1, 50, GetItemReclassJnlQuantity(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_ItemReclassJnlAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        DocumentNo := PrintM11ItemReclassJnl(LineQty);

        LibraryReportValidation.VerifyCellValue(23 + LineQty * 2 - 1, 68, GetItemReclassJnlAmount(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderCorrAccDimensionUT()
    begin
        // Verify selected dimension is added to buffer line for the same line dimension
        CheckDimensionInTransferOrder(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderAnotherCorrAccDimensionUT()
    begin
        // Verify selected dimension is not filled in when it does not match line dimension
        CheckDimensionInTransferOrder(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipmentCorrAccDimensionUT()
    begin
        // Verify selected dimension is added to buffer line for the same line dimension
        CheckDimensionInTransferShipment(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipmentAnotherCorrAccDimensionUT()
    begin
        // Verify selected dimension is not filled in when it does not match line dimension
        CheckDimensionInTransferShipment(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferReceiptCorrAccDimensionUT()
    begin
        // Verify selected dimension is added to buffer line for the same line dimension
        CheckDimensionInTransferReceipt(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferReceiptAnotherCorrAccDimensionUT()
    begin
        // Verify selected dimension is not filled in when it does not match line dimension
        CheckDimensionInTransferReceipt(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItenJnlLineCorrAccDimensionUT()
    begin
        // Verify selected dimension is added to buffer line for the same line dimension
        CheckDimensionInItemJnlLine(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItenJnlLineCorrAnotherAccDimensionUT()
    begin
        // Verify selected dimension is not filled in when it does not match line dimension
        CheckDimensionInItemJnlLine(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M11_TransferOrder19LineNotMiss()
    var
        ItemNo: array[22] of Code[20];
    begin
        // [SCENARIO 431489] M-11 report lost a line on print form
        // [GIVEN] Transfer Order with 22 lines
        // [WHEN] Print M-11 Report for Transfer Order
        PrintM11ItemReclassJnlItemNo(22, ItemNo);
        // [THEN] Line 19 with Item[19] should exists on the report
        LibraryReportValidation.VerifyCellValue(48, 29, ItemNo[19]);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure PrintM11TransferOrder(LineQty: Integer): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        ShipmentRequestM11: Report "Shipment Request M-11";
        ItemNo: array[5] of Code[20];
        Qty: array[5] of Decimal;
        i: Integer;
    begin
        Initialize();

        for i := 1 to LineQty do begin
            ItemNo[i] := LibraryRUReports.CreateItemWithCost();
            Qty[i] := LibraryRandom.RandDecInRange(5, 10, 2);
        end;
        CreateTransferOrder(TransferHeader, LibraryRUReports.CreateLocation(false), ItemNo, Qty, LineQty);

        TransferHeader.SetRange("No.", TransferHeader."No.");
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ShipmentRequestM11.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ShipmentRequestM11.SetTableView(TransferHeader);
        ShipmentRequestM11.UseRequestPage(false);
        ShipmentRequestM11.Run();

        exit(TransferHeader."No.");
    end;

    local procedure PrintM11TransferShipment(LineQty: Integer): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        ShipmentRequestM11: Report "Shipment Request M-11";
        FromLocationCode: Code[10];
        ItemNo: array[5] of Code[20];
        Qty: array[5] of Decimal;
    begin
        Initialize();

        FromLocationCode := InitItemInventory(ItemNo, Qty, LineQty);

        CreatePostTransferOrder(TransferHeader, FromLocationCode, ItemNo, Qty, LineQty, true, false);

        TransferShipmentHeader.SetRange("Transfer-from Code", FromLocationCode);
        TransferShipmentHeader.FindFirst();

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ShipmentRequestM11.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ShipmentRequestM11.SetTableView(TransferShipmentHeader);
        ShipmentRequestM11.UseRequestPage(false);
        ShipmentRequestM11.Run();

        exit(TransferShipmentHeader."No.");
    end;

    local procedure PrintM11TransferReceipt(LineQty: Integer): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        ShipmentRequestM11: Report "Shipment Request M-11";
        FromLocationCode: Code[10];
        ItemNo: array[5] of Code[20];
        Qty: array[5] of Decimal;
    begin
        Initialize();

        FromLocationCode := InitItemInventory(ItemNo, Qty, LineQty);

        CreatePostTransferOrder(TransferHeader, FromLocationCode, ItemNo, Qty, LineQty, true, true);

        TransferReceiptHeader.SetRange("Transfer-from Code", FromLocationCode);
        TransferReceiptHeader.FindFirst();

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ShipmentRequestM11.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ShipmentRequestM11.SetTableView(TransferReceiptHeader);
        ShipmentRequestM11.UseRequestPage(false);
        ShipmentRequestM11.Run();

        exit(TransferReceiptHeader."No.");
    end;

    local procedure PrintM11ItemReclassJnl(LineQty: Integer): Code[20]
    var
        ItemNo: array[22] of Code[20];
    begin
        exit(PrintM11ItemReclassJnlItemNo(LineQty, ItemNo))
    end;

    local procedure PrintM11ItemReclassJnlItemNo(LineQty: Integer; ItemNo: Array[22] of Code[20]) DocumentNo: Code[20]
    var
        ItemJnlLine: Record "Item Journal Line";
        ShipmentRequestM11: Report "Shipment Request M-11";
        Qty: array[22] of Decimal;
        i: Integer;
    begin
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();

        for i := 1 to LineQty do begin
            ItemNo[i] := LibraryRUReports.CreateItemWithCost();
            Qty[i] := LibraryRandom.RandDecInRange(5, 10, 2);
            CreateReclassItemJournalLine(DocumentNo, ItemNo[i], Qty[i], i = 1);
        end;

        ItemJnlLine.SetRange("Document No.", DocumentNo);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ShipmentRequestM11.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ShipmentRequestM11.SetTableView(ItemJnlLine);
        ShipmentRequestM11.UseRequestPage(false);
        ShipmentRequestM11.Run();
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ItemNo: array[3] of Code[20]; Quantity: array[3] of Decimal; LineQty: Integer)
    var
        TransferLine: Record "Transfer Line";
        i: Integer;
    begin
        LibraryInventory.CreateTransferHeader(
          TransferHeader, FromLocationCode,
          LibraryRUReports.CreateLocation(false), LibraryRUReports.CreateLocation(true));

        for i := 1 to LineQty do
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo[i], Quantity[i]);
    end;

    local procedure CreatePostTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ItemNo: array[3] of Code[20]; Quantity: array[3] of Decimal; LineQty: Integer; Ship: Boolean; Receive: Boolean)
    begin
        CreateTransferOrder(TransferHeader, FromLocationCode, ItemNo, Quantity, LineQty);
        LibraryInventory.PostTransferHeader(TransferHeader, Ship, Receive);
    end;

    local procedure InitItemInventory(var ItemNo: array[5] of Code[20]; var Qty: array[5] of Decimal; LineQty: Integer) FromLocationCode: Code[10]
    var
        i: Integer;
    begin
        FromLocationCode := LibraryRUReports.CreateLocation(false);
        for i := 1 to LineQty do begin
            ItemNo[i] := LibraryRUReports.CreateItemWithCost();
            Qty[i] := LibraryRandom.RandDecInRange(5, 10, 2);
            LibraryRUReports.CreateAndPostItemJournalLine(FromLocationCode, ItemNo[i], Qty[i], i = 1);
        end;
    end;

    local procedure CreateReclassItemJournalLine(DocumentNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; ClearJnl: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        Item: Record Item;
    begin
        LibraryRUReports.InitItemJournalLine(ItemJnlLine, ItemJournalTemplate.Type::Transfer, ClearJnl);

        with ItemJnlLine do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJnlLine, "Journal Template Name", "Journal Batch Name", "Entry Type"::Transfer, ItemNo, 0);
            Validate("Document No.", DocumentNo);
            Validate("Location Code", LibraryRUReports.CreateLocation(false));
            Validate("New Location Code", LibraryRUReports.CreateLocation(false));
            Validate(Quantity, Qty);
            Item.Get(ItemNo);
            Validate("Unit Cost", Item."Unit Cost");
            Modify(true);
        end;
    end;

    local procedure GetTransferOrderQuantity(DocumentNo: Code[20]): Text
    var
        TransferLine: Record "Transfer Line";
    begin
        with TransferLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            exit(Format(Quantity));
        end;
    end;

    local procedure GetTransferOrderAmount(DocumentNo: Code[20]): Text
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        with TransferLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            Item.Get("Item No.");
            exit(Format(Round(Quantity * Item."Unit Cost")));
        end;
    end;

    local procedure GetTransferShipmentQuantity(DocumentNo: Code[20]): Text
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        with TransferShipmentLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            exit(Format(Quantity));
        end;
    end;

    local procedure GetTransferShipmentAmount(DocumentNo: Code[20]): Text
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
        Item: Record Item;
    begin
        with TransferShipmentLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            Item.Get("Item No.");
            exit(Format(Round(Quantity * Item."Unit Cost")));
        end;
    end;

    local procedure GetTransferReceiptQuantity(DocumentNo: Code[20]): Text
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        with TransferReceiptLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            exit(Format(Quantity));
        end;
    end;

    local procedure GetTransferReceiptAmount(DocumentNo: Code[20]): Text
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
        Item: Record Item;
    begin
        with TransferReceiptLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            Item.Get("Item No.");
            exit(Format(Round(Quantity * Item."Unit Cost")));
        end;
    end;

    local procedure GetItemReclassJnlQuantity(DocumentNo: Code[20]): Text
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        with ItemJnlLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            exit(Format(Quantity));
        end;
    end;

    local procedure GetItemReclassJnlAmount(DocumentNo: Code[20]): Text
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        with ItemJnlLine do begin
            SetRange("Document No.", DocumentNo);
            FindLast();
            Item.Get("Item No.");
            exit(Format(Round(Quantity * Item."Unit Cost")));
        end;
    end;

    local procedure CheckDimensionInTransferOrder(AnotherDimValue: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        LineBuffer: Record "Item Journal Line" temporary;
        DimensionValue: Record "Dimension Value";
        ShipmentRequestM11Report: Report "Shipment Request M-11";
    begin
        Initialize();

        CreateTransferOrderWithDimension(TransferHeader, DimensionValue);
        AssignReportAndExpectedDimValues(DimensionValue, AnotherDimValue);

        ShipmentRequestM11Report.InitializeRequest('', '', '', DimensionValue."Dimension Code", '', '', '', false, 0);
        ShipmentRequestM11Report.CopyFromTransferHeader(TransferHeader, LineBuffer);

        Assert.AreEqual(
          DimensionValue.Code, LineBuffer."Shortcut Dimension 2 Code",
          StrSubstNo(IncorrectDimValueErr, TransferHeader.TableCaption()));
    end;

    local procedure CheckDimensionInTransferShipment(AnotherDimValue: Boolean)
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        LineBuffer: Record "Item Journal Line" temporary;
        DimensionValue: Record "Dimension Value";
        ShipmentRequestM11Report: Report "Shipment Request M-11";
    begin
        Initialize();

        CreateTransferShipmentWithDimension(TransferShipmentHeader, DimensionValue);
        AssignReportAndExpectedDimValues(DimensionValue, AnotherDimValue);

        ShipmentRequestM11Report.InitializeRequest('', '', '', DimensionValue."Dimension Code", '', '', '', false, 0);
        ShipmentRequestM11Report.CopyFromTransferShipmentHeader(TransferShipmentHeader, LineBuffer);

        Assert.AreEqual(
          DimensionValue.Code, LineBuffer."Shortcut Dimension 2 Code",
          StrSubstNo(IncorrectDimValueErr, TransferShipmentHeader.TableCaption()));
    end;

    local procedure CheckDimensionInTransferReceipt(AnotherDimValue: Boolean)
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        LineBuffer: Record "Item Journal Line" temporary;
        DimensionValue: Record "Dimension Value";
        ShipmentRequestM11Report: Report "Shipment Request M-11";
    begin
        Initialize();

        CreateTransferReceiptWithDimension(TransferReceiptHeader, DimensionValue);
        AssignReportAndExpectedDimValues(DimensionValue, AnotherDimValue);

        ShipmentRequestM11Report.InitializeRequest('', '', '', DimensionValue."Dimension Code", '', '', '', false, 0);
        ShipmentRequestM11Report.CopyFromTransferReceiptHeader(TransferReceiptHeader, LineBuffer);

        Assert.AreEqual(
          DimensionValue.Code, LineBuffer."Shortcut Dimension 2 Code",
          StrSubstNo(IncorrectDimValueErr, TransferReceiptHeader.TableCaption()));
    end;

    local procedure CheckDimensionInItemJnlLine(AnotherDimValue: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        LineBuffer: Record "Item Journal Line" temporary;
        DimensionValue: Record "Dimension Value";
        ShipmentRequestM11Report: Report "Shipment Request M-11";
    begin
        Initialize();

        CreateItemJnlLineWithDimension(ItemJnlLine, DimensionValue);
        AssignReportAndExpectedDimValues(DimensionValue, AnotherDimValue);

        ShipmentRequestM11Report.InitializeRequest('', '', '', DimensionValue."Dimension Code", '', '', '', false, 0);
        ShipmentRequestM11Report.CopyFromItemJournalLine(ItemJnlLine, LineBuffer);

        Assert.AreEqual(
          DimensionValue.Code, LineBuffer."Shortcut Dimension 2 Code",
          StrSubstNo(IncorrectDimValueErr, ItemJnlLine.TableCaption()));
    end;

    local procedure CreateTransferOrderWithDimension(var TransferHeader: Record "Transfer Header"; var DimensionValue: Record "Dimension Value")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferHeader."No." := LibraryUtility.GenerateGUID();
        TransferHeader.Insert();
        TransferHeader.SetRange("No.", TransferHeader."No.");

        CreateDimValue(DimensionValue);

        with TransferLine do begin
            "Document No." := TransferHeader."No.";
            "Item No." := LibraryRUReports.CreateItemWithCost();
            "Dimension Set ID" := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);
            Insert();
        end;
    end;

    local procedure CreateTransferShipmentWithDimension(var TransferShipmentHeader: Record "Transfer Shipment Header"; var DimensionValue: Record "Dimension Value")
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentHeader."No." := LibraryUtility.GenerateGUID();
        TransferShipmentHeader.Insert();
        TransferShipmentHeader.SetRange("No.", TransferShipmentHeader."No.");

        CreateDimValue(DimensionValue);

        with TransferShipmentLine do begin
            "Document No." := TransferShipmentHeader."No.";
            "Item No." := LibraryRUReports.CreateItemWithCost();
            "Dimension Set ID" := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);
            Insert();
        end;
    end;

    local procedure CreateTransferReceiptWithDimension(var TransferReceiptHeader: Record "Transfer Receipt Header"; var DimensionValue: Record "Dimension Value")
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptHeader."No." := LibraryUtility.GenerateGUID();
        TransferReceiptHeader.Insert();
        TransferReceiptHeader.SetRange("No.", TransferReceiptHeader."No.");

        CreateDimValue(DimensionValue);

        with TransferReceiptLine do begin
            "Document No." := TransferReceiptHeader."No.";
            "Item No." := LibraryRUReports.CreateItemWithCost();
            "Dimension Set ID" := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);
            Insert();
        end;
    end;

    local procedure CreateItemJnlLineWithDimension(var ItemJnlLine: Record "Item Journal Line"; var DimensionValue: Record "Dimension Value")
    begin
        CreateDimValue(DimensionValue);

        with ItemJnlLine do begin
            "Journal Template Name" := LibraryUtility.GenerateGUID();
            "Item No." := LibraryRUReports.CreateItemWithCost();
            "Dimension Set ID" := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);
            Insert();
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", '');
        end;
    end;

    local procedure CreateDimValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure AssignReportAndExpectedDimValues(var DimensionValue: Record "Dimension Value"; AnotherDimValue: Boolean)
    var
        Dimension: Record Dimension;
    begin
        if not AnotherDimValue then
            exit;

        Dimension.SetFilter(Code, '<>%1', DimensionValue."Dimension Code");
        Dimension.FindFirst();
        DimensionValue."Dimension Code" := Dimension.Code;
        DimensionValue.Code := '';
    end;
}


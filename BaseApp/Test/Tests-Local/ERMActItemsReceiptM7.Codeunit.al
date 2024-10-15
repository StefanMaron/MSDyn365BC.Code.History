codeunit 144708 "ERM Act Items Receipt M-7"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;
        ValueNotExistErr: Label 'Value %1 does not exist on worksheet %2';

    [Test]
    [Scope('OnPrem')]
    procedure M7_PurchaseOrderDocumentNo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PrintM7PurchOrder(PurchaseHeader, 1);

        LibraryReportValidation.VerifyCellValue(12, 19, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_PurchaseOrderAmounts()
    var
        PurchaseHeader: Record "Purchase Header";
        AmountArr: array[5] of Decimal;
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, ArrayLen(AmountArr));
        PrintM7PurchOrder(PurchaseHeader, LineQty);

        GetPurchaseLineAmounts(AmountArr, PurchaseHeader."No.");
        VerifyLineAmounts(AmountArr, LineQty, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemDocumentReceiptDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM7ItemDocumentReceipt(1);

        LibraryReportValidation.VerifyCellValue(12, 19, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemDocumentReceiptAmounts()
    var
        DocumentNo: Code[20];
        AmountArr: array[5] of Decimal;
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, ArrayLen(AmountArr));
        DocumentNo := PrintM7ItemDocumentReceipt(LineQty);

        GetDocumentLineAmounts(AmountArr, DocumentNo);
        VerifyLineAmounts(AmountArr, LineQty, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemReceiptDocumentNo()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := PrintM7ItemReceipt(1);

        LibraryReportValidation.VerifyCellValue(12, 19, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M7_ItemReceiptAmounts()
    var
        DocumentNo: Code[20];
        AmountArr: array[5] of Decimal;
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandIntInRange(2, ArrayLen(AmountArr));
        DocumentNo := PrintM7ItemReceipt(LineQty);

        GetReceiptLineAmounts(AmountArr, DocumentNo);
        VerifyLineAmounts(AmountArr, LineQty, 3);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;

        isInitialized := true;
        Commit;
    end;

    local procedure PrintM7PurchOrder(var PurchaseHeader: Record "Purchase Header"; LineQty: Integer)
    var
        ActItemsReceiptM7: Report "Act Items Receipt M-7";
    begin
        Initialize;

        CreatePurchDocument(PurchaseHeader, LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        PurchaseHeader.SetRecFilter;
        ActItemsReceiptM7.SetTableView(PurchaseHeader);
        ActItemsReceiptM7.SetFileNameSilent(LibraryReportValidation.GetFileName);
        ActItemsReceiptM7.UseRequestPage(false);
        ActItemsReceiptM7.Run;
    end;

    local procedure PrintM7ItemDocumentReceipt(LineQty: Integer): Code[20]
    var
        ItemDocumentHeader: Record "Item Document Header";
        ActItemsReceiptM7: Report "Act Items Receipt M-7";
    begin
        Initialize;

        CreateItemDocumentReceipt(ItemDocumentHeader, LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        ItemDocumentHeader.SetRecFilter;
        ActItemsReceiptM7.SetTableView(ItemDocumentHeader);
        ActItemsReceiptM7.SetFileNameSilent(LibraryReportValidation.GetFileName);
        ActItemsReceiptM7.UseRequestPage(false);
        ActItemsReceiptM7.Run;

        exit(ItemDocumentHeader."No.");
    end;

    local procedure PrintM7ItemReceipt(LineQty: Integer) DocumentNo: Code[20]
    var
        ItemReceiptHeader: Record "Item Receipt Header";
        ActItemsReceiptM7: Report "Act Items Receipt M-7";
    begin
        Initialize;

        DocumentNo := CreateAndPostItemDocument(LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        ItemReceiptHeader.SetRange("No.", DocumentNo);
        ActItemsReceiptM7.SetTableView(ItemReceiptHeader);
        ActItemsReceiptM7.SetFileNameSilent(LibraryReportValidation.GetFileName);
        ActItemsReceiptM7.UseRequestPage(false);
        ActItemsReceiptM7.Run;
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; LineQty: Integer)
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", CreateLocation);
        PurchaseHeader.Modify(true);

        for i := 1 to LineQty do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
              LibraryInventory.CreateItemNo, LibraryRandom.RandDecInRange(5, 10, 2));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure CreateAndPostItemDocument(LineQty: Integer): Code[20]
    var
        ItemDocumentHeader: Record "Item Document Header";
    begin
        CreateItemDocumentReceipt(ItemDocumentHeader, LineQty);

        CODEUNIT.Run(CODEUNIT::"Item Doc.-Post Receipt", ItemDocumentHeader);

        exit(ItemDocumentHeader."Posting No.");
    end;

    local procedure CreateItemDocumentReceipt(var ItemDocumentHeader: Record "Item Document Header"; LineQty: Integer)
    var
        i: Integer;
    begin
        with ItemDocumentHeader do begin
            Init;
            "Document Type" := "Document Type"::Receipt;
            Validate("Location Code", CreateLocation);
            Insert(true);
        end;

        for i := 1 to LineQty do
            CreateItemDocumentLine(ItemDocumentHeader);
    end;

    local procedure CreateItemDocumentLine(var ItemDocumentHeader: Record "Item Document Header")
    var
        ItemDocumentLine: Record "Item Document Line";
        RecRef: RecordRef;
    begin
        with ItemDocumentLine do begin
            Init;
            Validate("Document Type", ItemDocumentHeader."Document Type");
            Validate("Document No.", ItemDocumentHeader."No.");
            RecRef.GetTable(ItemDocumentLine);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Validate("Item No.", LibraryInventory.CreateItemNo);
            Validate(Quantity, LibraryRandom.RandDecInRange(5, 10, 2));
            Validate("Unit Amount", LibraryRandom.RandDecInRange(10, 100, 2));
            Insert(true);
        end;
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure GetPurchaseLineAmounts(var AmountArr: array[5] of Decimal; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        with PurchaseLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange("Document No.", DocumentNo);
            FindSet;
            repeat
                i += 1;
                AmountArr[i] := Amount;
            until Next = 0;
        end;
    end;

    local procedure GetDocumentLineAmounts(var AmountArr: array[5] of Decimal; DocumentNo: Code[20])
    var
        ItemDocumentLine: Record "Item Document Line";
        i: Integer;
    begin
        with ItemDocumentLine do begin
            SetRange("Document Type", "Document Type"::Receipt);
            SetRange("Document No.", DocumentNo);
            FindSet;
            repeat
                i += 1;
                AmountArr[i] := Amount;
            until Next = 0;
        end;
    end;

    local procedure GetReceiptLineAmounts(var AmountArr: array[5] of Decimal; DocumentNo: Code[20])
    var
        ItemReceiptLine: Record "Item Receipt Line";
        i: Integer;
    begin
        with ItemReceiptLine do begin
            SetRange("Document No.", DocumentNo);
            FindSet;
            repeat
                i += 1;
                AmountArr[i] := Amount;
            until Next = 0;
        end;
    end;

    local procedure VerifyLineAmounts(AmountArr: array[5] of Decimal; LineQty: Integer; WorksheetNo: Integer)
    var
        i: Integer;
    begin
        for i := 1 to LineQty do
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(
                WorksheetNo, Format(AmountArr[i])), StrSubstNo(ValueNotExistErr, Format(AmountArr[i]), WorksheetNo));
    end;
}


codeunit 7380 "Phys. Invt. Count.-Management"
{

    trigger OnRun()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
    begin
        with Item do begin
            SetFilter("Phys Invt Counting Period Code", '<>''''');
            SetFilter("Next Counting Start Date", '<>%1', 0D);
            SetFilter("Next Counting End Date", '<>%1', 0D);
            OnRunOnAfterSetItemFilters(Item, SourceJnl);
            if Find('-') then
                repeat
                    if ("Last Counting Period Update" < "Next Counting Start Date") and
                       (WorkDate >= "Next Counting Start Date")
                    then
                        InsertTempPhysCountBuffer(
                          "No.", '', '', "Shelf No.", "Phys Invt Counting Period Code",
                          Description, "Next Counting Start Date", "Next Counting End Date", "Last Counting Period Update", 1);
                until Next = 0;
        end;

        with SKU do begin
            SetFilter("Phys Invt Counting Period Code", '<>''''');
            SetFilter("Next Counting Start Date", '<>%1', 0D);
            SetFilter("Next Counting End Date", '<>%1', 0D);
            if SourceJnl = SourceJnl::WhseJnl then
                SetRange("Location Code", WhseJnlLine."Location Code");
            OnRunOnAfterSetSKUFilters(SKU, SourceJnl);
            if Find('-') then
                repeat
                    if ("Last Counting Period Update" < "Next Counting Start Date") and
                       (WorkDate >= "Next Counting Start Date")
                    then
                        InsertTempPhysCountBuffer(
                          "Item No.", "Variant Code", "Location Code",
                          "Shelf No.", "Phys Invt Counting Period Code", Description,
                          "Next Counting Start Date", "Next Counting End Date", "Last Counting Period Update", 2);

                until Next = 0;
        end;

        if PAGE.RunModal(
             PAGE::"Phys. Invt. Item Selection", TempPhysInvtItemSelection) <> ACTION::LookupOK
        then
            exit;

        TempPhysInvtItemSelection.SetRange(Selected, true);
        if TempPhysInvtItemSelection.Find('-') then
            case SourceJnl of
                SourceJnl::PhysInvtOrder:
                    CreatePhysInvtOrderLines;
                SourceJnl::ItemJnl:
                    CreatePhysInvtItemJnl;
                SourceJnl::WhseJnl:
                    CreatePhysInvtWhseJnl;
                SourceJnl::Custom:
                    OnCreateCustomPhysInvtJournal(TempPhysInvtItemSelection, SortingMethod, HideValidationDialog);
            end;
    end;

    var
        TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary;
        PhysInvtCount: Record "Phys. Invt. Counting Period";
        ItemJnlLine: Record "Item Journal Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        TempItem: Record Item temporary;
        TempSKU: Record "Stockkeeping Unit" temporary;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        SourceJnl: Option ItemJnl,WhseJnl,PhysInvtOrder,Custom;
        Text000: Label 'Processing items    #1##########';
        SortingMethod: Option " ",Item,Bin;
        Text001: Label 'Do you want to update the Next Counting Period of the %1?';
        Text002: Label 'Cancelled.';
        HideValidationDialog: Boolean;

    local procedure InsertTempPhysCountBuffer(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ShelfBin: Code[10]; PhysInvtCountCode: Code[10]; Description: Text[100]; CountingPeriodStartDate: Date; CountingPeriodEndDate: Date; LastCountDate: Date; SourceType: Option Item,SKU)
    begin
        TempPhysInvtItemSelection.Init();
        TempPhysInvtItemSelection."Item No." := ItemNo;
        TempPhysInvtItemSelection."Variant Code" := VariantCode;
        TempPhysInvtItemSelection."Location Code" := LocationCode;
        TempPhysInvtItemSelection."Phys Invt Counting Period Code" := PhysInvtCountCode;
        TempPhysInvtItemSelection."Phys Invt Counting Period Type" := SourceType;
        TempPhysInvtItemSelection."Shelf No." := ShelfBin;
        TempPhysInvtItemSelection."Last Counting Date" := LastCountDate;
        TempPhysInvtItemSelection."Next Counting Start Date" := CountingPeriodStartDate;
        TempPhysInvtItemSelection."Next Counting End Date" := CountingPeriodEndDate;
        GetPhysInvtCount(PhysInvtCountCode);
        TempPhysInvtItemSelection."Count Frequency per Year" := PhysInvtCount."Count Frequency per Year";
        TempPhysInvtItemSelection.Description := Description;
        if TempPhysInvtItemSelection.Insert() then;
    end;

    local procedure CreatePhysInvtItemJnl()
    var
        ItemJnlBatch: Record "Item Journal Batch";
        CalculatePhysInvtCounting: Report "Calculate Phys. Invt. Counting";
        Window: Dialog;
        PostingDate: Date;
        DocNo: Code[20];
        PrintDoc: Boolean;
        PrintDocPerItem: Boolean;
        ZeroQty: Boolean;
        PrintQtyCalculated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePhysInvtItemJnl(ItemJnlLine, TempPhysInvtItemSelection, IsHandled);
        if IsHandled then
            exit;

        ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
        CalculatePhysInvtCounting.SetItemJnlLine(ItemJnlBatch);
        CalculatePhysInvtCounting.RunModal;

        if CalculatePhysInvtCounting.GetRequest(
             PostingDate, DocNo, SortingMethod, PrintDoc, PrintDocPerItem, ZeroQty, PrintQtyCalculated)
        then begin
            Window.Open(Text000, TempPhysInvtItemSelection."Item No.");
            repeat
                Window.Update;
                IsHandled := false;
                OnBeforeCalcInvtQtyOnHand(DocNo, PostingDate, ZeroQty, TempPhysInvtItemSelection, IsHandled);
                if not IsHandled then
                    CalcInvtQtyOnHand(DocNo, PostingDate, ZeroQty, TempPhysInvtItemSelection);
            until TempPhysInvtItemSelection.Next = 0;
            Window.Close;

            if PrintDoc then begin
                OnBeforePrintPhysInvtList(ItemJnlBatch, PrintQtyCalculated, TempPhysInvtItemSelection, IsHandled);
                if not IsHandled then
                    PrintPhysInvtList(ItemJnlBatch, PrintQtyCalculated, PrintDocPerItem, TempPhysInvtItemSelection);
            end;
        end;
    end;

    local procedure CreatePhysInvtWhseJnl()
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        CalculatePhysInvtCounting: Report "Calculate Phys. Invt. Counting";
        Window: Dialog;
        PostingDate: Date;
        DocNo: Code[20];
        PrintDoc: Boolean;
        PrintDocPerItem: Boolean;
        ZeroQty: Boolean;
        PrintQtyCalculated: Boolean;
        IsHandled: Boolean;
    begin
        WhseJnlBatch.Get(
          WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
        CalculatePhysInvtCounting.SetWhseJnlLine(WhseJnlBatch);
        CalculatePhysInvtCounting.RunModal;

        if CalculatePhysInvtCounting.GetRequest(
             PostingDate, DocNo, SortingMethod, PrintDoc, PrintDocPerItem, ZeroQty, PrintQtyCalculated)
        then begin
            Window.Open(Text000, TempPhysInvtItemSelection."Item No.");
            repeat
                Window.Update;
                IsHandled := false;
                OnBeforeCalcWhseQtyOnHand(DocNo, PostingDate, ZeroQty, TempPhysInvtItemSelection, IsHandled);
                if not IsHandled then
                    CalcWhseQtyOnHand(DocNo, PostingDate, ZeroQty, TempPhysInvtItemSelection);
            until TempPhysInvtItemSelection.Next = 0;
            Window.Close;

            if PrintDoc then begin
                IsHandled := false;
                OnBeforePrintWhseInvtList(WhseJnlBatch, PrintQtyCalculated, TempPhysInvtItemSelection, IsHandled);
                if not IsHandled then
                    PrintWhseInvtList(WhseJnlBatch, PrintQtyCalculated, PrintDocPerItem, TempPhysInvtItemSelection);
            end;
        end;
    end;

    local procedure CalcInvtQtyOnHand(DocNo: Code[20]; PostingDate: Date; ZeroQty: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary)
    var
        Item: Record Item;
        CalculateInventory: Report "Calculate Inventory";
    begin
        CalculateInventory.SetSkipDim(true);
        CalculateInventory.InitializeRequest(PostingDate, DocNo, ZeroQty, false);
        CalculateInventory.SetItemJnlLine(ItemJnlLine);
        CalculateInventory.InitializePhysInvtCount(
          TempPhysInvtItemSelection."Phys Invt Counting Period Code",
          TempPhysInvtItemSelection."Phys Invt Counting Period Type");
        CalculateInventory.UseRequestPage(false);
        CalculateInventory.SetHideValidationDialog(true);
        Item.SetRange("No.", TempPhysInvtItemSelection."Item No.");
        if TempPhysInvtItemSelection."Phys Invt Counting Period Type" =
           TempPhysInvtItemSelection."Phys Invt Counting Period Type"::SKU
        then begin
            Item.SetRange("Variant Filter", TempPhysInvtItemSelection."Variant Code");
            Item.SetRange("Location Filter", TempPhysInvtItemSelection."Location Code");
        end;
        CalculateInventory.SetTableView(Item);
        CalculateInventory.RunModal;
        Clear(CalculateInventory);
    end;

    local procedure CalcWhseQtyOnHand(DocNo: Code[20]; PostingDate: Date; ZeroQty: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary)
    var
        BinContent: Record "Bin Content";
        WhseCalculateInventory: Report "Whse. Calculate Inventory";
    begin
        WhseCalculateInventory.InitializeRequest(PostingDate, DocNo, ZeroQty);
        WhseCalculateInventory.InitializePhysInvtCount(
          TempPhysInvtItemSelection."Phys Invt Counting Period Code",
          TempPhysInvtItemSelection."Phys Invt Counting Period Type");
        WhseCalculateInventory.SetWhseJnlLine(WhseJnlLine);
        WhseCalculateInventory.UseRequestPage(false);
        WhseCalculateInventory.SetHideValidationDialog(true);
        BinContent.SetRange("Location Code", TempPhysInvtItemSelection."Location Code");
        BinContent.SetRange("Item No.", TempPhysInvtItemSelection."Item No.");
        if TempPhysInvtItemSelection."Phys Invt Counting Period Type" =
           TempPhysInvtItemSelection."Phys Invt Counting Period Type"::SKU
        then
            BinContent.SetRange("Variant Code", TempPhysInvtItemSelection."Variant Code");
        WhseCalculateInventory.SetTableView(BinContent);
        WhseCalculateInventory.RunModal;
        Clear(WhseCalculateInventory);
    end;

    procedure CalcPeriod(LastDate: Date; var NextCountingStartDate: Date; var NextCountingEndDate: Date; CountFrequency: Integer)
    var
        Calendar: Record Date;
        LastCountDate: Date;
        YearEndDate: Date;
        StartDate: Date;
        EndDate: Date;
        Periods: array[4] of Date;
        Days: Decimal;
        i: Integer;
    begin
        if LastDate = 0D then
            LastCountDate := WorkDate
        else
            LastCountDate := LastDate;

        i := Date2DMY(WorkDate, 3);
        Calendar.Reset();
        Calendar.SetRange("Period Type", Calendar."Period Type"::Year);
        Calendar.SetRange("Period No.", i);
        Calendar.Find('-');
        StartDate := Calendar."Period Start";
        YearEndDate := NormalDate(Calendar."Period End");

        case CountFrequency of
            1, 2, 3, 4, 6, 12:
                begin
                    FindCurrentPhysInventoryPeriod(Calendar, StartDate, EndDate, LastCountDate, CountFrequency);
                    if LastDate <> 0D then begin
                        Calendar.Next(12 / CountFrequency);
                        StartDate := EndDate + 1;
                        EndDate := NormalDate(Calendar."Period Start") - 1;
                    end;
                    NextCountingStartDate := StartDate;
                    NextCountingEndDate := EndDate;
                end;
            24:
                begin
                    FindCurrentPhysInventoryPeriod(Calendar, StartDate, EndDate, LastCountDate, 12);
                    Days := (EndDate - StartDate + 1) div 2; // number of days in half a month
                    Periods[1] := StartDate;
                    Periods[2] := StartDate + Days;
                    Calendar.Next;
                    StartDate := EndDate + 1;
                    EndDate := NormalDate(Calendar."Period Start") - 1;
                    Days := (EndDate - StartDate + 1) div 2;
                    Periods[3] := StartDate;
                    Periods[4] := StartDate + Days;
                    i := 0;
                    repeat
                        i += 1;
                    until (LastCountDate >= Periods[i]) and (LastCountDate <= (Periods[i + 1] - 1));
                    if LastDate <> 0D then
                        i += 1;
                    NextCountingStartDate := Periods[i];
                    NextCountingEndDate := Periods[i + 1] - 1;
                end;
            else begin
                    Calendar.Reset();
                    Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
                    Calendar.SetRange("Period Start", StartDate, YearEndDate);
                    Calendar.SetRange("Period No.");
                    Days := (Calendar.Count div CountFrequency);
                    if NextCountingStartDate <> 0D then begin
                        if LastCountDate < NextCountingStartDate then
                            exit;
                        StartDate := NextCountingStartDate;
                        EndDate := NextCountingEndDate;
                        while LastCountDate >= StartDate do begin
                            StartDate := EndDate + 1;
                            EndDate := CalcDate('<+' + Format(Days) + 'D>', StartDate);
                        end;
                    end;

                    if LastDate = 0D then
                        NextCountingStartDate := CalcDate('<+' + Format(Days) + 'D>', LastCountDate)
                    else
                        NextCountingStartDate := StartDate;
                    NextCountingEndDate := CalcDate('<+' + Format(Days) + 'D>', NextCountingStartDate);
                end;
        end;
    end;

    local procedure GetPhysInvtCount(PhysInvtCountCode: Code[10])
    begin
        if PhysInvtCount.Code <> PhysInvtCountCode then
            PhysInvtCount.Get(PhysInvtCountCode);
    end;

    procedure InitFromItemJnl(ItemJnlLine2: Record "Item Journal Line")
    begin
        ItemJnlLine := ItemJnlLine2;
        SourceJnl := SourceJnl::ItemJnl;
    end;

    procedure InitFromWhseJnl(WhseJnlLine2: Record "Warehouse Journal Line")
    begin
        WhseJnlLine := WhseJnlLine2;
        SourceJnl := SourceJnl::WhseJnl;
    end;

    procedure InitFromCustomJnl()
    begin
        SourceJnl := SourceJnl::Custom;
    end;

    procedure GetSortingMethod(var SortingMethod2: Option " ",Item,Bin)
    begin
        SortingMethod2 := SortingMethod;
    end;

    local procedure PrintPhysInvtList(var ItemJnlBatch: Record "Item Journal Batch"; PrintQtyCalculated: Boolean; PrintDocPerItem: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary)
    var
        PhysInvtList: Report "Phys. Inventory List";
    begin
        if not PrintDocPerItem then begin
            ItemJnlBatch.SetRecFilter;
            ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
            ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
            PhysInvtList.UseRequestPage(false);
            PhysInvtList.Initialize(PrintQtyCalculated);
            PhysInvtList.SetTableView(ItemJnlBatch);
            PhysInvtList.SetTableView(ItemJnlLine);
            PhysInvtList.Run;
        end else begin
            TempPhysInvtItemSelection.Find('-');
            repeat
                ItemJnlBatch.SetRecFilter;
                PhysInvtList.SetTableView(ItemJnlBatch);
                ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
                ItemJnlLine.SetRange("Item No.", TempPhysInvtItemSelection."Item No.");
                PhysInvtList.UseRequestPage(false);
                PhysInvtList.Initialize(PrintQtyCalculated);
                PhysInvtList.SetTableView(ItemJnlLine);
                PhysInvtList.Run;
                TempPhysInvtItemSelection.SetRange("Item No.",
                  TempPhysInvtItemSelection."Item No.");
                TempPhysInvtItemSelection.Find('+');
                TempPhysInvtItemSelection.SetRange("Item No.");
            until TempPhysInvtItemSelection.Next = 0;
        end;
        Clear(PhysInvtList);
    end;

    local procedure PrintWhseInvtList(var WhseJnlBatch: Record "Warehouse Journal Batch"; PrintQtyCalculated: Boolean; PrintDocPerItem: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary)
    var
        WhsePhysInvtList: Report "Whse. Phys. Inventory List";
    begin
        if not PrintDocPerItem then begin
            WhseJnlBatch.SetRecFilter;
            case SortingMethod of
                SortingMethod::Item:
                    WhseJnlLine.SetCurrentKey("Location Code", "Item No.", "Variant Code");
                SortingMethod::Bin:
                    WhseJnlLine.SetCurrentKey("Location Code", "Bin Code");
            end;
            WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
            WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
            WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
            WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
            WhseJnlLine.SetRange("Location Code", WhseJnlBatch."Location Code");
            WhsePhysInvtList.UseRequestPage(false);
            WhsePhysInvtList.Initialize(PrintQtyCalculated);
            WhsePhysInvtList.SetTableView(WhseJnlBatch);
            WhsePhysInvtList.SetTableView(WhseJnlLine);
            WhsePhysInvtList.Run;
        end else begin
            TempPhysInvtItemSelection.Find('-');
            repeat
                WhseJnlBatch.SetRecFilter;
                case SortingMethod of
                    SortingMethod::Item:
                        WhseJnlLine.SetCurrentKey("Location Code", "Item No.", "Variant Code");
                    SortingMethod::Bin:
                        WhseJnlLine.SetCurrentKey("Location Code", "Bin Code");
                end;
                WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
                WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
                WhseJnlLine.SetRange("Item No.", TempPhysInvtItemSelection."Item No.");
                WhseJnlLine.SetRange("Location Code", TempPhysInvtItemSelection."Location Code");
                WhsePhysInvtList.UseRequestPage(false);
                WhsePhysInvtList.Initialize(PrintQtyCalculated);
                WhsePhysInvtList.SetTableView(WhseJnlBatch);
                WhsePhysInvtList.SetTableView(WhseJnlLine);
                WhsePhysInvtList.Run;
                TempPhysInvtItemSelection.SetRange("Item No.",
                  TempPhysInvtItemSelection."Item No.");
                TempPhysInvtItemSelection.Find('+');
                TempPhysInvtItemSelection.SetRange("Item No.");
            until TempPhysInvtItemSelection.Next = 0;
        end;
        Clear(WhsePhysInvtList);
    end;

    procedure UpdateSKUPhysInvtCount(var SKU: Record "Stockkeeping Unit")
    begin
        with SKU do begin
            if (not MarkedOnly) and (GetFilters = '') then
                SetRecFilter;

            FindSet;
            repeat
                TestField("Phys Invt Counting Period Code");
            until Next = 0;

            if not HideValidationDialog then
                if not Confirm(Text001, false, TableCaption) then
                    Error(Text002);

            FindSet;
            repeat
                GetPhysInvtCount("Phys Invt Counting Period Code");
                PhysInvtCount.TestField("Count Frequency per Year");
                "Last Counting Period Update" := WorkDate;
                CalcPeriod(
                  "Last Counting Period Update", "Next Counting Start Date", "Next Counting End Date",
                  PhysInvtCount."Count Frequency per Year");
                Modify;
            until Next = 0;
        end;
    end;

    procedure UpdateItemPhysInvtCount(var Item: Record Item)
    begin
        with Item do begin
            if (not MarkedOnly) and (GetFilters = '') then
                SetRecFilter;

            FindSet;
            repeat
                TestField("Phys Invt Counting Period Code");
            until Next = 0;

            if not HideValidationDialog then
                if not Confirm(Text001, false, TableCaption) then
                    Error(Text002);

            FindSet;
            repeat
                GetPhysInvtCount("Phys Invt Counting Period Code");
                PhysInvtCount.TestField("Count Frequency per Year");
                "Last Counting Period Update" := WorkDate;
                CalcPeriod(
                  "Last Counting Period Update", "Next Counting Start Date", "Next Counting End Date",
                  PhysInvtCount."Count Frequency per Year");
                Modify;
            until Next = 0;
        end;
    end;

    procedure UpdateItemSKUListPhysInvtCount()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
    begin
        with TempItem do begin
            if FindSet then
                repeat
                    Item.Reset();
                    Item.Get("No.");
                    UpdateItemPhysInvtCount(Item);
                until Next = 0;
        end;

        with TempSKU do begin
            if FindSet then
                repeat
                    SKU.Reset();
                    SKU.Get("Location Code", "Item No.", "Variant Code");
                    UpdateSKUPhysInvtCount(SKU);
                until Next = 0;
        end;
    end;

    procedure AddToTempItemSKUList(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; PhysInvtCountingPeriodType: Option " ",Item,SKU)
    begin
        case PhysInvtCountingPeriodType of
            PhysInvtCountingPeriodType::Item:
                InsertTempItem(ItemNo);
            PhysInvtCountingPeriodType::SKU:
                InsertTempSKU(ItemNo, LocationCode, VariantCode);
        end;
    end;

    local procedure InsertTempItem(ItemNo: Code[20])
    begin
        with TempItem do begin
            if Get(ItemNo) then
                exit;

            Init;
            "No." := ItemNo;
            Insert;
        end;
    end;

    local procedure InsertTempSKU(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        with TempSKU do begin
            if Get(LocationCode, ItemNo, VariantCode) then
                exit;

            Init;
            "Location Code" := LocationCode;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            Insert;
        end;
    end;

    procedure InitTempItemSKUList()
    begin
        SetHideValidationDialog(true);

        TempItem.DeleteAll();
        TempSKU.DeleteAll();
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure InitFromPhysInvtOrder(PhysInvtOrderHeader2: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader := PhysInvtOrderHeader2;
        SourceJnl := SourceJnl::PhysInvtOrder;
    end;

    local procedure CreatePhysInvtOrderLines()
    var
        Item: Record Item;
        CalcPhysInvtOrderCountRep: Report "Calc. Phys. Invt. Order Count";
        CalcPhysInvtOrderLinesRep: Report "Calc. Phys. Invt. Order Lines";
        Window: Dialog;
        ZeroQty: Boolean;
        CalcQtyExpected: Boolean;
    begin
        CalcPhysInvtOrderCountRep.RunModal;
        if not CalcPhysInvtOrderCountRep.GetRequest(ZeroQty, CalcQtyExpected) then
            exit;

        Window.Open(Text000, TempPhysInvtItemSelection."Item No.");
        repeat
            Window.Update;
            CalcPhysInvtOrderLinesRep.SetPhysInvtOrderHeader(PhysInvtOrderHeader);
            CalcPhysInvtOrderLinesRep.InitializeInvtCount(
              TempPhysInvtItemSelection."Phys Invt Counting Period Code",
              TempPhysInvtItemSelection."Phys Invt Counting Period Type");
            CalcPhysInvtOrderLinesRep.SetHideValidationDialog(true);
            CalcPhysInvtOrderLinesRep.InitializeRequest(ZeroQty, CalcQtyExpected);
            CalcPhysInvtOrderLinesRep.UseRequestPage(false);
            Item.SetRange("No.", TempPhysInvtItemSelection."Item No.");
            if TempPhysInvtItemSelection."Phys Invt Counting Period Type" =
               TempPhysInvtItemSelection."Phys Invt Counting Period Type"::SKU
            then begin
                Item.SetRange("Variant Filter", TempPhysInvtItemSelection."Variant Code");
                Item.SetRange("Location Filter", TempPhysInvtItemSelection."Location Code");
            end;
            CalcPhysInvtOrderLinesRep.SetTableView(Item);
            CalcPhysInvtOrderLinesRep.RunModal;
            Clear(CalcPhysInvtOrderLinesRep);
        until TempPhysInvtItemSelection.Next = 0;
        Window.Close;
    end;

    local procedure FindCurrentPhysInventoryPeriod(var Calendar: Record Date; var StartDate: Date; var EndDate: Date; LastDate: Date; CountFrequency: Integer)
    var
        OldStartDate: Date;
    begin
        if StartDate > LastDate then begin
            Calendar.Reset();
            Calendar.SetRange("Period Type", Calendar."Period Type"::Year);
            Calendar.SetRange("Period No.", Date2DMY(LastDate, 3));
            Calendar.FindFirst;
            StartDate := Calendar."Period Start";
        end;
        Calendar.Reset();
        Calendar.SetRange("Period Type", Calendar."Period Type"::Month);
        Calendar.SetFilter("Period Start", '>=%1', StartDate);
        Calendar.FindFirst;
        while StartDate <= LastDate do begin
            OldStartDate := StartDate;
            Calendar.Next(12 / CountFrequency);
            StartDate := Calendar."Period Start";
            EndDate := NormalDate(Calendar."Period Start") - 1;
        end;
        StartDate := OldStartDate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvtQtyOnHand(DocNo: Code[20]; PostingDate: Date; ZeroQty: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcWhseQtyOnHand(DocNo: Code[20]; PostingDate: Date; ZeroQty: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePhysInvtItemJnl(var ItemJournalLine: Record "Item Journal Line"; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPhysInvtList(var ItemJournalBatch: Record "Item Journal Batch"; PrintQtyCalculated: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWhseInvtList(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; PrintQtyCalculated: Boolean; var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomPhysInvtJournal(var TempPhysInvtItemSelection: Record "Phys. Invt. Item Selection" temporary; SortingMethod: Option " ",Item,Bin; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetItemFilters(var Item: Record Item; SourceJnl: Option ItemJnl,WhseJnl,PhysInvtOrder,Custom)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetSKUFilters(var StockkeepingUnit: Record "Stockkeeping Unit"; SourceJnl: Option ItemJnl,WhseJnl,PhysInvtOrder,Custom)
    begin
    end;
}


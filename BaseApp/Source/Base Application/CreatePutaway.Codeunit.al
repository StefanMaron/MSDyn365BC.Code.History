codeunit 7313 "Create Put-away"
{
    TableNo = "Posted Whse. Receipt Line";

    trigger OnRun()
    begin
        OnBeforeRun(Rec);

        PostedWhseRcptLine.Copy(Rec);
        Code;
        Copy(PostedWhseRcptLine);

        OnAfterRun(Rec);
    end;

    var
        CrossDockBinContent: Record "Bin Content";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        xPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary;
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivHeader: Record "Warehouse Activity Header" temporary;
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        PutAwayTemplHeader: Record "Put-away Template Header";
        PutAwayTemplLine: Record "Put-away Template Line";
        Location: Record Location;
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        PutAwayItemUOM: Record "Item Unit of Measure";
        WMSMgt: Codeunit "WMS Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        BinTypeFilter: Text[250];
        MessageText: Text[80];
        WarehouseClassCode: Code[10];
        AssignedID: Code[50];
        EverythingHandled: Boolean;
        DoNotFillQtytoHandle: Boolean;
        BreakbulkFilter: Boolean;
        QtyToPickBase: Decimal;
        QtyToPutAwayBase: Decimal;
        RemQtyToPutAwayBase: Decimal;
        LineNo: Integer;
        OldLineNo: Integer;
        BreakbulkNo: Integer;
        EntryNo: Integer;
        SortActivity: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type";
        Text001: Label 'There are no %1 created.';
        Text002: Label 'There is not enough bin capacity for items.';
        NewCrossDockBinContent: Boolean;
        CrossDock: Boolean;
        CrossDockInfo: Option;
        Text003: Label 'There is no default bin for one or more item.';

    local procedure "Code"()
    var
        BinType: Record "Bin Type";
        BinContentQtyBase: Decimal;
        TakeLineNo: Integer;
        BreakPackage: Boolean;
        Breakbulk: Boolean;
    begin
        OnBeforeCode(PostedWhseRcptLine);

        with PostedWhseRcptLine do begin
            QtyToPickBase := 0;
            QtyToPutAwayBase := 0;
            CrossDockInfo := 0;
            MessageText := '';
            EverythingHandled := false;
            TempWhseActivLine.DeleteAll();

            GetLocation("Location Code");
            if not Location."Bin Mandatory" then begin
                MakeCrossDockPutAway;
                CalcQtyToPutAway(true, false);
                exit;
            end;

            if Location."Directed Put-away and Pick" then begin
                GetItemAndSKU("Item No.", "Location Code", "Variant Code");
                GetPutAwayUOM;
                GetPutAwayTemplate;
                if PutAwayTemplHeader.Code = '' then begin
                    MessageText := StrSubstNo(Text001, PutAwayTemplHeader.TableCaption);
                    exit;
                end;

                PutAwayTemplLine.Reset();
                PutAwayTemplLine.SetRange("Put-away Template Code", PutAwayTemplHeader.Code);
                if not PutAwayTemplLine.Find('-') then begin
                    MessageText := StrSubstNo(Text001, PutAwayTemplLine.TableCaption);
                    exit;
                end;
                RemQtyToPutAwayBase := "Qty. (Base)";
                if "Qty. per Unit of Measure" > PutAwayItemUOM."Qty. per Unit of Measure" then
                    CreateBreakPackageLines(PostedWhseRcptLine);

                if RemQtyToPutAwayBase = 0 then
                    exit;
            end else
                RemQtyToPutAwayBase := "Qty. (Base)";

            MakeCrossDockPutAway;

            LineNo := LineNo + 10000;
            if Location."Directed Put-away and Pick" then begin
                BinType.CreateBinTypeFilter(BinTypeFilter, 2);
                repeat
                    QtyToPutAwayBase := RemQtyToPutAwayBase;
                    if not (PutAwayTemplLine."Find Empty Bin" or PutAwayTemplLine."Find Floating Bin") or
                       PutAwayTemplLine."Find Fixed Bin" or
                       PutAwayTemplLine."Find Same Item" or
                       PutAwayTemplLine."Find Unit of Measure Match" or
                       PutAwayTemplLine."Find Bin w. Less than Min. Qty"
                    then begin
                        // Calc Availability per Bin Content
                        if FindBinContent("Location Code", "Item No.", "Variant Code", WarehouseClassCode) then
                            repeat
                                if BinContent."Bin Code" <> "Bin Code" then begin
                                    QtyToPutAwayBase := RemQtyToPutAwayBase;

                                    BinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
                                    BinContentQtyBase :=
                                      BinContent."Quantity (Base)" + BinContent."Put-away Quantity (Base)" + BinContent."Positive Adjmt. Qty. (Base)";
                                    if (not PutAwayTemplLine."Find Bin w. Less than Min. Qty" or
                                        (BinContentQtyBase < BinContent."Min. Qty." * BinContent."Qty. per Unit of Measure")) and
                                       (not PutAwayTemplLine."Find Empty Bin" or (BinContentQtyBase <= 0))
                                    then begin
                                        if BinContent."Max. Qty." <> 0 then begin
                                            QtyToPutAwayBase := Max(BinContent."Max. Qty." * BinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                                            if QtyToPutAwayBase > RemQtyToPutAwayBase then
                                                QtyToPutAwayBase := RemQtyToPutAwayBase;
                                        end;

                                        GetBin("Location Code", BinContent."Bin Code");
                                        CalcQtyToPutAway(false, false);
                                    end;
                                end;
                            until not NextBinContent;
                    end else begin
                        // Calc Availability per Bin
                        if FindBin("Location Code", WarehouseClassCode) then
                            repeat
                                if Bin.Code <> "Bin Code" then begin
                                    QtyToPutAwayBase := RemQtyToPutAwayBase;
                                    if BinContent.Get(
                                         "Location Code", Bin.Code, "Item No.", "Variant Code", PutAwayItemUOM.Code)
                                    then begin
                                        BinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
                                        BinContentQtyBase :=
                                          BinContent."Quantity (Base)" +
                                          BinContent."Put-away Quantity (Base)" +
                                          BinContent."Positive Adjmt. Qty. (Base)";

                                        if BinContent."Max. Qty." <> 0 then begin
                                            QtyToPutAwayBase := BinContent."Max. Qty." * BinContent."Qty. per Unit of Measure" - BinContentQtyBase;
                                            if QtyToPutAwayBase > RemQtyToPutAwayBase then
                                                QtyToPutAwayBase := RemQtyToPutAwayBase;
                                        end;
                                        CalcQtyToPutAway(false, false);
                                        BinContentQtyBase := BinContent.CalcQtyBase;
                                        if BinContent."Max. Qty." <> 0 then begin
                                            QtyToPutAwayBase :=
                                              BinContent."Max. Qty." * BinContent."Qty. per Unit of Measure" - BinContentQtyBase;
                                            if QtyToPutAwayBase > RemQtyToPutAwayBase then
                                                QtyToPutAwayBase := RemQtyToPutAwayBase;
                                        end;
                                    end else
                                        CalcQtyToPutAway(false, true);
                                end;
                            until not NextBin;
                    end;
                until (PutAwayTemplLine.Next = 0) or EverythingHandled;
            end else begin
                Clear(Bin);
                if WMSMgt.GetDefaultBin("Item No.", "Variant Code", "Location Code", Bin.Code) then
                    Bin.Get(Location.Code, Bin.Code);
                QtyToPutAwayBase := RemQtyToPutAwayBase;
                CalcQtyToPutAway(false, false);
            end;

            if not EverythingHandled and Location."Always Create Put-away Line" then begin
                QtyToPutAwayBase := RemQtyToPutAwayBase;
                CalcQtyToPutAway(true, false);
            end;

            if QtyToPickBase > 0 then begin
                if InsertBreakPackageLines then begin
                    TakeLineNo := OldLineNo + 30000;
                    Breakbulk := true;
                end else begin
                    TakeLineNo := OldLineNo + 10000;
                    if ("Unit of Measure Code" <> PutAwayItemUOM.Code) and
                       Location."Directed Put-away and Pick"
                    then
                        BreakPackage := true;
                end;
                CreateNewWhseActivity(
                  PostedWhseRcptLine, WhseActivLine, 1, TakeLineNo, 0, QtyToPickBase, false, BreakPackage, false, Breakbulk);

                OnCodeOnAfterCreateNewWhseActivity(WhseActivLine);

                OldLineNo := LineNo;
            end else
                if MessageText = '' then
                    if Location."Directed Put-away and Pick" then
                        MessageText := Text002
                    else
                        MessageText := Text003;
        end
    end;

    local procedure CreateBreakPackageLines(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        with PostedWhseRcptLine do begin
            LineNo := LineNo + 10000;
            BreakbulkNo := BreakbulkNo + 1;
            CreateNewWhseActivity(
              PostedWhseReceiptLine, TempWhseActivLine, 1, LineNo,
              BreakbulkNo, "Qty. (Base)", false, true, false, false);
            LineNo := LineNo + 10000;
            CreateNewWhseActivity(
              PostedWhseReceiptLine, TempWhseActivLine, 2, LineNo,
              BreakbulkNo, RemQtyToPutAwayBase, false, false, false, true);
        end;
    end;

    local procedure InsertBreakPackageLines(): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        if TempWhseActivLine.Find('-') then begin
            repeat
                WhseActivLine.Init();
                WhseActivLine := TempWhseActivLine;
                WhseActivLine."Activity Type" := WhseActivHeader.Type;
                WhseActivLine."No." := WhseActivHeader."No.";
                WhseActivLine."Bin Code" := PostedWhseRcptLine."Bin Code";
                WhseActivLine."Zone Code" := PostedWhseRcptLine."Zone Code";
                WhseActivLine.Insert();
                OnAfterWhseActivLineInsert(WhseActivLine);
            until TempWhseActivLine.Next = 0;
            exit(true);
        end
    end;

    local procedure CreateNewWhseActivity(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var WhseActivLine: Record "Warehouse Activity Line"; ActionType: Option ,Take,Place; LineNo: Integer; BreakbulkNo: Integer; QtyToHandleBase: Decimal; InsertHeader: Boolean; BreakPackage: Boolean; EmptyZoneBin: Boolean; Breakbulk: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateNewWhseActivity(
          PostedWhseRcptLine, WhseActivLine, WhseActivHeader, Location, InsertHeader, Bin, ActionType, LineNo,
          BreakbulkNo, BreakbulkFilter, QtyToHandleBase, BreakPackage, EmptyZoneBin, Breakbulk, CrossDockInfo, PutAwayItemUOM,
          DoNotFillQtytoHandle, IsHandled);
        if IsHandled then
            exit;

        with PostedWhseRcptLine do begin
            if (WhseActivHeader."No." = '') and InsertHeader then
                InsertWhseActivHeader("Location Code");

            WhseActivLine.Init();
            WhseActivLine."Activity Type" := WhseActivHeader.Type;
            WhseActivLine."No." := WhseActivHeader."No.";
            WhseActivLine."Line No." := LineNo;
            WhseActivLine."Action Type" := ActionType;
            WhseActivLine."Source Type" := "Source Type";
            WhseActivLine."Source Subtype" := "Source Subtype";
            WhseActivLine."Source No." := "Source No.";
            WhseActivLine."Source Line No." := "Source Line No.";
            WhseActivLine."Source Document" := "Source Document";
            if WhseActivLine."Source Type" = 0 then
                WhseActivLine."Whse. Document Type" := WhseActivLine."Whse. Document Type"::"Internal Put-away"
            else
                WhseActivLine."Whse. Document Type" := WhseActivLine."Whse. Document Type"::Receipt;
            WhseActivLine."Whse. Document No." := "No.";
            WhseActivLine."Whse. Document Line No." := "Line No.";
            WhseActivLine."Location Code" := Location.Code;
            WhseActivLine."Shelf No." := "Shelf No.";
            WhseActivLine."Due Date" := "Due Date";
            WhseActivLine."Starting Date" := "Starting Date";
            WhseActivLine."Breakbulk No." := BreakbulkNo;
            WhseActivLine."Original Breakbulk" := Breakbulk;
            if BreakbulkFilter then
                WhseActivLine.Breakbulk := Breakbulk;
            case ActionType of
                ActionType::Take:
                    begin
                        WhseActivLine."Bin Code" := "Bin Code";
                        WhseActivLine."Zone Code" := "Zone Code";
                    end;
                ActionType::Place:
                    begin
                        if not EmptyZoneBin then
                            AssignPlaceBinZone(WhseActivLine);
                    end;
                else begin
                        WhseActivLine."Bin Code" := '';
                        WhseActivLine."Zone Code" := '';
                    end
            end;
            OnCreateNewWhseActivityOnAfterAssignBinZone(WhseActivLine);
            if WhseActivLine."Bin Code" <> '' then begin
                WhseActivLine."Special Equipment Code" :=
                  GetSpecEquipmentCode(WhseActivLine."Bin Code");
                GetBin(WhseActivLine."Location Code", WhseActivLine."Bin Code");
                WhseActivLine.Dedicated := Bin.Dedicated;
                WhseActivLine."Bin Ranking" := Bin."Bin Ranking";
                WhseActivLine."Bin Type Code" := Bin."Bin Type Code";
            end;
            WhseActivLine."Item No." := "Item No.";
            WhseActivLine."Variant Code" := "Variant Code";
            WhseActivLine.Description := Description;
            WhseActivLine."Description 2" := "Description 2";
            WhseActivLine."Cross-Dock Information" := CrossDockInfo;
            if BreakPackage or (ActionType = 0) or
               not Location."Directed Put-away and Pick"
            then begin
                WhseActivLine."Unit of Measure Code" := "Unit of Measure Code";
                WhseActivLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            end else begin
                WhseActivLine."Unit of Measure Code" := PutAwayItemUOM.Code;
                WhseActivLine."Qty. per Unit of Measure" := PutAwayItemUOM."Qty. per Unit of Measure";
            end;
            WhseActivLine.Validate(
              Quantity, Round(QtyToHandleBase / WhseActivLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
            if QtyToHandleBase <> 0 then begin
                WhseActivLine."Qty. (Base)" := QtyToHandleBase;
                WhseActivLine."Qty. to Handle (Base)" := QtyToHandleBase;
                WhseActivLine."Qty. Outstanding (Base)" := QtyToHandleBase;
            end;
            if DoNotFillQtytoHandle then begin
                WhseActivLine."Qty. to Handle" := 0;
                WhseActivLine."Qty. to Handle (Base)" := 0;
                WhseActivLine.Cubage := 0;
                WhseActivLine.Weight := 0;
            end;
            if "Serial No." <> '' then
                WhseActivLine.TestField("Qty. per Unit of Measure", 1);
            WhseActivLine.CopyTrackingFromPostedWhseRcptLine(PostedWhseRcptLine);
            WhseActivLine."Warranty Date" := "Warranty Date";
            WhseActivLine."Expiration Date" := "Expiration Date";
            OnBeforeWhseActivLineInsert(WhseActivLine, PostedWhseRcptLine);
            WhseActivLine.Insert();
            OnAfterWhseActivLineInsert(WhseActivLine);
        end;
    end;

    local procedure AssignPlaceBinZone(var WhseActivLine: Record "Warehouse Activity Line")
    var
        Bin2: Record Bin;
    begin
        with WhseActivLine do begin
            "Bin Code" := Bin.Code;
            "Zone Code" := Bin."Zone Code";
            if Location.IsBWReceive and
               (CrossDockInfo <> "Cross-Dock Information"::"Cross-Dock Items") and
               ((Bin.Code = PostedWhseRcptLine."Bin Code") or Location.IsBinBWReceiveOrShip(Bin.Code))
            then begin
                Bin2.SetRange("Location Code", Location.Code);
                Bin2.SetFilter(Code, '<>%1&<>%2&<>%3', Location."Receipt Bin Code", Location."Shipment Bin Code",
                  PostedWhseRcptLine."Bin Code");
                if Bin2.FindFirst then begin
                    "Bin Code" := Bin2.Code;
                    "Zone Code" := Bin2."Zone Code";
                end else begin
                    "Bin Code" := '';
                    "Zone Code" := '';
                end;
            end;
        end;

        OnAfterAssignPlaceBinZone(WhseActivLine);
    end;

    local procedure InsertWhseActivHeader(LocationCode: Code[10])
    begin
        WhseActivHeader.LockTable();
        WhseActivHeader.Init();
        WhseActivHeader.Type := WhseActivHeader.Type::"Put-away";
        WhseActivHeader."Location Code" := LocationCode;
        WhseActivHeader.Validate("Assigned User ID", AssignedID);
        WhseActivHeader."Sorting Method" := SortActivity;
        WhseActivHeader."Breakbulk Filter" := BreakbulkFilter;
        OnBeforeWhseActivHeaderInsert(WhseActivHeader, PostedWhseRcptLine);
        WhseActivHeader.Insert(true);
        Commit();
        OnAfterWhseActivHeaderInsert(WhseActivHeader);
        InsertTempWhseActivHeader(WhseActivHeader);
        WhseActivLine.LockTable();
    end;

    local procedure FindBinContent(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WarehouseClassCode: Code[10]): Boolean
    var
        BinContentFound: Boolean;
        IsHandled: Boolean;
    begin
        with BinContent do begin
            Reset;
            SetCurrentKey("Location Code", "Warehouse Class Code", Fixed, "Bin Ranking");
            SetRange("Location Code", LocationCode);
            SetRange("Warehouse Class Code", WarehouseClassCode);
            if PutAwayTemplLine."Find Fixed Bin" then
                SetRange(Fixed, true)
            else
                SetRange(Fixed, false);
            SetFilter("Block Movement", '%1|%2', "Block Movement"::" ", "Block Movement"::Outbound);
            SetFilter("Bin Type Code", BinTypeFilter);
            SetRange("Cross-Dock Bin", false);
            if PutAwayTemplLine."Find Same Item" then begin
                SetCurrentKey(
                  "Location Code", "Item No.", "Variant Code", "Warehouse Class Code", Fixed, "Bin Ranking");
                SetRange("Item No.", ItemNo);
                SetRange("Variant Code", VariantCode);
            end;
            if PutAwayTemplLine."Find Unit of Measure Match" then
                SetRange("Unit of Measure Code", PutAwayItemUOM.Code);
            IsHandled := false;
            OnFindBinContent(PostedWhseRcptLine, PutAwayTemplLine, BinContent, BinContentFound, IsHandled);
            if not IsHandled then
                BinContentFound := Find('+');

            exit(BinContentFound);
        end
    end;

    local procedure FindBin(LocationCode: Code[10]; WarehouseClassCode: Code[10]): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        BinFound: Boolean;
        IsHandled: Boolean;
    begin
        with Bin do begin
            Reset;
            SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
            SetRange("Location Code", LocationCode);
            SetRange("Warehouse Class Code", WarehouseClassCode);
            SetRange("Adjustment Bin", false);
            SetFilter("Block Movement", '%1|%2', "Block Movement"::" ", "Block Movement"::Outbound);
            SetFilter("Bin Type Code", BinTypeFilter);
            SetRange("Cross-Dock Bin", false);
            if PutAwayTemplLine."Find Empty Bin" then
                SetRange(Empty, true);
            IsHandled := false;
            OnFindBin(PostedWhseRcptLine, PutAwayTemplLine, Bin, BinFound, IsHandled);
            if IsHandled then
                exit(BinFound);

            if Find('+') then begin
                if not (PutAwayTemplLine."Find Empty Bin" or PutAwayTemplLine."Find Floating Bin") then
                    exit(true);
                repeat
                    if PutAwayTemplLine."Find Empty Bin" then begin
                        WhseActivLine.SetCurrentKey("Bin Code", "Location Code", "Action Type");
                        WhseActivLine.SetRange("Bin Code", Code);
                        WhseActivLine.SetRange("Location Code", LocationCode);
                        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
                        if WhseActivLine.IsEmpty then
                            if not PutAwayTemplLine."Find Floating Bin" or IsFloatingBin then
                                exit(true);
                    end else
                        if IsFloatingBin then
                            exit(true);
                until Next(-1) = 0;
            end;
        end;
        exit(false)
    end;

    local procedure CalcQtyToPutAway(EmptyZoneBin: Boolean; NewBinContent: Boolean)
    var
        ActionType: Option ,Take,Place;
    begin
        if Location."Bin Mandatory" then begin
            ActionType := ActionType::Place;
            if not EmptyZoneBin and Location."Directed Put-away and Pick" then
                CalcAvailCubageAndWeight;
            if QtyToPutAwayBase >= RemQtyToPutAwayBase then begin
                QtyToPutAwayBase := RemQtyToPutAwayBase;
                EverythingHandled := true;
            end else
                RemQtyToPutAwayBase := RemQtyToPutAwayBase - QtyToPutAwayBase;
        end else
            QtyToPutAwayBase := PostedWhseRcptLine."Qty. (Base)";

        QtyToPickBase := QtyToPickBase + QtyToPutAwayBase;
        if QtyToPutAwayBase > 0 then begin
            LineNo := LineNo + 10000;
            if NewBinContent and Location."Directed Put-away and Pick" then
                CreateBinContent(PostedWhseRcptLine);
            CreateNewWhseActivity(
              PostedWhseRcptLine, WhseActivLine, ActionType, LineNo,
              0, QtyToPutAwayBase, true, false, EmptyZoneBin, false)
        end
    end;

    local procedure CalcAvailCubageAndWeight()
    var
        AvailPerCubageBase: Decimal;
        AvailPerWeightBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailCubageAndWeight(Bin, PostedWhseRcptLine, PutAwayItemUOM, QtyToPutAwayBase, IsHandled);
        if IsHandled then
            exit;

        with Bin do begin
            if ("Maximum Cubage" <> 0) or ("Maximum Weight" <> 0) then begin
                if (PutAwayItemUOM.Cubage <> 0) or (PutAwayItemUOM.Weight <> 0) then
                    CalcCubageAndWeight(AvailPerCubageBase, AvailPerWeightBase, false);
                if ("Maximum Cubage" <> 0) and (PutAwayItemUOM.Cubage <> 0) then begin
                    AvailPerCubageBase := AvailPerCubageBase div PutAwayItemUOM.Cubage * PutAwayItemUOM."Qty. per Unit of Measure";
                    if AvailPerCubageBase < 0 then
                        AvailPerCubageBase := 0;
                    if AvailPerCubageBase < QtyToPutAwayBase then
                        QtyToPutAwayBase := AvailPerCubageBase;
                end;
                if ("Maximum Weight" <> 0) and (PutAwayItemUOM.Weight <> 0) then begin
                    AvailPerWeightBase := AvailPerWeightBase div PutAwayItemUOM.Weight * PutAwayItemUOM."Qty. per Unit of Measure";
                    if AvailPerWeightBase < 0 then
                        AvailPerWeightBase := 0;
                    if AvailPerWeightBase < QtyToPutAwayBase then
                        QtyToPutAwayBase := AvailPerWeightBase;
                end
            end
        end
    end;

    local procedure CreateBinContent(PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    var
        NewBinContent: Record "Bin Content";
    begin
        with PostedWhseRcptLine do begin
            NewBinContent.Init();
            NewBinContent."Location Code" := Bin."Location Code";
            NewBinContent."Bin Code" := Bin.Code;
            NewBinContent."Item No." := "Item No.";
            NewBinContent."Variant Code" := "Variant Code";
            NewBinContent."Unit of Measure Code" := PutAwayItemUOM.Code;
            NewBinContent.Dedicated := Bin.Dedicated;
            NewBinContent."Zone Code" := Bin."Zone Code";
            NewBinContent."Bin Type Code" := Bin."Bin Type Code";
            NewBinContent."Warehouse Class Code" := Bin."Warehouse Class Code";
            NewBinContent."Block Movement" := Bin."Block Movement";
            NewBinContent."Qty. per Unit of Measure" := PutAwayItemUOM."Qty. per Unit of Measure";
            NewBinContent."Bin Ranking" := Bin."Bin Ranking";
            NewBinContent."Cross-Dock Bin" := Bin."Cross-Dock Bin";
            OnCreateBinContentOnBeforeNewBinContentInsert(NewBinContent, PostedWhseRcptLine);
            NewBinContent.Insert();
        end;
    end;

    procedure GetSpecEquipmentCode(BinCode: Code[20]): Code[10]
    begin
        case Location."Special Equipment" of
            Location."Special Equipment"::"According to Bin":
                begin
                    GetBin(Location.Code, BinCode);
                    if Bin."Special Equipment Code" <> '' then
                        exit(Bin."Special Equipment Code");

                    if SKU."Special Equipment Code" <> '' then
                        exit(SKU."Special Equipment Code");

                    exit(Item."Special Equipment Code")
                end;
            Location."Special Equipment"::"According to SKU/Item":
                begin
                    if SKU."Special Equipment Code" <> '' then
                        exit(SKU."Special Equipment Code");

                    if Item."Special Equipment Code" <> '' then
                        exit(Item."Special Equipment Code");

                    GetBin(Location.Code, BinCode);
                    exit(Bin."Special Equipment Code")
                end
        end
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            Location.Get(LocationCode)
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            Bin.Get(LocationCode, BinCode)
    end;

    local procedure GetItemAndSKU(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        if Item."No." <> ItemNo then begin
            Item.Get(ItemNo);
            GetWarehouseClassCode;
        end;
        if (ItemNo <> SKU."Item No.") or
           (LocationCode <> SKU."Location Code") or
           (VariantCode <> SKU."Variant Code")
        then begin
            if not SKU.Get(Location.Code, Item."No.", PostedWhseRcptLine."Variant Code") then
                Clear(SKU)
        end;

        OnAfterGetItemAndSKU(Location, Item, SKU);
    end;

    local procedure GetWarehouseClassCode()
    begin
        WarehouseClassCode := Item."Warehouse Class Code";
    end;

    local procedure GetPutAwayUOM()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPutAwayUOM(PutAwayItemUOM, PostedWhseRcptLine, IsHandled);
        if IsHandled then
            exit;

        if not Location."Directed Put-away and Pick" then begin
            PutAwayItemUOM.Code := PostedWhseRcptLine."Unit of Measure Code";
            PutAwayItemUOM."Qty. per Unit of Measure" := PostedWhseRcptLine."Qty. per Unit of Measure";
            exit;
        end;
        if (PutAwayItemUOM."Item No." <> '') and (PutAwayItemUOM.Code <> '') and
           (SKU."Item No." = PutAwayItemUOM."Item No.") and
           (SKU."Put-away Unit of Measure Code" = PutAwayItemUOM.Code)
        then
            exit;

        if (SKU."Put-away Unit of Measure Code" <> '') and
           ((Item."No." <> PutAwayItemUOM."Item No.") or
            (SKU."Put-away Unit of Measure Code" <> PutAwayItemUOM.Code))
        then begin
            if not PutAwayItemUOM.Get(Item."No.", SKU."Put-away Unit of Measure Code") then
                if not PutAwayItemUOM.Get(Item."No.", Item."Put-away Unit of Measure Code") then
                    PutAwayItemUOM.Get(Item."No.", PostedWhseRcptLine."Unit of Measure Code")
        end else
            if (Item."No." <> PutAwayItemUOM."Item No.") or
               (Item."Put-away Unit of Measure Code" <> PutAwayItemUOM.Code)
            then
                if not PutAwayItemUOM.Get(Item."No.", Item."Put-away Unit of Measure Code") then
                    PutAwayItemUOM.Get(Item."No.", PostedWhseRcptLine."Unit of Measure Code")
    end;

    local procedure GetPutAwayTemplate()
    begin
        if SKU."Put-away Template Code" <> '' then begin
            if SKU."Put-away Template Code" <> PutAwayTemplHeader.Code then
                if not PutAwayTemplHeader.Get(SKU."Put-away Template Code") then
                    if (Item."Put-away Template Code" <> '') and
                       (Item."Put-away Template Code" <> PutAwayTemplHeader.Code)
                    then
                        if not PutAwayTemplHeader.Get(Item."Put-away Template Code") then
                            if (PutAwayTemplHeader.Code <> Location."Put-away Template Code")
                            then
                                PutAwayTemplHeader.Get(Location."Put-away Template Code");
        end else
            if (Item."Put-away Template Code" <> '') or
               (Item."Put-away Template Code" <> PutAwayTemplHeader.Code)
            then begin
                if not PutAwayTemplHeader.Get(Item."Put-away Template Code") then
                    if (PutAwayTemplHeader.Code <> Location."Put-away Template Code")
                    then
                        PutAwayTemplHeader.Get(Location."Put-away Template Code")
            end else
                PutAwayTemplHeader.Get(Location."Put-away Template Code")
    end;

    procedure SetValues(NewAssignedID: Code[50]; NewSortActivity: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; NewDoNotFillQtytoHandle: Boolean; BreakbulkFilter2: Boolean)
    begin
        AssignedID := NewAssignedID;
        SortActivity := NewSortActivity;
        DoNotFillQtytoHandle := NewDoNotFillQtytoHandle;
        BreakbulkFilter := BreakbulkFilter2;

        OnAfterSetValues(AssignedID, SortActivity, DoNotFillQtytoHandle, BreakbulkFilter);
    end;

    procedure GetWhseActivHeaderNo(var FirstPutAwayNo: Code[20]; var LastPutAwayNo: Code[20])
    begin
        FirstPutAwayNo := WhseActivHeader."No.";
        LastPutAwayNo := WhseActivHeader."No.";

        OnAfterGetWhseActivHeaderNo(FirstPutAwayNo, LastPutAwayNo);
    end;

    procedure EverythingIsHandled(): Boolean
    begin
        exit(EverythingHandled);
    end;

    local procedure InsertTempWhseActivHeader(WhseActivHeader: Record "Warehouse Activity Header")
    begin
        TempWhseActivHeader.Init();
        TempWhseActivHeader := WhseActivHeader;
        TempWhseActivHeader.Insert();
    end;

    procedure GetFirstPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header"): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        Found: Boolean;
    begin
        Found := TempWhseActivHeader.Find('-');
        if Found then begin
            WhseActivHeader := TempWhseActivHeader;
            WhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
            WhseActivLine.SetRange("No.", WhseActivHeader."No.");
            Found := WhseActivLine.FindFirst;
        end;
        exit(Found);
    end;

    procedure GetNextPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header"): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        Found: Boolean;
    begin
        Found := TempWhseActivHeader.Next <> 0;
        if Found then begin
            WhseActivHeader := TempWhseActivHeader;
            WhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
            WhseActivLine.SetRange("No.", WhseActivHeader."No.");
            Found := WhseActivLine.FindFirst;
        end;
        exit(Found);
    end;

    procedure GetMessage(var ErrText000: Text[80])
    begin
        ErrText000 := MessageText;
    end;

    procedure UpdateTempWhseItemTrkgLines(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer)
    begin
        TempWhseItemTrkgLine.Init();
        EntryNo += 1;
        TempWhseItemTrkgLine."Entry No." := EntryNo;
        TempWhseItemTrkgLine."Source Type" := SourceType;
        TempWhseItemTrkgLine."Source ID" := PostedWhseRcptLine."No.";
        TempWhseItemTrkgLine."Source Ref. No." := PostedWhseRcptLine."Line No.";
        TempWhseItemTrkgLine.CopyTrackingFromPostedWhseRcptLine(PostedWhseRcptLine);
        TempWhseItemTrkgLine."Quantity (Base)" := QtyToPickBase;
        OnUpdateTempWhseItemTrkgLines(TempWhseItemTrkgLine, PostedWhseRcptLine);
        TempWhseItemTrkgLine.Insert();
    end;

    procedure GetQtyHandledBase(var TempRec: Record "Whse. Item Tracking Line" temporary) QtyHandledBase: Decimal
    begin
        TempRec.Reset();
        TempRec.DeleteAll();
        QtyHandledBase := 0;
        if TempWhseItemTrkgLine.Find('-') then
            repeat
                QtyHandledBase += TempWhseItemTrkgLine."Quantity (Base)";
                TempRec := TempWhseItemTrkgLine;
                TempRec.Insert();
            until TempWhseItemTrkgLine.Next = 0;
        TempWhseItemTrkgLine.DeleteAll();
        exit(QtyHandledBase);
    end;

    local procedure MakeCrossDockPutAway()
    var
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UseCrossDock: Boolean;
        UOMCode: Code[10];
    begin
        with PostedWhseRcptLine do begin
            if not CrossDock then
                exit;
            CrossDockMgt.GetUseCrossDock(UseCrossDock, "Location Code", "Item No.");
            if not UseCrossDock then
                exit;
            if "Qty. Cross-Docked" <> 0 then begin
                if not Location."Bin Mandatory" then
                    PutAwayItemUOM.Get("Item No.", "Unit of Measure Code")
                else
                    Bin.Get("Location Code", "Cross-Dock Bin Code");
                LineNo := LineNo + 10000;
                xPostedWhseRcptLine := PostedWhseRcptLine;
                if Location."Directed Put-away and Pick" then
                    Quantity := "Qty. Cross-Docked (Base)" / PutAwayItemUOM."Qty. per Unit of Measure"
                else
                    Quantity := "Qty. Cross-Docked";

                QtyToPutAwayBase := "Qty. Cross-Docked (Base)";
                RemQtyToPutAwayBase := "Qty. Cross-Docked (Base)";
                "Zone Code" := "Cross-Dock Zone Code";
                "Bin Code" := "Cross-Dock Bin Code";
                if Location."Directed Put-away and Pick" then
                    UOMCode := PutAwayItemUOM.Code
                else
                    UOMCode := "Unit of Measure Code";
                if CrossDockBinContent.Get("Location Code", "Cross-Dock Bin Code", "Item No.", "Variant Code", UOMCode) then
                    NewCrossDockBinContent := false
                else
                    NewCrossDockBinContent := true;
                if not Location."Bin Mandatory" then
                    NewCrossDockBinContent := false;
                CrossDockInfo := 1;
                CalcQtyToPutAway(false, NewCrossDockBinContent);
                CrossDockInfo := 2;
                PostedWhseRcptLine := xPostedWhseRcptLine;
                QtyToPutAwayBase := "Qty. (Base)" - "Qty. Cross-Docked (Base)";
                RemQtyToPutAwayBase := "Qty. (Base)" - "Qty. Cross-Docked (Base)";
                if Location."Directed Put-away and Pick" then
                    Quantity := ("Qty. (Base)" - "Qty. Cross-Docked (Base)") / PutAwayItemUOM."Qty. per Unit of Measure"
                else
                    Quantity := Quantity - "Qty. Cross-Docked";
                "Qty. (Base)" := Quantity * "Qty. per Unit of Measure";
                EverythingHandled := false;
            end;
        end;

        OnAfterMakeCrossDockPutAway(PostedWhseRcptLine);
    end;

    procedure SetCrossDockValues(NewCrossDock: Boolean)
    begin
        CrossDock := NewCrossDock;
    end;

    procedure DeleteBlankBinContent(WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        if WarehouseActivityLine.FindSet then
            repeat
                WarehouseActivityLine.DeleteBinContent(WarehouseActivityLine."Action Type"::Place);
            until WarehouseActivityLine.Next = 0;
    end;

    local procedure IsFloatingBin(): Boolean
    begin
        if Bin.Dedicated = true then
            exit(false);
        with BinContent do begin
            Reset;
            SetRange("Location Code", Bin."Location Code");
            SetRange("Zone Code", Bin."Zone Code");
            SetRange("Bin Code", Bin.Code);
            if FindSet then
                repeat
                    if Fixed or Default then
                        exit(false);
                until Next = 0;
            exit(true);
        end;
    end;

    local procedure "Max"(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 >= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure NextBin(): Boolean
    var
        BinFound: Boolean;
        IsHandled: Boolean;
    begin
        if EverythingHandled then
            exit(false);

        IsHandled := false;
        OnNextBin(PostedWhseRcptLine, PutAwayTemplLine, Bin, BinFound, IsHandled);
        if not IsHandled then
            BinFound := Bin.Next(-1) <> 0;

        exit(BinFound);
    end;

    local procedure NextBinContent(): Boolean
    var
        BinContentFound: Boolean;
        IsHandled: Boolean;
    begin
        if EverythingHandled then
            exit(false);

        IsHandled := false;
        OnNextBinContent(PostedWhseRcptLine, PutAwayTemplLine, BinContent, BinContentFound, IsHandled);
        if not IsHandled then
            BinContentFound := BinContent.Next(-1) <> 0;

        exit(BinContentFound);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignPlaceBinZone(var WarehouseActivityLine: Record "Warehouse Activity Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemAndSKU(Location: Record Location; var Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseActivHeaderNo(var FirstPutAwayNo: Code[20]; var LastPutAwayNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeCrossDockPutAway(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetValues(var AssignedID: Code[50]; var SortActivity: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; var DoNotFillQtytoHandle: Boolean; var BreakbulkFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseActivHeaderInsert(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailCubageAndWeight(var Bin: Record Bin; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PutAwayItemUOM: Record "Item Unit of Measure"; var QtyToPutAwayBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewWhseActivity(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivHeader: Record "Warehouse Activity Header"; var Location: Record Location; InsertHeader: Boolean; Bin: Record Bin; ActionType: Option ,Take,Place; LineNo: Integer; BreakbulkNo: Integer; BreakbulkFilter: Boolean; QtyToHandleBase: Decimal; BreakPackage: Boolean; EmptyZoneBin: Boolean; Breakbulk: Boolean; CrossDockInfo: Option; PutAwayItemUOM: Record "Item Unit of Measure"; DoNotFillQtytoHandle: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPutAwayUOM(var PutAwayItemUOM: Record "Item Unit of Measure"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivHeaderInsert(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCreateNewWhseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateBinContentOnBeforeNewBinContentInsert(var BinContent: Record "Bin Content"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewWhseActivityOnAfterAssignBinZone(var WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBin(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PutAwayTemplateLine: Record "Put-away Template Line"; var Bin: Record Bin; var BinFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBinContent(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PutAwayTemplateLine: Record "Put-away Template Line"; var BinContent: Record "Bin Content"; var BinContentFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextBin(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PutAwayTemplateLine: Record "Put-away Template Line"; var Bin: Record Bin; var BinFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextBinContent(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PutAwayTemplateLine: Record "Put-away Template Line"; var BinContent: Record "Bin Content"; var BinContentFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTempWhseItemTrkgLines(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;
}


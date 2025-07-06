namespace Microsoft.Warehouse.Activity;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Telemetry;

codeunit 7313 "Create Put-away"
{
    Permissions = tabledata "Production Order" = rm,
                  tabledata "Prod. Order Line" = rm;
    TableNo = "Posted Whse. Receipt Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(Rec, IsHandled);
        if IsHandled then
            exit;

        PostedWhseReceiptLine.Copy(Rec);
        Code();
        Rec.Copy(PostedWhseReceiptLine);

        OnAfterRun(Rec);
    end;

    var
        CrossDockBinContent: Record "Bin Content";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        TempPostedWhseReceiptLine: Record "Posted Whse. Receipt Line" temporary;
        CurrWarehouseActivityHeader: Record "Warehouse Activity Header";
        CurrWarehouseActivityLine: Record "Warehouse Activity Line";
        CurrLocation: Record Location;
        CurrBinContent: Record "Bin Content";
        CurrBin: Record Bin;
        CurrItem: Record Item;
        CurrStockkeepingUnit: Record "Stockkeeping Unit";
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PutAwayItemUnitOfMeasure: Record "Item Unit of Measure";
        BasePutAwayItemUnitOfMeasure: Record "Item Unit of Measure";
        TempWarehouseActivityHeader: Record "Warehouse Activity Header" temporary;
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        TempProductionOrderForWhsePutAwayForProdOutput: Record "Production Order" temporary;
        TempItemJournalLineForWhsePutAwayForProdOutput: Record "Item Journal Line" temporary;
        WMSManagement: Codeunit "WMS Management";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MfgPutAwayHelper: Codeunit "Mfg. Put Away Helper";
        BinTypeFilter: Text;
        MessageText: Text;
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
        SortActivity: Enum "Whse. Activity Sorting Method";
        NewCrossDockBinContent: Boolean;
        CrossDock: Boolean;
        CalledFromPutAwayWorksheet: Boolean;
        CrossDockInfo: Option;
        TemplateDoesNotExistMsg: Label 'There are no %1 created.', Comment = '%1 = put-away template header or line table caption';
        PutawayNotCreatedMsg: Label 'Put-away not created for one or more items based on the template and capacity.';
        NoDefaultBinMsg: Label 'There is no default bin for one or more item.';
        BinPolicyTelemetryCategoryTok: Label 'Bin Policy', Locked = true;
        DefaultBinPutawayPolicyTelemetryTok: Label 'Default Bin Put-away Policy in used for inventory put-away.', Locked = true;
        PutawayTemplateBinPutawayPolicyTelemetryTok: Label 'Put-away template Bin Put-away Policy in used for inventory put-away.', Locked = true;
        PutAwayActivityNoHasBeenCreatedMsg: Label 'Put-away activity no. %1 has been created.', Comment = '%1 = Put-away Activity No. ';
        NothingToCreateErr: Label 'There is nothing to create.';

    local procedure "Code"()
    var
        BinType: Record "Bin Type";
        BinContentQtyBase: Decimal;
        TakeLineNo: Integer;
        BreakPackage: Boolean;
        Breakbulk: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCode(PostedWhseReceiptLine);

        QtyToPickBase := 0;
        QtyToPutAwayBase := 0;
        CrossDockInfo := 0;
        MessageText := '';
        EverythingHandled := false;
        TempWarehouseActivityLine.DeleteAll();

        GetLocation(PostedWhseReceiptLine."Location Code");
        if not CurrLocation."Bin Mandatory" then begin
            MakeCrossDockPutAway();
            CalcQtyToPutAway(true, false);
            exit;
        end;

        case CurrLocation."Put-away Bin Policy" of
            CurrLocation."Put-away Bin Policy"::"Default Bin":
                begin
                    FeatureTelemetry.LogUsage('0000KP5', BinPolicyTelemetryCategoryTok, DefaultBinPutawayPolicyTelemetryTok);
                    RemQtyToPutAwayBase := PostedWhseReceiptLine."Qty. (Base)";
                    MakeCrossDockPutAway();
                    Clear(CurrBin);
                    if WMSManagement.GetDefaultBin(PostedWhseReceiptLine."Item No.", PostedWhseReceiptLine."Variant Code", PostedWhseReceiptLine."Location Code", CurrBin.Code) then begin
                        CurrBin.SetLoadFields(Code, Dedicated, "Bin Ranking", "Bin Type Code", Empty, "Maximum Cubage", "Maximum Weight", "Location Code", "Zone Code", "Warehouse Class Code", "Block Movement", "Cross-Dock Bin", "Special Equipment Code");
                        CurrBin.Get(CurrLocation.Code, CurrBin.Code);
                        OnCodeOnAfterGetDefaultBin(PostedWhseReceiptLine, CurrBin);
                        QtyToPutAwayBase := RemQtyToPutAwayBase;
                        LineNo := LineNo + 10000;
                        CalcQtyToPutAway(false, false);
                    end;
                end;
            CurrLocation."Put-away Bin Policy"::"Put-away Template":
                begin
                    FeatureTelemetry.LogUsage('0000KP6', BinPolicyTelemetryCategoryTok, PutawayTemplateBinPutawayPolicyTelemetryTok);
                    GetItemAndSKU(PostedWhseReceiptLine."Item No.", PostedWhseReceiptLine."Location Code", PostedWhseReceiptLine."Variant Code");
                    GetPutAwayUOM();
                    GetPutAwayTemplate();
                    if PutAwayTemplateHeader.Code = '' then begin
                        MessageText := StrSubstNo(TemplateDoesNotExistMsg, PutAwayTemplateHeader.TableCaption());
                        exit;
                    end;

                    PutAwayTemplateLine.Reset();
                    PutAwayTemplateLine.SetRange("Put-away Template Code", PutAwayTemplateHeader.Code);
                    OnCodeOnAfterFilterPutAwayTemplateLine(PutAwayTemplateLine, PostedWhseReceiptLine);
                    if not PutAwayTemplateLine.Find('-') then begin
                        MessageText := StrSubstNo(TemplateDoesNotExistMsg, PutAwayTemplateLine.TableCaption());
                        exit;
                    end;

                    RemQtyToPutAwayBase := PostedWhseReceiptLine."Qty. (Base)";

                    if CurrLocation."Directed Put-away and Pick" then begin
                        if PostedWhseReceiptLine."Qty. per Unit of Measure" > PutAwayItemUnitOfMeasure."Qty. per Unit of Measure" then
                            CreateBreakPackageLines(PostedWhseReceiptLine);

                        if RemQtyToPutAwayBase = 0 then
                            exit;
                    end;

                    MakeCrossDockPutAway();

                    LineNo := LineNo + 10000;
                    IsHandled := false;
                    OnCodeOnBeforeCreateBinTypeFilter(PostedWhseReceiptLine, CurrWarehouseActivityLine, CurrWarehouseActivityHeader, CurrLocation, LineNo, BreakbulkNo, BreakbulkFilter, QtyToPutAwayBase, RemQtyToPutAwayBase, BreakPackage, Breakbulk, CrossDockInfo, PutAwayItemUnitOfMeasure, DoNotFillQtytoHandle, EverythingHandled, IsHandled);
                    if not IsHandled then
                        if CurrLocation."Directed Put-away and Pick" then
                            BinType.MakeBinTypeFilter(BinTypeFilter, BinType.FieldNo("Put away"));

                    IsHandled := false;
                    OnCodeOnBeforeSearchBin(PostedWhseReceiptLine, CurrWarehouseActivityLine, CurrWarehouseActivityHeader, CurrLocation, LineNo, BreakbulkNo, BreakbulkFilter, QtyToPutAwayBase, RemQtyToPutAwayBase, BreakPackage, Breakbulk, CrossDockInfo, PutAwayItemUnitOfMeasure, DoNotFillQtytoHandle, EverythingHandled, IsHandled);
                    if not IsHandled then
                        repeat
                            QtyToPutAwayBase := RemQtyToPutAwayBase;
                            IsHandled := false;
                            OnBeforeApplyPutAwayTemplateLine(PostedWhseReceiptLine, PutAwayTemplateLine, CurrLocation, CurrBin, IsHandled);
                            if IsHandled then
                                CalcQtyToPutAway(false, false)
                            else
                                if not (PutAwayTemplateLine."Find Empty Bin" or PutAwayTemplateLine."Find Floating Bin") or
                                   PutAwayTemplateLine."Find Fixed Bin" or
                                   PutAwayTemplateLine."Find Same Item" or
                                   PutAwayTemplateLine."Find Unit of Measure Match" or
                                   PutAwayTemplateLine."Find Bin w. Less than Min. Qty"
                                then begin
                                    // Calc Availability per Bin Content
                                    if FindBinContent(PostedWhseReceiptLine."Location Code", PostedWhseReceiptLine."Item No.", PostedWhseReceiptLine."Variant Code", WarehouseClassCode) then
                                        repeat
                                            IsHandled := false;
                                            OnBeforeCalcAvailabilityPerBinContent(CurrBinContent, WarehouseClassCode, IsHandled);
                                            if not IsHandled then
                                                if CurrBinContent."Bin Code" <> PostedWhseReceiptLine."Bin Code" then begin
                                                    QtyToPutAwayBase := RemQtyToPutAwayBase;

                                                    CurrBinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
                                                    BinContentQtyBase :=
                                                      CurrBinContent."Quantity (Base)" + CurrBinContent."Put-away Quantity (Base)" + CurrBinContent."Positive Adjmt. Qty. (Base)";
                                                    if (not PutAwayTemplateLine."Find Bin w. Less than Min. Qty" or
                                                        (BinContentQtyBase < CurrBinContent."Min. Qty." * CurrBinContent."Qty. per Unit of Measure")) and
                                                       (not PutAwayTemplateLine."Find Empty Bin" or (BinContentQtyBase <= 0))
                                                    then begin
                                                        if CurrBinContent."Max. Qty." <> 0 then begin
                                                            QtyToPutAwayBase := Max(CurrBinContent."Max. Qty." * CurrBinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                                                            if QtyToPutAwayBase > RemQtyToPutAwayBase then
                                                                QtyToPutAwayBase := RemQtyToPutAwayBase;
                                                        end;

                                                        GetBin(PostedWhseReceiptLine."Location Code", CurrBinContent."Bin Code");
                                                        CalcQtyToPutAway(false, false);
                                                    end;
                                                end;
                                        until not NextBinContent();
                                end else
                                    // Calc Availability per Bin
                                    if FindBin(PostedWhseReceiptLine."Location Code", WarehouseClassCode) then
                                        repeat
                                            if CurrBin.Code <> PostedWhseReceiptLine."Bin Code" then begin
                                                QtyToPutAwayBase := RemQtyToPutAwayBase;
                                                if CurrBinContent.Get(
                                                         PostedWhseReceiptLine."Location Code", CurrBin.Code, PostedWhseReceiptLine."Item No.", PostedWhseReceiptLine."Variant Code", PutAwayItemUnitOfMeasure.Code)
                                                then begin
                                                    CurrBinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
                                                    BinContentQtyBase :=
                                                      CurrBinContent."Quantity (Base)" +
                                                      CurrBinContent."Put-away Quantity (Base)" +
                                                      CurrBinContent."Positive Adjmt. Qty. (Base)";

                                                    if CurrBinContent."Max. Qty." <> 0 then begin
                                                        QtyToPutAwayBase :=
                                                          Max(CurrBinContent."Max. Qty." * CurrBinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                                                        if QtyToPutAwayBase > RemQtyToPutAwayBase then
                                                            QtyToPutAwayBase := RemQtyToPutAwayBase;
                                                    end;
                                                    CalcQtyToPutAway(false, false);
                                                    BinContentQtyBase := CurrBinContent.CalcQtyBase();
                                                    if CurrBinContent."Max. Qty." <> 0 then begin
                                                        QtyToPutAwayBase :=
                                                          Max(CurrBinContent."Max. Qty." * CurrBinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                                                        if QtyToPutAwayBase > RemQtyToPutAwayBase then
                                                            QtyToPutAwayBase := RemQtyToPutAwayBase;
                                                    end;
                                                end else
                                                    CalcQtyToPutAway(false, true);
                                            end;
                                        until not NextBin();
                        until (PutAwayTemplateLine.Next() = 0) or EverythingHandled;
                end;
            else
                OnCreatePutawayForPostedWhseReceiptLine(PostedWhseReceiptLine, RemQtyToPutAwayBase, EverythingHandled);
        end;

        if not EverythingHandled and CurrLocation."Always Create Put-away Line" then begin
            LineNo := LineNo + 10000;
            QtyToPutAwayBase := RemQtyToPutAwayBase;
            CalcQtyToPutAway(true, false);
        end;

        if QtyToPickBase > 0 then begin
            if InsertBreakPackageLines() then begin
                TakeLineNo := OldLineNo + 30000;
                Breakbulk := true;
            end else begin
                TakeLineNo := OldLineNo + 10000;
                if (PostedWhseReceiptLine."Unit of Measure Code" <> PutAwayItemUnitOfMeasure.Code) and CurrLocation."Directed Put-away and Pick" then
                    BreakPackage := true;
            end;
            CreateNewWhseActivity(
                  PostedWhseReceiptLine, CurrWarehouseActivityLine, Enum::"Warehouse Action Type"::Take, TakeLineNo, 0, QtyToPickBase, false, BreakPackage, false, Breakbulk);

            OnCodeOnAfterCreateNewWhseActivity(CurrWarehouseActivityLine);

            OldLineNo := LineNo;
        end else
            if MessageText = '' then
                if CurrLocation."Put-away Bin Policy" = Enum::"Put-away Bin Policy"::"Put-away Template" then
                    MessageText := PutawayNotCreatedMsg
                else
                    if CurrLocation."Put-away Bin Policy" = Enum::"Put-away Bin Policy"::"Default Bin" then
                        MessageText := NoDefaultBinMsg;

        OnAfterCode(CurrWarehouseActivityHeader);
    end;

    local procedure CreateBreakPackageLines(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateBreakPackageLines(PostedWhseReceiptLine, TempWarehouseActivityLine, LineNo, BreakbulkNo, RemQtyToPutAwayBase, IsHandled);
        if IsHandled then
            exit;

        LineNo := LineNo + 10000;
        BreakbulkNo := BreakbulkNo + 1;
        CreateNewWhseActivity(
          PostedWhseReceiptLine, TempWarehouseActivityLine, Enum::"Warehouse Action Type"::Take, LineNo,
          BreakbulkNo, PostedWhseReceiptLine."Qty. (Base)", false, true, false, false);
        LineNo := LineNo + 10000;
        CreateNewWhseActivity(
          PostedWhseReceiptLine, TempWarehouseActivityLine, Enum::"Warehouse Action Type"::Place, LineNo,
          BreakbulkNo, RemQtyToPutAwayBase, false, false, false, true);
    end;

    local procedure InsertBreakPackageLines(): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        if TempWarehouseActivityLine.Find('-') then begin
            repeat
                WhseActivLine.Init();
                WhseActivLine := TempWarehouseActivityLine;
                WhseActivLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                WhseActivLine."No." := CurrWarehouseActivityHeader."No.";
                WhseActivLine."Bin Code" := PostedWhseReceiptLine."Bin Code";
                WhseActivLine."Zone Code" := PostedWhseReceiptLine."Zone Code";
                WhseActivLine.Insert();
                OnAfterWhseActivLineInsert(WhseActivLine);
            until TempWarehouseActivityLine.Next() = 0;
            exit(true);
        end
    end;

    local procedure CreateNewWhseActivity(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var WhseActivLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; LineNo: Integer;
                                                                                                                                                                       BreakbulkNo: Integer;
                                                                                                                                                                       QtyToHandleBase: Decimal;
                                                                                                                                                                       InsertHeader: Boolean;
                                                                                                                                                                       BreakPackage: Boolean;
                                                                                                                                                                       EmptyZoneBin: Boolean;
                                                                                                                                                                       Breakbulk: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateNewWhseActivity(
          PostedWhseRcptLine, WhseActivLine, CurrWarehouseActivityHeader, CurrLocation, InsertHeader, CurrBin, ActionType.AsInteger(), LineNo,
          BreakbulkNo, BreakbulkFilter, QtyToHandleBase, BreakPackage, EmptyZoneBin, Breakbulk, CrossDockInfo, PutAwayItemUnitOfMeasure,
          DoNotFillQtytoHandle, IsHandled);
        if IsHandled then
            exit;

        if (CurrWarehouseActivityHeader."No." = '') and InsertHeader then
            InsertWhseActivHeader(PostedWhseRcptLine);

        WhseActivLine.Init();
        WhseActivLine."Activity Type" := CurrWarehouseActivityHeader.Type;
        WhseActivLine."No." := CurrWarehouseActivityHeader."No.";
        WhseActivLine."Line No." := LineNo;
        WhseActivLine."Action Type" := ActionType;
        WhseActivLine."Source Type" := PostedWhseRcptLine."Source Type";
        WhseActivLine."Source Subtype" := PostedWhseRcptLine."Source Subtype";
        WhseActivLine."Source No." := PostedWhseRcptLine."Source No.";
        WhseActivLine."Source Line No." := PostedWhseRcptLine."Source Line No.";
        WhseActivLine."Source Document" := PostedWhseRcptLine."Source Document";
        if WhseActivLine."Source Type" = 0 then
            WhseActivLine."Whse. Document Type" := WhseActivLine."Whse. Document Type"::"Internal Put-away"
        else
            WhseActivLine."Whse. Document Type" := WhseActivLine."Whse. Document Type"::Receipt;
        WhseActivLine."Whse. Document No." := PostedWhseRcptLine."No.";
        WhseActivLine."Whse. Document Line No." := PostedWhseRcptLine."Line No.";
        WhseActivLine."Location Code" := CurrLocation.Code;
        WhseActivLine."Shelf No." := PostedWhseRcptLine."Shelf No.";
        WhseActivLine."Due Date" := PostedWhseRcptLine."Due Date";
        WhseActivLine."Starting Date" := PostedWhseRcptLine."Starting Date";
        WhseActivLine."Breakbulk No." := BreakbulkNo;
        WhseActivLine."Original Breakbulk" := Breakbulk;
        if BreakbulkFilter then
            WhseActivLine.Breakbulk := Breakbulk;
        case ActionType of
            ActionType::Take:
                begin
                    WhseActivLine."Bin Code" := PostedWhseRcptLine."Bin Code";
                    WhseActivLine."Zone Code" := PostedWhseRcptLine."Zone Code";
                end;
            ActionType::Place:
                if not EmptyZoneBin then
                    AssignPlaceBinZone(WhseActivLine, PostedWhseRcptLine, CurrLocation, CurrBin)
                else begin
                    WhseActivLine."Bin Code" := '';
                    WhseActivLine."Zone Code" := '';
                end
        end;
        OnCreateNewWhseActivityOnAfterAssignBinZone(WhseActivLine);
        WhseActivLine."Item No." := PostedWhseRcptLine."Item No.";
        WhseActivLine."Variant Code" := PostedWhseRcptLine."Variant Code";
        WhseActivLine.Description := PostedWhseRcptLine.Description;
        WhseActivLine."Description 2" := PostedWhseRcptLine."Description 2";
        if WhseActivLine."Bin Code" <> '' then begin
            GetBin(WhseActivLine."Location Code", WhseActivLine."Bin Code");
            WhseActivLine.Dedicated := CurrBin.Dedicated;
            WhseActivLine."Bin Ranking" := CurrBin."Bin Ranking";
            WhseActivLine."Bin Type Code" := CurrBin."Bin Type Code";
            GetItemAndSKU(WhseActivLine."Item No.", WhseActivLine."Location Code", WhseActivLine."Variant Code");
            WhseActivLine."Special Equipment Code" := GetSpecEquipmentCode(WhseActivLine."Bin Code");
        end;
        WhseActivLine."Cross-Dock Information" := CrossDockInfo;
        if BreakPackage or (ActionType = ActionType::" ") or
           not CurrLocation."Directed Put-away and Pick"
        then begin
            WhseActivLine."Unit of Measure Code" := PostedWhseRcptLine."Unit of Measure Code";
            WhseActivLine."Qty. per Unit of Measure" := PostedWhseRcptLine."Qty. per Unit of Measure";
            WhseActivLine."Qty. Rounding Precision" := PostedWhseRcptLine."Qty. Rounding Precision";
            WhseActivLine."Qty. Rounding Precision (Base)" := PostedWhseRcptLine."Qty. Rounding Precision (Base)";
        end else begin
            WhseActivLine."Unit of Measure Code" := PutAwayItemUnitOfMeasure.Code;
            WhseActivLine."Qty. per Unit of Measure" := PutAwayItemUnitOfMeasure."Qty. per Unit of Measure";
            WhseActivLine."Qty. Rounding Precision" := PutAwayItemUnitOfMeasure."Qty. Rounding Precision";
            WhseActivLine."Qty. Rounding Precision (Base)" := BasePutAwayItemUnitOfMeasure."Qty. Rounding Precision";
        end;
        WhseActivLine.Validate(
          Quantity, UnitOfMeasureManagement.RoundQty(QtyToHandleBase / WhseActivLine."Qty. per Unit of Measure", WhseActivLine."Qty. Rounding Precision"));
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
        if PostedWhseRcptLine."Serial No." <> '' then
            WhseActivLine.ValidateQtyWhenSNDefined();

        WhseActivLine.CopyTrackingFromPostedWhseRcptLine(PostedWhseRcptLine);
        WhseActivLine."Warranty Date" := PostedWhseRcptLine."Warranty Date";
        WhseActivLine."Expiration Date" := PostedWhseRcptLine."Expiration Date";
        OnBeforeWhseActivLineInsert(WhseActivLine, PostedWhseRcptLine);
        WhseActivLine.Insert();
        OnAfterWhseActivLineInsert(WhseActivLine);
    end;

    procedure AssignPlaceBinZone(var WhseActivLine: Record "Warehouse Activity Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; Location: Record Location; Bin: Record Bin)
    var
        Bin2: Record Bin;
        BinCodeFilterText: Text[250];
    begin
        WhseActivLine."Bin Code" := Bin.Code;
        WhseActivLine."Zone Code" := Bin."Zone Code";
        if Location.IsBWReceive() and
           (CrossDockInfo <> WhseActivLine."Cross-Dock Information"::"Cross-Dock Items") and
           ((Bin.Code = PostedWhseRcptLine."Bin Code") or Location.IsBinBWReceiveOrShip(Bin.Code))
        then begin
            Bin2.SetRange("Location Code", Location.Code);
            if Location."Receipt Bin Code" <> '' then
                AddToFilterText(BinCodeFilterText, '&', '<>', Location."Receipt Bin Code");
            if Location."Shipment Bin Code" <> '' then
                AddToFilterText(BinCodeFilterText, '&', '<>', Location."Shipment Bin Code");
            if PostedWhseRcptLine."Bin Code" <> '' then
                AddToFilterText(BinCodeFilterText, '&', '<>', PostedWhseRcptLine."Bin Code");
            OnAssignPlaceBinZoneOnBeforeApplyBinCodeFilter(BinCodeFilterText, Location, PostedWhseRcptLine);
            if BinCodeFilterText <> '' then
                Bin2.SetFilter(Code, BinCodeFilterText);
            OnAssignPlaceBinZoneOnAfterBin2SetFilters(PostedWhseRcptLine, WhseActivLine, Location, Bin2);
            Bin2.SetLoadFields(Code, "Zone Code");
            if Bin2.FindFirst() then begin
                WhseActivLine."Bin Code" := Bin2.Code;
                WhseActivLine."Zone Code" := Bin2."Zone Code";
            end else begin
                WhseActivLine."Bin Code" := '';
                WhseActivLine."Zone Code" := '';
            end;
        end;

        OnAfterAssignPlaceBinZone(WhseActivLine);
    end;

    local procedure AddToFilterText(var TextVar: Text[250]; Separator: Code[1]; Comparator: Code[2]; Addendum: Code[20])
    begin
        if TextVar = '' then
            TextVar := Comparator + '''' + Addendum + ''''
        else
            TextVar += Separator + Comparator + '''' + Addendum + '''';
    end;

    local procedure InsertWhseActivHeader(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        OnBeforeInsertWhseActivHeader(PostedWhseRcptLine);

        CurrWarehouseActivityHeader.LockTable();
        CurrWarehouseActivityHeader.Init();
        CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::"Put-away";
        CurrWarehouseActivityHeader."Location Code" := PostedWhseRcptLine."Location Code";
        CurrWarehouseActivityHeader.Validate("Assigned User ID", AssignedID);
        CurrWarehouseActivityHeader."Sorting Method" := SortActivity;
        CurrWarehouseActivityHeader."Breakbulk Filter" := BreakbulkFilter;
        OnBeforeWhseActivHeaderInsert(CurrWarehouseActivityHeader, PostedWhseRcptLine);
        CurrWarehouseActivityHeader.Insert(true);
        OnAfterWhseActivHeaderInsert(CurrWarehouseActivityHeader);
        InsertTempWhseActivHeader(CurrWarehouseActivityHeader);
        CurrWarehouseActivityLine.LockTable();
    end;

    local procedure FindBinContent(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WarehouseClassCode: Code[10]): Boolean
    var
        BinContentFound: Boolean;
        IsHandled: Boolean;
    begin
        CurrBinContent.Reset();
        CurrBinContent.ReadIsolation(IsolationLevel::ReadCommitted);
        CurrBinContent.SetCurrentKey("Location Code", "Warehouse Class Code", Fixed, "Bin Ranking");
        CurrBinContent.SetRange("Location Code", LocationCode);
        CurrBinContent.SetRange("Warehouse Class Code", WarehouseClassCode);
        if PutAwayTemplateLine."Find Fixed Bin" then
            CurrBinContent.SetRange(Fixed, true)
        else
            CurrBinContent.SetRange(Fixed, false);
        CurrBinContent.SetFilter("Block Movement", '%1|%2', CurrBinContent."Block Movement"::" ", CurrBinContent."Block Movement"::Outbound);
        CurrBinContent.SetFilter("Bin Type Code", BinTypeFilter);
        CurrBinContent.SetRange("Cross-Dock Bin", false);
        if PutAwayTemplateLine."Find Same Item" then begin
            CurrBinContent.SetCurrentKey(
              "Location Code", "Item No.", "Variant Code", "Warehouse Class Code", Fixed, "Bin Ranking");
            CurrBinContent.SetRange("Item No.", ItemNo);
            CurrBinContent.SetRange("Variant Code", VariantCode);
        end;
        if PutAwayTemplateLine."Find Unit of Measure Match" then
            CurrBinContent.SetRange("Unit of Measure Code", PutAwayItemUnitOfMeasure.Code);
        IsHandled := false;
        OnFindBinContent(PostedWhseReceiptLine, PutAwayTemplateLine, CurrBinContent, BinContentFound, IsHandled);
        if not IsHandled then
            BinContentFound := CurrBinContent.Find('+');

        exit(BinContentFound);
    end;

    procedure FindBin(LocationCode: Code[10]; WarehouseClassCode: Code[10]): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        BinFound: Boolean;
        IsHandled: Boolean;
    begin
        CurrBin.Reset();
        CurrBin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
        CurrBin.SetRange("Location Code", LocationCode);
        CurrBin.SetRange("Warehouse Class Code", WarehouseClassCode);
        CurrBin.SetRange("Adjustment Bin", false);
        CurrBin.SetFilter("Block Movement", '%1|%2', CurrBin."Block Movement"::" ", CurrBin."Block Movement"::Outbound);
        CurrBin.SetFilter("Bin Type Code", BinTypeFilter);
        CurrBin.SetRange("Cross-Dock Bin", false);
        if PutAwayTemplateLine."Find Empty Bin" then
            CurrBin.SetRange(CurrBin.Empty, true);
        IsHandled := false;
        OnFindBin(PostedWhseReceiptLine, PutAwayTemplateLine, CurrBin, BinFound, IsHandled);
        if IsHandled then
            exit(BinFound);

        if CurrBin.Find('+') then begin
            if not (PutAwayTemplateLine."Find Empty Bin" or PutAwayTemplateLine."Find Floating Bin") then
                exit(true);
            repeat
                if PutAwayTemplateLine."Find Empty Bin" then begin
                    WhseActivLine.SetCurrentKey("Bin Code", "Location Code", "Action Type");
                    WhseActivLine.SetRange("Bin Code", CurrBin.Code);
                    WhseActivLine.SetRange("Location Code", LocationCode);
                    WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
                    if WhseActivLine.IsEmpty() then
                        if not PutAwayTemplateLine."Find Floating Bin" or IsFloatingBin() then
                            exit(true);
                end else
                    if IsFloatingBin() then
                        exit(true);
            until CurrBin.Next(-1) = 0;
        end;
        exit(false);
    end;

    procedure CalcQtyToPutAway(EmptyZoneBin: Boolean; NewBinContent: Boolean)
    var
        ActionType: Enum "Warehouse Action Type";
    begin
        if CurrLocation."Bin Mandatory" then begin
            ActionType := ActionType::Place;
            if not EmptyZoneBin and (CurrLocation."Bin Capacity Policy" <> CurrLocation."Bin Capacity Policy"::"Never Check Capacity") then
                CalcAvailCubageAndWeight();
            AssignQtyToPutAwayForBinMandatory();
        end else
            QtyToPutAwayBase := PostedWhseReceiptLine."Qty. (Base)";

        OnCalcQtyToPutAwayOnAfterSetQtyToPutAwayBase(
            PostedWhseReceiptLine, CurrLocation, CurrBin, CrossDockInfo, EmptyZoneBin, QtyToPutAwayBase, EverythingHandled, RemQtyToPutAwayBase, NewBinContent);
        QtyToPickBase := QtyToPickBase + QtyToPutAwayBase;
        if QtyToPutAwayBase > 0 then begin
            LineNo := LineNo + 10000;
            if NewBinContent and CurrLocation."Directed Put-away and Pick" then
                CreateBinContent(PostedWhseReceiptLine);
            CreateNewWhseActivity(
              PostedWhseReceiptLine, CurrWarehouseActivityLine, ActionType, LineNo,
              0, QtyToPutAwayBase, true, false, EmptyZoneBin, false)
        end
    end;

    local procedure AssignQtyToPutAwayForBinMandatory()
    begin
        OnBeforeAssignQtyToPutAwayForBinMandatory(CurrItem, CurrLocation, QtyToPutAwayBase, RemQtyToPutAwayBase);

        if QtyToPutAwayBase >= RemQtyToPutAwayBase then begin
            QtyToPutAwayBase := RemQtyToPutAwayBase;
            EverythingHandled := true;
        end else
            RemQtyToPutAwayBase := RemQtyToPutAwayBase - QtyToPutAwayBase;
    end;

    local procedure CalcAvailCubageAndWeight()
    var
        AvailPerCubageBase: Decimal;
        AvailPerWeightBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailCubageAndWeight(CurrBin, PostedWhseReceiptLine, PutAwayItemUnitOfMeasure, QtyToPutAwayBase, IsHandled, PutAwayTemplateLine);
        if IsHandled then
            exit;

        if (CurrBin."Maximum Cubage" <> 0) or (CurrBin."Maximum Weight" <> 0) then begin
            if (PutAwayItemUnitOfMeasure.Cubage <> 0) or (PutAwayItemUnitOfMeasure.Weight <> 0) then begin
                IsHandled := false;
                OnCalcAvailCubageAndWeightOnBeforeCalcCubageAndWeight(CurrBin, AvailPerCubageBase, AvailPerWeightBase, IsHandled);
                if not IsHandled then
                    CurrBin.CalcCubageAndWeight(AvailPerCubageBase, AvailPerWeightBase, false);
            end;
            if (CurrBin."Maximum Cubage" <> 0) and (PutAwayItemUnitOfMeasure.Cubage <> 0) then begin
                AvailPerCubageBase := AvailPerCubageBase div PutAwayItemUnitOfMeasure.Cubage * PutAwayItemUnitOfMeasure."Qty. per Unit of Measure";
                if AvailPerCubageBase < 0 then
                    AvailPerCubageBase := 0;
                if AvailPerCubageBase < QtyToPutAwayBase then
                    QtyToPutAwayBase := AvailPerCubageBase;
            end;
            if (CurrBin."Maximum Weight" <> 0) and (PutAwayItemUnitOfMeasure.Weight <> 0) then begin
                AvailPerWeightBase := AvailPerWeightBase div PutAwayItemUnitOfMeasure.Weight * PutAwayItemUnitOfMeasure."Qty. per Unit of Measure";
                if AvailPerWeightBase < 0 then
                    AvailPerWeightBase := 0;
                if AvailPerWeightBase < QtyToPutAwayBase then
                    QtyToPutAwayBase := AvailPerWeightBase;
            end;
        end;
    end;

    local procedure CreateBinContent(PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    var
        NewBinContent: Record "Bin Content";
    begin
        NewBinContent.Init();
        NewBinContent."Location Code" := CurrBin."Location Code";
        NewBinContent."Bin Code" := CurrBin.Code;
        NewBinContent."Item No." := PostedWhseRcptLine."Item No.";
        NewBinContent."Variant Code" := PostedWhseRcptLine."Variant Code";
        NewBinContent."Unit of Measure Code" := PutAwayItemUnitOfMeasure.Code;
        NewBinContent.Dedicated := CurrBin.Dedicated;
        NewBinContent."Zone Code" := CurrBin."Zone Code";
        NewBinContent."Bin Type Code" := CurrBin."Bin Type Code";
        NewBinContent."Warehouse Class Code" := CurrBin."Warehouse Class Code";
        NewBinContent."Block Movement" := CurrBin."Block Movement";
        NewBinContent."Qty. per Unit of Measure" := PutAwayItemUnitOfMeasure."Qty. per Unit of Measure";
        NewBinContent."Bin Ranking" := CurrBin."Bin Ranking";
        NewBinContent."Cross-Dock Bin" := CurrBin."Cross-Dock Bin";
        OnCreateBinContentOnBeforeNewBinContentInsert(NewBinContent, PostedWhseRcptLine, CurrBin, CurrBinContent);
        NewBinContent.Insert();
    end;

    procedure GetSpecEquipmentCode(BinCode: Code[20]): Code[10]
    begin
        case CurrLocation."Special Equipment" of
            CurrLocation."Special Equipment"::"According to Bin":
                begin
                    GetBin(CurrLocation.Code, BinCode);
                    if CurrBin."Special Equipment Code" <> '' then
                        exit(CurrBin."Special Equipment Code");

                    if CurrStockkeepingUnit."Special Equipment Code" <> '' then
                        exit(CurrStockkeepingUnit."Special Equipment Code");

                    exit(CurrItem."Special Equipment Code")
                end;
            CurrLocation."Special Equipment"::"According to SKU/Item":
                begin
                    if CurrStockkeepingUnit."Special Equipment Code" <> '' then
                        exit(CurrStockkeepingUnit."Special Equipment Code");

                    if CurrItem."Special Equipment Code" <> '' then
                        exit(CurrItem."Special Equipment Code");

                    GetBin(CurrLocation.Code, BinCode);
                    exit(CurrBin."Special Equipment Code")
                end
        end
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> CurrLocation.Code then
            CurrLocation.Get(LocationCode);

        OnAfterGetLocation(LocationCode, CurrLocation, PostedWhseReceiptLine);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (CurrBin."Location Code" <> LocationCode) or
           (CurrBin.Code <> BinCode)
        then begin
            CurrBin.SetLoadFields(Code, "Location Code", "Zone Code", "Dedicated", "Bin Ranking", "Bin Type Code", "Empty", "Maximum Cubage", "Maximum Weight",
                              "Warehouse Class Code", "Block Movement", "Cross-Dock Bin", "Special Equipment Code");
            CurrBin.Get(LocationCode, BinCode);
        end;
    end;

    local procedure GetItemAndSKU(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        if CurrItem."No." <> ItemNo then begin
            CurrItem.SetLoadFields("Special Equipment Code", "No.", "Warehouse Class Code", "Put-away Unit of Measure Code", "Base Unit of Measure", "Put-away Template Code");
            CurrItem.Get(ItemNo);
            GetWarehouseClassCode();
        end;
        if (ItemNo <> CurrStockkeepingUnit."Item No.") or
           (LocationCode <> CurrStockkeepingUnit."Location Code") or
           (VariantCode <> CurrStockkeepingUnit."Variant Code")
        then
            if not CurrStockkeepingUnit.Get(CurrLocation.Code, CurrItem."No.", PostedWhseReceiptLine."Variant Code") then
                Clear(CurrStockkeepingUnit);

        OnAfterGetItemAndSKU(CurrLocation, CurrItem, CurrStockkeepingUnit);
    end;

    local procedure GetWarehouseClassCode()
    begin
        WarehouseClassCode := CurrItem."Warehouse Class Code";
        OnAfterGetWarehouseClassCode(WarehouseClassCode, CurrItem, CurrStockkeepingUnit);
    end;

    local procedure GetPutAwayUOM()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPutAwayUOM(PutAwayItemUnitOfMeasure, PostedWhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        if not CurrLocation."Directed Put-away and Pick" then begin
            PutAwayItemUnitOfMeasure.Code := PostedWhseReceiptLine."Unit of Measure Code";
            PutAwayItemUnitOfMeasure."Qty. per Unit of Measure" := PostedWhseReceiptLine."Qty. per Unit of Measure";
            PutAwayItemUnitOfMeasure."Qty. Rounding Precision" := PostedWhseReceiptLine."Qty. Rounding Precision";
            BasePutAwayItemUnitOfMeasure."Qty. Rounding Precision" := PostedWhseReceiptLine."Qty. Rounding Precision (Base)";
            exit;
        end;
        if (PutAwayItemUnitOfMeasure."Item No." <> '') and (PutAwayItemUnitOfMeasure.Code <> '') and
           (CurrStockkeepingUnit."Item No." = PutAwayItemUnitOfMeasure."Item No.") and
           (CurrStockkeepingUnit."Put-away Unit of Measure Code" = PutAwayItemUnitOfMeasure.Code)
        then
            exit;

        if (CurrStockkeepingUnit."Put-away Unit of Measure Code" <> '') and
           ((CurrItem."No." <> PutAwayItemUnitOfMeasure."Item No.") or
            (CurrStockkeepingUnit."Put-away Unit of Measure Code" <> PutAwayItemUnitOfMeasure.Code))
        then begin
            if not PutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrStockkeepingUnit."Put-away Unit of Measure Code") then
                if not PutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrItem."Put-away Unit of Measure Code") then
                    PutAwayItemUnitOfMeasure.Get(CurrItem."No.", PostedWhseReceiptLine."Unit of Measure Code")
        end else
            if (CurrItem."No." <> PutAwayItemUnitOfMeasure."Item No.") or
               (CurrItem."Put-away Unit of Measure Code" <> PutAwayItemUnitOfMeasure.Code)
            then
                if not PutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrItem."Put-away Unit of Measure Code") then
                    PutAwayItemUnitOfMeasure.Get(CurrItem."No.", PostedWhseReceiptLine."Unit of Measure Code");

        BasePutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrItem."Base Unit of Measure");
    end;

    local procedure GetPutAwayTemplate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPutAwayTemplate(CurrStockkeepingUnit, CurrItem, CurrLocation, PutAwayTemplateHeader, IsHandled);
        if IsHandled then
            exit;

        if CurrStockkeepingUnit."Put-away Template Code" <> '' then begin
            if CurrStockkeepingUnit."Put-away Template Code" <> PutAwayTemplateHeader.Code then
                if not PutAwayTemplateHeader.Get(CurrStockkeepingUnit."Put-away Template Code") then
                    if (CurrItem."Put-away Template Code" <> '') and
                       (CurrItem."Put-away Template Code" <> PutAwayTemplateHeader.Code)
                    then
                        if not PutAwayTemplateHeader.Get(CurrItem."Put-away Template Code") then
                            if (PutAwayTemplateHeader.Code <> CurrLocation."Put-away Template Code")
                            then
                                PutAwayTemplateHeader.Get(CurrLocation."Put-away Template Code");
        end else
            if (CurrItem."Put-away Template Code" <> '') or
               (CurrItem."Put-away Template Code" <> PutAwayTemplateHeader.Code)
            then begin
                if not PutAwayTemplateHeader.Get(CurrItem."Put-away Template Code") then
                    if (PutAwayTemplateHeader.Code <> CurrLocation."Put-away Template Code")
                    then
                        PutAwayTemplateHeader.Get(CurrLocation."Put-away Template Code")
            end else
                PutAwayTemplateHeader.Get(CurrLocation."Put-away Template Code")
    end;

    procedure SetValues(NewAssignedID: Code[50]; NewSortActivity: Enum "Whse. Activity Sorting Method"; NewDoNotFillQtytoHandle: Boolean;
                                                                      BreakbulkFilter2: Boolean)
    begin
        AssignedID := NewAssignedID;
        SortActivity := NewSortActivity;
        DoNotFillQtytoHandle := NewDoNotFillQtytoHandle;
        BreakbulkFilter := BreakbulkFilter2;

        OnAfterSetValues(AssignedID, SortActivity, DoNotFillQtytoHandle, BreakbulkFilter);
    end;

    procedure GetWhseActivHeaderNo(var FirstPutAwayNo: Code[20]; var LastPutAwayNo: Code[20])
    begin
        FirstPutAwayNo := CurrWarehouseActivityHeader."No.";
        LastPutAwayNo := CurrWarehouseActivityHeader."No.";

        OnAfterGetWhseActivHeaderNo(FirstPutAwayNo, LastPutAwayNo);
    end;

    procedure EverythingIsHandled(): Boolean
    begin
        OnBeforeEverythingIsHandled(EverythingHandled);
        exit(EverythingHandled);
    end;

    local procedure InsertTempWhseActivHeader(WhseActivHeader: Record "Warehouse Activity Header")
    begin
        TempWarehouseActivityHeader.Init();
        TempWarehouseActivityHeader := WhseActivHeader;
        TempWarehouseActivityHeader.Insert();
    end;

    procedure GetFirstPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header"): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        Found: Boolean;
    begin
        OnBeforeGetFirstPutAwayDocument(TempWarehouseActivityHeader);
        Found := TempWarehouseActivityHeader.Find('-');
        if Found then begin
            WhseActivHeader := TempWarehouseActivityHeader;
            WhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
            WhseActivLine.SetRange("No.", WhseActivHeader."No.");
            Found := not WhseActivLine.IsEmpty();
        end;
        exit(Found);
    end;

    procedure GetNextPutAwayDocument(var WhseActivHeader: Record "Warehouse Activity Header"): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        Found: Boolean;
    begin
        OnBeforeGetNextPutAwayDocument(TempWarehouseActivityHeader);
        Found := TempWarehouseActivityHeader.Next() <> 0;
        if Found then begin
            WhseActivHeader := TempWarehouseActivityHeader;
            WhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
            WhseActivLine.SetRange("No.", WhseActivHeader."No.");
            Found := not WhseActivLine.IsEmpty();
        end;
        exit(Found);
    end;

#if not CLEAN24
    [Obsolete('Replaced with GetMessageText that is without Text length limit', '24.0')]
    procedure GetMessage(var ErrText000: Text[80])
    begin
        ErrText000 := CopyStr(MessageText, 1, MaxStrLen(ErrText000));

        OnAfterGetMessage(ErrText000);
    end;
#endif

    procedure GetMessageText(var ErrorText: Text)
#if not CLEAN24
    var
        ErrorText80: Text[80];
#endif
    begin
        ErrorText := MessageText;

#if not CLEAN24
        ErrorText80 := CopyStr(ErrorText, 1, MaxStrLen(ErrorText80));
        OnAfterGetMessage(ErrorText80);
        if CopyStr(ErrorText, 1, MaxStrLen(ErrorText80)) <> ErrorText80 then
            ErrorText := ErrorText80;
#endif
        OnAfterGetMessageText(ErrorText);
    end;

    procedure UpdateTempWhseItemTrkgLines(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer)
    begin
        TempWhseItemTrackingLine.Init();
        EntryNo += 1;
        TempWhseItemTrackingLine."Entry No." := EntryNo;
        TempWhseItemTrackingLine."Source Type" := SourceType;
        TempWhseItemTrackingLine."Source ID" := PostedWhseRcptLine."No.";
        TempWhseItemTrackingLine."Source Ref. No." := PostedWhseRcptLine."Line No.";
        TempWhseItemTrackingLine.CopyTrackingFromPostedWhseRcptLine(PostedWhseRcptLine);
        TempWhseItemTrackingLine."Quantity (Base)" := QtyToPickBase;
        OnUpdateTempWhseItemTrkgLines(TempWhseItemTrackingLine, PostedWhseRcptLine);
        TempWhseItemTrackingLine.Insert();
    end;

    procedure GetQtyHandledBase(var TempRec: Record "Whse. Item Tracking Line" temporary) QtyHandledBase: Decimal
    begin
        OnBeforeGetQtyHandledBase(TempWhseItemTrackingLine);
        TempRec.Reset();
        TempRec.DeleteAll();
        QtyHandledBase := 0;
        if TempWhseItemTrackingLine.Find('-') then
            repeat
                QtyHandledBase += TempWhseItemTrackingLine."Quantity (Base)";
                TempRec := TempWhseItemTrackingLine;
                TempRec.Insert();
            until TempWhseItemTrackingLine.Next() = 0;
        TempWhseItemTrackingLine.DeleteAll();
        exit(QtyHandledBase);
    end;

    local procedure MakeCrossDockPutAway()
    var
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UseCrossDock: Boolean;
        UOMCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeCrossDockPutAway(CurrLocation, PutAwayItemUnitOfMeasure, CurrBin, LineNo, CrossDockInfo, QtyToPutAwayBase, RemQtyToPutAwayBase, EverythingHandled, IsHandled, PostedWhseReceiptLine, CrossDock);
        if not IsHandled then begin
            if not CrossDock then
                exit;
            CrossDockMgt.GetUseCrossDock(UseCrossDock, PostedWhseReceiptLine."Location Code", PostedWhseReceiptLine."Item No.");
            if not UseCrossDock then
                exit;
            if PostedWhseReceiptLine."Qty. Cross-Docked" <> 0 then begin
                if not CurrLocation."Bin Mandatory" then
                    PutAwayItemUnitOfMeasure.Get(PostedWhseReceiptLine."Item No.", PostedWhseReceiptLine."Unit of Measure Code")
                else begin
                    CurrBin.SetLoadFields(Code, Dedicated, "Bin Ranking", "Bin Type Code", Empty, "Maximum Cubage", "Maximum Weight", "Location Code", "Zone Code", "Warehouse Class Code", "Block Movement", "Cross-Dock Bin", "Special Equipment Code");
                    CurrBin.Get(PostedWhseReceiptLine."Location Code", PostedWhseReceiptLine."Cross-Dock Bin Code");
                end;
                LineNo := LineNo + 10000;
                TempPostedWhseReceiptLine := PostedWhseReceiptLine;
                if CurrLocation."Directed Put-away and Pick" then
                    PostedWhseReceiptLine.Quantity := PostedWhseReceiptLine."Qty. Cross-Docked (Base)" / PutAwayItemUnitOfMeasure."Qty. per Unit of Measure"
                else
                    PostedWhseReceiptLine.Quantity := PostedWhseReceiptLine."Qty. Cross-Docked";

                QtyToPutAwayBase := PostedWhseReceiptLine."Qty. Cross-Docked (Base)";
                RemQtyToPutAwayBase := PostedWhseReceiptLine."Qty. Cross-Docked (Base)";
                PostedWhseReceiptLine."Zone Code" := PostedWhseReceiptLine."Cross-Dock Zone Code";
                PostedWhseReceiptLine."Bin Code" := PostedWhseReceiptLine."Cross-Dock Bin Code";
                if CurrLocation."Directed Put-away and Pick" then
                    UOMCode := PutAwayItemUnitOfMeasure.Code
                else
                    UOMCode := PostedWhseReceiptLine."Unit of Measure Code";
                if CrossDockBinContent.Get(PostedWhseReceiptLine."Location Code", PostedWhseReceiptLine."Cross-Dock Bin Code", PostedWhseReceiptLine."Item No.", PostedWhseReceiptLine."Variant Code", UOMCode) then
                    NewCrossDockBinContent := false
                else
                    NewCrossDockBinContent := true;
                if not CurrLocation."Bin Mandatory" then
                    NewCrossDockBinContent := false;
                CrossDockInfo := 1;
                CalcQtyToPutAway(false, NewCrossDockBinContent);
                CrossDockInfo := 2;
                PostedWhseReceiptLine := TempPostedWhseReceiptLine;
                QtyToPutAwayBase := PostedWhseReceiptLine."Qty. (Base)" - PostedWhseReceiptLine."Qty. Cross-Docked (Base)";
                RemQtyToPutAwayBase := PostedWhseReceiptLine."Qty. (Base)" - PostedWhseReceiptLine."Qty. Cross-Docked (Base)";
                if CurrLocation."Directed Put-away and Pick" then
                    PostedWhseReceiptLine.Quantity := (PostedWhseReceiptLine."Qty. (Base)" - PostedWhseReceiptLine."Qty. Cross-Docked (Base)") / PutAwayItemUnitOfMeasure."Qty. per Unit of Measure"
                else
                    PostedWhseReceiptLine.Quantity := PostedWhseReceiptLine.Quantity - PostedWhseReceiptLine."Qty. Cross-Docked";
                PostedWhseReceiptLine."Qty. (Base)" := PostedWhseReceiptLine.Quantity * PostedWhseReceiptLine."Qty. per Unit of Measure";
                EverythingHandled := false;
            end;
        end;

        OnAfterMakeCrossDockPutAway(PostedWhseReceiptLine);
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
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.DeleteBinContent(WarehouseActivityLine."Action Type"::Place.AsInteger());
            until WarehouseActivityLine.Next() = 0;
    end;

    procedure IsFloatingBin(): Boolean
    begin
        if CurrBin.Dedicated then
            exit(false);

        CurrBinContent.Reset();
        CurrBinContent.ReadIsolation(IsolationLevel::ReadUnCommitted);
        CurrBinContent.SetRange(CurrBinContent."Location Code", CurrBin."Location Code");
        CurrBinContent.SetRange(CurrBinContent."Zone Code", CurrBin."Zone Code");
        CurrBinContent.SetRange(CurrBinContent."Bin Code", CurrBin.Code);
        if CurrBinContent.FindSet() then
            repeat
                if CurrBinContent.Fixed or CurrBinContent.Default then
                    exit(false);
            until CurrBinContent.Next() = 0;
        exit(true);
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
        OnNextBin(PostedWhseReceiptLine, PutAwayTemplateLine, CurrBin, BinFound, IsHandled);
        if not IsHandled then
            BinFound := CurrBin.Next(-1) <> 0;

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
        OnNextBinContent(PostedWhseReceiptLine, PutAwayTemplateLine, CurrBinContent, BinContentFound, IsHandled);
        if not IsHandled then
            BinContentFound := CurrBinContent.Next(-1) <> 0;

        exit(BinContentFound);
    end;

    internal procedure IncludeIntoWhsePutAwayForProdOrder(ItemJournalLine: Record "Item Journal Line")
    begin
        if not ShouldCreateWhsePutAwayForProdOutput(ItemJournalLine) then
            exit;

        AppendToTempProductionOrderForWhsePutAwayForProdOutput(ItemJournalLine);
        AppendToTempItemJournalLineForWhsePutAwayForProdOutput(ItemJournalLine);
    end;

    local procedure AppendToTempProductionOrderForWhsePutAwayForProdOutput(ItemJournalLine: Record "Item Journal Line")
    var
        ProductionOrder: Record "Production Order";
    begin
        if TempProductionOrderForWhsePutAwayForProdOutput.Get(TempProductionOrderForWhsePutAwayForProdOutput.Status::Released, ItemJournalLine."Order No.") then
            exit;

        ProductionOrder.Get(TempProductionOrderForWhsePutAwayForProdOutput.Status::Released, ItemJournalLine."Order No.");
        TempProductionOrderForWhsePutAwayForProdOutput.Init();
        TempProductionOrderForWhsePutAwayForProdOutput := ProductionOrder;
        TempProductionOrderForWhsePutAwayForProdOutput.Insert();
    end;

    local procedure AppendToTempItemJournalLineForWhsePutAwayForProdOutput(ItemJournalLine: Record "Item Journal Line")
    begin
        TempItemJournalLineForWhsePutAwayForProdOutput.Reset();
        TempItemJournalLineForWhsePutAwayForProdOutput.SetRange("Order No.", ItemJournalLine."Order No.");
        TempItemJournalLineForWhsePutAwayForProdOutput.SetRange("Order Line No.", ItemJournalLine."Order Line No.");
        if not TempItemJournalLineForWhsePutAwayForProdOutput.IsEmpty() then
            exit;

        TempItemJournalLineForWhsePutAwayForProdOutput.Init();
        TempItemJournalLineForWhsePutAwayForProdOutput := ItemJournalLine;
        TempItemJournalLineForWhsePutAwayForProdOutput.Insert();
    end;

    internal procedure CreateWhsePutAwayForProdOutput()
    begin
        OnBeforeCreateWhsePutAwayForProdOutput(TempProductionOrderForWhsePutAwayForProdOutput);
        if TempProductionOrderForWhsePutAwayForProdOutput.FindSet() then
            repeat
                ProcessWhsePutAwayForProdOrderFromItemJnlLine(TempProductionOrderForWhsePutAwayForProdOutput);
            until TempProductionOrderForWhsePutAwayForProdOutput.Next() = 0;
    end;

    local procedure ProcessWhsePutAwayForProdOrderFromItemJnlLine(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        TempItemJournalLineForWhsePutAwayForProdOutput.Reset();
        TempItemJournalLineForWhsePutAwayForProdOutput.SetRange("Order No.", ProductionOrder."No.");
        if TempItemJournalLineForWhsePutAwayForProdOutput.FindSet() then
            repeat
                MfgPutAwayHelper.FindProdOrderLine(ProdOrderLine, TempItemJournalLineForWhsePutAwayForProdOutput);
                CreateWhsePutAwayForProdOrderOutputLine(ProdOrderLine);
            until TempItemJournalLineForWhsePutAwayForProdOutput.Next() = 0;
    end;

    procedure SetCalledFromPutAwayWorksheet(NewCalledFromPutAwayWorksheet: Boolean)
    begin
        CalledFromPutAwayWorksheet := NewCalledFromPutAwayWorksheet;
    end;

    internal procedure CreateWhsePutAwayForProdOrderOutputLine(ProdOrderLine: Record "Prod. Order Line")
    var
        TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary;
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if ItemTrackingManagement.GetWhseItemTrkgSetup(ProdOrderLine."Item No.") then
            ItemTrackingManagement.InitItemTrackingForTempWhseWorksheetLine(
                  Enum::"Warehouse Worksheet Document Type"::Production,
                  ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
                  Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(),
                  ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0);

        if CalledFromPutAwayWorksheet then
            ItemTrackingManagement.SplitProdOrderLineForOutputPutAway(ProdOrderLine, TempProdOrdLineTrackingBuff, ProdOrderLine."Finished Qty. (Base)")
        else
            ItemTrackingManagement.SplitProdOrderLineForOutputPutAway(ProdOrderLine, TempProdOrdLineTrackingBuff, 0);

        TempProdOrdLineTrackingBuff.Reset();
        if TempProdOrdLineTrackingBuff.FindSet() then
            repeat
                CreateWhsePutAwayForProdOutput(ProdOrderLine, TempProdOrdLineTrackingBuff);
                DeleteBlankBinContent(CurrWarehouseActivityHeader);
            until TempProdOrdLineTrackingBuff.Next() = 0;
    end;

    internal procedure ShouldCreateWhsePutAwayForProdOutput(ItemJournalLine: Record "Item Journal Line"): Boolean
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        xProductionOrder: Record "Production Order";
        xProdOrderLine: Record "Prod. Order Line";
        ShouldCreateWhsePutAway: Boolean;
        WhsePutAwayRequired: Boolean;
    begin
        if ItemJournalLine."Entry Type" <> ItemJournalLine."Entry Type"::Output then
            exit;

        if not MfgPutAwayHelper.IsLastOperation(ItemJournalLine) then
            exit;

        if ItemJournalLine."Location Code" = '' then
            exit;

        GetLocation(ItemJournalLine."Location Code");
        WhsePutAwayRequired := CurrLocation.RequireWhsePutAwayForProdOutput(ItemJournalLine."Location Code");
        ShouldCreateWhsePutAway := WhsePutAwayRequired and not CurrLocation."Use Put-away Worksheet";
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.");
        ProductionOrder.Get(ProductionOrder.Status::Released, ItemJournalLine."Order No.");

        if not WhsePutAwayRequired then begin
            xProdOrderLine := ProdOrderLine;
            ProdOrderLine."Put-away Status" := ProdOrderLine."Put-away Status"::"Completely Put Away";
            if ProdOrderLine."Put-away Status" <> xProdOrderLine."Put-away Status" then
                ProdOrderLine.Modify();

            xProductionOrder := ProductionOrder;
            ProductionOrder."Document Put-away Status" := ProductionOrder.GetHeaderPutAwayStatus(0);
            if ProductionOrder."Document Put-away Status" <> xProductionOrder."Document Put-away Status" then
                ProductionOrder.Modify();
        end;

        if WhsePutAwayRequired then begin
            MfgPutAwayHelper.CreateWhsePutAwayRequestForProdOutput(ProductionOrder, ProdOrderLine);

            xProdOrderLine := ProdOrderLine;
            ProdOrderLine."Put-away Status" := ProdOrderLine.GetLinePutAwayStatus();
            if ProdOrderLine."Put-away Status" <> xProdOrderLine."Put-away Status" then
                ProdOrderLine.Modify();

            xProductionOrder := ProductionOrder;
            ProductionOrder."Document Put-away Status" := ProductionOrder.GetHeaderPutAwayStatus(0);
            if ProductionOrder."Document Put-away Status" <> xProductionOrder."Document Put-away Status" then
                ProductionOrder.Modify();
        end;

        if not ShouldCreateWhsePutAway then
            if WhsePutAwayRequired then begin
                InitiateMasterRelations(ProdOrderLine);
                if not BinContentExistForProdOrderLine(ProdOrderLine) then
                    CreateBinContentForProdOrderOutputLine(ProdOrderLine);
            end;

        exit(ShouldCreateWhsePutAway);
    end;

    local procedure BinContentExistForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"): Boolean
    begin
        if not CurrBin.Get(ProdOrderLine."Location Code", ProdOrderLine."Bin Code") then
            exit;

        exit(CurrBinContent.Get(
                ProdOrderLine."Location Code",
                CurrBin.Code,
                ProdOrderLine."Item No.",
                ProdOrderLine."Variant Code",
                PutAwayItemUnitOfMeasure.Code));
    end;

    internal procedure CreateWhsePutAwayForProdOrder(var ProductionOrder: Record "Production Order")
    begin
        OnBeforeCreateWhsePutAwayForProdOrder(ProductionOrder);
        if not MfgPutAwayHelper.CanCreateProdWhsePutAway(ProductionOrder) then
            exit;

        ProcessWhsePutAwayForProdOrder(ProductionOrder);

        if GuiAllowed() then
            if CurrWarehouseActivityHeader."No." <> '' then
                Message(PutAwayActivityNoHasBeenCreatedMsg, CurrWarehouseActivityHeader."No.")
            else
                Error(NothingToCreateErr);
    end;

    local procedure ProcessWhsePutAwayForProdOrder(ProductionOrder: Record "Production Order")
    var
        Location: Record Location;
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetAutoCalcFields("Put-away Qty. (Base)", "Put-away Qty.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ProdOrderLine.FindSet() then
            repeat
                if Location.RequireWhsePutAwayForProdOutput(ProdOrderLine."Location Code") then
                    CreateWhsePutAwayForProdOrderOutputLine(ProdOrderLine);
            until ProdOrderLine.Next() = 0;
    end;

    local procedure CalcQtyToWhsePutAwayForProdOutput(EmptyZoneBin: Boolean; NewBinContent: Boolean; ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary)
    var
        WarehouseActionType: Enum "Warehouse Action Type";
    begin
        if CurrLocation."Bin Mandatory" then begin
            WarehouseActionType := WarehouseActionType::Place;
            if not EmptyZoneBin and (CurrLocation."Bin Capacity Policy" <> CurrLocation."Bin Capacity Policy"::"Never Check Capacity") then
                CalcAvailCubageAndWeight();

            AssignQtyToPutAwayForBinMandatory();
        end else
            if TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)" >= (ProdOrderLine."Put-away Qty. (Base)" + ProdOrderLine."Qty. Put Away (Base)") then
                QtyToPutAwayBase := TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)" - (ProdOrderLine."Put-away Qty. (Base)" + ProdOrderLine."Qty. Put Away (Base)")
            else
                QtyToPutAwayBase := TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)";

        QtyToPickBase := QtyToPickBase + QtyToPutAwayBase;
        if QtyToPutAwayBase <= 0 then
            exit;

        LineNo := LineNo + 10000;
        if NewBinContent and CurrLocation."Directed Put-away and Pick" then
            CreateBinContentForProdOrderOutputLine(ProdOrderLine);

        CreateNewWhseActivityForProdOrderLine(ProdOrderLine, TempProdOrdLineTrackingBuff, CurrWarehouseActivityLine, WarehouseActionType, LineNo, 0, QtyToPutAwayBase, true, false, EmptyZoneBin, false);
    end;

    local procedure AssignPlaceBinZoneForProdOrderLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderLine: Record "Prod. Order Line"; Location: Record Location; Bin: Record Bin)
    var
        Bin2: Record Bin;
    begin
        WarehouseActivityLine."Bin Code" := Bin.Code;
        WarehouseActivityLine."Zone Code" := Bin."Zone Code";
        if Location.IsBWReceive() and
           (CrossDockInfo <> WarehouseActivityLine."Cross-Dock Information"::"Cross-Dock Items") and
           ((Bin.Code = ProdOrderLine."Bin Code") or Location.IsBinBWProdOutput(Bin.Code))
        then begin
            Bin2.SetRange("Location Code", Location.Code);
            Bin2.SetFilter(Code, '<>%1&<>%2&<>%3', Location."To-Production Bin Code", Location."Shipment Bin Code",
              ProdOrderLine."Bin Code");
            Bin2.SetLoadFields(Code, "Zone Code");
            if Bin2.FindFirst() then begin
                WarehouseActivityLine."Bin Code" := Bin2.Code;
                WarehouseActivityLine."Zone Code" := Bin2."Zone Code";
            end else begin
                WarehouseActivityLine."Bin Code" := '';
                WarehouseActivityLine."Zone Code" := '';
            end;
        end;
    end;

    local procedure CreateWhsePutAwayForProdOutput(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary)
    var
        TakeLineNo: Integer;
        BreakPackage: Boolean;
        Breakbulk: Boolean;
    begin
        InitializeGlobalsWhsePutAwayForProdOutput();

        GetLocation(ProdOrderLine."Location Code");
        if not CurrLocation."Bin Mandatory" then begin
            CalcQtyToWhsePutAwayForProdOutput(true, false, ProdOrderLine, TempProdOrdLineTrackingBuff);
            exit;
        end;

        case CurrLocation."Put-away Bin Policy" of
            CurrLocation."Put-away Bin Policy"::"Default Bin":
                CreateWhsePutAwayForProdOutputFromDefaultBin(ProdOrderLine, TempProdOrdLineTrackingBuff);
            CurrLocation."Put-away Bin Policy"::"Put-away Template":
                CreateWhsePutAwayForProdOutputFromTemplate(ProdOrderLine, TempProdOrdLineTrackingBuff);
        end;

        if not EverythingHandled and CurrLocation."Always Create Put-away Line" then begin
            LineNo := LineNo + 10000;
            QtyToPutAwayBase := RemQtyToPutAwayBase;
            CalcQtyToWhsePutAwayForProdOutput(true, false, ProdOrderLine, TempProdOrdLineTrackingBuff);
        end;

        if QtyToPickBase <= 0 then
            if MessageText = '' then
                if CurrLocation."Put-away Bin Policy" = Enum::"Put-away Bin Policy"::"Put-away Template" then
                    MessageText := PutawayNotCreatedMsg
                else
                    if CurrLocation."Put-away Bin Policy" = Enum::"Put-away Bin Policy"::"Default Bin" then
                        MessageText := NoDefaultBinMsg;

        if InsertBreakPackageLinesForProdOrderLine(ProdOrderLine) then begin
            TakeLineNo := OldLineNo + 30000;
            Breakbulk := true;
        end else begin
            TakeLineNo := OldLineNo + 10000;
            if (ProdOrderLine."Unit of Measure Code" <> PutAwayItemUnitOfMeasure.Code) and CurrLocation."Directed Put-away and Pick" then
                BreakPackage := true;
        end;

        CreateNewWhseActivityForProdOrderLine(
            ProdOrderLine,
            TempProdOrdLineTrackingBuff,
            CurrWarehouseActivityLine,
            Enum::"Warehouse Action Type"::Take,
            TakeLineNo,
            0,
            QtyToPickBase,
            false,
            BreakPackage,
            false,
            Breakbulk);

        OldLineNo := LineNo;
    end;

    local procedure FindBinForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; var BinContentQtyBase: Decimal)
    begin
        OnBeforeFindBinForProdOrderLine(ProdOrderLine, TempProdOrdLineTrackingBuff, BinContentQtyBase);
        if not FindBin(ProdOrderLine."Location Code", WarehouseClassCode) then
            exit;

        repeat
            if BinContentAndProdOrderLineHaveDiffBin(CurrBinContent."Bin Code", ProdOrderLine."Bin Code") then
                CalcQtyFromBin(ProdOrderLine, TempProdOrdLineTrackingBuff, BinContentQtyBase);
        until not NextBin();
    end;

    local procedure FindBinFromBinContentForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; var BinContentQtyBase: Decimal)
    begin
        OnBeforeFindBinFromBinContentForProdOrderLine(ProdOrderLine, TempProdOrdLineTrackingBuff, BinContentQtyBase);
        if not FindBinContent(ProdOrderLine."Location Code", ProdOrderLine."Item No.", ProdOrderLine."Variant Code", WarehouseClassCode) then
            exit;

        repeat
            if BinContentAndProdOrderLineHaveDiffBin(CurrBinContent."Bin Code", ProdOrderLine."Bin Code") then
                CalcQtyFromBinContent(ProdOrderLine, TempProdOrdLineTrackingBuff, BinContentQtyBase);
        until not NextBinContent();
    end;

    local procedure CalcQtyFromBin(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; var BinContentQtyBase: Decimal)
    begin
        QtyToPutAwayBase := RemQtyToPutAwayBase;
        if not CurrBinContent.Get(
            ProdOrderLine."Location Code",
            CurrBin.Code,
            ProdOrderLine."Item No.",
            ProdOrderLine."Variant Code",
            PutAwayItemUnitOfMeasure.Code)
        then begin
            CalcQtyToWhsePutAwayForProdOutput(false, true, ProdOrderLine, TempProdOrdLineTrackingBuff);
            exit;
        end;

        CurrBinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
        BinContentQtyBase :=
          CurrBinContent."Quantity (Base)" +
          CurrBinContent."Put-away Quantity (Base)" +
          CurrBinContent."Positive Adjmt. Qty. (Base)";

        if CurrBinContent."Max. Qty." <> 0 then begin
            QtyToPutAwayBase :=
              Max(CurrBinContent."Max. Qty." * CurrBinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
            if QtyToPutAwayBase > RemQtyToPutAwayBase then
                QtyToPutAwayBase := RemQtyToPutAwayBase;
        end;
        CalcQtyToWhsePutAwayForProdOutput(false, false, ProdOrderLine, TempProdOrdLineTrackingBuff);
        BinContentQtyBase := CurrBinContent.CalcQtyBase();
        if CurrBinContent."Max. Qty." <> 0 then begin
            QtyToPutAwayBase :=
              Max(CurrBinContent."Max. Qty." * CurrBinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
            if QtyToPutAwayBase > RemQtyToPutAwayBase then
                QtyToPutAwayBase := RemQtyToPutAwayBase;
        end;
    end;

    local procedure CalcQtyFromBinContent(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; var BinContentQtyBase: Decimal)
    begin
        QtyToPutAwayBase := RemQtyToPutAwayBase;

        CurrBinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
        BinContentQtyBase :=
          CurrBinContent."Quantity (Base)" + CurrBinContent."Put-away Quantity (Base)" + CurrBinContent."Positive Adjmt. Qty. (Base)";
        if (not PutAwayTemplateLine."Find Bin w. Less than Min. Qty" or
            (BinContentQtyBase < CurrBinContent."Min. Qty." * CurrBinContent."Qty. per Unit of Measure")) and
           (not PutAwayTemplateLine."Find Empty Bin" or (BinContentQtyBase <= 0))
        then begin
            if CurrBinContent."Max. Qty." <> 0 then begin
                QtyToPutAwayBase := Max(CurrBinContent."Max. Qty." * CurrBinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                if QtyToPutAwayBase > RemQtyToPutAwayBase then
                    QtyToPutAwayBase := RemQtyToPutAwayBase;
            end;

            GetBin(ProdOrderLine."Location Code", CurrBinContent."Bin Code");
            CalcQtyToWhsePutAwayForProdOutput(false, false, ProdOrderLine, TempProdOrdLineTrackingBuff);
        end;
    end;

    local procedure BinContentAndProdOrderLineHaveDiffBin(CurrContentBinCode: Code[20]; ProdOrderLineBinCode: Code[20]): Boolean
    begin
        exit(CurrContentBinCode <> ProdOrderLineBinCode);
    end;

    local procedure IsTemplateLineEnableForFindBinFields(): Boolean
    begin
        exit((PutAwayTemplateLine."Find Empty Bin" or PutAwayTemplateLine."Find Floating Bin") or
            PutAwayTemplateLine."Find Fixed Bin" or
            PutAwayTemplateLine."Find Same Item" or
            PutAwayTemplateLine."Find Unit of Measure Match" or
            PutAwayTemplateLine."Find Bin w. Less than Min. Qty");
    end;

    local procedure UpdateRemQtyToPutAwayBaseFromProdOrderLine(var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; ProdOrderLine: Record "Prod. Order Line")
    begin
        if CalledFromPutAwayWorksheet then
            RemQtyToPutAwayBase := TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)"
        else
            if (TempProdOrdLineTrackingBuff."Lot No." <> '') or (TempProdOrdLineTrackingBuff."Serial No." <> '') or (TempProdOrdLineTrackingBuff."Package No." <> '') then
                RemQtyToPutAwayBase := TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)"
            else
                RemQtyToPutAwayBase := ProdOrderLine.GetRemainingPutAwayQty();
    end;

    local procedure CreateWhsePutAwayForProdOutputFromTemplate(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary)
    var
        BinType: Record "Bin Type";
        BinContentQtyBase: Decimal;
    begin
        InitiateMasterRelations(ProdOrderLine);
        if not IsValidPutAwayTemplate() then
            exit;

        UpdateRemQtyToPutAwayBaseFromProdOrderLine(TempProdOrdLineTrackingBuff, ProdOrderLine);

        if CurrLocation."Directed Put-away and Pick" then begin
            if ProdOrderLine."Qty. per Unit of Measure" > ProdOrderLine."Qty. per Unit of Measure" then
                CreateBreakPackageLines(ProdOrderLine, TempProdOrdLineTrackingBuff);

            if RemQtyToPutAwayBase = 0 then
                exit;
        end;

        LineNo := LineNo + 10000;
        if CurrLocation."Directed Put-away and Pick" then
            BinType.MakeBinTypeFilter(BinTypeFilter, BinType.FieldNo("Put away"));

        repeat
            QtyToPutAwayBase := RemQtyToPutAwayBase;

            if not IsTemplateLineEnableForFindBinFields() then
                FindBinFromBinContentForProdOrderLine(ProdOrderLine, TempProdOrdLineTrackingBuff, BinContentQtyBase) // Calc Availability per Bin Content
            else
                FindBinForProdOrderLine(ProdOrderLine, TempProdOrdLineTrackingBuff, BinContentQtyBase); // Calc Availability per Bin
        until (PutAwayTemplateLine.Next() = 0) or EverythingHandled;
    end;

    local procedure CreateWhsePutAwayForProdOutputFromDefaultBin(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary)
    begin
        FeatureTelemetry.LogUsage('0000KP5', BinPolicyTelemetryCategoryTok, DefaultBinPutawayPolicyTelemetryTok);
        UpdateRemQtyToPutAwayBaseFromProdOrderLine(TempProdOrdLineTrackingBuff, ProdOrderLine);

        Clear(CurrBin);
        if WMSManagement.GetDefaultBin(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code", CurrBin.Code) then begin
            CurrBin.SetLoadFields(Code, Dedicated, "Bin Ranking", "Bin Type Code", Empty, "Maximum Cubage", "Maximum Weight", "Location Code", "Zone Code", "Warehouse Class Code", "Block Movement", "Cross-Dock Bin", "Special Equipment Code");
            CurrBin.Get(CurrLocation.Code, CurrBin.Code);
            QtyToPutAwayBase := RemQtyToPutAwayBase;
            LineNo := LineNo + 10000;
            CalcQtyToWhsePutAwayForProdOutput(false, false, ProdOrderLine, TempProdOrdLineTrackingBuff);
        end;
    end;

    local procedure InitiateMasterRelations(ProdOrderLine: Record "Prod. Order Line")
    begin
        GetItemAndSKU(ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code");
        GetPutAwayUOMForProdOrderLine(ProdOrderLine);

        if CurrLocation."Put-away Bin Policy" = CurrLocation."Put-away Bin Policy"::"Put-away Template" then
            GetPutAwayTemplate();
    end;

    local procedure IsValidPutAwayTemplate(): Boolean
    begin
        if PutAwayTemplateHeader.Code = '' then begin
            MessageText := StrSubstNo(TemplateDoesNotExistMsg, PutAwayTemplateHeader.TableCaption());
            exit;
        end;

        PutAwayTemplateLine.Reset();
        PutAwayTemplateLine.SetRange("Put-away Template Code", PutAwayTemplateHeader.Code);
        if not PutAwayTemplateLine.FindFirst() then begin
            MessageText := StrSubstNo(TemplateDoesNotExistMsg, PutAwayTemplateLine.TableCaption());
            exit;
        end;

        exit(true);
    end;

    local procedure InsertBreakPackageLinesForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        if TempWarehouseActivityLine.FindSet() then begin
            repeat
                WhseActivLine.Init();
                WhseActivLine := TempWarehouseActivityLine;
                WhseActivLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                WhseActivLine."No." := CurrWarehouseActivityHeader."No.";
                WhseActivLine."Bin Code" := ProdOrderLine."Bin Code";
                WhseActivLine.Insert();
            until TempWarehouseActivityLine.Next() = 0;
            exit(true);
        end
    end;

    internal procedure CreateBinContentForProdOrderOutputLine(ProdOrderLine: Record "Prod. Order Line")
    var
        NewBinContent: Record "Bin Content";
        Bin: Record Bin;
    begin
        if not Bin.Get(ProdOrderLine."Location Code", ProdOrderLine."Bin Code") then
            exit;

        if CurrBin.Code = '' then
            CurrBin := Bin;

        NewBinContent.Init();
        NewBinContent."Location Code" := CurrBin."Location Code";
        NewBinContent."Bin Code" := CurrBin.Code;
        NewBinContent."Item No." := ProdOrderLine."Item No.";
        NewBinContent."Variant Code" := ProdOrderLine."Variant Code";
        NewBinContent."Unit of Measure Code" := PutAwayItemUnitOfMeasure.Code;
        NewBinContent.Dedicated := CurrBin.Dedicated;
        NewBinContent."Zone Code" := CurrBin."Zone Code";
        NewBinContent."Bin Type Code" := CurrBin."Bin Type Code";
        NewBinContent."Warehouse Class Code" := CurrBin."Warehouse Class Code";
        NewBinContent."Block Movement" := CurrBin."Block Movement";
        NewBinContent."Qty. per Unit of Measure" := PutAwayItemUnitOfMeasure."Qty. per Unit of Measure";
        NewBinContent."Bin Ranking" := CurrBin."Bin Ranking";
        NewBinContent."Cross-Dock Bin" := CurrBin."Cross-Dock Bin";
        NewBinContent.Insert();
    end;

    local procedure CreateBreakPackageLines(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary)
    var
        Qty: Decimal;
    begin
        if CalledFromPutAwayWorksheet then
            Qty := TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)"
        else
            Qty := ProdOrderLine.GetRemainingPutAwayQty();

        LineNo := LineNo + 10000;
        BreakbulkNo := BreakbulkNo + 1;
        CreateNewWhseActivityForProdOrderLine(
            ProdOrderLine,
            TempProdOrdLineTrackingBuff,
            CurrWarehouseActivityLine,
            Enum::"Warehouse Action Type"::Take,
            LineNo,
            BreakbulkNo,
            Qty,
            false,
            true,
            false,
            false);

        LineNo := LineNo + 10000;
        CreateNewWhseActivityForProdOrderLine(
            ProdOrderLine,
            TempProdOrdLineTrackingBuff,
            CurrWarehouseActivityLine,
            Enum::"Warehouse Action Type"::Take,
            LineNo,
            BreakbulkNo,
            RemQtyToPutAwayBase,
            false,
            false,
            false,
            true);
    end;

    local procedure CreateNewWhseActivityForProdOrderLine(
        ProdOrderLine: Record "Prod. Order Line";
        var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary;
        var WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActionType: Enum "Warehouse Action Type";
        NewLineNo: Integer;
        NewBreakBulkNo: Integer;
        QtyToHandleBase: Decimal;
        InsertHeader: Boolean;
        BreakPackage: Boolean;
        EmptyZoneBin: Boolean;
        BreakBulk: Boolean)
    var
        Bin: Record Bin;
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
    begin
        if (CurrWarehouseActivityHeader."No." = '') and InsertHeader then
            InsertWarehouseActivityHeaderForProdOutputPutAway(ProdOrderLine);

        if CurrWarehouseActivityHeader."No." = '' then
            Error(NothingToCreateErr);

        ProdOrderWarehouseMgt.TransferFromOutputLine(WarehouseActivityLine, ProdOrderLine);
        WarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
        WarehouseActivityLine."Line No." := NewLineNo;
        WarehouseActivityLine."Location Code" := ProdOrderLine."Location Code";
        WarehouseActivityLine."Action Type" := WarehouseActionType;
        WarehouseActivityLine."Source Document" := WarehouseActivityLine."Source Document"::"Prod. Output";
        WarehouseActivityLine."Breakbulk No." := NewBreakBulkNo;
        WarehouseActivityLine."Original Breakbulk" := Breakbulk;
        case WarehouseActionType of
            WarehouseActionType::Take:
                begin
                    WarehouseActivityLine."Bin Code" := ProdOrderLine."Bin Code";
                    if Bin.Get(ProdOrderLine."Location Code", WarehouseActivityLine."Bin Code") then
                        WarehouseActivityLine."Zone Code" := Bin."Zone Code";
                end;
            WarehouseActionType::Place:
                if not EmptyZoneBin then
                    AssignPlaceBinZoneForProdOrderLine(WarehouseActivityLine, ProdOrderLine, CurrLocation, CurrBin)
                else
                    WarehouseActivityLine."Bin Code" := '';
        end;

        if WarehouseActivityLine."Bin Code" <> '' then begin
            GetBin(WarehouseActivityLine."Location Code", WarehouseActivityLine."Bin Code");
            WarehouseActivityLine.Dedicated := CurrBin.Dedicated;
            WarehouseActivityLine."Bin Ranking" := CurrBin."Bin Ranking";
            WarehouseActivityLine."Bin Type Code" := CurrBin."Bin Type Code";
            GetItemAndSKU(WarehouseActivityLine."Item No.", WarehouseActivityLine."Location Code", WarehouseActivityLine."Variant Code");
            WarehouseActivityLine."Special Equipment Code" := GetSpecEquipmentCode(WarehouseActivityLine."Bin Code");
        end;
        if BreakPackage or (WarehouseActionType = WarehouseActionType::" ") or
            not CurrLocation."Directed Put-away and Pick"
        then begin
            WarehouseActivityLine."Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
            WarehouseActivityLine."Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
            WarehouseActivityLine."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
            WarehouseActivityLine."Qty. Rounding Precision (Base)" := ProdOrderLine."Qty. Rounding Precision (Base)";
        end else begin
            WarehouseActivityLine."Unit of Measure Code" := PutAwayItemUnitOfMeasure.Code;
            WarehouseActivityLine."Qty. per Unit of Measure" := PutAwayItemUnitOfMeasure."Qty. per Unit of Measure";
            WarehouseActivityLine."Qty. Rounding Precision" := PutAwayItemUnitOfMeasure."Qty. Rounding Precision";
            WarehouseActivityLine."Qty. Rounding Precision (Base)" := BasePutAwayItemUnitOfMeasure."Qty. Rounding Precision";
        end;

        WarehouseActivityLine.Validate(
              Quantity, UnitOfMeasureManagement.RoundQty(QtyToHandleBase / WarehouseActivityLine."Qty. per Unit of Measure", WarehouseActivityLine."Qty. Rounding Precision"));
        if QtyToHandleBase <> 0 then begin
            WarehouseActivityLine."Qty. (Base)" := QtyToHandleBase;
            WarehouseActivityLine."Qty. to Handle (Base)" := QtyToHandleBase;
            WarehouseActivityLine."Qty. Outstanding (Base)" := QtyToHandleBase;
        end;
        if DoNotFillQtytoHandle then begin
            WarehouseActivityLine."Qty. to Handle" := 0;
            WarehouseActivityLine."Qty. to Handle (Base)" := 0;
            WarehouseActivityLine.Cubage := 0;
            WarehouseActivityLine.Weight := 0;
        end;
        WarehouseActivityLine.CopyTrackingFromProdOrderLineTrackingBuffer(TempProdOrdLineTrackingBuff);
        WarehouseActivityLine."Warranty Date" := TempProdOrdLineTrackingBuff."Warranty Date";
        WarehouseActivityLine."Expiration Date" := TempProdOrdLineTrackingBuff."Expiration Date";

        WarehouseActivityLine.Insert();
    end;

    local procedure InsertWarehouseActivityHeaderForProdOutputPutAway(ProdOrderLine: Record "Prod. Order Line")
    begin
        CurrWarehouseActivityHeader.Init();
        CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::"Put-away";
        CurrWarehouseActivityHeader."Location Code" := ProdOrderLine."Location Code";
        CurrWarehouseActivityHeader.Validate("Assigned User ID", AssignedID);
        CurrWarehouseActivityHeader."Sorting Method" := SortActivity;
        CurrWarehouseActivityHeader."Breakbulk Filter" := BreakbulkFilter;
        CurrWarehouseActivityHeader."Source Document" := CurrWarehouseActivityHeader."Source Document"::"Prod. Output";
        CurrWarehouseActivityHeader.Insert(true);
        InsertTempWhseActivHeader(CurrWarehouseActivityHeader);
    end;

    local procedure GetPutAwayUOMForProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    begin
        if not CurrLocation."Directed Put-away and Pick" then begin
            PutAwayItemUnitOfMeasure.Code := ProdOrderLine."Unit of Measure Code";
            PutAwayItemUnitOfMeasure."Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
            PutAwayItemUnitOfMeasure."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
            BasePutAwayItemUnitOfMeasure."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision (Base)";
            exit;
        end;
        if (PutAwayItemUnitOfMeasure."Item No." <> '') and (PutAwayItemUnitOfMeasure.Code <> '') and
           (CurrStockkeepingUnit."Item No." = PutAwayItemUnitOfMeasure."Item No.") and
           (CurrStockkeepingUnit."Put-away Unit of Measure Code" = PutAwayItemUnitOfMeasure.Code)
        then
            exit;

        if (CurrStockkeepingUnit."Put-away Unit of Measure Code" <> '') and
           ((CurrItem."No." <> PutAwayItemUnitOfMeasure."Item No.") or
            (CurrStockkeepingUnit."Put-away Unit of Measure Code" <> PutAwayItemUnitOfMeasure.Code))
        then begin
            if not PutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrStockkeepingUnit."Put-away Unit of Measure Code") then
                if not PutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrItem."Put-away Unit of Measure Code") then
                    PutAwayItemUnitOfMeasure.Get(CurrItem."No.", ProdOrderLine."Unit of Measure Code")
        end else
            if (CurrItem."No." <> PutAwayItemUnitOfMeasure."Item No.") or
               (CurrItem."Put-away Unit of Measure Code" <> PutAwayItemUnitOfMeasure.Code)
            then
                if not PutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrItem."Put-away Unit of Measure Code") then
                    PutAwayItemUnitOfMeasure.Get(CurrItem."No.", ProdOrderLine."Unit of Measure Code");

        BasePutAwayItemUnitOfMeasure.Get(CurrItem."No.", CurrItem."Base Unit of Measure");
    end;

    local procedure InitializeGlobalsWhsePutAwayForProdOutput()
    begin
        QtyToPickBase := 0;
        QtyToPutAwayBase := 0;
        CrossDockInfo := 0;
        MessageText := '';
        EverythingHandled := false;
        TempWarehouseActivityLine.DeleteAll();
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
    local procedure OnAfterGetLocation(LocationCode: Code[10]; var Location: Record Location; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

#if not CLEAN24
    [Obsolete('Replaced with OnAfterGetMessageText as parent procedure GetMessage is replaced GetMessageText', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetMessage(var MessageText: Text[80])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetMessageText(var MessageText: Text)
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
    local procedure OnAfterSetValues(var AssignedID: Code[50]; var SortActivity: Enum "Whse. Activity Sorting Method"; var DoNotFillQtytoHandle: Boolean; var BreakbulkFilter: Boolean)
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
    local procedure OnAssignPlaceBinZoneOnAfterBin2SetFilters(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; WhseActivLine: Record "Warehouse Activity Line"; Location: Record Location; var Bin2: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyPutAwayTemplateLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; PutAwayTemplLine: Record "Put-away Template Line"; Location: Record Location; var Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignQtyToPutAwayForBinMandatory(Item: Record Item; Location: Record Location; var QtyToPutAwayBase: Decimal; var RemQtyToPutAwayBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailabilityPerBinContent(BinContent: Record "Bin Content"; WarehouseClassCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailCubageAndWeight(var Bin: Record Bin; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PutAwayItemUOM: Record "Item Unit of Measure"; var QtyToPutAwayBase: Decimal; var IsHandled: Boolean; PutAwayTemplLine: Record "Put-away Template Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewWhseActivity(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivHeader: Record "Warehouse Activity Header"; var Location: Record Location; InsertHeader: Boolean; Bin: Record Bin; ActionType: Option ,Take,Place; var LineNo: Integer; BreakbulkNo: Integer; BreakbulkFilter: Boolean; QtyToHandleBase: Decimal; BreakPackage: Boolean; var EmptyZoneBin: Boolean; Breakbulk: Boolean; CrossDockInfo: Option; PutAwayItemUOM: Record "Item Unit of Measure"; DoNotFillQtytoHandle: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateBreakPackageLines(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var TempWhseActivLine: Record "Warehouse Activity Line"; var LineNo: Integer; var BreakbulkNo: Integer; var RemQtyToPutAwayBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEverythingIsHandled(var EverythingHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
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
    local procedure OnBeforeGetPutAwayTemplate(SKU: Record "Stockkeeping Unit"; Item: Record Item; Location: Record Location; var PutAwayTemplHeader: Record "Put-away Template Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFirstPutAwayDocument(var TempWarehouseActivityHeader: Record "Warehouse Activity Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextPutAwayDocument(var TempWarehouseActivityHeader: Record "Warehouse Activity Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetQtyHandledBase(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseActivHeader(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeMakeCrossDockPutAway(var Location: Record Location; var PutAwayItemUOM: Record "Item Unit of Measure"; var Bin: Record Bin; var LineNo: Integer; var CrossDockInfo: Option; var QtyToPutAwayBase: Decimal; var RemQtyToPutAwayBase: Decimal; var EverythingHandled: Boolean; var IsHandled: Boolean; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; CrossDock: Boolean)
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
    local procedure OnCalcQtyToPutAwayOnAfterSetQtyToPutAwayBase(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; Location: Record Location; Bin: Record Bin; CrossDockInfo: Option; EmptyZoneBin: Boolean; var QtyToPutAwayBase: Decimal; var EverythingHandled: Boolean; var RemQtyToPutAwayBase: Decimal; NewBinContent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCreateNewWhseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGetDefaultBin(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateBinContentOnBeforeNewBinContentInsert(var BinContent: Record "Bin Content"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var Bin: Record Bin; var OldBinContent: Record "Bin Content")
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

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailCubageAndWeightOnBeforeCalcCubageAndWeight(var Bin: Record Bin; var AvailPerCubageBase: Decimal; var AvailPerWeightBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForPostedWhseReceiptLine(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var RemQtyToPutAwayBase: Decimal; var EverythingHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCreateBinTypeFilter(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var Location: Record Location; var LineNo: Integer; BreakbulkNo: Integer; BreakbulkFilter: Boolean; var QtyToPutAwayBase: Decimal; var RemQtyToPutAwayBase: Decimal; BreakPackage: Boolean; Breakbulk: Boolean; CrossDockInfo: Option; PutAwayItemUnitofMeasure: Record "Item Unit of Measure"; DoNotFillQtytoHandle: Boolean; var EverythingHandled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSearchBin(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var Location: Record Location; var LineNo: Integer; BreakbulkNo: Integer; BreakbulkFilter: Boolean; var QtyToPutAwayBase: Decimal; var RemQtyToPutAwayBase: Decimal; BreakPackage: Boolean; Breakbulk: Boolean; CrossDockInfo: Option; PutAwayItemUnitofMeasure: Record "Item Unit of Measure"; DoNotFillQtytoHandle: Boolean; var EverythingHandled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterFilterPutAwayTemplateLine(var PutAwayTemplateLine: Record "Put-away Template Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhsePutAwayForProdOutput(var TempProductionOrderForWhsePutAwayForProdOutput: Record "Production Order" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinFromBinContentForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; var BinContentQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; var BinContentQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhsePutAwayForProdOrder(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignPlaceBinZoneOnBeforeApplyBinCodeFilter(var BinCodeFilterText: Text[250]; var Location: Record Location; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWarehouseClassCode(var WarehouseClassCode: Code[10]; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;
}


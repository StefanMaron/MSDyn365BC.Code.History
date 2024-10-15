namespace Microsoft.Inventory.Availability;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using System.Utilities;

codeunit 5531 "Calc. Inventory Page Data"
{

    trigger OnRun()
    begin
    end;

    var
        TempInvtEventBuf: Record "Inventory Event Buffer" temporary;
        CalcItemAvailability: Codeunit "Calc. Item Availability";
        RecRef: RecordRef;
        PageLineNo: Integer;
        UnsupportedEntitySourceErr: Label 'Unsupported Entity Source Type = %1, Source Subtype = %2.', Comment = '%1 = source type, %2 = source subtype';
        Text0032: Label 'Current Qty. on Hand';
        Text0036: Label 'Sales %1';
        Text0038: Label 'Purchase %1';
        Text0246: Label 'Plan Reverted';
        Text1003: Label 'Project %1';
        Text5405: Label 'Production %1';
        Text5407: Label 'Component %1';
        Text5740: Label 'Transfer %1';
        Text5900: Label 'Service %1';
        Text9851: Label 'Forecast Sales';
        Text9852: Label 'Forecast Component';
        Text900: Label 'Assembly Order %1';
        Text901: Label 'Assembly Component %1';

    procedure Initialize(var Item: Record Item; ForecastName: Code[10]; IncludeBlanketOrders: Boolean; ExcludeForecastBefore: Date; IncludePlan: Boolean)
    begin
        OnBeforeInitialize(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);

        TempInvtEventBuf.Reset();
        TempInvtEventBuf.DeleteAll();

        CalcItemAvailability.CalcNewInvtEventBuf(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);
        CalcItemAvailability.GetInvEventBuffer(TempInvtEventBuf);

        OnAfterInitialize(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);
    end;

    procedure CreatePeriodEntries(var InvtPageData: Record "Inventory Page Data"; PeriodType: Option Day,Week,Month,Quarter,Year)
    var
        Date: Record Date;
        LastDateInPeriod: Date;
    begin
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.SetCurrentKey("Availability Date", Type);
        if TempInvtEventBuf.Find('-') then
            repeat
                if TempInvtEventBuf.Type = TempInvtEventBuf.Type::Inventory then begin
                    InvtPageData.Init();
                    InvtPageData.Code := '';
                    InvtPageData."Line No." := NextPageLineNo();
                    InvtPageData."Period Type" := Date."Period Type";
                    InvtPageData."Period Start" := TempInvtEventBuf."Availability Date";
                    InvtPageData.Description := Format(TempInvtEventBuf.Type);
                    InvtPageData.Level := 0;
                    OnCreatePeriodEntriesOnBeforeInvtPageDataInsert(InvtPageData, TempInvtEventBuf);
                    InvtPageData.Insert();
                    LastDateInPeriod := TempInvtEventBuf."Availability Date";
                end else begin
                    Date.SetRange("Period Type", PeriodType);
                    Date.SetFilter("Period Start", '<=%1', TempInvtEventBuf."Availability Date");
                    if Date.FindLast() then begin
                        InvtPageData.Init();
                        InvtPageData.Code := Format(Date."Period Start");
                        InvtPageData."Line No." := NextPageLineNo();
                        InvtPageData."Period Type" := Date."Period Type";
                        InvtPageData."Period Start" := Date."Period Start";
                        InvtPageData."Period End" := Date."Period End";
                        InvtPageData.Description := FormatPeriodDescription(Date);
                        InvtPageData.Level := 0;
                        InvtPageData.Insert();
                        LastDateInPeriod := Date."Period End";
                    end;
                end;
                TempInvtEventBuf.SetFilter("Availability Date", '<=%1', LastDateInPeriod);
                TempInvtEventBuf.Find('+');
                TempInvtEventBuf.SetRange("Availability Date");
            until TempInvtEventBuf.Next() = 0;
        TempInvtEventBuf.Reset();
    end;

    procedure DetailsForPeriodEntry(var InvtPageData: Record "Inventory Page Data"; Positive: Boolean)
    var
        PeriodInvtPageData: Record "Inventory Page Data";
        IsHandled: Boolean;
    begin
        PeriodInvtPageData.Copy(InvtPageData);
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.SetCurrentKey("Availability Date", Type);
        TempInvtEventBuf.SetRange("Availability Date", InvtPageData."Period Start", InvtPageData."Period End");
        TempInvtEventBuf.SetRange(Positive, Positive);
        if TempInvtEventBuf.Find('-') then
            repeat
                TransferToPeriodDetails(InvtPageData, TempInvtEventBuf);
                UpdateInventory(InvtPageData, TempInvtEventBuf);
                InvtPageData."Line No." := NextPageLineNo();
                IsHandled := false;
                OnDetailsForPeriodEntryOnBeforeInvtPageDataInsert(InvtPageData, IsHandled);
                if not IsHandled then
                    InvtPageData.Insert();
                UpdatePeriodTotals(PeriodInvtPageData, InvtPageData);
                UpdateInventory(PeriodInvtPageData, TempInvtEventBuf);
            until TempInvtEventBuf.Next() = 0;
        InvtPageData.Copy(PeriodInvtPageData);

        OnDetailsForPeriodEntryOnBeforeInvtPageDataModify(InvtPageData);
        InvtPageData.Modify();
    end;

    local procedure TransferToPeriodDetails(var InventoryPageData: Record "Inventory Page Data"; var FromInvtEventBuf: Record "Inventory Event Buffer")
    var
        SourceType: Integer;
        SourceSubtype: Integer;
        SourceID: Code[20];
        SourceBatchName: Code[10];
        SourceProdOrderLine: Integer;
        SourceRefNo: Integer;
        IsHandled: Boolean;
    begin
        InventoryPageData.Init();

        InventoryPageData.Code := Format(FromInvtEventBuf."Availability Date");
        InventoryPageData."Period Start" := FromInvtEventBuf."Availability Date";
        InventoryPageData."Availability Date" := FromInvtEventBuf."Availability Date";
        InventoryPageData.Level := 1;
        InventoryPageData."Source Line ID" := FromInvtEventBuf."Source Line ID";
        InventoryPageData."Item No." := FromInvtEventBuf."Item No.";
        InventoryPageData."Variant Code" := FromInvtEventBuf."Variant Code";
        InventoryPageData."Location Code" := FromInvtEventBuf."Location Code";
        InventoryPageData."Remaining Quantity (Base)" := FromInvtEventBuf."Remaining Quantity (Base)";
        InventoryPageData.Positive := FromInvtEventBuf.Positive;
        CalcItemAvailability.GetSourceReferences(FromInvtEventBuf."Source Line ID", FromInvtEventBuf."Transfer Direction",
          SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);
        case SourceType of
            DATABASE::"Item Ledger Entry":
                TransferInventory(FromInvtEventBuf, InventoryPageData);
            DATABASE::"Sales Line":
                TransferSalesLine(FromInvtEventBuf, InventoryPageData, SourceType, SourceSubtype, SourceID);
            DATABASE::"Purchase Line":
                TransferPurchLine(FromInvtEventBuf, InventoryPageData, SourceType, SourceSubtype, SourceID);
            DATABASE::"Transfer Line":
                TransferTransLine(FromInvtEventBuf, InventoryPageData, SourceType, SourceSubtype, SourceID);
            DATABASE::"Prod. Order Line":
                TransferProdOrderLine(FromInvtEventBuf, InventoryPageData, SourceSubtype, SourceID);
            DATABASE::"Prod. Order Component":
                TransferProdOrderComp(FromInvtEventBuf, InventoryPageData, SourceSubtype, SourceID);
            DATABASE::"Service Line":
                TransferServiceLine(FromInvtEventBuf, InventoryPageData, SourceSubtype, SourceID);
            DATABASE::"Job Planning Line":
                TransferJobPlanningLine(FromInvtEventBuf, InventoryPageData, SourceID);
            DATABASE::"Requisition Line":
                TransferReqLine(FromInvtEventBuf, InventoryPageData, SourceID, SourceBatchName, SourceRefNo);
            DATABASE::"Planning Component":
                TransferPlanningComp(FromInvtEventBuf, InventoryPageData, SourceID, SourceBatchName, SourceProdOrderLine);
            DATABASE::"Production Forecast Entry":
                TransferProdForecastEntry(FromInvtEventBuf, InventoryPageData, SourceRefNo);
            DATABASE::"Assembly Header":
                TransferAssemblyHeader(FromInvtEventBuf, InventoryPageData, SourceSubtype, SourceID);
            DATABASE::"Assembly Line":
                TransferAssemblyLine(FromInvtEventBuf, InventoryPageData, SourceSubtype, SourceID, SourceRefNo);
            else begin
                OnTransferToPeriodDetailsElseCase(InventoryPageData, FromInvtEventBuf, IsHandled);
                if not IsHandled then
                    Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
            end;
        end;
        OnAfterTransferToPeriodDetails(InventoryPageData, FromInvtEventBuf, SourceType, SourceSubtype);
    end;

    local procedure TransferInventory(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data")
    begin
        InventoryPageData.Type := InventoryPageData.Type::" ";
        InventoryPageData.Description := Text0032;
        InventoryPageData.Source := InventoryEventBuffer."Location Code" + ' ' + InventoryEventBuffer."Variant Code";
        InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferSalesLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(SalesHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData.Description := SalesHeader."Sell-to Customer Name";
        InventoryPageData.Source := StrSubstNo(Text0036, Format(SalesHeader."Document Type"));
        InventoryPageData."Document No." := SalesHeader."No.";
        case SourceSubtype of
            1,
            2,
            3:
                begin
                    // Sales Order or similar to go into Gross Requirements
                    InventoryPageData.Type := InventoryPageData.Type::Sale;
                    InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            4:
                begin
                    // Blanket Order
                    InventoryPageData.Type := InventoryPageData.Type::"Blanket Sales Order";
                    InventoryPageData.Forecast := InventoryEventBuffer."Orig. Quantity (Base)";
                    InventoryPageData."Remaining Forecast" := InventoryEventBuffer."Remaining Quantity (Base)";
                end;
            5:
                begin
                    // Sales Return Order
                    InventoryPageData.Type := InventoryPageData.Type::"Sales Return";
                    InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            else
                Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
        end;
    end;

    local procedure TransferPurchLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(PurchHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData.Description := PurchHeader."Buy-from Vendor Name";
        InventoryPageData.Source := StrSubstNo(Text0038, Format(PurchHeader."Document Type"));
        InventoryPageData."Document No." := PurchHeader."No.";
        case SourceSubtype of
            1,
            2,
            3:
                begin
                    // Purchase Order or similar to go into Scheduled Receipts
                    InventoryPageData.Type := InventoryPageData.Type::Purchase;
                    InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            5:
                begin
                    // Purchase Return Order
                    InventoryPageData.Type := InventoryPageData.Type::"Purch. Return";
                    InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            else
                Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
        end;
    end;

    local procedure TransferTransLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        TransHeader: Record "Transfer Header";
    begin
        TransHeader.Get(SourceID);
        RecRef.GetTable(TransHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := TransHeader."No.";
        case SourceSubtype of
            0:
                case InventoryEventBuffer.Type of
                    InventoryEventBuffer.Type::Transfer:
                        begin
                            // Outbound Transfer
                            InventoryPageData.Type := InventoryPageData.Type::Transfer;
                            InventoryPageData.Description := TransHeader."Transfer-to Name";
                            InventoryPageData.Source := StrSubstNo(Text5740, Format(TransHeader."Transfer-to Code"));
                            InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                            InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                        end;
                    InventoryEventBuffer.Type::"Plan Revert":
                        begin
                            InventoryPageData.Type := InventoryPageData.Type::"Plan Revert";
                            InventoryPageData.Description := TransHeader."Transfer-to Name";
                            InventoryPageData.Source := Text0246;
                            InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
                            InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
                        end;
                end;
            1:
                begin
                    // Inbound Transfer
                    InventoryPageData.Type := InventoryPageData.Type::Transfer;
                    InventoryPageData.Description := TransHeader."Transfer-from Name";
                    InventoryPageData.Source := StrSubstNo(Text5740, Format(TransHeader."Transfer-from Code"));
                    InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            else
                Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
        end;
        OnAfterTransferTransLine(InventoryPageData, TransHeader);
    end;

    local procedure TransferProdOrderLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.Get(SourceSubtype, SourceID);
        RecRef.GetTable(ProdOrder);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ProdOrder."No.";
        InventoryPageData.Type := InventoryPageData.Type::Production;
        InventoryPageData.Description := ProdOrder.Description;
        InventoryPageData.Source := StrSubstNo(Text5405, Format(ProdOrder.Status));
        InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferProdOrderComp(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.Get(SourceSubtype, SourceID);
        RecRef.GetTable(ProdOrder);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ProdOrder."No.";
        InventoryPageData.Description := ProdOrder.Description;
        case InventoryEventBuffer.Type of
            InventoryEventBuffer.Type::Component:
                begin
                    InventoryPageData.Type := InventoryPageData.Type::Component;
                    InventoryPageData.Source := StrSubstNo(Text5407, Format(ProdOrder.Status));
                    InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            InventoryEventBuffer.Type::"Plan Revert":
                begin
                    InventoryPageData.Type := InventoryPageData.Type::"Plan Revert";
                    InventoryPageData.Source := Text0246;
                    InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
                end;
        end;
        OnAfterTransferProdOrderComp(InventoryPageData, ProdOrder);
    end;

    local procedure TransferServiceLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ServHeader: Record "Service Header";
    begin
        ServHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(ServHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ServHeader."No.";
        InventoryPageData.Type := InventoryPageData.Type::Service;
        InventoryPageData.Description := ServHeader."Ship-to Name";
        InventoryPageData.Source := StrSubstNo(Text5900, Format(ServHeader."Document Type"));
        InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferJobPlanningLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20])
    var
        Job: Record Job;
    begin
        Job.Get(SourceID);
        RecRef.GetTable(Job);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := Job."No.";
        InventoryPageData.Type := InventoryPageData.Type::Job;
        InventoryPageData.Description := Job."Bill-to Customer No.";
        InventoryPageData.Source := StrSubstNo(Text1003, Format(Job.Status));
        InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferReqLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get(SourceID, SourceBatchName, SourceRefNo);
        RecRef.GetTable(ReqLine);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ReqLine."Ref. Order No.";
        InventoryPageData.Type := InventoryPageData.Type::Plan;
        InventoryPageData.Source := Format(InventoryEventBuffer."Ref. Order Type") + ' ' + Format(InventoryEventBuffer."Action Message");
        InventoryPageData.Description := ReqLine.Description;
        InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
    end;

    local procedure TransferPlanningComp(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get(SourceID, SourceBatchName, SourceProdOrderLine);
        RecRef.GetTable(ReqLine);
        InventoryPageData."Source Document ID" := InventoryEventBuffer."Source Line ID";
        InventoryPageData."Document No." := ReqLine."Ref. Order No.";
        InventoryPageData.Type := InventoryPageData.Type::Plan;
        InventoryPageData.Description := ReqLine.Description;
        InventoryPageData.Source := StrSubstNo(Text5407, Format(InventoryEventBuffer."Action Message"));
        InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
        OnAfterTransferPlanningComp(InventoryPageData, ReqLine);
    end;

    local procedure TransferProdForecastEntry(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceRefNo: Integer)
    var
        ProdForecastName: Record "Production Forecast Name";
        ProdForecastEntry: Record "Production Forecast Entry";
    begin
        ProdForecastEntry.Get(SourceRefNo);
        ProdForecastName.Get(ProdForecastEntry."Production Forecast Name");
        RecRef.GetTable(ProdForecastName);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ProdForecastName.Name;
        InventoryPageData.Type := InventoryPageData.Type::Forecast;
        InventoryPageData.Description := ProdForecastName.Description;
        if InventoryEventBuffer."Forecast Type" = InventoryEventBuffer."Forecast Type"::Sales then
            InventoryPageData.Source := Text9851
        else
            InventoryPageData.Source := Text9852;
        InventoryPageData.Forecast := InventoryEventBuffer."Orig. Quantity (Base)";
        InventoryPageData."Remaining Forecast" := InventoryEventBuffer."Remaining Quantity (Base)";
    end;

    local procedure TransferAssemblyHeader(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Option; SourceID: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(AssemblyHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := AssemblyHeader."No.";
        InventoryPageData.Type := InventoryPageData.Type::"Assembly Order";
        InventoryPageData.Description := AssemblyHeader.Description;
        InventoryPageData.Source := StrSubstNo(Text900, Format(AssemblyHeader."Document Type"));
        InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferAssemblyLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Get(SourceSubtype, SourceID, SourceRefNo);
        RecRef.GetTable(AssemblyLine);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := AssemblyLine."Document No.";
        InventoryPageData."Line No." := AssemblyLine."Line No.";
        InventoryPageData.Type := InventoryPageData.Type::"Assembly Component";
        InventoryPageData.Description := AssemblyLine.Description;
        InventoryPageData.Source := StrSubstNo(Text901, Format(AssemblyLine."Document Type"));
        InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure UpdatePeriodTotals(var PeriodInvtPageData: Record "Inventory Page Data"; var DetailInvtPageData: Record "Inventory Page Data")
    begin
        PeriodInvtPageData."Remaining Quantity (Base)" += DetailInvtPageData."Remaining Quantity (Base)";
        PeriodInvtPageData."Gross Requirement" += DetailInvtPageData."Gross Requirement";
        PeriodInvtPageData."Reserved Requirement" += DetailInvtPageData."Reserved Requirement";
        PeriodInvtPageData."Scheduled Receipt" += DetailInvtPageData."Scheduled Receipt";
        PeriodInvtPageData."Reserved Receipt" += DetailInvtPageData."Reserved Receipt";
        PeriodInvtPageData.Forecast += DetailInvtPageData.Forecast;
        PeriodInvtPageData."Remaining Forecast" += DetailInvtPageData."Remaining Forecast";
        PeriodInvtPageData."Action Message Qty." += DetailInvtPageData."Action Message Qty.";

        OnAfterUpdatePeriodTotals(PeriodInvtPageData, DetailInvtPageData);
    end;

    local procedure UpdateInventory(var InvtPageData: Record "Inventory Page Data"; var InvtEventBuf: Record "Inventory Event Buffer")
    begin
        if InvtEventBuf."Action Message" <> InvtEventBuf."Action Message"::" " then
            InvtPageData."Suggested Projected Inventory" += InvtEventBuf."Remaining Quantity (Base)"
        else
            if InvtEventBuf.Type = InvtEventBuf.Type::Forecast then
                InvtPageData."Forecasted Projected Inventory" += InvtEventBuf."Remaining Quantity (Base)"
            else
                InvtPageData."Projected Inventory" += InvtEventBuf."Remaining Quantity (Base)";

        OnAfterUpdateInventory(InvtPageData, InvtEventBuf);
    end;

    local procedure NextPageLineNo(): Integer
    begin
        PageLineNo += 1;
        exit(PageLineNo);
    end;

    procedure ShowDocument(RecID: RecordID)
    begin
        CalcItemAvailability.ShowDocument(RecID);
    end;

    local procedure FormatPeriodDescription(Date: Record Date) PeriodDescription: Text[50]
    begin
        case Date."Period Type" of
            Date."Period Type"::Week,
          Date."Period Type"::Quarter,
          Date."Period Type"::Year:
                PeriodDescription := StrSubstNo('%1 %2', Format(Date."Period Type"), Date."Period Name");
            else
                PeriodDescription := Date."Period Name";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var Item: Record Item; var ForecastName: Code[10]; var IncludeBlanketOrders: Boolean; var ExcludeForecastBefore: Date; var IncludePlan: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToPeriodDetails(var InventoryPageData: Record "Inventory Page Data"; var InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTransLine(var InventoryPageData: Record "Inventory Page Data"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferProdOrderComp(var InventoryPageData: Record "Inventory Page Data"; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPlanningComp(var InventoryPageData: Record "Inventory Page Data"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInventory(var InvtPageData: Record "Inventory Page Data"; var InvtEventBuf: Record "Inventory Event Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePeriodTotals(var PeriodInvtPageData: Record "Inventory Page Data"; DetailInvtPageData: Record "Inventory Page Data")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDetailsForPeriodEntryOnBeforeInvtPageDataInsert(var InventoryPageData: Record "Inventory Page Data"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDetailsForPeriodEntryOnBeforeInvtPageDataModify(var InventoryPageData: Record "Inventory Page Data")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var Item: Record Item; var ForecastName: Code[10]; var IncludeBlanketOrders: Boolean; var ExcludeForecastBefore: Date; var IncludePlan: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePeriodEntriesOnBeforeInvtPageDataInsert(var InventoryPageData: Record "Inventory Page Data"; var TempInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    begin
    end;
}


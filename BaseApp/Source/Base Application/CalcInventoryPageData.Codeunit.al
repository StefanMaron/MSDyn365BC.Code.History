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
        Text1003: Label 'Job %1';
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
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.DeleteAll();

        CalcItemAvailability.CalcNewInvtEventBuf(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);
        CalcItemAvailability.GetInvEventBuffer(TempInvtEventBuf);
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
                    InvtPageData."Line No." := NextPageLineNo;
                    InvtPageData."Period Type" := Date."Period Type";
                    InvtPageData."Period Start" := TempInvtEventBuf."Availability Date";
                    InvtPageData.Description := Format(TempInvtEventBuf.Type);
                    InvtPageData.Level := 0;
                    InvtPageData.Insert();
                    LastDateInPeriod := TempInvtEventBuf."Availability Date";
                end else begin
                    Date.SetRange("Period Type", PeriodType);
                    Date.SetFilter("Period Start", '<=%1', TempInvtEventBuf."Availability Date");
                    if Date.FindLast then begin
                        InvtPageData.Init();
                        InvtPageData.Code := Format(Date."Period Start");
                        InvtPageData."Line No." := NextPageLineNo;
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
            until TempInvtEventBuf.Next = 0;
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
                InvtPageData."Line No." := NextPageLineNo;
                IsHandled := false;
                OnDetailsForPeriodEntryOnBeforeInvtPageDataInsert(InvtPageData, IsHandled);
                if not IsHandled then
                    InvtPageData.Insert();
                UpdatePeriodTotals(PeriodInvtPageData, InvtPageData);
                UpdateInventory(PeriodInvtPageData, TempInvtEventBuf);
            until TempInvtEventBuf.Next = 0;
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

        with FromInvtEventBuf do begin
            InventoryPageData.Code := Format("Availability Date");
            InventoryPageData."Period Start" := "Availability Date";
            InventoryPageData."Availability Date" := "Availability Date";
            InventoryPageData.Level := 1;
            InventoryPageData."Source Line ID" := "Source Line ID";
            InventoryPageData."Item No." := "Item No.";
            InventoryPageData."Variant Code" := "Variant Code";
            InventoryPageData."Location Code" := "Location Code";
            InventoryPageData."Remaining Quantity (Base)" := "Remaining Quantity (Base)";
            InventoryPageData.Positive := Positive;
            CalcItemAvailability.GetSourceReferences("Source Line ID", "Transfer Direction",
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
        end;
        OnAfterTransferToPeriodDetails(InventoryPageData, FromInvtEventBuf);
    end;

    local procedure TransferInventory(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data")
    begin
        with InventoryEventBuffer do begin
            InventoryPageData.Type := InventoryPageData.Type::" ";
            InventoryPageData.Description := Text0032;
            InventoryPageData.Source := "Location Code" + ' ' + "Variant Code";
            InventoryPageData."Scheduled Receipt" := "Remaining Quantity (Base)";
            InventoryPageData."Reserved Receipt" := "Reserved Quantity (Base)";
        end;
    end;

    local procedure TransferSalesLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        with InventoryEventBuffer do begin
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
                        InventoryPageData."Gross Requirement" := "Remaining Quantity (Base)";
                        InventoryPageData."Reserved Requirement" := "Reserved Quantity (Base)";
                    end;
                4:
                    begin
                        // Blanket Order
                        InventoryPageData.Type := InventoryPageData.Type::"Blanket Sales Order";
                        InventoryPageData.Forecast := "Orig. Quantity (Base)";
                        InventoryPageData."Remaining Forecast" := "Remaining Quantity (Base)";
                    end;
                5:
                    begin
                        // Sales Return Order
                        InventoryPageData.Type := InventoryPageData.Type::"Sales Return";
                        InventoryPageData."Scheduled Receipt" := "Remaining Quantity (Base)";
                        InventoryPageData."Reserved Receipt" := "Reserved Quantity (Base)";
                    end;
                else
                    Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
            end;
        end;
    end;

    local procedure TransferPurchLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        with InventoryEventBuffer do begin
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
                        InventoryPageData."Scheduled Receipt" := "Remaining Quantity (Base)";
                        InventoryPageData."Reserved Receipt" := "Reserved Quantity (Base)";
                    end;
                5:
                    begin
                        // Purchase Return Order
                        InventoryPageData.Type := InventoryPageData.Type::"Purch. Return";
                        InventoryPageData."Gross Requirement" := "Remaining Quantity (Base)";
                        InventoryPageData."Reserved Requirement" := "Reserved Quantity (Base)";
                    end;
                else
                    Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
            end;
        end;
    end;

    local procedure TransferTransLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        TransHeader: Record "Transfer Header";
    begin
        with InventoryEventBuffer do begin
            TransHeader.Get(SourceID);
            RecRef.GetTable(TransHeader);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := TransHeader."No.";
            case SourceSubtype of
                0:
                    case Type of
                        Type::Transfer:
                            begin
                                // Outbound Transfer
                                InventoryPageData.Type := InventoryPageData.Type::Transfer;
                                InventoryPageData.Description := TransHeader."Transfer-to Name";
                                InventoryPageData.Source := StrSubstNo(Text5740, Format(TransHeader."Transfer-to Code"));
                                InventoryPageData."Gross Requirement" := "Remaining Quantity (Base)";
                                InventoryPageData."Reserved Requirement" := "Reserved Quantity (Base)";
                            end;
                        Type::"Plan Revert":
                            begin
                                InventoryPageData.Type := InventoryPageData.Type::"Plan Revert";
                                InventoryPageData.Description := TransHeader."Transfer-to Name";
                                InventoryPageData.Source := Text0246;
                                InventoryPageData."Action Message Qty." := "Remaining Quantity (Base)";
                                InventoryPageData."Action Message" := "Action Message";
                            end;
                    end;
                1:
                    begin
                        // Inbound Transfer
                        InventoryPageData.Type := InventoryPageData.Type::Transfer;
                        InventoryPageData.Description := TransHeader."Transfer-from Name";
                        InventoryPageData.Source := StrSubstNo(Text5740, Format(TransHeader."Transfer-from Code"));
                        InventoryPageData."Scheduled Receipt" := "Remaining Quantity (Base)";
                        InventoryPageData."Reserved Receipt" := "Reserved Quantity (Base)";
                    end;
                else
                    Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
            end;
        end;
    end;

    local procedure TransferProdOrderLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        with InventoryEventBuffer do begin
            ProdOrder.Get(SourceSubtype, SourceID);
            RecRef.GetTable(ProdOrder);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := ProdOrder."No.";
            InventoryPageData.Type := InventoryPageData.Type::Production;
            InventoryPageData.Description := ProdOrder.Description;
            InventoryPageData.Source := StrSubstNo(Text5405, Format(ProdOrder.Status));
            InventoryPageData."Scheduled Receipt" := "Remaining Quantity (Base)";
            InventoryPageData."Reserved Receipt" := "Reserved Quantity (Base)";
        end;
    end;

    local procedure TransferProdOrderComp(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        with InventoryEventBuffer do begin
            ProdOrder.Get(SourceSubtype, SourceID);
            RecRef.GetTable(ProdOrder);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := ProdOrder."No.";
            InventoryPageData.Description := ProdOrder.Description;
            case Type of
                Type::Component:
                    begin
                        InventoryPageData.Type := InventoryPageData.Type::Component;
                        InventoryPageData.Source := StrSubstNo(Text5407, Format(ProdOrder.Status));
                        InventoryPageData."Gross Requirement" := "Remaining Quantity (Base)";
                        InventoryPageData."Reserved Requirement" := "Reserved Quantity (Base)";
                    end;
                Type::"Plan Revert":
                    begin
                        InventoryPageData.Type := InventoryPageData.Type::"Plan Revert";
                        InventoryPageData.Source := Text0246;
                        InventoryPageData."Action Message Qty." := "Remaining Quantity (Base)";
                        InventoryPageData."Action Message" := "Action Message";
                    end;
            end;
        end;
    end;

    local procedure TransferServiceLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ServHeader: Record "Service Header";
    begin
        with InventoryEventBuffer do begin
            ServHeader.Get(SourceSubtype, SourceID);
            RecRef.GetTable(ServHeader);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := ServHeader."No.";
            InventoryPageData.Type := InventoryPageData.Type::Service;
            InventoryPageData.Description := ServHeader."Ship-to Name";
            InventoryPageData.Source := StrSubstNo(Text5900, Format(ServHeader."Document Type"));
            InventoryPageData."Gross Requirement" := "Remaining Quantity (Base)";
            InventoryPageData."Reserved Requirement" := "Reserved Quantity (Base)";
        end;
    end;

    local procedure TransferJobPlanningLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20])
    var
        Job: Record Job;
    begin
        with InventoryEventBuffer do begin
            Job.Get(SourceID);
            RecRef.GetTable(Job);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := Job."No.";
            InventoryPageData.Type := InventoryPageData.Type::Job;
            InventoryPageData.Description := Job."Bill-to Customer No.";
            InventoryPageData.Source := StrSubstNo(Text1003, Format(Job.Status));
            InventoryPageData."Gross Requirement" := "Remaining Quantity (Base)";
            InventoryPageData."Reserved Requirement" := "Reserved Quantity (Base)";
        end;
    end;

    local procedure TransferReqLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        with InventoryEventBuffer do begin
            ReqLine.Get(SourceID, SourceBatchName, SourceRefNo);
            RecRef.GetTable(ReqLine);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := ReqLine."Ref. Order No.";
            InventoryPageData.Type := InventoryPageData.Type::Plan;
            InventoryPageData.Source := Format("Ref. Order Type") + ' ' + Format("Action Message");
            InventoryPageData.Description := ReqLine.Description;
            InventoryPageData."Action Message Qty." := "Remaining Quantity (Base)";
            InventoryPageData."Action Message" := "Action Message";
        end;
    end;

    local procedure TransferPlanningComp(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        with InventoryEventBuffer do begin
            ReqLine.Get(SourceID, SourceBatchName, SourceProdOrderLine);
            RecRef.GetTable(ReqLine);
            InventoryPageData."Source Document ID" := "Source Line ID";
            InventoryPageData."Document No." := ReqLine."Ref. Order No.";
            InventoryPageData.Type := InventoryPageData.Type::Plan;
            InventoryPageData.Description := ReqLine.Description;
            InventoryPageData.Source := StrSubstNo(Text5407, Format("Action Message"));
            InventoryPageData."Action Message Qty." := "Remaining Quantity (Base)";
            InventoryPageData."Action Message" := "Action Message";
        end;
    end;

    local procedure TransferProdForecastEntry(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceRefNo: Integer)
    var
        ProdForecastName: Record "Production Forecast Name";
        ProdForecastEntry: Record "Production Forecast Entry";
    begin
        with InventoryEventBuffer do begin
            ProdForecastEntry.Get(SourceRefNo);
            ProdForecastName.Get(ProdForecastEntry."Production Forecast Name");
            RecRef.GetTable(ProdForecastName);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := ProdForecastName.Name;
            InventoryPageData.Type := InventoryPageData.Type::Forecast;
            InventoryPageData.Description := ProdForecastName.Description;
            if "Forecast Type" = "Forecast Type"::Sales then
                InventoryPageData.Source := Text9851
            else
                InventoryPageData.Source := Text9852;
            InventoryPageData.Forecast := "Orig. Quantity (Base)";
            InventoryPageData."Remaining Forecast" := "Remaining Quantity (Base)";
        end;
    end;

    local procedure TransferAssemblyHeader(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Option; SourceID: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        with InventoryEventBuffer do begin
            AssemblyHeader.Get(SourceSubtype, SourceID);
            RecRef.GetTable(AssemblyHeader);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := AssemblyHeader."No.";
            InventoryPageData.Type := InventoryPageData.Type::"Assembly Order";
            InventoryPageData.Description := AssemblyHeader.Description;
            InventoryPageData.Source := StrSubstNo(Text900, Format(AssemblyHeader."Document Type"));
            InventoryPageData."Scheduled Receipt" := "Remaining Quantity (Base)";
            InventoryPageData."Reserved Receipt" := "Reserved Quantity (Base)";
        end;
    end;

    local procedure TransferAssemblyLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        with InventoryEventBuffer do begin
            AssemblyLine.Get(SourceSubtype, SourceID, SourceRefNo);
            RecRef.GetTable(AssemblyLine);
            InventoryPageData."Source Document ID" := RecRef.RecordId;
            InventoryPageData."Document No." := AssemblyLine."Document No.";
            InventoryPageData."Line No." := AssemblyLine."Line No.";
            InventoryPageData.Type := InventoryPageData.Type::"Assembly Component";
            InventoryPageData.Description := AssemblyLine.Description;
            InventoryPageData.Source := StrSubstNo(Text901, Format(AssemblyLine."Document Type"));
            InventoryPageData."Gross Requirement" := "Remaining Quantity (Base)";
            InventoryPageData."Reserved Requirement" := "Reserved Quantity (Base)";
        end;
    end;

    local procedure UpdatePeriodTotals(var PeriodInvtPageData: Record "Inventory Page Data"; var DetailInvtPageData: Record "Inventory Page Data")
    begin
        with DetailInvtPageData do begin
            PeriodInvtPageData."Remaining Quantity (Base)" += "Remaining Quantity (Base)";
            PeriodInvtPageData."Gross Requirement" += "Gross Requirement";
            PeriodInvtPageData."Reserved Requirement" += "Reserved Requirement";
            PeriodInvtPageData."Scheduled Receipt" += "Scheduled Receipt";
            PeriodInvtPageData."Reserved Receipt" += "Reserved Receipt";
            PeriodInvtPageData.Forecast += Forecast;
            PeriodInvtPageData."Remaining Forecast" += "Remaining Forecast";
            PeriodInvtPageData."Action Message Qty." += "Action Message Qty.";
        end;

        OnAfterUpdatePeriodTotals(PeriodInvtPageData, DetailInvtPageData);
    end;

    local procedure UpdateInventory(var InvtPageData: Record "Inventory Page Data"; var InvtEventBuf: Record "Inventory Event Buffer")
    begin
        with InvtEventBuf do begin
            if "Action Message" <> "Action Message"::" " then
                InvtPageData."Suggested Projected Inventory" += "Remaining Quantity (Base)"
            else
                if Type = Type::Forecast then
                    InvtPageData."Forecasted Projected Inventory" += "Remaining Quantity (Base)"
                else
                    InvtPageData."Projected Inventory" += "Remaining Quantity (Base)";
        end;
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
    local procedure OnAfterTransferToPeriodDetails(var InventoryPageData: Record "Inventory Page Data"; var InventoryEventBuffer: Record "Inventory Event Buffer")
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
}


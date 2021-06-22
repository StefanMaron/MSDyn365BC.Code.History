codeunit 99000886 "Capable to Promise"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Calculation with date #1######';
        OrderPromisingSetup: Record "Order Promising Setup";
        CompanyInfo: Record "Company Information";
        UOMMgt: Codeunit "Unit of Measure Management";
        OrderPromisingID: Code[20];
        LastEarlyDate: Date;
        LastLateDate: Date;
        OrderPromisingEnd: Date;
        OrderPromisingStart: Date;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        OrderPromisingLineNo: Integer;
        OrderPromisingLineToSave: Integer;
        SourceLineNo: Integer;

    local procedure ValidateCapableToPromise(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; NeededDate: Date; NeededQty: Decimal; UnitOfMeasure: Code[10]; PeriodType: Option Day,Week,Month,Quarter,Year; var DueDateOfReqLine: Date): Boolean
    var
        ReqLine: Record "Requisition Line";
        CumulativeATP: Decimal;
        ReqQty: Decimal;
        Ok: Boolean;
    begin
        CumulativeATP :=
          GetCumulativeATP(ItemNo, VariantCode, LocationCode, NeededDate, UnitOfMeasure, PeriodType);

        if CumulativeATP < 0 then begin
            if CumulativeATP + NeededQty <= 0 then
                ReqQty := NeededQty
            else
                ReqQty := -CumulativeATP;
            CreateReqLine(ItemNo, VariantCode, LocationCode, ReqQty, UnitOfMeasure, NeededDate, 1, ReqLine);
            OrderPromisingLineNo := OrderPromisingLineNo + 1;
            if ReqLine."Starting Date" < OrderPromisingStart then
                exit(false);
        end;
        Ok := CheckDerivedDemandCTP(ReqLine, PeriodType);
        if ReqLine."No." <> '' then begin
            if Ok then
                DueDateOfReqLine := ReqLine."Due Date"
        end else
            DueDateOfReqLine := NeededDate;
        exit(Ok);
    end;

    procedure CalcCapableToPromise(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; NeededDate: Date; NeededQty: Decimal; UnitOfMeasure: Code[10]; var LocOrderPromisingID: Code[20]; LocSourceLineNo: Integer; var LastValidLine: Integer; PeriodType: Option Day,Week,Month,Quarter,Year; PeriodLengthFormula: DateFormula): Date
    var
        CalculationDialog: Dialog;
        CalculationStartDate: Date;
        CapableToPromiseDate: Date;
        IsValid: Boolean;
        StopCalculation: Boolean;
        DueDateOfReqLine: Date;
    begin
        if NeededQty = 0 then
            exit(NeededDate);
        RemoveReqLines(LocOrderPromisingID, LocSourceLineNo, LastValidLine, false);
        SetOrderPromisingParameters(LocOrderPromisingID, LocSourceLineNo, PeriodLengthFormula);

        CapableToPromiseDate := 0D;
        CalculationStartDate := NeededDate;
        if CalculationStartDate = 0D then
            CalculationStartDate := OrderPromisingStart;
        OrderPromisingLineToSave := OrderPromisingLineNo;
        if not
           ValidateCapableToPromise(
             ItemNo, VariantCode, LocationCode, CalculationStartDate,
             NeededQty, UnitOfMeasure, PeriodType, DueDateOfReqLine)
        then begin
            StopCalculation := false;
            LastEarlyDate := CalculationStartDate;
            LastLateDate := OrderPromisingEnd;
            CalculationStartDate := OrderPromisingEnd;
            CalculationDialog.Open(Text000);
            repeat
                CalculationDialog.Update(1, Format(CalculationStartDate));
                RemoveReqLines(LocOrderPromisingID, LocSourceLineNo, OrderPromisingLineToSave, false);
                IsValid :=
                  ValidateCapableToPromise(ItemNo, VariantCode, LocationCode, CalculationStartDate,
                    NeededQty, UnitOfMeasure, PeriodType, DueDateOfReqLine);
                if IsValid then begin
                    CapableToPromiseDate := CalculationStartDate;
                    StopCalculation := GetNextCalcStartDate(CalculationStartDate, 0);
                end else
                    StopCalculation := GetNextCalcStartDate(CalculationStartDate, 1);
            until StopCalculation;
            if not IsValid and (CapableToPromiseDate > 0D) then begin
                RemoveReqLines(LocOrderPromisingID, LocSourceLineNo, OrderPromisingLineToSave, false);
                ValidateCapableToPromise(ItemNo, VariantCode, LocationCode, CapableToPromiseDate,
                  NeededQty, UnitOfMeasure, PeriodType, DueDateOfReqLine);
            end;
            CalculationDialog.Close;
        end else
            CapableToPromiseDate := CalculationStartDate;

        if CapableToPromiseDate <> DueDateOfReqLine then
            CapableToPromiseDate := DueDateOfReqLine;

        LastValidLine := GetNextOrderPromisingLineNo;
        if CapableToPromiseDate = 0D then
            RemoveReqLines(LocOrderPromisingID, LocSourceLineNo, OrderPromisingLineNo, false);
        exit(CapableToPromiseDate);
    end;

    local procedure GetNextCalcStartDate(var CalculationStartDate: Date; Direction: Option Backwards,Forwards): Boolean
    var
        BestResult: Boolean;
    begin
        BestResult := false;
        if Direction = Direction::Backwards then begin
            LastLateDate := CalculationStartDate;
            if LastLateDate - LastEarlyDate > 1 then
                CalculationStartDate := CalculationStartDate - Round((LastLateDate - LastEarlyDate) / 2, 1, '>')
            else
                BestResult := true;
        end else begin
            LastEarlyDate := CalculationStartDate;
            if LastLateDate - LastEarlyDate > 1 then
                CalculationStartDate := CalculationStartDate + Round((LastLateDate - LastEarlyDate) / 2, 1, '>')
            else
                BestResult := true;
        end;
        exit(BestResult);
    end;

    local procedure CreateReqLine(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; Unit: Code[10]; DueDate: Date; Direction: Option Forward,Backward; var ReqLine: Record "Requisition Line")
    var
        SalesLine: Record "Sales Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        PlngLnMgt: Codeunit "Planning Line Management";
    begin
        ReqLine.Init();
        ReqLine."Order Promising ID" := OrderPromisingID;
        ReqLine."Order Promising Line ID" := SourceLineNo;
        ReqLine."Order Promising Line No." := OrderPromisingLineNo;
        ReqLine."Worksheet Template Name" := OrderPromisingSetup."Order Promising Template";
        ReqLine."Journal Batch Name" := OrderPromisingSetup."Order Promising Worksheet";
        GetNextReqLineNo(ReqLine);
        ReqLine.Type := ReqLine.Type::Item;
        ReqLine."Location Code" := LocationCode;
        ReqLine.Validate("No.", ItemNo);
        ReqLine.Validate("Variant Code", VariantCode);
        ReqLine."Action Message" := ReqLine."Action Message"::New;
        ReqLine."Accept Action Message" := false;
        ReqLine.Validate("Ending Date",
          LeadTimeMgt.PlannedEndingDate(ItemNo, LocationCode, VariantCode, DueDate, ReqLine."Vendor No.", ReqLine."Ref. Order Type"));
        ReqLine."Ending Time" := 235959T;
        ReqLine.Validate(Quantity, Quantity);
        ReqLine.Validate("Unit of Measure Code", Unit);
        if ReqLine."Starting Date" = 0D then
            ReqLine."Starting Date" := WorkDate;
        OnBeforeReqLineInsert(ReqLine);
        ReqLine.Insert(true);
        PlngLnMgt.Calculate(ReqLine, Direction, true, true, 0);
        if SalesLine.Get(SalesLine."Document Type"::Order, ReqLine."Order Promising ID", ReqLine."Order Promising Line ID") then
            if SalesLine."Drop Shipment" then begin
                ReqLine."Sales Order No." := SalesLine."Document No.";
                ReqLine."Sales Order Line No." := SalesLine."Line No.";
                ReqLine."Sell-to Customer No." := SalesLine."Sell-to Customer No.";
                ReqLine."Purchasing Code" := SalesLine."Purchasing Code";
            end;
        OnBeforeReqLineModify(ReqLine);
        ReqLine.Modify();
    end;

    local procedure CheckDerivedDemandCTP(ReqLine: Record "Requisition Line"; PeriodType: Option Day,Week,Month,Quarter,Year): Boolean
    begin
        if ReqLine."Replenishment System" = ReqLine."Replenishment System"::Transfer then
            exit(CheckTransferShptCTP(ReqLine, PeriodType));

        exit(CheckCompsCapableToPromise(ReqLine, PeriodType));
    end;

    local procedure CheckCompsCapableToPromise(ReqLine: Record "Requisition Line"; PeriodType: Option Day,Week,Month,Quarter,Year): Boolean
    var
        PlanningComponent: Record "Planning Component";
        ReqLine2: Record "Requisition Line";
        IsValidDate: Boolean;
        DueDateOfReqLine: Date;
    begin
        with PlanningComponent do begin
            SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            SetRange("Worksheet Line No.", ReqLine."Line No.");
            if FindSet then
                repeat
                    if ("Supplied-by Line No." = 0) and Critical then begin
                        if not
                           ValidateCapableToPromise(
                             "Item No.", "Variant Code", "Location Code", "Due Date",
                             "Expected Quantity", "Unit of Measure Code", PeriodType, DueDateOfReqLine)
                        then begin
                            OrderPromisingLineNo := OrderPromisingLineNo - 1;
                            exit(false);
                        end;
                    end else
                        if "Supplied-by Line No." > 0 then
                            if ReqLine2.Get(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", "Supplied-by Line No.") then begin
                                IsValidDate := CheckDerivedDemandCTP(ReqLine2, PeriodType);
                                if not IsValidDate or (ReqLine2."Starting Date" < OrderPromisingStart) then
                                    exit(false);
                            end;
                until Next = 0
        end;
        exit(true);
    end;

    local procedure CheckTransferShptCTP(ReqLine: Record "Requisition Line"; PeriodType: Option Day,Week,Month,Quarter,Year): Boolean
    var
        Item: Record Item;
        DueDateOfReqLine: Date;
    begin
        with ReqLine do begin
            TestField("Replenishment System", "Replenishment System"::Transfer);
            Item.Get("No.");
            if Item.Critical then
                if not
                   ValidateCapableToPromise(
                     "No.", "Variant Code", "Transfer-from Code", "Transfer Shipment Date",
                     Quantity, "Unit of Measure Code", PeriodType, DueDateOfReqLine)
                then begin
                    OrderPromisingLineNo := OrderPromisingLineNo - 1;
                    exit(false);
                end;
        end;
        exit(true);
    end;

    local procedure GetNextReqLineNo(var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
    begin
        ReqLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine2.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        if ReqLine2.FindLast then
            ReqLine."Line No." := ReqLine2."Line No." + 10000
        else
            ReqLine."Line No." := 10000;
    end;

    local procedure SetOrderPromisingParameters(var LocOrderPromisingID: Code[20]; LocSourceLineNo: Integer; PeriodLengthFormula: DateFormula)
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        CompanyInfo.Get();
        OrderPromisingSetup.Get();
        OrderPromisingSetup.TestField("Order Promising Template");
        OrderPromisingSetup.TestField("Order Promising Worksheet");
        if LocOrderPromisingID = '' then begin
            LocOrderPromisingID := NoSeriesMgt.GetNextNo(OrderPromisingSetup."Order Promising Nos.", WorkDate, true);
            OrderPromisingLineNo := 1;
        end else
            OrderPromisingLineNo := GetNextOrderPromisingLineNo;
        OrderPromisingID := LocOrderPromisingID;
        SourceLineNo := LocSourceLineNo;
        OrderPromisingStart := CalcDate(OrderPromisingSetup."Offset (Time)", WorkDate);
        OrderPromisingEnd := CalcDate(PeriodLengthFormula, OrderPromisingStart);
    end;

    procedure RemoveReqLines(OrderPromisingID: Code[20]; SourceLineNo: Integer; LastGoodLineNo: Integer; FilterOnNonAccepted: Boolean)
    var
        ReqLine: Record "Requisition Line";
    begin
        with ReqLine do begin
            SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
            SetRange("Order Promising ID", OrderPromisingID);
            if SourceLineNo <> 0 then
                SetRange("Order Promising Line ID", SourceLineNo);
            if LastGoodLineNo <> 0 then
                SetFilter("Order Promising Line No.", '>=%1', LastGoodLineNo);
            if FilterOnNonAccepted then
                SetRange("Accept Action Message", false);
            if Find('-') then
                repeat
                    DeleteMultiLevel;
                    Delete(true);
                until Next = 0;
        end;
    end;

    local procedure GetCumulativeATP(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date; UnitOfMeasureCode: Code[10]; PeriodType: Option Day,Week,Month,Quarter,Year): Decimal
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AvailToPromise: Codeunit "Available to Promise";
        CumulativeATP: Decimal;
    begin
        Item.Get(ItemNo);
        Item.SetRange("Variant Filter", VariantCode);
        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("Date Filter", 0D, DueDate);

        CumulativeATP :=
          AvailToPromise.QtyAvailabletoPromise(
            Item, GrossRequirement, ScheduledReceipt, DueDate,
            PeriodType, CompanyInfo."Check-Avail. Period Calc.");

        if UnitOfMeasureCode = Item."Base Unit of Measure" then
            exit(CumulativeATP);

        ItemUnitOfMeasure.Get(ItemNo, UnitOfMeasureCode);
        exit(Round(CumulativeATP / ItemUnitOfMeasure."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    local procedure GetNextOrderPromisingLineNo(): Integer
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.SetCurrentKey("Order Promising ID");
        ReqLine.SetRange("Order Promising ID", OrderPromisingID);
        if ReqLine.FindLast then
            exit(ReqLine."Order Promising Line No." + 1);

        exit(1);
    end;

    procedure ReassignRefOrderNos(OrderPromisingID: Code[20])
    var
        MfgSetup: Record "Manufacturing Setup";
        RequisitionLine: Record "Requisition Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NewRefOrderNo: Code[20];
        LastRefOrderNo: Code[20];
    begin
        with RequisitionLine do begin
            SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
            SetRange("Order Promising ID", OrderPromisingID);
            SetRange("Ref. Order Type", "Ref. Order Type"::"Prod. Order");
            SetRange("Ref. Order Status", "Ref. Order Status"::Planned);
            SetFilter("Ref. Order No.", '<>%1', '');
            if not FindLast then
                exit;
            LastRefOrderNo := "Ref. Order No.";

            MfgSetup.Get();
            MfgSetup.TestField("Planned Order Nos.");

            SetFilter("Ref. Order No.", '<>%1&<=%2', '', LastRefOrderNo);
            Find('-');
            repeat
                SetRange("Ref. Order No.", "Ref. Order No.");
                FindLast;
                NewRefOrderNo := '';
                NoSeriesMgt.InitSeries(
                  MfgSetup."Planned Order Nos.", "No. Series", "Due Date", NewRefOrderNo, "No. Series");
                ModifyAll("Ref. Order No.", NewRefOrderNo);
                SetFilter("Ref. Order No.", '<>%1&<=%2', '', LastRefOrderNo);
            until Next = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReqLineInsert(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReqLineModify(var RequisitionLine: Record "Requisition Line")
    begin
    end;
}


codeunit 99000889 AvailabilityManagement
{
    Permissions = TableData "Sales Line" = r,
                  TableData "Purchase Line" = r,
                  TableData "Order Promising Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        InvtSetup: Record "Inventory Setup";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempServiceLine: Record "Service Line" temporary;
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        AvailToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";
        CaptionText: Text;
        HasGotCompanyInfo: Boolean;

        Text000: Label 'Sales Order';
        Text002: Label 'Service Order';
        Text003: Label 'Job Order';
        Text001: Label 'The Check-Avail. Period Calc. field cannot be empty in the Company Information card.';

    procedure GetCaption(): Text
    begin
        exit(CaptionText);
    end;

    procedure SetSalesHeader(var OrderPromisingLine: Record "Order Promising Line"; var SalesHeader: Record "Sales Header")
    begin
        CaptionText := Text000;
        OrderPromisingLine.DeleteAll();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Outstanding Quantity", '>0');
        if SalesLine.FindSet() then
            repeat
                if SalesLine.IsInventoriableItem() then begin
                    OrderPromisingLine.Init();
                    OrderPromisingLine."Entry No." := OrderPromisingLine.GetLastEntryNo() + 10000;
                    OrderPromisingLine.TransferFromSalesLine(SalesLine);
                    SalesLine.CalcFields("Reserved Qty. (Base)");
                    InsertPromisingLine(OrderPromisingLine, SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)");
                end;
            until SalesLine.Next() = 0;
    end;

    procedure SetServHeader(var OrderPromisingLine: Record "Order Promising Line"; var ServHeader: Record "Service Header")
    begin
        CaptionText := Text002;
        OrderPromisingLine.DeleteAll();
        ServLine.SetRange("Document Type", ServHeader."Document Type");
        ServLine.SetRange("Document No.", ServHeader."No.");
        ServLine.SetRange(Type, ServLine.Type::Item);
        ServLine.SetFilter("Outstanding Quantity", '>0');
        if ServLine.Find('-') then
            repeat
                OrderPromisingLine."Entry No." := OrderPromisingLine.GetLastEntryNo() + 10000;
                OrderPromisingLine.TransferFromServLine(ServLine);
                ServLine.CalcFields("Reserved Qty. (Base)");
                InsertPromisingLine(OrderPromisingLine, ServLine."Outstanding Qty. (Base)" - ServLine."Reserved Qty. (Base)");
            until ServLine.Next() = 0;
    end;

    procedure SetJob(var OrderPromisingLine: Record "Order Promising Line"; var Job: Record Job)
    begin
        CaptionText := Text003;
        OrderPromisingLine.DeleteAll();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange(Status, Job.Status);
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Remaining Qty.", '>0');
        if JobPlanningLine.Find('-') then
            repeat
                if JobPlanningLineIsInventoryItem() then begin
                    OrderPromisingLine."Entry No." := OrderPromisingLine.GetLastEntryNo() + 10000;
                    OrderPromisingLine.TransferFromJobPlanningLine(JobPlanningLine);
                    JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                    InsertPromisingLine(OrderPromisingLine, JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)");
                end;
            until JobPlanningLine.Next() = 0;
    end;

    local procedure InsertPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; UnavailableQty: Decimal)
    var
        LineItem: Record Item;
    begin
        with OrderPromisingLine do begin
            "Unavailable Quantity (Base)" := UnavailableQty;
            if "Unavailable Quantity (Base)" > 0 then begin
                "Required Quantity (Base)" := "Unavailable Quantity (Base)";
                GetCompanyInfo();
                if Format(CompanyInfo."Check-Avail. Period Calc.") <> '' then
                    "Unavailable Quantity (Base)" := -CalcAvailableQty(OrderPromisingLine)
                else
                    Error(Text001);
                if InvtSetup."Location Mandatory" then
                    TestField("Location Code");
                LineItem.SetLoadFields("Variant Mandatory if Exists");
                if LineItem.Get(OrderPromisingLine."Item No.") then
                    if LineItem.IsVariantMandatory() then
                        TestField("Variant Code");
                if "Unavailable Quantity (Base)" < 0 then
                    "Unavailable Quantity (Base)" := 0;
                if "Unavailable Quantity (Base)" > "Required Quantity (Base)" then
                    "Unavailable Quantity (Base)" := "Required Quantity (Base)";
            end else
                "Unavailable Quantity (Base)" := 0;
            if "Qty. per Unit of Measure" = 0 then
                "Qty. per Unit of Measure" := 1;
            "Unavailable Quantity" :=
              Round("Unavailable Quantity (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            "Required Quantity" :=
              Round("Required Quantity (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            OnBeforeOrderPromisingLineInsert(OrderPromisingLine);
            Insert();
        end;
    end;

    procedure CalcAvailableQty(var OrderPromisingLine: Record "Order Promising Line"): Decimal
    var
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        AvailabilityDate: Date;
    begin
        GetCompanyInfo();

        if Item."No." <> OrderPromisingLine."Item No." then
            Item.Get(OrderPromisingLine."Item No.");
        Item.SetRange("Variant Filter", OrderPromisingLine."Variant Code");
        Item.SetRange("Location Filter", OrderPromisingLine."Location Code");
        Item.SetRange("Date Filter", 0D, OrderPromisingLine."Original Shipment Date");

        if OrderPromisingLine."Original Shipment Date" <> 0D then
            AvailabilityDate := OrderPromisingLine."Original Shipment Date"
        else
            AvailabilityDate := WorkDate();

        OrderPromisingLine."Unavailability Date" :=
          AvailToPromise.GetPeriodEndingDate(
            CalcDate(CompanyInfo."Check-Avail. Period Calc.", AvailabilityDate), CompanyInfo."Check-Avail. Time Bucket");

        AvailToPromise.SetPromisingReqShipDate(OrderPromisingLine);
        exit(
          AvailToPromise.CalcQtyAvailabletoPromise(
            Item, GrossRequirement, ScheduledReceipt, AvailabilityDate,
            CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc."));
    end;

    procedure CalcCapableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var OrderPromisingID: Code[20])
    var
        SalesLine2: Record "Sales Line";
        ServLine2: Record "Service Line";
        JobPlanningLine2: Record "Job Planning Line";
        CapableToPromise: Codeunit "Capable to Promise";
        QtyReservedTotal: Decimal;
        OldCTPQty: Decimal;
        FeasibleDate: Date;
        LastValidLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCapableToPromise(OrderPromisingLine, CompanyInfo, OrderPromisingID, LastValidLine, IsHandled);
        if IsHandled then
            exit;

        LastValidLine := 1;
        with OrderPromisingLine do begin
            if Find('-') then
                repeat
                    case "Source Type" of
                        "Source Type"::Sales:
                            begin
                                Clear("Earliest Shipment Date");
                                Clear("Planned Delivery Date");
                                SalesLine2.Get("Source Subtype", "Source ID", "Source Line No.");
                                SalesLine2.CalcFields("Reserved Quantity");
                                QtyReservedTotal := SalesLine2."Reserved Quantity";
                                CapableToPromise.RemoveReqLines(SalesLine2."Document No.", SalesLine2."Line No.", 0, false);
                                SalesLine2.CalcFields("Reserved Quantity");
                                OldCTPQty := QtyReservedTotal - SalesLine2."Reserved Quantity";
                                FeasibleDate :=
                                  CapableToPromise.CalcCapableToPromiseDate(
                                    "Item No.", "Variant Code", "Location Code",
                                    "Original Shipment Date",
                                    "Unavailable Quantity" + OldCTPQty, "Unit of Measure Code",
                                    OrderPromisingID, "Source Line No.",
                                    LastValidLine, CompanyInfo."Check-Avail. Time Bucket",
                                    CompanyInfo."Check-Avail. Period Calc.");
                                if FeasibleDate <> "Original Shipment Date" then
                                    Validate("Earliest Shipment Date", FeasibleDate)
                                else
                                    Validate("Earliest Shipment Date", "Original Shipment Date");
                            end;
                        "Source Type"::"Service Order":
                            begin
                                Clear("Earliest Shipment Date");
                                Clear("Planned Delivery Date");
                                ServLine2.Get("Source Subtype", "Source ID", "Source Line No.");
                                ServLine2.CalcFields("Reserved Quantity");
                                QtyReservedTotal := ServLine2."Reserved Quantity";
                                CapableToPromise.RemoveReqLines(ServLine2."Document No.", ServLine2."Line No.", 0, false);
                                ServLine2.CalcFields("Reserved Quantity");
                                OldCTPQty := QtyReservedTotal - ServLine2."Reserved Quantity";
                                FeasibleDate :=
                                  CapableToPromise.CalcCapableToPromiseDate(
                                    "Item No.", "Variant Code", "Location Code",
                                    "Original Shipment Date",
                                    "Unavailable Quantity" + OldCTPQty, "Unit of Measure Code",
                                    OrderPromisingID, "Source Line No.",
                                    LastValidLine, CompanyInfo."Check-Avail. Time Bucket",
                                    CompanyInfo."Check-Avail. Period Calc.");
                                if FeasibleDate <> "Original Shipment Date" then
                                    Validate("Earliest Shipment Date", FeasibleDate)
                                else
                                    Validate("Earliest Shipment Date", "Original Shipment Date");
                            end;
                        "Source Type"::Job:
                            begin
                                Clear("Earliest Shipment Date");
                                Clear("Planned Delivery Date");
                                JobPlanningLine2.Reset();
                                JobPlanningLine2.SetRange(Status, "Source Subtype");
                                JobPlanningLine2.SetRange("Job No.", "Source ID");
                                JobPlanningLine2.SetRange("Job Contract Entry No.", "Source Line No.");
                                JobPlanningLine2.FindFirst();
                                JobPlanningLine2.CalcFields("Reserved Quantity");
                                QtyReservedTotal := JobPlanningLine2."Reserved Quantity";
                                CapableToPromise.RemoveReqLines(JobPlanningLine2."Job No.", JobPlanningLine2."Job Contract Entry No.", 0, false);
                                JobPlanningLine2.CalcFields("Reserved Quantity");
                                OldCTPQty := QtyReservedTotal - JobPlanningLine2."Reserved Quantity";
                                FeasibleDate :=
                                  CapableToPromise.CalcCapableToPromiseDate(
                                    "Item No.", "Variant Code", "Location Code",
                                    "Original Shipment Date",
                                    "Unavailable Quantity" + OldCTPQty, "Unit of Measure Code",
                                    OrderPromisingID, "Source Line No.",
                                    LastValidLine, CompanyInfo."Check-Avail. Time Bucket",
                                    CompanyInfo."Check-Avail. Period Calc.");
                                if FeasibleDate <> "Original Shipment Date" then
                                    Validate("Earliest Shipment Date", FeasibleDate)
                                else
                                    Validate("Earliest Shipment Date", "Original Shipment Date");
                            end;
                    end;
                    OnAfterCaseCalcCapableToPromise(OrderPromisingLine, CompanyInfo, OrderPromisingID, LastValidLine);
                    Modify();
                    CreateReservations(OrderPromisingLine);
                until Next() = 0;

            CapableToPromise.ReassignRefOrderNos(OrderPromisingID);
        end;
    end;

    procedure CalcAvailableToPromise(var OrderPromisingLine: Record "Order Promising Line")
    begin
        GetCompanyInfo();
        with OrderPromisingLine do begin
            SetCurrentKey("Requested Shipment Date");
            if Find('-') then
                repeat
                    Clear("Earliest Shipment Date");
                    Clear("Planned Delivery Date");
                    CalcAvailableToPromiseLine(OrderPromisingLine);
                until Next() = 0;
        end;
    end;

    local procedure CalcAvailableToPromiseLine(var OrderPromisingLine: Record "Order Promising Line")
    var
        SourceSalesLine: Record "Sales Line";
        NeededDate: Date;
        FeasibleDate: Date;
        AvailQty: Decimal;
        FeasibleDateFound: Boolean;
    begin
        with OrderPromisingLine do begin
            if Item."No." <> "Item no." then
                Item.Get("Item No.");
            Item.SetRange("Variant Filter", "Variant Code");
            Item.SetRange("Location Filter", "Location Code");
            OnCalcAvailableToPromiseLineOnAfterSetFilters(Item, OrderPromisingLine);
            case "Source Type" of
                "Source Type"::Sales,
                "Source Type"::"Service Order",
                "Source Type"::Job:
                    begin
                        if "Requested Shipment Date" <> 0D then
                            NeededDate := "Requested Shipment Date"
                        else
                            NeededDate := WorkDate();
                        AvailToPromise.SetOriginalShipmentDate(OrderPromisingLine);

                        FeasibleDateFound := false;
                        if "Source Type" = "Source Type"::Sales then
                            if SourceSalesLine.Get("Source Subtype", "Source ID", "Source Line No.") then
                                if SourceSalesLine."Special Order" then begin
                                    FeasibleDate := GetExpectedReceiptDateFromSpecialOrder(SourceSalesLine);
                                    FeasibleDateFound := true;
                                end;

                        if not FeasibleDateFound then
                            if "Required Quantity" = 0 then begin
                                FeasibleDate := "Original Shipment Date";
                                FeasibleDateFound := true;
                            end;

                        if not FeasibleDateFound then
                            FeasibleDate := AvailToPromise.CalcEarliestAvailabilityDate(
                                Item, Quantity, NeededDate, Quantity, "Original Shipment Date", AvailQty,
                                CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc.");

                        if (FeasibleDate <> 0D) and (FeasibleDate < "Requested Shipment Date") then
                            if GetRequestedDeliveryDateFromOrderPromisingLineSource(OrderPromisingLine) <> 0D then
                                FeasibleDate := "Requested Shipment Date";
                        Validate("Earliest Shipment Date", FeasibleDate);
                    end;
            end;
            OnCalcAvailableToPromiseLineOnBeforeModify(OrderPromisingLine);
            Modify();
        end;
    end;

    local procedure GetExpectedReceiptDateFromSpecialOrder(SalesLine: Record "Sales Line"): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchaseLine.Get(
             PurchaseLine."Document Type"::Order, SalesLine."Special Order Purchase No.", SalesLine."Special Order Purch. Line No.")
        then
            exit(PurchaseLine."Expected Receipt Date");
        exit(0D);
    end;

    local procedure GetRequestedDeliveryDateFromOrderPromisingLineSource(OrderPromisingLine: Record "Order Promising Line"): Date
    var
        SalesLine2: Record "Sales Line";
        ServiceLine2: Record "Service Line";
        JobPlanningLine2: Record "Job Planning Line";
    begin
        with OrderPromisingLine do
            case "Source Type" of
                "Source Type"::Sales:
                    if SalesLine2.Get("Source Subtype", "Source ID", "Source Line No.") then
                        exit(SalesLine2."Requested Delivery Date");
                "Source Type"::"Service Order":
                    if ServiceLine2.Get("Source Subtype", "Source ID", "Source Line No.") then
                        exit(ServiceLine2."Requested Delivery Date");
                "Source Type"::Job:
                    begin
                        JobPlanningLine2.SetRange(Status, "Source Subtype");
                        JobPlanningLine2.SetRange("Job No.", "Source ID");
                        JobPlanningLine2.SetRange("Job Contract Entry No.", "Source Line No.");
                        if JobPlanningLine2.FindFirst() then
                            exit(JobPlanningLine2."Requested Delivery Date");
                    end;
            end;
        exit(0D);
    end;

    procedure UpdateSource(var OrderPromisingLine: Record "Order Promising Line")
    begin
        if OrderPromisingLine.Find('-') then
            repeat
                UpdateSourceLine(OrderPromisingLine);
            until OrderPromisingLine.Next() = 0;
    end;

    local procedure UpdateSourceLine(var OrderPromisingLine2: Record "Order Promising Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ServLineReserve: Codeunit "Service Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        FullAutoReservation: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        case OrderPromisingLine2."Source Type" of
            OrderPromisingLine2."Source Type"::Sales:
                begin
                    SalesLine.Get(
                      OrderPromisingLine2."Source Subtype",
                      OrderPromisingLine2."Source ID", OrderPromisingLine2."Source Line No.");
                    if OrderPromisingLine2."Earliest Shipment Date" <> 0D then
                        SalesLine.Validate("Shipment Date", OrderPromisingLine2."Earliest Shipment Date");

                    SalesLineReserve.ReservQuantity(SalesLine, QtyToReserve, QtyToReserveBase);
                    if (SalesLine."Shipment Date" <> 0D) and
                       (SalesLine.Reserve = SalesLine.Reserve::Always) and
                       (QtyToReserveBase <> 0)
                    then begin
                        ReservMgt.SetReservSource(SalesLine);
                        ReservMgt.AutoReserve(
                          FullAutoReservation, '', SalesLine."Shipment Date", QtyToReserve, QtyToReserveBase);
                        SalesLine.CalcFields("Reserved Quantity");
                    end;

                    SalesLine.Modify();
                end;
            OrderPromisingLine2."Source Type"::"Service Order":
                begin
                    ServLine.Get(
                      OrderPromisingLine2."Source Subtype",
                      OrderPromisingLine2."Source ID", OrderPromisingLine2."Source Line No.");
                    if OrderPromisingLine2."Earliest Shipment Date" <> 0D then
                        ServLine.Validate("Needed by Date", OrderPromisingLine2."Earliest Shipment Date");

                    ServLineReserve.ReservQuantity(ServLine, QtyToReserve, QtyToReserveBase);
                    if (ServLine."Needed by Date" <> 0D) and
                       (ServLine.Reserve = ServLine.Reserve::Always) and
                       (QtyToReserveBase <> 0)
                    then begin
                        ReservMgt.SetReservSource(ServLine);
                        ReservMgt.AutoReserve(
                          FullAutoReservation, '', ServLine."Needed by Date", QtyToReserve, QtyToReserveBase);
                        ServLine.CalcFields("Reserved Quantity");
                    end;

                    ServLine.Modify();
                end;
            OrderPromisingLine2."Source Type"::Job:
                begin
                    JobPlanningLine.SetRange(Status, OrderPromisingLine2."Source Subtype");
                    JobPlanningLine.SetRange("Job No.", OrderPromisingLine2."Source ID");
                    JobPlanningLine.SetRange("Job Contract Entry No.", OrderPromisingLine2."Source Line No.");
                    JobPlanningLine.FindFirst();
                    if OrderPromisingLine2."Earliest Shipment Date" <> 0D then
                        JobPlanningLine.Validate("Planning Date", OrderPromisingLine2."Earliest Shipment Date");

                    JobPlanningLineReserve.ReservQuantity(JobPlanningLine, QtyToReserve, QtyToReserveBase);
                    if (JobPlanningLine."Planning Date" <> 0D) and
                       (JobPlanningLine.Reserve = JobPlanningLine.Reserve::Always) and
                       (QtyToReserveBase <> 0)
                    then begin
                        ReservMgt.SetReservSource(JobPlanningLine);
                        ReservMgt.AutoReserve(
                          FullAutoReservation, '', JobPlanningLine."Planning Date", QtyToReserve, QtyToReserveBase);
                        JobPlanningLine.CalcFields("Reserved Quantity");
                    end;

                    JobPlanningLine.Modify();
                end;
        end;
        OnAfterUpdateSourceLine(OrderPromisingLine2);
    end;

    local procedure GetCompanyInfo()
    begin
        if HasGotCompanyInfo then
            exit;
        HasGotCompanyInfo := CompanyInfo.Get() and InvtSetup.Get();
    end;

    local procedure CreateReservations(var OrderPromisingLine: Record "Order Promising Line")
    var
        ReqLine: Record "Requisition Line";
        SalesLine2: Record "Sales Line";
        ServLine2: Record "Service Line";
        JobPlanningLine2: Record "Job Planning Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ServLineReserve: Codeunit "Service Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ReservMgt: Codeunit "Reservation Management";
        SourceRecRef: RecordRef;
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
        NeededQty: Decimal;
        NeededQtyBase: Decimal;
        FullAutoReservation: Boolean;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Sales:
                begin
                    SalesLine2.Get(OrderPromisingLine."Source Subtype",
                      OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");

                    SalesLine2.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    NeededQty := SalesLine2."Outstanding Quantity" - SalesLine2."Reserved Quantity";
                    NeededQtyBase := SalesLine2."Outstanding Qty. (Base)" - SalesLine2."Reserved Qty. (Base)";
                end;
            OrderPromisingLine."Source Type"::"Service Order":
                begin
                    ServLine2.Get(OrderPromisingLine."Source Subtype",
                      OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");

                    ServLine2.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    NeededQty := ServLine2."Outstanding Quantity" - ServLine2."Reserved Quantity";
                    NeededQtyBase := ServLine2."Outstanding Qty. (Base)" - ServLine2."Reserved Qty. (Base)";
                end;
            OrderPromisingLine."Source Type"::Job:
                begin
                    JobPlanningLine2.SetRange(Status, OrderPromisingLine."Source Subtype");
                    JobPlanningLine2.SetRange("Job No.", OrderPromisingLine."Source ID");
                    JobPlanningLine2.SetRange("Job Contract Entry No.", OrderPromisingLine."Source Line No.");
                    JobPlanningLine2.FindFirst();

                    JobPlanningLine2.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    NeededQty := JobPlanningLine2."Remaining Qty." - JobPlanningLine2."Reserved Quantity";
                    NeededQtyBase := JobPlanningLine2."Remaining Qty. (Base)" - JobPlanningLine2."Reserved Qty. (Base)";
                end;
        end;

        OnCreateReservationsAfterFirstCASE(OrderPromisingLine, NeededQty, NeededQtyBase);

        ReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
        ReqLine.SetRange("Order Promising ID", OrderPromisingLine."Source ID");
        ReqLine.SetRange("Order Promising Line ID", OrderPromisingLine."Source Line No.");
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", OrderPromisingLine."Item No.");
        if ReqLine.FindFirst() then begin
            if ReqLine."Quantity (Base)" > NeededQtyBase then begin
                ReservQty := NeededQty;
                ReservQtyBase := NeededQtyBase
            end else begin
                ReservQty := ReqLine.Quantity;
                ReservQtyBase := ReqLine."Quantity (Base)";
            end;

            case OrderPromisingLine."Source Type" of
                OrderPromisingLine."Source Type"::Sales:
                    begin
                        if (SalesLine2.Reserve = SalesLine2.Reserve::Never) and not SalesLine2."Drop Shipment" then begin
                            SalesLine2.Reserve := SalesLine2.Reserve::Optional;
                            SalesLine2.Modify();
                            TempSalesLine := SalesLine2;
                            if TempSalesLine.Insert() then;
                        end;
                        SalesLineReserve.BindToRequisition(SalesLine2, ReqLine, ReservQty, ReservQtyBase);

                        SalesLine2.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                        if SalesLine2.Quantity <> SalesLine2."Reserved Quantity" then begin
                            SourceRecRef.GetTable(SalesLine2);
                            ReservMgt.SetReservSource(SourceRecRef);
                            ReservMgt.AutoReserve(
                              FullAutoReservation, '', SalesLine2."Shipment Date",
                              SalesLine2.Quantity - SalesLine2."Reserved Quantity",
                              SalesLine2."Quantity (Base)" - SalesLine2."Reserved Qty. (Base)");
                        end;
                    end;
                OrderPromisingLine."Source Type"::"Service Order":
                    begin
                        ServLineReserve.BindToRequisition(ServLine2, ReqLine, ReservQty, ReservQtyBase);
                        if ServLine2.Reserve = ServLine2.Reserve::Never then begin
                            ServLine2.Reserve := ServLine2.Reserve::Optional;
                            ServLine2.Modify();
                            TempServiceLine := ServLine2;
                            if TempServiceLine.Insert() then;
                        end;
                    end;
                OrderPromisingLine."Source Type"::Job:
                    begin
                        JobPlanningLineReserve.BindToRequisition(JobPlanningLine2, ReqLine, ReservQty, ReservQtyBase);
                        if JobPlanningLine2.Reserve = JobPlanningLine2.Reserve::Never then begin
                            JobPlanningLine2.Reserve := JobPlanningLine2.Reserve::Optional;
                            JobPlanningLine2.Modify();
                            TempJobPlanningLine := JobPlanningLine2;
                            if TempJobPlanningLine.Insert() then;
                        end;
                    end;
            end;
            OnCreateReservationsAfterSecondCASE(OrderPromisingLine, ReqLine, ReservQty, ReservQtyBase);
        end;
    end;

    procedure CancelReservations()
    var
        SalesLine2: Record "Sales Line";
        ServiceLine2: Record "Service Line";
        JobPlanningLine2: Record "Job Planning Line";
        ReservationEntry: Record "Reservation Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        if TempSalesLine.FindSet() then
            repeat
                SalesLine2 := TempSalesLine;
                SalesLine2.Find();
                ReservationEngineMgt.InitFilterAndSortingFor(ReservationEntry, true);
                SalesLine2.SetReservationFilters(ReservationEntry);
                if ReservationEntry.FindSet() then
                    repeat
                        ReservationEngineMgt.CancelReservation(ReservationEntry);
                    until ReservationEntry.Next() = 0;
                SalesLine2.Reserve := SalesLine2.Reserve::Never;
                SalesLine2.Modify();
            until TempSalesLine.Next() = 0;

        if TempServiceLine.FindSet() then
            repeat
                ServiceLine2 := TempServiceLine;
                ServiceLine2.Find();
                ReservationEngineMgt.InitFilterAndSortingFor(ReservationEntry, true);
                ServiceLine2.SetReservationFilters(ReservationEntry);
                if ReservationEntry.FindSet() then
                    repeat
                        ReservationEngineMgt.CancelReservation(ReservationEntry);
                    until ReservationEntry.Next() = 0;
                ServiceLine2.Reserve := ServiceLine2.Reserve::Never;
                ServiceLine2.Modify();
            until TempServiceLine.Next() = 0;

        if TempJobPlanningLine.FindSet() then
            repeat
                JobPlanningLine2 := TempJobPlanningLine;
                JobPlanningLine2.Find();
                ReservationEngineMgt.InitFilterAndSortingFor(ReservationEntry, true);
                JobPlanningLine2.SetReservationFilters(ReservationEntry);
                if ReservationEntry.FindSet() then
                    repeat
                        ReservationEngineMgt.CancelReservation(ReservationEntry);
                    until ReservationEntry.Next() = 0;
                JobPlanningLine2.Reserve := JobPlanningLine2.Reserve::Never;
                JobPlanningLine2.Modify();
            until TempJobPlanningLine.Next() = 0;
    end;

    local procedure JobPlanningLineIsInventoryItem(): Boolean
    var
        JobItem: Record Item;
    begin
        JobItem.Get(JobPlanningLine."No.");
        exit(JobItem.Type = JobItem.Type::Inventory);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCaseCalcCapableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInfo: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSourceLine(var OrderPromisingLine2: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOrderPromisingLineInsert(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableToPromiseLineOnAfterSetFilters(var Item: Record Item; var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableToPromiseLineOnBeforeModify(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationsAfterFirstCASE(var OrderPromisingLine: Record "Order Promising Line"; var NeededQty: Decimal; var NeededQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationsAfterSecondCASE(var OrderPromisingLine: Record "Order Promising Line"; var ReqLine: Record "Requisition Line"; var ReservQty: Decimal; var ReservQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCapableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInformation: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer; var IsHandled: Boolean)
    begin
    end;
}


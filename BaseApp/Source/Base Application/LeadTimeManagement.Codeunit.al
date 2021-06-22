codeunit 5404 "Lead-Time Management"
{

    trigger OnRun()
    begin
    end;

    var
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        SKU: Record "Stockkeeping Unit" temporary;
        CalChange: Record "Customized Calendar Change";
        LeadTimeCalcNegativeErr: Label 'The amount of time to replenish the item must not be negative.';
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        CalendarMgmt: Codeunit "Calendar Management";

    procedure PurchaseLeadTime(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]): Code[20]
    var
        ItemVend: Record "Item Vendor";
    begin
        // Returns the leadtime in a date formula

        GetItem(ItemNo);
        ItemVend."Vendor No." := VendorNo;
        ItemVend."Variant Code" := VariantCode;
        Item.FindItemVend(ItemVend, LocationCode);
        exit(Format(ItemVend."Lead Time Calculation"));
    end;

    procedure ManufacturingLeadTime(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Code[20]
    begin
        // Returns the leadtime in a date formula

        GetPlanningParameters.AtSKU(SKU, ItemNo, VariantCode, LocationCode);
        exit(Format(SKU."Lead Time Calculation"));
    end;

    procedure WhseOutBoundHandlingTime(LocationCode: Code[10]): Code[10]
    begin
        // Returns the outbound warehouse handling time in a date formula

        if LocationCode = '' then begin
            InvtSetup.Get();
            exit(Format(InvtSetup."Outbound Whse. Handling Time"));
        end;

        GetLocation(LocationCode);
        exit(Format(Location."Outbound Whse. Handling Time"));
    end;

    local procedure WhseInBoundHandlingTime(LocationCode: Code[10]): Code[10]
    begin
        // Returns the inbound warehouse handling time in a date formula

        if LocationCode = '' then begin
            InvtSetup.Get();
            exit(Format(InvtSetup."Inbound Whse. Handling Time"));
        end;

        GetLocation(LocationCode);
        exit(Format(Location."Inbound Whse. Handling Time"));
    end;

    procedure SafetyLeadTime(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Code[20]
    begin
        // Returns the safety lead time in a date formula

        GetPlanningParameters.AtSKU(SKU, ItemNo, VariantCode, LocationCode);
        exit(Format(SKU."Safety Lead Time"));
    end;

    procedure PlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; VendorNo: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly): Date
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        PlannedReceiptDate: Date;
        DateFormula: DateFormula;
        OrgDateExpression: Text[30];
        CheckBothCalendars: Boolean;
    begin
        // Returns Ending Date calculated backward from Due Date

        GetPlanningParameters.AtSKU(SKU, ItemNo, VariantCode, LocationCode);

        if RefOrderType = RefOrderType::Transfer then begin
            Evaluate(DateFormula, WhseInBoundHandlingTime(LocationCode));
            with TransferRoute do begin
                GetTransferRoute(
                  SKU."Transfer-from Code", LocationCode, "In-Transit Code", "Shipping Agent Code", "Shipping Agent Service Code");
                CalcPlanReceiptDateBackward(
                  PlannedReceiptDate, DueDate, DateFormula, LocationCode, "Shipping Agent Code", "Shipping Agent Service Code");
            end;
            exit(PlannedReceiptDate);
        end;
        FormatDateFormula(SKU."Safety Lead Time");
        OrgDateExpression := InternalLeadTimeDays(WhseInBoundHandlingTime(LocationCode) + Format(SKU."Safety Lead Time"));
        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
            CheckBothCalendars := true;
        end else
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        exit(CalendarMgmt.CalcDateBOC2(OrgDateExpression, DueDate, CustomCalendarChange, CheckBothCalendars));
    end;

    procedure PlannedStartingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; EndingDate: Date): Date
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        PlannedShipmentDate: Date;
        ShippingTime: DateFormula;
        CheckBothCalendars: Boolean;
    begin
        // Returns Starting Date calculated backward from Ending Date

        if RefOrderType = RefOrderType::Transfer then begin
            GetPlanningParameters.AtSKU(SKU, ItemNo, VariantCode, LocationCode);

            with TransferRoute do begin
                GetTransferRoute(
                  SKU."Transfer-from Code", LocationCode, "In-Transit Code", "Shipping Agent Code", "Shipping Agent Service Code");
                GetShippingTime(
                  SKU."Transfer-from Code", LocationCode, "Shipping Agent Code", "Shipping Agent Service Code", ShippingTime);
                CalcPlanShipmentDateBackward(
                  PlannedShipmentDate, EndingDate, ShippingTime,
                  SKU."Transfer-from Code", "Shipping Agent Code", "Shipping Agent Service Code");
            end;
            exit(PlannedShipmentDate);
        end;
        if DateFormulaIsEmpty(LeadTime) then
            exit(EndingDate);

        if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
            CheckBothCalendars := true;
        end else
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        exit(CalendarMgmt.CalcDateBOC2(InternalLeadTimeDays(LeadTime), EndingDate, CustomCalendarChange, CheckBothCalendars));
    end;

    procedure PlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; StartingDate: Date): Date
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        PlannedReceiptDate: Date;
        ShippingTime: DateFormula;
        CheckBothCalendars: Boolean;
    begin
        // Returns Ending Date calculated forward from Starting Date

        if RefOrderType = RefOrderType::Transfer then begin
            GetPlanningParameters.AtSKU(SKU, ItemNo, VariantCode, LocationCode);

            with TransferRoute do begin
                GetTransferRoute(
                  SKU."Transfer-from Code", LocationCode, "In-Transit Code", "Shipping Agent Code", "Shipping Agent Service Code");
                GetShippingTime(
                  SKU."Transfer-from Code", LocationCode, "Shipping Agent Code", "Shipping Agent Service Code", ShippingTime);
                CalcPlannedReceiptDateForward(
                  StartingDate, PlannedReceiptDate, ShippingTime, LocationCode, "Shipping Agent Code", "Shipping Agent Service Code");
            end;
            exit(PlannedReceiptDate);
        end;
        if DateFormulaIsEmpty(LeadTime) then
            exit(StartingDate);

        if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
            CheckBothCalendars := true;
        end else
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        exit(CalendarMgmt.CalcDateBOC(LeadTime, StartingDate, CustomCalendarChange, CheckBothCalendars));
    end;

    procedure PlannedDueDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; EndingDate: Date; VendorNo: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly): Date
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        ReceiptDate: Date;
        DateFormula: DateFormula;
        OrgDateExpression: Text[30];
        CheckBothCalendars: Boolean;
    begin
        // Returns Due Date calculated forward from Ending Date

        GetPlanningParameters.AtSKU(SKU, ItemNo, VariantCode, LocationCode);
        FormatDateFormula(SKU."Safety Lead Time");

        if RefOrderType = RefOrderType::Transfer then begin
            Evaluate(DateFormula, WhseInBoundHandlingTime(LocationCode));
            TransferRoute.CalcReceiptDateForward(EndingDate, ReceiptDate, DateFormula, LocationCode);
            exit(ReceiptDate);
        end;
        OrgDateExpression := WhseInBoundHandlingTime(LocationCode) + Format(SKU."Safety Lead Time");
        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
            CheckBothCalendars := true;
        end;
        exit(CalendarMgmt.CalcDateBOC(OrgDateExpression, EndingDate, CustomCalendarChange, CheckBothCalendars));
    end;

    local procedure FormatDateFormula(var DateFormula: DateFormula)
    var
        DateFormulaText: Text;
    begin
        if Format(DateFormula) = '' then
            Evaluate(DateFormula, '<+0D>')
        else
            if not (CopyStr(Format(DateFormula), 1, 1) in ['+', '-']) then begin
                DateFormulaText := '+' + Format(DateFormula); // DateFormula is formated to local language
                Evaluate(DateFormula, DateFormulaText);
            end;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure InternalLeadTimeDays(DateFormulaText: Code[30]): Text[20]
    var
        TotalDays: DateFormula;
        DateFormulaLoc: DateFormula;
    begin
        Evaluate(DateFormulaLoc, DateFormulaText);
        Evaluate(TotalDays, '<' + Format(CalcDate(DateFormulaLoc, WorkDate) - WorkDate) + 'D>'); // DateFormulaText is formatet to local language
        exit(Format(TotalDays));
    end;

    local procedure DateFormulaIsEmpty(DateFormulaText: Code[30]): Boolean
    var
        DateFormula: DateFormula;
    begin
        if DateFormulaText = '' then
            exit(true);

        Evaluate(DateFormula, DateFormulaText);
        exit(CalcDate(DateFormula, WorkDate) = WorkDate);
    end;

    procedure CheckLeadTimeIsNotNegative(LeadTimeDateFormula: DateFormula)
    begin
        if CalcDate(LeadTimeDateFormula, WorkDate) < WorkDate then
            Error(LeadTimeCalcNegativeErr);
    end;
}


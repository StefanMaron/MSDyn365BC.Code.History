report 699 "Calculate Plan - Req. Wksh."
{
    Caption = 'Calculate Plan - Req. Wksh.';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("Low-Level Code") WHERE(Type = CONST(Inventory));
            RequestFilterFields = "No.", "Search Description", "Location Filter";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                if Counter mod 5 = 0 then
                    Window.Update(1, "No.");
                Counter := Counter + 1;

                if SkipPlanningForItemOnReqWksh(Item) then
                    CurrReport.Skip();

                PlanningAssignment.SetRange("Item No.", "No.");

                ReqLine.LockTable();
                ActionMessageEntry.LockTable();

                IsHandled := false;
                OnBeforeDeleteReqLines(Item, PurchReqLine, ReqLineExtern, IsHandled);
                if not IsHandled then begin
                    PurchReqLine.SetRange("No.", "No.");
                    PurchReqLine.ModifyAll("Accept Action Message", false);
                    PurchReqLine.DeleteAll(true);

                    ReqLineExtern.SetRange(Type, ReqLine.Type::Item);
                    ReqLineExtern.SetRange("No.", "No.");
                    if ReqLineExtern.Find('-') then
                        repeat
                            ReqLineExtern.Delete(true);
                        until ReqLineExtern.Next = 0;
                end;

                InvtProfileOffsetting.SetParm(UseForecast, ExcludeForecastBefore, CurrWorksheetType);
                InvtProfileOffsetting.CalculatePlanFromWorksheet(
                  Item,
                  MfgSetup,
                  CurrTemplateName,
                  CurrWorksheetName,
                  FromDate,
                  ToDate,
                  true,
                  RespectPlanningParm);

                if PlanningAssignment.Find('-') then
                    repeat
                        if PlanningAssignment."Latest Date" <= ToDate then begin
                            PlanningAssignment.Inactive := true;
                            PlanningAssignment.Modify();
                        end;
                    until PlanningAssignment.Next = 0;

                Commit();
            end;

            trigger OnPostDataItem()
            begin
                OnAfterItemOnPostDataItem(Item);
            end;

            trigger OnPreDataItem()
            begin
                SKU.SetCurrentKey("Item No.");
                CopyFilter("Variant Filter", SKU."Variant Code");
                CopyFilter("Location Filter", SKU."Location Code");

                CopyFilter("Variant Filter", PlanningAssignment."Variant Code");
                CopyFilter("Location Filter", PlanningAssignment."Location Code");
                PlanningAssignment.SetRange(Inactive, false);
                PlanningAssignment.SetRange("Net Change Planning", true);

                ReqLineExtern.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
                CopyFilter("Variant Filter", ReqLineExtern."Variant Code");
                CopyFilter("Location Filter", ReqLineExtern."Location Code");

                PurchReqLine.SetCurrentKey(
                  Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date");
                PurchReqLine.SetRange(Type, PurchReqLine.Type::Item);
                CopyFilter("Variant Filter", PurchReqLine."Variant Code");
                CopyFilter("Location Filter", PurchReqLine."Location Code");
                PurchReqLine.SetFilter("Worksheet Template Name", ReqWkshTemplateFilter);
                PurchReqLine.SetFilter("Journal Batch Name", ReqWkshFilter);

                OnAfterItemOnPreDataItem(Item);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; FromDate)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date to use for new orders. This date is used to evaluate the inventory.';
                    }
                    field(EndingDate; ToDate)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date where the planning period ends. Demand is not included beyond this date.';
                    }
                    field(UseForecast; UseForecast)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Use Forecast';
                        TableRelation = "Production Forecast Name".Name;
                        ToolTip = 'Specifies a forecast that should be included as demand when running the planning batch job.';
                    }
                    field(ExcludeForecastBefore; ExcludeForecastBefore)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Exclude Forecast Before';
                        ToolTip = 'Specifies how much of the selected forecast to include, by entering a date before which forecast demand is not included.';
                    }
                    field(RespectPlanningParm; RespectPlanningParm)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Respect Planning Parameters for Supply Triggered by Safety Stock';
                        ToolTip = 'Specifies that planning lines triggered by safety stock will respect the following planning parameters: Reorder Point, Reorder Quantity, Reorder Point, and Maximum Inventory in addition to all order modifiers. If you do not select this check box, planning lines triggered by safety stock will only cover the exact demand quantity.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            MfgSetup.Get();
            UseForecast := MfgSetup."Current Production Forecast";

            OnAfterOnOpenPage(FromDate, ToDate);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        Counter := 0;
        if FromDate = 0D then
            Error(Text002);
        if ToDate = 0D then
            Error(Text003);
        PeriodLength := ToDate - FromDate + 1;
        if PeriodLength <= 0 then
            Error(Text004);

        if (Item.GetFilter("Variant Filter") <> '') and
           (MfgSetup."Current Production Forecast" <> '')
        then begin
            ProductionForecastEntry.SetRange("Production Forecast Name", MfgSetup."Current Production Forecast");
            Item.CopyFilter("No.", ProductionForecastEntry."Item No.");
            if MfgSetup."Use Forecast on Locations" then
                Item.CopyFilter("Location Filter", ProductionForecastEntry."Location Code");
            if not ProductionForecastEntry.IsEmpty then
                Error(Text005);
        end;

        ReqLine.SetRange("Worksheet Template Name", CurrTemplateName);
        ReqLine.SetRange("Journal Batch Name", CurrWorksheetName);

        Window.Open(
          Text006 +
          Text007);
    end;

    var
        Text002: Label 'Enter a starting date.';
        Text003: Label 'Enter an ending date.';
        Text004: Label 'The ending date must not be before the order date.';
        Text005: Label 'You must not use a variant filter when calculating MPS from a forecast.';
        Text006: Label 'Calculating the plan...\\';
        Text007: Label 'Item No.  #1##################';
        ReqLine: Record "Requisition Line";
        ActionMessageEntry: Record "Action Message Entry";
        ReqLineExtern: Record "Requisition Line";
        PurchReqLine: Record "Requisition Line";
        SKU: Record "Stockkeeping Unit";
        PlanningAssignment: Record "Planning Assignment";
        MfgSetup: Record "Manufacturing Setup";
        InvtProfileOffsetting: Codeunit "Inventory Profile Offsetting";
        Window: Dialog;
        CurrWorksheetType: Option Requisition,Planning;
        PeriodLength: Integer;
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        FromDate: Date;
        ToDate: Date;
        ReqWkshTemplateFilter: Code[50];
        ReqWkshFilter: Code[50];
        Counter: Integer;
        UseForecast: Code[10];
        ExcludeForecastBefore: Date;
        RespectPlanningParm: Boolean;

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10])
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
    end;

    procedure InitializeRequest(StartDate: Date; EndDate: Date)
    begin
        FromDate := StartDate;
        ToDate := EndDate;
    end;

    local procedure SkipPlanningForItemOnReqWksh(Item: Record Item): Boolean
    var
        SkipPlanning: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SkipPlanning := false;

        OnBeforeSkipPlanningForItemOnReqWksh(Item, SkipPlanning, IsHandled);
        if IsHandled then
            exit(SkipPlanning);

        with Item do
            if (CurrWorksheetType = CurrWorksheetType::Requisition) and
               ("Replenishment System" = "Replenishment System"::Purchase) and
               ("Reordering Policy" <> "Reordering Policy"::" ")
            then
                exit(false);

        with SKU do begin
            SetRange("Item No.", Item."No.");
            if Find('-') then
                repeat
                    if (CurrWorksheetType = CurrWorksheetType::Requisition) and
                       ("Replenishment System" in ["Replenishment System"::Purchase,
                                                   "Replenishment System"::Transfer]) and
                       ("Reordering Policy" <> "Reordering Policy"::" ")
                    then
                        exit(false);
                until Next = 0;
        end;

        SkipPlanning := true;
        OnAfterSkipPlanningForItemOnReqWksh(Item, SkipPlanning);
        exit(SkipPlanning);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var FromDate: Date; var ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemOnPreDataItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemOnPostDataItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSkipPlanningForItemOnReqWksh(Item: Record Item; var SkipPlanning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSkipPlanningForItemOnReqWksh(Item: Record Item; var SkipPlanning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteReqLines(Item: Record Item; var PurchReqLine: Record "Requisition Line"; var ReqLineExtern: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;
}


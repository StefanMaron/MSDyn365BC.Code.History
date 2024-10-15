namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

report 302 "Get Demand To Reserve"
{
    ApplicationArea = Reservation;
    ProcessingOnly = true;
    Caption = 'Get Demand to Reserve';

    dataset
    {
        dataitem(FilterItem; Item)
        {
            DataItemTableView = sorting("No.")
                                where(Type = const(Inventory));
            RequestFilterFields = "No.", "Variant Filter", "Location Filter", "Date Filter";
            RequestFilterHeading = 'Filters';
        }
        dataitem(SalesOrderLine; "Sales Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.")
                                where("Document Type" = const(Order),
                                      "Drop Shipment" = const(false),
                                      Type = const(Item),
                                      "Outstanding Qty. (Base)" = filter(<> 0));

            trigger OnPreDataItem()
            begin
                if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Sales Orders"]) then
                    CurrReport.Break();

                SetFilter("No.", FilterItem.GetFilter("No."));
                SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                SetFilter("Shipment Date", FilterItem.GetFilter("Date Filter"));

                FilterGroup(2);
                if DateFilter <> '' then
                    SetFilter("Shipment Date", DateFilter);
                if VariantFilterFromBatch <> '' then
                    SetFilter("Variant Code", VariantFilterFromBatch);
                if LocationFilterFromBatch <> '' then
                    SetFilter("Location Code", LocationFilterFromBatch);
                FilterGroup(0);
            end;

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                if not IsInventoriableItem() then
                    CurrReport.Skip();

                if not CheckIfSalesLineMeetsReservedFromStockSetting(Abs("Outstanding Qty. (Base)"), ReservedFromStock)
                then
                    CurrReport.Skip();

                if ItemFilterFromBatch <> '' then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", "No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        CurrReport.Skip();
                end;

                OnSalesOrderLineOnAfterGetRecordOnBeforeSetTempSalesLine(SalesOrderLine);

                TempSalesLine := SalesOrderLine;
                TempSalesLine.Insert();
            end;
        }
        dataitem(TransferOrderLine; "Transfer Line")
        {
            DataItemTableView = sorting("Document No.", "Line No.")
                                where("Derived From Line No." = const(0),
                                       "Outstanding Qty. (Base)" = filter(<> 0));

            trigger OnPreDataItem()
            begin
                if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Transfer Orders"]) then
                    CurrReport.Break();

                SetFilter("Item No.", FilterItem.GetFilter("No."));
                SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                SetFilter("Transfer-from Code", FilterItem.GetFilter("Location Filter"));
                SetFilter("Shipment Date", FilterItem.GetFilter("Date Filter"));

                FilterGroup(2);
                if DateFilter <> '' then
                    SetFilter("Shipment Date", DateFilter);
                if VariantFilterFromBatch <> '' then
                    SetFilter("Variant Code", VariantFilterFromBatch);
                if LocationFilterFromBatch <> '' then
                    SetFilter("Transfer-from Code", LocationFilterFromBatch);
                FilterGroup(0);
            end;

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                if not CheckIfTransferLineMeetsReservedFromStockSetting("Outstanding Qty. (Base)", ReservedFromStock)
                then
                    CurrReport.Skip();

                if ItemFilterFromBatch <> '' then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", "Item No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        CurrReport.Skip();
                end;

                TempTransferLine := TransferOrderLine;
                TempTransferLine.Insert();
            end;
        }
        dataitem(ServiceOrderLine; "Service Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.")
                                where("Document Type" = const(Order),
                                      Type = const(Item),
                                      "Outstanding Qty. (Base)" = filter(<> 0));

            trigger OnPreDataItem()
            begin
                if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Service Orders"]) then
                    CurrReport.Break();

                SetFilter("No.", FilterItem.GetFilter("No."));
                SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                SetFilter("Needed by Date", FilterItem.GetFilter("Date Filter"));

                FilterGroup(2);
                if DateFilter <> '' then
                    SetFilter("Needed by Date", DateFilter);
                if VariantFilterFromBatch <> '' then
                    SetFilter("Variant Code", VariantFilterFromBatch);
                if LocationFilterFromBatch <> '' then
                    SetFilter("Location Code", LocationFilterFromBatch);
                FilterGroup(0);
            end;

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                if not IsInventoriableItem() then
                    CurrReport.Skip();

                if not CheckIfServiceLineMeetsReservedFromStockSetting(Abs("Outstanding Qty. (Base)"), ReservedFromStock)
                then
                    CurrReport.Skip();

                if ItemFilterFromBatch <> '' then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", "No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        CurrReport.Skip();
                end;

                TempServiceLine := ServiceOrderLine;
                TempServiceLine.Insert();
            end;
        }
        dataitem(JobPlanningLine; "Job Planning Line")
        {
            DataItemTableView = sorting("Job No.", "Job Task No.", "Line No.")
                                where(Type = const(Item),
                                      "Remaining Qty. (Base)" = filter(<> 0));

            trigger OnPreDataItem()
            begin
                if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Job Usage"]) then
                    CurrReport.Break();

                SetFilter("No.", FilterItem.GetFilter("No."));
                SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                SetFilter("Planning Date", FilterItem.GetFilter("Date Filter"));

                FilterGroup(2);
                if DateFilter <> '' then
                    SetFilter("Planning Date", DateFilter);
                if VariantFilterFromBatch <> '' then
                    SetFilter("Variant Code", VariantFilterFromBatch);
                if LocationFilterFromBatch <> '' then
                    SetFilter("Location Code", LocationFilterFromBatch);
                FilterGroup(0);
            end;

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                if not IsInventoriableItem() then
                    CurrReport.Skip();

                if not CheckIfJobPlngLineMeetsReservedFromStockSetting("Remaining Qty. (Base)", ReservedFromStock)
                then
                    CurrReport.Skip();

                if ItemFilterFromBatch <> '' then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", "No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        CurrReport.Skip();
                end;

                TempJobPlanningLine := JobPlanningLine;
                TempJobPlanningLine.Insert();
            end;
        }
        dataitem(AssemblyLine; "Assembly Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.")
                                where("Document Type" = const(Order),
                                      Type = const(Item),
                                      "Remaining Quantity (Base)" = filter(<> 0));

            trigger OnPreDataItem()
            begin
                if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Assembly Components"]) then
                    CurrReport.Break();

                SetFilter("No.", FilterItem.GetFilter("No."));
                SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                SetFilter("Due Date", FilterItem.GetFilter("Date Filter"));

                FilterGroup(2);
                if DateFilter <> '' then
                    SetFilter("Due Date", DateFilter);
                if VariantFilterFromBatch <> '' then
                    SetFilter("Variant Code", VariantFilterFromBatch);
                if LocationFilterFromBatch <> '' then
                    SetFilter("Location Code", LocationFilterFromBatch);
                FilterGroup(0);
            end;

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                if not IsInventoriableItem() then
                    CurrReport.Skip();

                if not CheckIfAssemblyLineMeetsReservedFromStockSetting("Remaining Quantity (Base)", ReservedFromStock)
                then
                    CurrReport.Skip();

                if ItemFilterFromBatch <> '' then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", "No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        CurrReport.Skip();
                end;

                TempAssemblyLine := AssemblyLine;
                TempAssemblyLine.Insert();
            end;
        }
        dataitem(ProdOrderComponent; "Prod. Order Component")
        {
            DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.")
                                where(Status = const(Released),
                                      "Remaining Qty. (Base)" = filter(<> 0));

            trigger OnPreDataItem()
            begin
                if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Production Components"]) then
                    CurrReport.Break();

                SetFilter("Item No.", FilterItem.GetFilter("No."));
                SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
                SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
                SetFilter("Due Date", FilterItem.GetFilter("Date Filter"));

                FilterGroup(2);
                if DateFilter <> '' then
                    SetFilter("Due Date", DateFilter);
                if VariantFilterFromBatch <> '' then
                    SetFilter("Variant Code", VariantFilterFromBatch);
                if LocationFilterFromBatch <> '' then
                    SetFilter("Location Code", LocationFilterFromBatch);
                FilterGroup(0);
            end;

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                if not IsInventoriableItem() then
                    CurrReport.Skip();

                if not CheckIfProdOrderCompMeetsReservedFromStockSetting("Remaining Qty. (Base)", ReservedFromStock)
                then
                    CurrReport.Skip();

                if ItemFilterFromBatch <> '' then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", "Item No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        CurrReport.Skip();
                end;

                TempProdOrderComponent := ProdOrderComponent;
                TempProdOrderComponent.Insert();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(BatchFilters)
                {
                    Editable = false;
                    Caption = 'Batch Filters';
                    Visible = BatchFiltersVisible;

                    field("Batch Name"; BatchName)
                    {
                        Caption = 'Batch Name';
                        ToolTip = 'Specifies the batch name to use for the reservation worksheet.';
                    }
                    field("Demand Type From Batch"; DemandTypeFromBatch)
                    {
                        Caption = 'Demand Type';
                        ToolTip = 'Specifies the demand type to use for the reservation worksheet.';
                    }
                    field("Item Filter"; ItemFilterFromBatch)
                    {
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the item filter to use for the reservation worksheet.';
                    }
                    field("Variant Filter"; VariantFilterFromBatch)
                    {
                        Caption = 'Variant Filter';
                        ToolTip = 'Specifies the variant filter to use for the reservation worksheet.';
                        Importance = Additional;
                    }
                    field("Location Filter"; LocationFilterFromBatch)
                    {
                        Caption = 'Location Filter';
                        ToolTip = 'Specifies the location filter to use for the reservation worksheet.';
                        Importance = Additional;
                    }
                    field("Start Date"; StartDateFromBatchInText)
                    {
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the start date to use for the reservation worksheet.';
                    }
                    field("End Date"; EndDateFromBatchInText)
                    {
                        Caption = 'End Date';
                        ToolTip = 'Specifies the end date to use for the reservation worksheet.';
                    }
                }
                group(Settings)
                {
                    Caption = 'Settings';

                    field("Show Batch Filters"; BatchFiltersVisible)
                    {
                        Caption = 'Show batch filters';
                        ToolTip = 'Specifies whether to show or hide the batch filters.';
                        Importance = Additional;
                    }
                    field("Demand Type"; DemandType)
                    {
                        Caption = 'Demand Type';
                        ToolTip = 'Specifies the type of demand to reserve.';
                        Editable = DemandTypeEditable;
                    }
                    field(Name; ReservedFromStock)
                    {
                        Caption = 'Reserved from stock';
                        ToolTip = 'Specifies whether you want to include only demand lines that are fully or partially reserved from stock.';
                        ValuesAllowed = 0, None, Partial;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Auto Allocate"; AutoAllocate)
                    {
                        Caption = 'Allocate After Populate';
                        ToolTip = 'Specifies whether to automatically allocate quantity in the reservation worksheet after the report is run.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            DemandTypeEditable := DemandTypeFromBatch = DemandTypeFromBatch::All;
            if not DemandTypeEditable then
                DemandType := DemandTypeFromBatch;
        end;
    }

    trigger OnInitReport()
    begin
        Clear(BatchName);
        Clear(DemandTypeFromBatch);
        Clear(ItemFilterFromBatch);
        Clear(VariantFilterFromBatch);
        Clear(LocationFilterFromBatch);
        Clear(DateFilter);
        Clear(StartDateFromBatch);
        Clear(EndDateFromBatch);
    end;

    trigger OnPreReport()
    begin
        TempSalesLine.DeleteAll();
        TempTransferLine.DeleteAll();
        TempServiceLine.DeleteAll();
        TempJobPlanningLine.DeleteAll();
        TempAssemblyLine.DeleteAll();
        TempProdOrderComponent.DeleteAll();
    end;

    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
        TempSalesLine: Record "Sales Line" temporary;
        TempTransferLine: Record "Transfer Line" temporary;
        TempServiceLine: Record "Service Line" temporary;
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        DemandType: Enum "Reservation Demand Type";
        DemandTypeFromBatch: Enum "Reservation Demand Type";
        ReservedFromStock: Enum "Reservation From Stock";
        BatchName: Code[10];
        ItemFilterFromBatch: Text;
        VariantFilterFromBatch: Text;
        LocationFilterFromBatch: Text;
        StartDateFromBatchInText: Text;
        EndDateFromBatchInText: Text;
        DateFilter: Text;
        StartDateFromBatch: Date;
        EndDateFromBatch: Date;
        DemandTypeEditable: Boolean;
        AutoAllocate: Boolean;
        BatchFiltersVisible: Boolean;

    procedure GetSalesOrderLines(var TempSalesLineToReturn: Record "Sales Line" temporary)
    begin
        TempSalesLineToReturn.Copy(TempSalesLine, true);
    end;

    procedure GetTransferOrderLines(var TempTransferLineToReturn: Record "Transfer Line" temporary)
    begin
        TempTransferLineToReturn.Copy(TempTransferLine, true);
    end;

    procedure GetServiceOrderLines(var TempServiceLineToReturn: Record "Service Line" temporary)
    begin
        TempServiceLineToReturn.Copy(TempServiceLine, true);
    end;

    procedure GetJobPlanningLines(var TempJobPlanningLineToReturn: Record "Job Planning Line" temporary)
    begin
        TempJobPlanningLineToReturn.Copy(TempJobPlanningLine, true);
    end;

    procedure GetAssemblyLines(var TempAssemblyLineToReturn: Record "Assembly Line" temporary)
    begin
        TempAssemblyLineToReturn.Copy(TempAssemblyLine, true);
    end;

    procedure GetProdOrderComponents(var TempProdOrderComponentToReturn: Record "Prod. Order Component" temporary)
    begin
        TempProdOrderComponentToReturn.Copy(TempProdOrderComponent, true);
    end;

    procedure GetAllocateAfterPopulate(): Boolean
    begin
        exit(AutoAllocate);
    end;

    procedure SetBatchName(NewBatchName: Code[10])
    begin
        BatchName := NewBatchName;
        GetBatchFilters();
    end;

    local procedure GetBatchFilters()
    var
        StartDateFormulaFromBatch: DateFormula;
        EndDateFormulaFromBatch: DateFormula;
        StartDate: Date;
        EndDate: Date;
    begin
        if not ReservationWkshBatch.Get(BatchName) then
            exit;

        DemandTypeFromBatch := ReservationWkshBatch."Demand Type";
        ItemFilterFromBatch := ReservationWkshBatch.GetItemFilterAsDisplayText();
        VariantFilterFromBatch := ReservationWkshBatch.GetVariantFilterBlobAsText();
        LocationFilterFromBatch := ReservationWkshBatch.GetLocationFilterBlobAsText();
        StartDateFromBatchInText := '';
        EndDateFromBatchInText := '';

        if Format(ReservationWkshBatch."Start Date Formula") = '' then
            StartDateFromBatch := 0D
        else begin
            StartDateFormulaFromBatch := ReservationWkshBatch."Start Date Formula";
            StartDateFromBatch := CalcDate(StartDateFormulaFromBatch, WorkDate());
            StartDateFromBatchInText := Format(StartDateFromBatch);
        end;
        if Format(ReservationWkshBatch."End Date Formula") = '' then
            EndDateFromBatch := DMY2Date(31, 12, 9998)
        else begin
            EndDateFormulaFromBatch := ReservationWkshBatch."End Date Formula";
            EndDateFromBatch := CalcDate(EndDateFormulaFromBatch, WorkDate());
            EndDateFromBatchInText := Format(EndDateFromBatch);
        end;
        StartDate := StartDateFromBatch;
        EndDate := EndDateFromBatch;
        DateFilter := Format(StartDate) + '..' + Format(EndDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesOrderLineOnAfterGetRecordOnBeforeSetTempSalesLine(var OrderSalesLine: Record "Sales Line")
    begin
    end;
}
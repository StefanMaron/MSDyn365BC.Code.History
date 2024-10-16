namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;

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
        OnGetDemand(FilterItem, ReservationWkshBatch, DemandType, DateFilter, VariantFilterFromBatch, LocationFilterFromBatch, ItemFilterFromBatch, ReservedFromStock);
    end;

    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
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

#if not CLEAN25
    [Obsolete('Replaced by codeunit Sales Get Demand To Reserve', '25.0')]
    procedure GetSalesOrderLines(var TempSalesLineToReturn: Record Microsoft.Sales.Document."Sales Line" temporary)
    begin
        // TempSalesLineToReturn.Copy(TempSalesLine, true);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by codeunit Trans. Get Demand To Reserve', '25.0')]
    procedure GetTransferOrderLines(var TempTransferLineToReturn: Record Microsoft.Inventory.Transfer."Transfer Line" temporary)
    begin
        // TempTransferLineToReturn.Copy(TempTransferLine, true);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by codeunit Serv. Get Demand To Reserve', '25.0')]
    procedure GetServiceOrderLines(var TempServiceLineToReturn: Record Microsoft.Service.Document."Service Line" temporary)
    begin
        // TempServiceLineToReturn.Copy(TempServiceLine, true);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by codeunit Job Planning Line Get Demand', '25.0')]
    procedure GetJobPlanningLines(var TempJobPlanningLineToReturn: Record Microsoft.Projects.Project.Planning."Job Planning Line" temporary)
    begin
        // TempJobPlanningLineToReturn.Copy(TempJobPlanningLine, true);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by codeunit Asm. Get Demand To Reserve', '25.0')]
    procedure GetAssemblyLines(var TempAssemblyLineToReturn: Record Microsoft.Assembly.Document."Assembly Line" temporary)
    begin
        // TempAssemblyLineToReturn.Copy(TempAssemblyLine, true);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by codeunit Mfg. Get Demand To Reserve', '25.0')]
    procedure GetProdOrderComponents(var TempProdOrderComponentToReturn: Record Microsoft.Manufacturing.Document."Prod. Order Component" temporary)
    begin
        // TempProdOrderComponentToReturn.Copy(TempProdOrderComponent, true);
    end;
#endif

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

    procedure SetParameters(NewBatchFiltersVisible: Boolean; NewDemandType: Enum "Reservation Demand Type"; NewReservedFromStock: Enum "Reservation From Stock"; NewAutoAllocate: Boolean)
    begin
        BatchFiltersVisible := NewBatchFiltersVisible;
        DemandType := NewDemandType;
        ReservedFromStock := NewReservedFromStock;
        AutoAllocate := NewAutoAllocate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDemand(var FilterItem: Record Item; var ReservationWkshBatch: Record "Reservation Wksh. Batch"; DemandType: Enum "Reservation Demand Type"; DateFilter: Text; VariantFilterFromBatch: Text; LocationFilterFromBatch: Text; ItemFilterFromBatch: Text; ReservedFromStock: Enum "Reservation From Stock");
    begin
    end;

#if not CLEAN25
    internal procedure RunOnSalesOrderLineOnAfterGetRecordOnBeforeSetTempSalesLine(var OrderSalesLine: Record Microsoft.Sales.Document."Sales Line"; var IsHandled: Boolean)
    begin
        OnSalesOrderLineOnAfterGetRecordOnBeforeSetTempSalesLine(OrderSalesLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit SalesGetDemandToReserve as OnGetDemandOnBeforeSetTempSalesLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSalesOrderLineOnAfterGetRecordOnBeforeSetTempSalesLine(var OrderSalesLine: Record Microsoft.Sales.Document."Sales Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnTransferOrderLineOnAfterGetRecordOnBeforeSetTempTransferLine(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean)
    begin
        OnTransferOrderLineOnAfterGetRecordOnBeforeSetTempTransferLine(TransferLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit TransGetDemandToReserve as OnGetDemandOnBeforeSetTempTransferLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferOrderLineOnAfterGetRecordOnBeforeSetTempTransferLine(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnServiceOrderLineOnAfterGetRecordOnBeforeSetTempServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
        OnServiceOrderLineOnAfterGetRecordOnBeforeSetTempServiceLine(ServiceLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServGetDemandToReserve as OnGetDemandOnBeforeSetTempServiceLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServiceOrderLineOnAfterGetRecordOnBeforeSetTempServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnJobPlanningLineOnAfterGetRecordOnBeforeSetTempJobPlanningLine(var JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line"; var IsHandled: Boolean)
    begin
        OnJobPlanningLineOnAfterGetRecordOnBeforeSetTempJobPlanningLine(JobPlanningLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit JobPlanningLineGetDemandToReserve as OnGetDemandOnBeforeSetTempJobPlanningLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnJobPlanningLineOnAfterGetRecordOnBeforeSetTempJobPlanningLine(var JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnAssemblyLineOnAfterGetRecordOnBeforeSetTempAssemblyLine(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; var IsHandled: Boolean)
    begin
        OnAssemblyLineOnAfterGetRecordOnBeforeSetTempAssemblyLine(AssemblyLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit AsmGetDemandToReserve as OnGetDemandOnBeforeSetTempAssemblyLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAssemblyLineOnAfterGetRecordOnBeforeSetTempAssemblyLine(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnProdOrderComponentOnAfterGetRecordOnBeforeSetTempProdOrderComponent(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var IsHandled: Boolean)
    begin
        OnProdOrderComponentOnAfterGetRecordOnBeforeSetTempProdOrderComponent(ProdOrderComponent, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgGetDemandToReserve as OnGetDemandOnBeforeSetTempProdOrderComponent', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnProdOrderComponentOnAfterGetRecordOnBeforeSetTempProdOrderComponent(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;
#endif
}
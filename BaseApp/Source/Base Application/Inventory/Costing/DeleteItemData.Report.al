namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using System.Environment;
using System.Utilities;

report 5800 "Delete Item Data"
{
    ApplicationArea = Basic, Suite;
    ProcessingOnly = true;
    UseRequestPage = false;
    Caption = 'Delete Item Data';
    Permissions = tabledata "Item Ledger Entry" = d,
                  tabledata "Value Entry" = d,
                  tabledata "Item Application Entry" = d,
                  tabledata "Avg. Cost Adjmt. Entry Point" = d,
                  tabledata "Capacity Ledger Entry" = d,
                  tabledata "Production Order" = d,
                  tabledata "Prod. Order Line" = d,
                  tabledata "Post Value Entry to G/L" = d,
                  tabledata "Inventory Adjmt. Entry (Order)" = d,
                  tabledata "Cost Adj. Item Bucket" = d,
                  tabledata "Cost Adjustment Log" = d,
                  tabledata "Cost Adjustment Detailed Log" = d;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            var
                CompanyInformation: Record "Company Information";
                EnvironmentInformation: Codeunit "Environment Information";
                ListOfTables: TextBuilder;
            begin
                CompanyInformation.Get();
                if not EnvironmentInformation.IsSandbox() and not CompanyInformation."Demo Company" then
                    Error(NotTestEnvironmentErr);

                ListOfTables.AppendLine(ItemLedgerEntry.TableCaption());
                ListOfTables.AppendLine(ItemApplicationEntry.TableCaption());
                ListOfTables.AppendLine(ValueEntry.TableCaption());
                ListOfTables.AppendLine(AvgCostAdjmtEntryPoint.TableCaption());
                ListOfTables.AppendLine(CapacityLedgerEntry.TableCaption());
                ListOfTables.AppendLine(ProductionOrder.TableCaption());
                ListOfTables.AppendLine(ProdOrderLine.TableCaption());
                ListOfTables.AppendLine(PostValueEntrytoGL.TableCaption());
                ListOfTables.AppendLine(InventoryAdjmtEntryOrder.TableCaption());
                ListOfTables.AppendLine(CostAdjItemBucket.TableCaption());
                ListOfTables.AppendLine(CostAdjustmentLog.TableCaption());
                ListOfTables.AppendLine(CostAdjustmentDetailedLog.TableCaption());

                if not Confirm(DeleteCriticalDataQst + ListOfTables.ToText()) then
                    Error(JobCancelledErr);
            end;

            trigger OnAfterGetRecord()
            begin
                ItemLedgerEntry.DeleteAll();
                ItemApplicationEntry.DeleteAll();
                ValueEntry.DeleteAll();
                AvgCostAdjmtEntryPoint.DeleteAll();
                CapacityLedgerEntry.DeleteAll();
                ProductionOrder.DeleteAll();
                ProdOrderLine.DeleteAll();
                PostValueEntrytoGL.DeleteAll();
                InventoryAdjmtEntryOrder.DeleteAll();
                CostAdjItemBucket.DeleteAll();
                CostAdjustmentLog.DeleteAll();
                CostAdjustmentDetailedLog.DeleteAll();
            end;

            trigger OnPostDataItem()
            begin
                Message(DataWasDeletedMsg);
            end;
        }
    }

    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        ValueEntry: Record "Value Entry";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
        CostAdjustmentLog: Record "Cost Adjustment Log";
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
        NotTestEnvironmentErr: Label 'This job will delete critical data and must only be run in the demo company or in a sandbox environment.';
        DeleteCriticalDataQst: Label 'Are you sure you want to continue?\This job will empty the following tables:\';
        JobCancelledErr: Label 'The job has been cancelled.';
        DataWasDeletedMsg: Label 'The data has been deleted.';
}
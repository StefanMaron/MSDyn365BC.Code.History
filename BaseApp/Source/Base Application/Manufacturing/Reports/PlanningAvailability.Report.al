namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Setup;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Utilities;

report 99001048 "Planning Availability"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/PlanningAvailability.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Planning Availability';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Forecast Entry"; "Production Forecast Entry")
        {
            DataItemTableView = sorting("Production Forecast Name", "Item No.", "Variant Code", "Component Forecast", "Forecast Date", "Location Code");

            trigger OnAfterGetRecord()
            begin
                BufferCounter += 1;
                TempForecastPlanningBuffer.SetRange("Item No.", "Item No.");
                TempForecastPlanningBuffer.SetRange(Date, "Forecast Date");
                if "Component Forecast" then
                    TempForecastPlanningBuffer.SetRange("Document Type", TempForecastPlanningBuffer."Document Type"::"Production Forecast-Component")
                else
                    TempForecastPlanningBuffer.SetRange("Document Type", TempForecastPlanningBuffer."Document Type"::"Production Forecast-Sales");

                if TempForecastPlanningBuffer.FindFirst() then begin
                    TempForecastPlanningBuffer."Gross Requirement" += "Forecast Quantity";
                    TempForecastPlanningBuffer.Modify();
                end else
                    InsertNewForecast("Production Forecast Entry");
            end;

            trigger OnPreDataItem()
            var
                MfgSetup: Record "Manufacturing Setup";
            begin
                MfgSetup.Get();
                SetRange("Production Forecast Name", MfgSetup."Current Production Forecast");
            end;
        }
        dataitem("Sales Line"; "Sales Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Shipment Date", "No.", Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Sales Order";
                    TempPlanningBuffer."Document No." := "Document No.";
                    TempPlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                    TempPlanningBuffer.Insert();
                end else begin
                    TempPlanningBuffer.SetRange("Item No.", "No.");
                    TempPlanningBuffer.SetRange(Date, "Shipment Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Gross Requirement" := TempPlanningBuffer."Gross Requirement" + "Outstanding Qty. (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Shipment Date", "No.", Description);
                        TempPlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                end;
                ModifyForecast("No.", "Shipment Date", TempPlanningBuffer."Document Type"::"Production Forecast-Sales", "Outstanding Qty. (Base)");
            end;

            trigger OnPreDataItem()
            begin
                TempPlanningBuffer.DeleteAll();
                SetRange("Document Type", "Document Type"::Order);
                SetRange(Type, Type::Item);
            end;
        }
        dataitem("Job Planning Line"; "Job Planning Line")
        {
            DataItemTableView = sorting("Job No.", "Job Task No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Planning Date", "No.", Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Job Order";
                    TempPlanningBuffer."Document No." := "Job No.";
                    TempPlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                    TempPlanningBuffer.Insert();
                end else begin
                    TempPlanningBuffer.SetRange("Item No.", "No.");
                    TempPlanningBuffer.SetRange(Date, "Planning Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Gross Requirement" := TempPlanningBuffer."Gross Requirement" + "Remaining Qty. (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Planning Date", "No.", Description);
                        TempPlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Status, Status::Order);
                SetRange(Type, Type::Item);
            end;
        }
        dataitem("Purchase Line"; "Purchase Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                ReqLine2.SetRange("Ref. Order No.", "Document No.");
                ReqLine2.SetRange("Ref. Line No.", "Line No.");
                if ReqLine2.FindFirst() then
                    CurrReport.Skip();

                if Selection then begin
                    NewRecordWithDetails("Expected Receipt Date", "No.", Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Purchase Order";
                    TempPlanningBuffer."Document No." := "Document No.";
                    TempPlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)";
                    TempPlanningBuffer.Insert();
                end else begin
                    TempPlanningBuffer.SetRange("Item No.", "No.");
                    TempPlanningBuffer.SetRange(Date, "Expected Receipt Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Scheduled Receipts" := TempPlanningBuffer."Scheduled Receipts" + "Outstanding Qty. (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Expected Receipt Date", "No.", Description);
                        TempPlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Document Type", "Document Type"::Order);
                SetRange(Type, Type::Item);
                ReqLine2.Reset();
                ReqLine2.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
                ReqLine2.SetRange("Ref. Order Type", ReqLine2."Ref. Order Type"::Purchase);
            end;
        }
        dataitem("Transfer Line"; "Transfer Line")
        {
            DataItemTableView = sorting("Transfer-from Code", Status, "Derived From Line No.", "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Shipment Date", "In-Transit Code");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Shipment Date", "Item No.", Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::Transfer;
                    TempPlanningBuffer."Document No." := "Document No.";
                    TempPlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                    TempPlanningBuffer.Insert();
                    NewRecordWithDetails("Receipt Date", "Item No.", Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::Transfer;
                    TempPlanningBuffer."Document No." := "Document No.";
                    TempPlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)" + "Qty. in Transit (Base)";
                    TempPlanningBuffer.Insert();
                end else begin
                    TempPlanningBuffer.SetRange("Item No.", "Item No.");
                    TempPlanningBuffer.SetRange(Date, "Shipment Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Gross Requirement" := TempPlanningBuffer."Gross Requirement" + "Outstanding Qty. (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Shipment Date", "Item No.", Description);
                        TempPlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                    TempPlanningBuffer.SetRange(Date, "Receipt Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Scheduled Receipts" :=
                          TempPlanningBuffer."Scheduled Receipts" +
                          "Outstanding Qty. (Base)" +
                          "Qty. in Transit (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Receipt Date", "Item No.", Description);
                        TempPlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)" + "Qty. in Transit (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Derived From Line No.", 0);
            end;
        }
        dataitem("Prod. Order Line"; "Prod. Order Line")
        {
            DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if not (Status in [Status::Simulated, Status::Finished]) then begin
                    ReqLine2.SetRange("Ref. Order Status", Status);
                    ReqLine2.SetRange("Ref. Order No.", "Prod. Order No.");
                    ReqLine2.SetRange("Ref. Line No.", "Line No.");
                    if ReqLine2.FindFirst() then
                        CurrReport.Skip();

                    if Selection then begin
                        NewRecordWithDetails("Due Date", "Item No.", Description);
                        TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Purchase Order";
                        TempPlanningBuffer."Document No." := "Prod. Order No.";
                        case Status of
                            Status::"Firm Planned":
                                begin
                                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Firm Planned Prod. Order";
                                    TempPlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                                end;
                            Status::Released:
                                begin
                                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Released Prod. Order";
                                    TempPlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                                end;
                            Status::Planned:
                                begin
                                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Planned Prod. Order";
                                    TempPlanningBuffer."Planned Receipts" := "Remaining Qty. (Base)";
                                end;
                        end;
                        TempPlanningBuffer.Insert();
                    end else begin
                        TempPlanningBuffer.SetRange("Item No.", "Item No.");
                        TempPlanningBuffer.SetRange(Date, "Due Date");
                        if TempPlanningBuffer.Find('-') then begin
                            if Status = Status::Planned then
                                TempPlanningBuffer."Planned Receipts" :=
                                  TempPlanningBuffer."Planned Receipts" +
                                  "Remaining Qty. (Base)"
                            else
                                TempPlanningBuffer."Scheduled Receipts" :=
                                  TempPlanningBuffer."Scheduled Receipts" +
                                  "Remaining Qty. (Base)";
                            TempPlanningBuffer.Modify();
                        end else begin
                            NewRecordWithDetails("Due Date", "Item No.", Description);
                            if Status = Status::Planned then
                                TempPlanningBuffer."Planned Receipts" := "Remaining Qty. (Base)"
                            else
                                TempPlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                            TempPlanningBuffer.Insert();
                        end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                ReqLine2.Reset();
                ReqLine2.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
                ReqLine2.SetRange("Ref. Order Type", ReqLine2."Ref. Order Type"::"Prod. Order");
            end;
        }
        dataitem("Requisition Line"; "Requisition Line")
        {
            DataItemTableView = sorting("Worksheet Template Name", "Journal Batch Name", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Due Date", "No.", Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Requisition Line";
                    TempPlanningBuffer."Document No." := "Prod. Order No.";
                    TempPlanningBuffer."Planned Receipts" := "Quantity (Base)";
                    TempPlanningBuffer.Insert();
                end else begin
                    TempPlanningBuffer.SetRange("Item No.", "No.");
                    TempPlanningBuffer.SetRange(Date, "Due Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Planned Receipts" := TempPlanningBuffer."Planned Receipts" + "Quantity (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Due Date", "No.", Description);
                        TempPlanningBuffer."Planned Receipts" := "Quantity (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Type, Type::Item);
            end;
        }
        dataitem("Prod. Order Component"; "Prod. Order Component")
        {
            DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if not (Status in [Status::Simulated, Status::Finished]) then begin
                    ReqLine2.SetRange("Ref. Order Status", Status);
                    ReqLine2.SetRange("Ref. Order No.", "Prod. Order No.");
                    ReqLine2.SetRange("Ref. Line No.", "Prod. Order Line No.");
                    if ReqLine2.FindFirst() then
                        CurrReport.Skip();

                    if Selection then begin
                        NewRecordWithDetails("Due Date", "Item No.", Description);
                        TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Purchase Order";
                        TempPlanningBuffer."Document No." := "Prod. Order No.";
                        TempPlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                        case Status of
                            Status::"Firm Planned":
                                TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Firm Planned Prod. Order Comp.";
                            Status::Released:
                                TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Released Prod. Order Comp.";
                            Status::Planned:
                                TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Planned Prod. Order Comp.";
                        end;
                        TempPlanningBuffer.Insert();
                    end else begin
                        TempPlanningBuffer.SetRange("Item No.", "Item No.");
                        TempPlanningBuffer.SetRange(Date, "Due Date");
                        if TempPlanningBuffer.Find('-') then begin
                            TempPlanningBuffer."Gross Requirement" := TempPlanningBuffer."Gross Requirement" + "Remaining Qty. (Base)";
                            TempPlanningBuffer.Modify();
                        end else begin
                            NewRecordWithDetails("Due Date", "Item No.", Description);
                            TempPlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                            TempPlanningBuffer.Insert();
                        end;
                    end;
                end;
                ModifyForecast("Item No.", "Due Date", TempPlanningBuffer."Document Type"::"Production Forecast-Component", "Remaining Qty. (Base)");
            end;

            trigger OnPreDataItem()
            begin
                ReqLine2.Reset();
                ReqLine2.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
                ReqLine2.SetRange("Ref. Order Type", ReqLine2."Ref. Order Type"::"Prod. Order");
            end;
        }
        dataitem("Planning Component"; "Planning Component")
        {
            DataItemTableView = sorting("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Due Date", "Item No.", Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Planning Comp.";
                    TempPlanningBuffer."Document No." := ReqLine."Ref. Order No.";
                    TempPlanningBuffer."Gross Requirement" := "Expected Quantity (Base)";
                    TempPlanningBuffer.Insert();
                end else begin
                    TempPlanningBuffer.SetRange("Item No.", "Item No.");
                    TempPlanningBuffer.SetRange(Date, "Due Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Gross Requirement" := TempPlanningBuffer."Gross Requirement" + "Expected Quantity (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Due Date", "Item No.", Description);
                        TempPlanningBuffer."Gross Requirement" := "Expected Quantity (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                end;
                ModifyForecast("Item No.", "Due Date", TempPlanningBuffer."Document Type"::"Production Forecast-Component", "Expected Quantity (Base)");
            end;
        }
        dataitem("Planning Buffer"; "Planning Buffer")
        {
            DataItemTableView = sorting("Item No.", Date);
            RequestFilterFields = "Item No.", Date;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PlngBuffTableCaptFilter; TempPlanningBuffer.TableCaption + ': ' + PlanningFilter)
            {
            }
            column(PlanningFilter; PlanningFilter)
            {
            }
            column(ItemInventory; Item.Inventory)
            {
            }
            column(PlanningBuffItemNo; TempPlanningBuffer."Item No.")
            {
            }
            column(PlanningBuffDesc; TempPlanningBuffer.Description)
            {
            }
            column(ShowIntBody1; PrintBoolean and Selection)
            {
            }
            column(PlanningBuffDocNo; TempPlanningBuffer."Document No.")
            {
            }
            column(PlanningBuffDocType; Format(TempPlanningBuffer."Document Type"))
            {
            }
            column(ProjectedBalance; ProjectedBalance)
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlngBuffScheduledReceipts; TempPlanningBuffer."Scheduled Receipts")
            {
            }
            column(PlngBuffPlannedReceipts; TempPlanningBuffer."Planned Receipts")
            {
            }
            column(PlngBuffGrossRequirement; TempPlanningBuffer."Gross Requirement")
            {
            }
            column(PlanningBuffDate; Format(TempPlanningBuffer.Date))
            {
            }
            column(ShowIntBody2; Selection and PrintBoolean2)
            {
            }
            column(ShowIntBody3; PrintBoolean and (not Selection))
            {
            }
            column(ShowIntBody4; (not Selection) and PrintBoolean2)
            {
            }
            column(PlanningAvailabilityCaptn; PlanningAvailabilityCaptnLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(DocumentNoCaption; DocumentNoCaptionLbl)
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(ProjectedBalanceCaption; ProjectedBalanceCaptionLbl)
            {
            }
            column(ScheduledReceiptsCaption; ScheduledReceiptsCaptionLbl)
            {
            }
            column(PlannedReceiptsCaption; PlannedReceiptsCaptionLbl)
            {
            }
            column(GrossRequirementCaption; GrossRequirementCaptionLbl)
            {
            }
            column(AvailableInventoryCaption; AvailableInventoryCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempPlanningBuffer.Find('-')
                else
                    if TempPlanningBuffer.Next() = 0 then
                        CurrReport.Break();

                Item.SetRange("Date Filter", 0D, TempPlanningBuffer.Date);
                if Item.Get(TempPlanningBuffer."Item No.") then begin
                    PrintBoolean2 := true;
                    if TempPlanningBuffer."Item No." = OldItem then
                        PrintBoolean := false
                    else begin
                        PrintBoolean := true;
                        OldItem := TempPlanningBuffer."Item No.";
                        Item.CalcFields(Inventory);
                        ProjectedBalance := Item.Inventory;
                    end;

                    ProjectedBalance :=
                      ProjectedBalance -
                      TempPlanningBuffer."Gross Requirement" +
                      TempPlanningBuffer."Planned Receipts" +
                      TempPlanningBuffer."Scheduled Receipts";
                end else
                    PrintBoolean2 := false;
            end;

            trigger OnPreDataItem()
            begin
                TempForecastPlanningBuffer.Reset();
                TempForecastPlanningBuffer.SetFilter("Gross Requirement", '>0');
                if TempForecastPlanningBuffer.FindSet() then
                    repeat
                        if Selection then begin
                            NewRecord();
                            TempPlanningBuffer := TempForecastPlanningBuffer;
                            TempPlanningBuffer."Buffer No." := BufferCounter;
                            TempPlanningBuffer.Insert();
                        end else begin
                            TempPlanningBuffer.SetRange("Item No.", TempForecastPlanningBuffer."Item No.");
                            TempPlanningBuffer.SetRange(Date, TempForecastPlanningBuffer.Date);
                            if TempPlanningBuffer.FindSet(true) then begin
                                TempPlanningBuffer."Gross Requirement" += TempForecastPlanningBuffer."Gross Requirement";
                                TempPlanningBuffer.Modify();
                            end else begin
                                NewRecord();
                                TempPlanningBuffer := TempForecastPlanningBuffer;
                                TempPlanningBuffer."Buffer No." := BufferCounter;
                                TempPlanningBuffer.Insert();
                            end;
                        end;
                    until TempForecastPlanningBuffer.Next() = 0;

                TempPlanningBuffer.SetCurrentKey("Item No.", Date);
                TempPlanningBuffer.CopyFilters("Planning Buffer");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Selection; Selection)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Detailed';
                        DrillDown = true;
                        ToolTip = 'Specifies whether you want the report to display a detailed list of each demand and supply entry. The report will instead show the total cumulative demand and supply.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Selection := true;
    end;

    trigger OnPreReport()
    begin
        PlanningFilter := "Planning Buffer".GetFilters();

        CollectData();
    end;

    var
        TempPlanningBuffer: Record "Planning Buffer" temporary;
        TempForecastPlanningBuffer: Record "Planning Buffer" temporary;
        Item: Record Item;
        ReqLine: Record "Requisition Line";
        ReqLine2: Record "Requisition Line";
        PlanningFilter: Text;
        OldItem: Code[20];
        PrintBoolean: Boolean;
        BufferCounter: Integer;
        Selection: Boolean;
        ProjectedBalance: Decimal;
        PrintBoolean2: Boolean;
        PlanningAvailabilityCaptnLbl: Label 'Planning Availability';
        CurrReportPageNoCaptionLbl: Label 'Page';
        DocumentNoCaptionLbl: Label 'Document No.';
        DocumentTypeCaptionLbl: Label 'Document Type';
        ProjectedBalanceCaptionLbl: Label 'Projected Balance';
        ScheduledReceiptsCaptionLbl: Label 'Scheduled Receipts';
        PlannedReceiptsCaptionLbl: Label 'Planned Receipts';
        GrossRequirementCaptionLbl: Label 'Gross Requirement';
        AvailableInventoryCaptionLbl: Label 'Available Inventory';
        DateCaptionLbl: Label 'Date';

    local procedure CollectData();
    begin
        OnCollectData(TempPlanningBuffer, Selection);
    end;

    local procedure NewRecord()
    begin
        TempPlanningBuffer.SetRange("Item No.");
        TempPlanningBuffer.SetRange(Date);

        if not TempPlanningBuffer.Find('+') then
            BufferCounter := 1
        else begin
            BufferCounter := TempPlanningBuffer."Buffer No." + 1;
            Clear(TempPlanningBuffer);
        end;
        TempPlanningBuffer."Buffer No." := BufferCounter;
    end;

    procedure NewRecordWithDetails(NewDate: Date; NewItemNo: Code[20]; NewDescription: Text[100])
    begin
        NewRecord();
        TempPlanningBuffer.Date := NewDate;
        TempPlanningBuffer."Item No." := NewItemNo;
        TempPlanningBuffer.Description := NewDescription;
    end;

    local procedure InsertNewForecast(ProdForecastEntry: Record "Production Forecast Entry")
    begin
        TempForecastPlanningBuffer.Init();
        TempForecastPlanningBuffer."Buffer No." := BufferCounter;
        TempForecastPlanningBuffer.Date := ProdForecastEntry."Forecast Date";
        if ProdForecastEntry."Component Forecast" then
            TempForecastPlanningBuffer."Document Type" := TempForecastPlanningBuffer."Document Type"::"Production Forecast-Component"
        else
            TempForecastPlanningBuffer."Document Type" := TempForecastPlanningBuffer."Document Type"::"Production Forecast-Sales";
        TempForecastPlanningBuffer."Document No." := ProdForecastEntry."Production Forecast Name";
        TempForecastPlanningBuffer."Item No." := ProdForecastEntry."Item No.";
        TempForecastPlanningBuffer.Description := ProdForecastEntry.Description;
        TempForecastPlanningBuffer."Gross Requirement" := ProdForecastEntry."Forecast Quantity";
        TempForecastPlanningBuffer.Insert();
    end;

    local procedure ModifyForecast(ItemNo: Code[20]; Date: Date; DocumentType: Option; Quantity: Decimal)
    begin
        Clear(TempForecastPlanningBuffer);
        TempForecastPlanningBuffer.SetRange("Item No.", ItemNo);
        TempForecastPlanningBuffer.SetFilter(Date, '..%1', Date);
        TempForecastPlanningBuffer.SetRange("Document Type", DocumentType);
        if TempForecastPlanningBuffer.FindLast() then begin
            TempForecastPlanningBuffer."Gross Requirement" -= Quantity;
            TempForecastPlanningBuffer.Modify();
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCollectData(var TempPlanningBuffer: Record "Planning Buffer" temporary; Selection: Boolean)
    begin
    end;
}


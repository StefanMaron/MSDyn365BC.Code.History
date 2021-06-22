report 99001048 "Planning Availability"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PlanningAvailability.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Planning Availability';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Forecast Entry"; "Production Forecast Entry")
        {
            DataItemTableView = SORTING("Production Forecast Name", "Item No.", "Component Forecast", "Forecast Date", "Location Code");

            trigger OnAfterGetRecord()
            begin
                BufferCounter += 1;
                TempForecastPlanningBuffer.SetRange("Item No.", "Item No.");
                TempForecastPlanningBuffer.SetRange(Date, "Forecast Date");
                if "Component Forecast" then
                    TempForecastPlanningBuffer.SetRange("Document Type", TempForecastPlanningBuffer."Document Type"::"Production Forecast-Component")
                else
                    TempForecastPlanningBuffer.SetRange("Document Type", TempForecastPlanningBuffer."Document Type"::"Production Forecast-Sales");

                if TempForecastPlanningBuffer.FindFirst then begin
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
            DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Shipment Date", "No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Sales Order";
                    PlanningBuffer."Document No." := "Document No.";
                    PlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                    PlanningBuffer.Insert();
                end else begin
                    PlanningBuffer.SetRange("Item No.", "No.");
                    PlanningBuffer.SetRange(Date, "Shipment Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Gross Requirement" := PlanningBuffer."Gross Requirement" + "Outstanding Qty. (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Shipment Date", "No.", Description);
                        PlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                        PlanningBuffer.Insert();
                    end;
                end;
                ModifyForecast("No.", "Shipment Date", PlanningBuffer."Document Type"::"Production Forecast-Sales", "Outstanding Qty. (Base)");
            end;

            trigger OnPreDataItem()
            begin
                PlanningBuffer.DeleteAll();
                SetRange("Document Type", "Document Type"::Order);
                SetRange(Type, Type::Item);
            end;
        }
        dataitem("Service Line"; "Service Line")
        {
            DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Needed by Date", "No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Service Order";
                    PlanningBuffer."Document No." := "Document No.";
                    PlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                    PlanningBuffer.Insert();
                end else begin
                    PlanningBuffer.SetRange("Item No.", "No.");
                    PlanningBuffer.SetRange(Date, "Needed by Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Gross Requirement" := PlanningBuffer."Gross Requirement" + "Outstanding Qty. (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Posting Date", "No.", Description);
                        PlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                        PlanningBuffer.Insert();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Document Type", "Document Type"::Order);
                SetRange(Type, Type::Item);
            end;
        }
        dataitem("Job Planning Line"; "Job Planning Line")
        {
            DataItemTableView = SORTING("Job No.", "Job Task No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Planning Date", "No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Job Order";
                    PlanningBuffer."Document No." := "Job No.";
                    PlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                    PlanningBuffer.Insert();
                end else begin
                    PlanningBuffer.SetRange("Item No.", "No.");
                    PlanningBuffer.SetRange(Date, "Planning Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Gross Requirement" := PlanningBuffer."Gross Requirement" + "Remaining Qty. (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Planning Date", "No.", Description);
                        PlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                        PlanningBuffer.Insert();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Status, Status::Order);
                SetRange(Type, "Service Line".Type::Item);
            end;
        }
        dataitem("Purchase Line"; "Purchase Line")
        {
            DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                ReqLine2.SetRange("Ref. Order No.", "Document No.");
                ReqLine2.SetRange("Ref. Line No.", "Line No.");
                if ReqLine2.FindFirst then
                    CurrReport.Skip();

                if Selection then begin
                    NewRecordWithDetails("Expected Receipt Date", "No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Purchase Order";
                    PlanningBuffer."Document No." := "Document No.";
                    PlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)";
                    PlanningBuffer.Insert();
                end else begin
                    PlanningBuffer.SetRange("Item No.", "No.");
                    PlanningBuffer.SetRange(Date, "Expected Receipt Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Scheduled Receipts" := PlanningBuffer."Scheduled Receipts" + "Outstanding Qty. (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Expected Receipt Date", "No.", Description);
                        PlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)";
                        PlanningBuffer.Insert();
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
            DataItemTableView = SORTING("Transfer-from Code", Status, "Derived From Line No.", "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Shipment Date", "In-Transit Code");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Shipment Date", "Item No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::Transfer;
                    PlanningBuffer."Document No." := "Document No.";
                    PlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                    PlanningBuffer.Insert();
                    NewRecordWithDetails("Receipt Date", "Item No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::Transfer;
                    PlanningBuffer."Document No." := "Document No.";
                    PlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)" + "Qty. in Transit (Base)";
                    PlanningBuffer.Insert();
                end else begin
                    PlanningBuffer.SetRange("Item No.", "Item No.");
                    PlanningBuffer.SetRange(Date, "Shipment Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Gross Requirement" := PlanningBuffer."Gross Requirement" + "Outstanding Qty. (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Shipment Date", "Item No.", Description);
                        PlanningBuffer."Gross Requirement" := "Outstanding Qty. (Base)";
                        PlanningBuffer.Insert();
                    end;
                    PlanningBuffer.SetRange(Date, "Receipt Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Scheduled Receipts" :=
                          PlanningBuffer."Scheduled Receipts" +
                          "Outstanding Qty. (Base)" +
                          "Qty. in Transit (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Receipt Date", "Item No.", Description);
                        PlanningBuffer."Scheduled Receipts" := "Outstanding Qty. (Base)" + "Qty. in Transit (Base)";
                        PlanningBuffer.Insert();
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
            DataItemTableView = SORTING(Status, "Prod. Order No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if not (Status in [Status::Simulated, Status::Finished]) then begin
                    ReqLine2.SetRange("Ref. Order Status", Status);
                    ReqLine2.SetRange("Ref. Order No.", "Prod. Order No.");
                    ReqLine2.SetRange("Ref. Line No.", "Line No.");
                    if ReqLine2.FindFirst then
                        CurrReport.Skip();

                    if Selection then begin
                        NewRecordWithDetails("Due Date", "Item No.", Description);
                        PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Purchase Order";
                        PlanningBuffer."Document No." := "Prod. Order No.";
                        case Status of
                            Status::"Firm Planned":
                                begin
                                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Firm Planned Prod. Order";
                                    PlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                                end;
                            Status::Released:
                                begin
                                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Released Prod. Order";
                                    PlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                                end;
                            Status::Planned:
                                begin
                                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Planned Prod. Order";
                                    PlanningBuffer."Planned Receipts" := "Remaining Qty. (Base)";
                                end;
                        end;
                        PlanningBuffer.Insert();
                    end else begin
                        PlanningBuffer.SetRange("Item No.", "Item No.");
                        PlanningBuffer.SetRange(Date, "Due Date");
                        if PlanningBuffer.Find('-') then begin
                            if Status = Status::Planned then
                                PlanningBuffer."Planned Receipts" :=
                                  PlanningBuffer."Planned Receipts" +
                                  "Remaining Qty. (Base)"
                            else
                                PlanningBuffer."Scheduled Receipts" :=
                                  PlanningBuffer."Scheduled Receipts" +
                                  "Remaining Qty. (Base)";
                            PlanningBuffer.Modify();
                        end else begin
                            NewRecordWithDetails("Due Date", "Item No.", Description);
                            if Status = Status::Planned then
                                PlanningBuffer."Planned Receipts" := "Remaining Qty. (Base)"
                            else
                                PlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                            PlanningBuffer.Insert();
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
            DataItemTableView = SORTING("Worksheet Template Name", "Journal Batch Name", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Due Date", "No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Requisition Line";
                    PlanningBuffer."Document No." := "Prod. Order No.";
                    PlanningBuffer."Planned Receipts" := "Quantity (Base)";
                    PlanningBuffer.Insert();
                end else begin
                    PlanningBuffer.SetRange("Item No.", "No.");
                    PlanningBuffer.SetRange(Date, "Due Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Planned Receipts" := PlanningBuffer."Planned Receipts" + "Quantity (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Due Date", "No.", Description);
                        PlanningBuffer."Planned Receipts" := "Quantity (Base)";
                        PlanningBuffer.Insert();
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
            DataItemTableView = SORTING(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if not (Status in [Status::Simulated, Status::Finished]) then begin
                    ReqLine2.SetRange("Ref. Order Status", Status);
                    ReqLine2.SetRange("Ref. Order No.", "Prod. Order No.");
                    ReqLine2.SetRange("Ref. Line No.", "Prod. Order Line No.");
                    if ReqLine2.FindFirst then
                        CurrReport.Skip();

                    if Selection then begin
                        NewRecordWithDetails("Due Date", "Item No.", Description);
                        PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Purchase Order";
                        PlanningBuffer."Document No." := "Prod. Order No.";
                        PlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                        case Status of
                            Status::"Firm Planned":
                                PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Firm Planned Prod. Order Comp.";
                            Status::Released:
                                PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Released Prod. Order Comp.";
                            Status::Planned:
                                PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Planned Prod. Order Comp.";
                        end;
                        PlanningBuffer.Insert();
                    end else begin
                        PlanningBuffer.SetRange("Item No.", "Item No.");
                        PlanningBuffer.SetRange(Date, "Due Date");
                        if PlanningBuffer.Find('-') then begin
                            PlanningBuffer."Gross Requirement" := PlanningBuffer."Gross Requirement" + "Remaining Qty. (Base)";
                            PlanningBuffer.Modify();
                        end else begin
                            NewRecordWithDetails("Due Date", "Item No.", Description);
                            PlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                            PlanningBuffer.Insert();
                        end;
                    end;
                end;
                ModifyForecast("Item No.", "Due Date", PlanningBuffer."Document Type"::"Production Forecast-Component", "Remaining Qty. (Base)");
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
            DataItemTableView = SORTING("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Selection then begin
                    NewRecordWithDetails("Due Date", "Item No.", Description);
                    PlanningBuffer."Document Type" := PlanningBuffer."Document Type"::"Planning Comp.";
                    PlanningBuffer."Document No." := ReqLine."Ref. Order No.";
                    PlanningBuffer."Gross Requirement" := "Expected Quantity (Base)";
                    PlanningBuffer.Insert();
                end else begin
                    PlanningBuffer.SetRange("Item No.", "Item No.");
                    PlanningBuffer.SetRange(Date, "Due Date");
                    if PlanningBuffer.Find('-') then begin
                        PlanningBuffer."Gross Requirement" := PlanningBuffer."Gross Requirement" + "Expected Quantity (Base)";
                        PlanningBuffer.Modify();
                    end else begin
                        NewRecordWithDetails("Due Date", "Item No.", Description);
                        PlanningBuffer."Gross Requirement" := "Expected Quantity (Base)";
                        PlanningBuffer.Insert();
                    end;
                end;
                ModifyForecast("Item No.", "Due Date", PlanningBuffer."Document Type"::"Production Forecast-Component", "Expected Quantity (Base)");
            end;
        }
        dataitem("Planning Buffer"; "Planning Buffer")
        {
            DataItemTableView = SORTING("Item No.", Date);
            RequestFilterFields = "Item No.", Date;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PlngBuffTableCaptFilter; PlanningBuffer.TableCaption + ': ' + PlanningFilter)
            {
            }
            column(PlanningFilter; PlanningFilter)
            {
            }
            column(ItemInventory; Item.Inventory)
            {
            }
            column(PlanningBuffItemNo; PlanningBuffer."Item No.")
            {
            }
            column(PlanningBuffDesc; PlanningBuffer.Description)
            {
            }
            column(ShowIntBody1; PrintBoolean and Selection)
            {
            }
            column(PlanningBuffDocNo; PlanningBuffer."Document No.")
            {
            }
            column(PlanningBuffDocType; Format(PlanningBuffer."Document Type"))
            {
            }
            column(ProjectedBalance; ProjectedBalance)
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlngBuffScheduledReceipts; PlanningBuffer."Scheduled Receipts")
            {
            }
            column(PlngBuffPlannedReceipts; PlanningBuffer."Planned Receipts")
            {
            }
            column(PlngBuffGrossRequirement; PlanningBuffer."Gross Requirement")
            {
            }
            column(PlanningBuffDate; Format(PlanningBuffer.Date))
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
                    PlanningBuffer.Find('-')
                else
                    if PlanningBuffer.Next = 0 then
                        CurrReport.Break();

                Item.SetRange("Date Filter", 0D, PlanningBuffer.Date);
                if Item.Get(PlanningBuffer."Item No.") then begin
                    PrintBoolean2 := true;
                    if PlanningBuffer."Item No." = OldItem then
                        PrintBoolean := false
                    else begin
                        PrintBoolean := true;
                        OldItem := PlanningBuffer."Item No.";
                        Item.CalcFields(Inventory);
                        ProjectedBalance := Item.Inventory;
                    end;

                    ProjectedBalance :=
                      ProjectedBalance -
                      PlanningBuffer."Gross Requirement" +
                      PlanningBuffer."Planned Receipts" +
                      PlanningBuffer."Scheduled Receipts";
                end else
                    PrintBoolean2 := false;
            end;

            trigger OnPreDataItem()
            begin
                TempForecastPlanningBuffer.Reset();
                TempForecastPlanningBuffer.SetFilter("Gross Requirement", '>0');
                if TempForecastPlanningBuffer.FindSet then
                    repeat
                        if Selection then begin
                            NewRecord;
                            PlanningBuffer := TempForecastPlanningBuffer;
                            PlanningBuffer."Buffer No." := BufferCounter;
                            PlanningBuffer.Insert();
                        end else begin
                            PlanningBuffer.SetRange("Item No.", TempForecastPlanningBuffer."Item No.");
                            PlanningBuffer.SetRange(Date, TempForecastPlanningBuffer.Date);
                            if PlanningBuffer.FindSet(true) then begin
                                PlanningBuffer."Gross Requirement" += TempForecastPlanningBuffer."Gross Requirement";
                                PlanningBuffer.Modify();
                            end else begin
                                NewRecord;
                                PlanningBuffer := TempForecastPlanningBuffer;
                                PlanningBuffer."Buffer No." := BufferCounter;
                                PlanningBuffer.Insert();
                            end;
                        end;
                    until TempForecastPlanningBuffer.Next = 0;

                PlanningBuffer.SetCurrentKey("Item No.", Date);
                PlanningBuffer.CopyFilters("Planning Buffer");
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
        PlanningFilter := "Planning Buffer".GetFilters;
    end;

    var
        PlanningBuffer: Record "Planning Buffer" temporary;
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

    local procedure NewRecord()
    begin
        PlanningBuffer.SetRange("Item No.");
        PlanningBuffer.SetRange(Date);

        if not PlanningBuffer.Find('+') then
            BufferCounter := 1
        else begin
            BufferCounter := PlanningBuffer."Buffer No." + 1;
            Clear(PlanningBuffer);
        end;
        PlanningBuffer."Buffer No." := BufferCounter;
    end;

    local procedure NewRecordWithDetails(NewDate: Date; NewItemNo: Code[20]; NewDescription: Text[100])
    begin
        NewRecord;
        PlanningBuffer.Date := NewDate;
        PlanningBuffer."Item No." := NewItemNo;
        PlanningBuffer.Description := NewDescription;
    end;

    local procedure InsertNewForecast(ProdForecastEntry: Record "Production Forecast Entry")
    begin
        TempForecastPlanningBuffer.Init();
        TempForecastPlanningBuffer."Buffer No." := BufferCounter;
        with ProdForecastEntry do begin
            TempForecastPlanningBuffer.Date := "Forecast Date";
            if "Component Forecast" then
                TempForecastPlanningBuffer."Document Type" := TempForecastPlanningBuffer."Document Type"::"Production Forecast-Component"
            else
                TempForecastPlanningBuffer."Document Type" := TempForecastPlanningBuffer."Document Type"::"Production Forecast-Sales";
            TempForecastPlanningBuffer."Document No." := "Production Forecast Name";
            TempForecastPlanningBuffer."Item No." := "Item No.";
            TempForecastPlanningBuffer.Description := Description;
            TempForecastPlanningBuffer."Gross Requirement" := "Forecast Quantity";
            TempForecastPlanningBuffer.Insert();
        end;
    end;

    local procedure ModifyForecast(ItemNo: Code[20]; Date: Date; DocumentType: Option; Quantity: Decimal)
    begin
        Clear(TempForecastPlanningBuffer);
        TempForecastPlanningBuffer.SetRange("Item No.", ItemNo);
        TempForecastPlanningBuffer.SetFilter(Date, '..%1', Date);
        TempForecastPlanningBuffer.SetRange("Document Type", DocumentType);
        if TempForecastPlanningBuffer.FindLast then begin
            TempForecastPlanningBuffer."Gross Requirement" -= Quantity;
            TempForecastPlanningBuffer.Modify();
        end;
    end;
}


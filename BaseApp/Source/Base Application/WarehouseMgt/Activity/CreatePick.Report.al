﻿namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

report 5754 "Create Pick"
{
    Caption = 'Create Pick';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                PickWhseWkshLine.SetFilter("Qty. to Handle (Base)", '>%1', 0);
                PickWhseWkshLineFilter.CopyFilters(PickWhseWkshLine);

                if PickWhseWkshLine.Find('-') then begin
                    if PickWhseWkshLine."Location Code" = '' then
                        Location.Init()
                    else
                        Location.Get(PickWhseWkshLine."Location Code");
                    repeat
                        CheckSourceDocument();
                        PickWhseWkshLine.CheckBin(PickWhseWkshLine."Location Code", PickWhseWkshLine."To Bin Code", true);
                        TempNo := TempNo + 1;

                        if PerWhseDoc then begin
                            PickWhseWkshLine.SetRange("Whse. Document Type", PickWhseWkshLine."Whse. Document Type");
                            PickWhseWkshLine.SetRange("Whse. Document No.", PickWhseWkshLine."Whse. Document No.");
                        end;
                        if PerDestination then begin
                            PickWhseWkshLine.SetRange("Destination Type", PickWhseWkshLine."Destination Type");
                            PickWhseWkshLine.SetRange("Destination No.", PickWhseWkshLine."Destination No.");
                            OnAfterGetRecordOnBeforeSetPickFiltersPerDestination(PickWhseWkshLine);
                            SetPickFilters();
                            PickWhseWkshLineFilter.CopyFilter("Destination Type", PickWhseWkshLine."Destination Type");
                            PickWhseWkshLineFilter.CopyFilter("Destination No.", PickWhseWkshLine."Destination No.");
                        end else begin
                            PickWhseWkshLineFilter.CopyFilter("Destination Type", PickWhseWkshLine."Destination Type");
                            PickWhseWkshLineFilter.CopyFilter("Destination No.", PickWhseWkshLine."Destination No.");
                            SetPickFilters();
                        end;
                        PickWhseWkshLineFilter.CopyFilter("Whse. Document Type", PickWhseWkshLine."Whse. Document Type");
                        PickWhseWkshLineFilter.CopyFilter("Whse. Document No.", PickWhseWkshLine."Whse. Document No.");
                        OnAfterGetRecordOnAfterPickWhseWkshLineFilterSetFilters(PickWhseWkshLineFilter, PickWhseWkshLine);
                    until not PickWhseWkshLine.Find('-');
                    CheckPickActivity();
                end else begin
                    IsHandled := false;
                    OnBeforeNothingToHandedErr(IsHandled, PickWhseWkshLineFilter);
                    if not IsHandled then
                        Error(NothingToHandedErr);
                end;
            end;

            trigger OnPreDataItem()
            var
                CreatePickParameters: Record "Create Pick Parameters";
            begin
                Clear(CreatePick);
                CreatePickParameters."Assigned ID" := AssignedID;
                CreatePickParameters."Sorting Method" := SortPick;
                CreatePickParameters."Max No. of Lines" := MaxNoOfLines;
                CreatePickParameters."Max No. of Source Doc." := MaxNoOfSourceDoc;
                CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandle;
                CreatePickParameters."Breakbulk Filter" := BreakbulkFilter;
                CreatePickParameters."Per Bin" := PerBin;
                CreatePickParameters."Per Zone" := PerZone;
                CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::"Pick Worksheet";
                CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
                OnPreDataItemOnBeforeCreatePickSetParameters(CreatePickParameters);

                CreatePick.SetParameters(CreatePickParameters);

                OnAfterIntegerOnPreDataItem();
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
                    group("Create Pick")
                    {
                        Caption = 'Create Pick';
                        field(PerWhseDoc; PerWhseDoc)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Whse. Document';
                            ToolTip = 'Specifies if you want to create separate pick documents for worksheet lines with the same warehouse source document.';
                        }
                        field(PerDestination; PerDestination)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Cust./Vend./Loc.';
                            ToolTip = 'Specifies if you want to create separate pick documents for each customer (sale orders), vendor (purchase return orders), and location (transfer orders).';
                        }
                        field(PerItem; PerItem)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Item';
                            ToolTip = 'Specifies if you want to create separate pick documents for each item in the pick worksheet.';
                        }
                        field(PerZone; PerZone)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per From Zone';
                            ToolTip = 'Specifies if you want to create separate pick documents for each zone that you will take the items from.';
                        }
                        field(PerBin; PerBin)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Bin';
                            ToolTip = 'Specifies if you want to create separate pick documents for each bin that you will take the items from.';
                        }
                        field(PerDate; PerDate)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Due Date';
                            ToolTip = 'Specifies if you want to create separate pick documents for source documents that have the same due date.';
                        }
                    }
                    field(MaxNoOfLines; MaxNoOfLines)
                    {
                        ApplicationArea = Warehouse;
                        BlankZero = true;
                        Caption = 'Max. No. of Pick Lines';
                        MinValue = 0;
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to create pick documents that have no more than the specified number of lines in each document.';
                    }
                    field(MaxNoOfSourceDoc; MaxNoOfSourceDoc)
                    {
                        ApplicationArea = Warehouse;
                        BlankZero = true;
                        Caption = 'Max. No. of Pick Source Docs.';
                        MinValue = 0;
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to create pick documents that each cover no more than the specified number of source documents.';
                    }
                    field(AssignedID; AssignedID)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Assigned User ID';
                        TableRelation = "Warehouse Employee";
                        ToolTip = 'Specifies the ID of the assigned user to perform the pick instruction.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            WhseEmployee: Record "Warehouse Employee";
                            LookupWhseEmployee: Page "Warehouse Employee List";
                        begin
                            WhseEmployee.SetCurrentKey("Location Code");
                            WhseEmployee.SetRange("Location Code", LocationCode);
                            LookupWhseEmployee.LookupMode(true);
                            LookupWhseEmployee.SetTableView(WhseEmployee);
                            if LookupWhseEmployee.RunModal() = ACTION::LookupOK then begin
                                LookupWhseEmployee.GetRecord(WhseEmployee);
                                AssignedID := WhseEmployee."User ID";
                            end;
                        end;

                        trigger OnValidate()
                        var
                            WhseEmployee: Record "Warehouse Employee";
                        begin
                            if AssignedID <> '' then
                                WhseEmployee.Get(AssignedID, LocationCode);
                        end;
                    }
                    field(SortPick; SortPick)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sorting Method for Pick Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies that you want to select from the available options to sort lines in the created pick document.';
                    }
                    field(BreakbulkFilter; BreakbulkFilter)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Set Breakbulk Filter';
                        ToolTip = 'Specifies if you do not want to view the intermediate breakbulk pick lines, when a larger unit of measure is converted to a smaller unit of measure and completely picked.';
                    }
                    field(DoNotFillQtytoHandle; DoNotFillQtytoHandle)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Do Not Fill Qty. to Handle';
                        ToolTip = 'Specifies if you want to leave the Quantity to Handle field in the created pick lines empty.';
                    }
                    field(PrintPick; PrintPick)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Print Pick';
                        ToolTip = 'Specifies that you want to print the pick documents when they are created.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if LocationCode <> '' then begin
                Location.Get(LocationCode);
                if Location."Use ADCS" then
                    DoNotFillQtytoHandle := true;
            end;

            OnAfterOnOpenPage(DoNotFillQtytoHandle);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnAfterOnPostReport(FirstPickNo, LastPickNo)
    end;

    var
        Location: Record Location;
        PickWhseWkshLineFilter: Record "Whse. Worksheet Line";
        Cust: Record Customer;
        LocationCode: Code[10];
        AssignedID: Code[50];
        FirstPickNo: Code[20];
        FirstSetPickNo: Code[20];
        LastPickNo: Code[20];
        MaxNoOfLines: Integer;
        MaxNoOfSourceDoc: Integer;
        TempNo: Integer;
        SortPick: Enum "Whse. Activity Sorting Method";
        PerDestination: Boolean;
        PerItem: Boolean;
        PerZone: Boolean;
        PerBin: Boolean;
        PerWhseDoc: Boolean;
        PerDate: Boolean;
        PrintPick: Boolean;
        DoNotFillQtytoHandle: Boolean;
        Text003: Label 'You can create a Pick only for the available quantity in %1 %2 = %3,%4 = %5,%6 = %7,%8 = %9.';
        BreakbulkFilter: Boolean;

        NothingToHandedErr: Label 'There is nothing to handle, because the worksheet lines do not contain a value for quantity to handle.';
        Text001: Label 'Pick activity no. %1 has been created.';
        Text002: Label 'Pick activities no. %1 to %2 have been created.';
        NothingToHandleErr: Label 'There is nothing to handle. %1.';
        SourceDocumentDoesNotExistErr: Label 'The %1 does not exist. Filters: %2.', Comment = '%1 = Table caption; %2 = filters';

    protected var
        PickWhseWkshLine: Record "Whse. Worksheet Line";
        CreatePick: Codeunit "Create Pick";

    local procedure CreateTempLine()
    var
        DummySalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PickWhseActivHeader: Record "Warehouse Activity Header";
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
        PickQty: Decimal;
        PickQtyBase: Decimal;
        OldFirstSetPickNo: Code[20];
        TotalQtyPickedBase: Decimal;
        PickListReportID: Integer;
        IsHandled: Boolean;
    begin
        PickWhseWkshLine.LockTable();
        repeat
            if Location."Bin Mandatory" and
               (not Location."Always Create Pick Line")
            then
                if PickWhseWkshLine.CalcAvailableQtyBase() < PickWhseWkshLine."Qty. to Handle (Base)" then
                    Error(
                      Text003,
                      PickWhseWkshLine.TableCaption(), PickWhseWkshLine.FieldCaption("Worksheet Template Name"),
                      PickWhseWkshLine."Worksheet Template Name", PickWhseWkshLine.FieldCaption(Name),
                      PickWhseWkshLine.Name, PickWhseWkshLine.FieldCaption("Location Code"),
                      PickWhseWkshLine."Location Code", PickWhseWkshLine.FieldCaption("Line No."),
                      PickWhseWkshLine."Line No.");

            PickWhseWkshLine.TestField("Qty. per Unit of Measure");
            CreatePick.SetWhseWkshLine(PickWhseWkshLine, TempNo);
            case PickWhseWkshLine."Whse. Document Type" of
                PickWhseWkshLine."Whse. Document Type"::Shipment:
                    begin
                        WarehouseShipmentLine.Get(PickWhseWkshLine."Whse. Document No.", PickWhseWkshLine."Whse. Document Line No.");
                        if not WarehouseShipmentLine."Assemble to Order" then
                            CreatePick.SetTempWhseItemTrkgLine(
                              PickWhseWkshLine."Whse. Document No.", Database::"Warehouse Shipment Line", '', 0,
                              PickWhseWkshLine."Whse. Document Line No.", PickWhseWkshLine."Location Code")
                        else
                            CreatePick.SetTempWhseItemTrkgLine(
                              PickWhseWkshLine."Source No.", Database::"Assembly Line", '', 0,
                              PickWhseWkshLine."Source Line No.", PickWhseWkshLine."Location Code");
                    end;
                PickWhseWkshLine."Whse. Document Type"::Assembly:
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWhseWkshLine."Whse. Document No.", Database::"Assembly Line", '', 0,
                      PickWhseWkshLine."Whse. Document Line No.", PickWhseWkshLine."Location Code");
                PickWhseWkshLine."Whse. Document Type"::"Internal Pick":
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWhseWkshLine."Whse. Document No.", Database::"Whse. Internal Pick Line", '', 0,
                      PickWhseWkshLine."Whse. Document Line No.", PickWhseWkshLine."Location Code");
                PickWhseWkshLine."Whse. Document Type"::Production:
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWhseWkshLine."Source No.", PickWhseWkshLine."Source Type", '', PickWhseWkshLine."Source Line No.",
                      PickWhseWkshLine."Source Subline No.", PickWhseWkshLine."Location Code");
                PickWhseWkshLine."Whse. Document Type"::Job:
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWhseWkshLine."Source No.", Database::"Job Planning Line", '', 0,
                      PickWhseWkshLine."Source Line No.", PickWhseWkshLine."Location Code");
                else // Movement Worksheet Line
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWhseWkshLine.Name, Database::"Prod. Order Component", PickWhseWkshLine."Worksheet Template Name",
                      0, PickWhseWkshLine."Line No.", PickWhseWkshLine."Location Code");
            end;

            PickQty := PickWhseWkshLine."Qty. to Handle";
            PickQtyBase := PickWhseWkshLine."Qty. to Handle (Base)";
            OnAfterSetQuantityToPick(PickWhseWkshLine, PickQty, PickQtyBase);
            if (PickQty > 0) and
               (PickWhseWkshLine."Destination Type" = PickWhseWkshLine."Destination Type"::Customer)
            then begin
                PickWhseWkshLine.TestField("Destination No.");
                Cust.Get(PickWhseWkshLine."Destination No.");
                IsHandled := false;
                OnCreateTempLineOnBeforeCustCheckBlockedCustOnDocs(PickWhseWkshLine, IsHandled);
                if not IsHandled then
                    case PickWhseWkshLine."Source Document" of
                        PickWhseWkshLine."Source Document"::"Sales Order":
                            Cust.CheckBlockedCustOnDocs(Cust, DummySalesHeader."Document Type"::Order, false, false);
                        PickWhseWkshLine."Source Document"::"Sales Return Order":
                            Cust.CheckBlockedCustOnDocs(Cust, DummySalesHeader."Document Type"::"Return Order", false, false);
                    end;
            end;

            CreatePick.SetCalledFromWksh(true);

            OnCreateTempLineOnBeforeCreatePickCreateTempLine(PickWhseWkshLine);
            with PickWhseWkshLine do
                CreatePick.CreateTempLine("Location Code", "Item No.", "Variant Code",
                  "Unit of Measure Code", '', "To Bin Code", "Qty. per Unit of Measure",
                  "Qty. Rounding Precision", "Qty. Rounding Precision (Base)", PickQty, PickQtyBase);

            TotalQtyPickedBase := CreatePick.GetActualQtyPickedBase();

            // Update/delete lines
            PickWhseWkshLine."Qty. to Handle (Base)" := PickWhseWkshLine.CalcBaseQty(PickWhseWkshLine."Qty. to Handle");
            if PickWhseWkshLine."Qty. (Base)" =
               PickWhseWkshLine."Qty. Handled (Base)" + TotalQtyPickedBase
            then
                PickWhseWkshLine.Delete(true)
            else begin
                PickWhseWkshLine."Qty. Handled" := PickWhseWkshLine."Qty. Handled" + PickWhseWkshLine.CalcQty(TotalQtyPickedBase);
                PickWhseWkshLine."Qty. Handled (Base)" := PickWhseWkshLine.CalcBaseQty(PickWhseWkshLine."Qty. Handled");
                PickWhseWkshLine."Qty. Outstanding" := PickWhseWkshLine.Quantity - PickWhseWkshLine."Qty. Handled";
                PickWhseWkshLine."Qty. Outstanding (Base)" := PickWhseWkshLine.CalcBaseQty(PickWhseWkshLine."Qty. Outstanding");
                PickWhseWkshLine."Qty. to Handle" := 0;
                PickWhseWkshLine."Qty. to Handle (Base)" := 0;
                OnBeforePickWhseWkshLineModify(PickWhseWkshLine);
                PickWhseWkshLine.Modify();
            end;
        until PickWhseWkshLine.Next() = 0;

        OldFirstSetPickNo := FirstSetPickNo;
        OnBeforeCreatePickWhseDocument(PickWhseWkshLine);
        CreatePick.CreateWhseDocument(FirstSetPickNo, LastPickNo, false);
        if FirstSetPickNo = OldFirstSetPickNo then
            exit;

        if FirstPickNo = '' then
            FirstPickNo := FirstSetPickNo;
        CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
        ItemTrackingMgt.UpdateWhseItemTrkgLines(TempWhseItemTrkgLine);
        Commit();

        PickWhseActivHeader.SetRange(Type, PickWhseActivHeader.Type::Pick);
        PickWhseActivHeader.SetRange("No.", FirstSetPickNo, LastPickNo);
        PickWhseActivHeader.Find('-');
        repeat
            if SortPick <> SortPick::None then
                PickWhseActivHeader.SortWhseDoc();
            Commit();
            if PrintPick then begin
                PickListReportID := Report::"Picking List";
                OnBeforePrintPickList(PickWhseActivHeader, PickListReportID, IsHandled);
                if not IsHandled then
                    WarehouseDocumentPrint.PrintPickHeader(PickWhseActivHeader);
            end;
        until PickWhseActivHeader.Next() = 0;
    end;

    procedure SetWkshPickLine(var PickWhseWkshLine2: Record "Whse. Worksheet Line")
    var
        SortingMethod: Option;
    begin
        PickWhseWkshLine.CopyFilters(PickWhseWkshLine2);
        LocationCode := PickWhseWkshLine2."Location Code";

        SortingMethod := SortPick;
        OnAfterSetWkshPickLine(PickWhseWkshLine2, SortingMethod);
        SortPick := "Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    procedure GetResultMessage() ReturnValue: Boolean
    begin
        if FirstPickNo <> '' then
            if FirstPickNo = LastPickNo then
                Message(Text001, FirstPickNo)
            else
                Message(Text002, FirstPickNo, LastPickNo);
        ReturnValue := FirstPickNo <> '';
        OnAfterGetResultMessage(ReturnValue);
        exit(ReturnValue);
    end;

    procedure InitializeReport(AssignedID2: Code[50]; MaxNoOfLines2: Integer; MaxNoOfSourceDoc2: Integer; SortPick2: Enum "Whse. Activity Sorting Method"; PerDestination2: Boolean;
                                                                                                                         PerItem2: Boolean;
                                                                                                                         PerZone2: Boolean;
                                                                                                                         PerBin2: Boolean;
                                                                                                                         PerWhseDoc2: Boolean;
                                                                                                                         PerDate2: Boolean;
                                                                                                                         PrintPick2: Boolean;
                                                                                                                         DoNotFillQtytoHandle2: Boolean;
                                                                                                                         BreakbulkFilter2: Boolean)
    begin
        AssignedID := AssignedID2;
        MaxNoOfLines := MaxNoOfLines2;
        MaxNoOfSourceDoc := MaxNoOfSourceDoc2;
        SortPick := SortPick2;
        PerDestination := PerDestination2;
        PerItem := PerItem2;
        PerZone := PerZone2;
        PerBin := PerBin2;
        PerWhseDoc := PerWhseDoc2;
        PerDate := PerDate2;
        PrintPick := PrintPick2;
        DoNotFillQtytoHandle := DoNotFillQtytoHandle2;
        BreakbulkFilter := BreakbulkFilter2;
    end;

    local procedure CheckPickActivity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPickActivity(IsHandled, FirstPickNo);
        if IsHandled then
            exit;

        if FirstPickNo = '' then
            Error(NothingToHandleErr, CreatePick.GetCannotBeHandledReason());
    end;

    local procedure SetPickFilters()
    begin
        OnBeforeSetPickFilters(PickWhseWkshLine);

        if PerItem then begin
            PickWhseWkshLine.SetRange("Item No.", PickWhseWkshLine."Item No.");
            if PerBin then
                SetPerBinFilters()
            else begin
                if not Location."Bin Mandatory" then
                    PickWhseWkshLineFilter.CopyFilter("Shelf No.", PickWhseWkshLine."Shelf No.");
                SetPerDateFilters();
            end;
            PickWhseWkshLineFilter.CopyFilter("Item No.", PickWhseWkshLine."Item No.");
        end else begin
            PickWhseWkshLineFilter.CopyFilter("Item No.", PickWhseWkshLine."Item No.");
            if PerBin then
                SetPerBinFilters()
            else begin
                if not Location."Bin Mandatory" then
                    PickWhseWkshLineFilter.CopyFilter("Shelf No.", PickWhseWkshLine."Shelf No.");
                SetPerDateFilters();
            end;
        end;

        OnAfterSetPickFilters(PickWhseWkshLine, PickWhseWkshLineFilter);
    end;

    local procedure SetPerBinFilters()
    begin
        if not Location."Bin Mandatory" then
            PickWhseWkshLine.SetRange("Shelf No.", PickWhseWkshLine."Shelf No.");
        if PerDate then begin
            PickWhseWkshLine.SetRange("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
        end else begin
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
        end;
        if not Location."Bin Mandatory" then
            PickWhseWkshLineFilter.CopyFilter("Shelf No.", PickWhseWkshLine."Shelf No.");
    end;

    local procedure SetPerDateFilters()
    begin
        if PerDate then begin
            PickWhseWkshLine.SetRange("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
        end else begin
            PickWhseWkshLineFilter.CopyFilter("Due Date", PickWhseWkshLine."Due Date");
            CreateTempLine();
        end;
    end;

    local procedure CheckSourceDocument()
    var
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        ProdOrderComp: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        case PickWhseWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.SetRange("Document Type", PickWhseWkshLine."Source Subtype");
                    SalesLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
                    SalesLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
                    if SalesLine.IsEmpty() then
                        Error(SourceDocumentDoesNotExistErr, SalesLine.TableCaption(), SalesLine.GetFilters());
                end;
            Database::"Purchase Line":
                begin
                    PurchLine.SetRange("Document Type", PickWhseWkshLine."Source Subtype");
                    PurchLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
                    PurchLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
                    if PurchLine.IsEmpty() then
                        Error(SourceDocumentDoesNotExistErr, PurchLine.TableCaption(), PurchLine.GetFilters());
                end;
            Database::"Transfer Line":
                begin
                    TransLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
                    TransLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
                    if TransLine.IsEmpty() then
                        Error(SourceDocumentDoesNotExistErr, TransLine.TableCaption(), TransLine.GetFilters());
                end;
            Database::"Prod. Order Component":
                begin
                    ProdOrderComp.SetRange(Status, PickWhseWkshLine."Source Subtype");
                    ProdOrderComp.SetRange("Prod. Order No.", PickWhseWkshLine."Source No.");
                    ProdOrderComp.SetRange("Prod. Order Line No.", PickWhseWkshLine."Source Line No.");
                    ProdOrderComp.SetRange("Line No.", PickWhseWkshLine."Source Subline No.");
                    if ProdOrderComp.IsEmpty() then
                        Error(SourceDocumentDoesNotExistErr, ProdOrderComp.TableCaption(), ProdOrderComp.GetFilters());
                end;
            Database::"Assembly Line":
                begin
                    AssemblyLine.SetRange("Document Type", PickWhseWkshLine."Source Subtype");
                    AssemblyLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
                    AssemblyLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
                    if AssemblyLine.IsEmpty() then
                        Error(SourceDocumentDoesNotExistErr, AssemblyLine.TableCaption(), AssemblyLine.GetFilters());
                end;
            Database::Job:
                begin
                    JobPlanningLine.SetRange("Job Contract Entry No.", PickWhseWkshLine."Source Line No.");
                    if not JobPlanningLine.FindFirst() then
                        Error(SourceDocumentDoesNotExistErr, JobPlanningLine.TableCaption(), JobPlanningLine.GetFilters());
                    JobPlanningLine.TestStatusOpen();
                end;
            Database::"Service Line":
                begin
                    ServiceLine.SetRange("Document Type", PickWhseWkshLine."Source Subtype");
                    ServiceLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
                    ServiceLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
                    if ServiceLine.IsEmpty() then
                        Error(SourceDocumentDoesNotExistErr, ServiceLine.TableCaption(), ServiceLine.GetFilters());
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetResultMessage(var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var DoNotFillQtytoHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPostReport(FirstPickNo: Code[20]; LastPickNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQuantityToPick(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var PickQty: Decimal; var PickQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPickFilters(var PickWhseWkshLine: Record "Whse. Worksheet Line"; var PickWhseWkshLineFilter: Record "Whse. Worksheet Line");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIntegerOnPreDataItem()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPickActivity(var IsHandled: Boolean; FirstPickNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickWhseDocument(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNothingToHandedErr(var IsHandled: Boolean; var PickWhseWkshLineFilter: Record "Whse. Worksheet Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickWhseWkshLineModify(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPickList(var PickWhseActivHeader: Record "Warehouse Activity Header"; var PickListReportID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPickFilters(var PickWhseWkshLine: Record "Whse. Worksheet Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWkshPickLine(PickWhseWkshLine: Record "Whse. Worksheet Line"; var SortPick: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnBeforeSetPickFiltersPerDestination(var PickWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterPickWhseWkshLineFilterSetFilters(var PickWhseWkshLineFilter: Record "Whse. Worksheet Line"; var PickWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemOnBeforeCreatePickSetParameters(var CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCustCheckBlockedCustOnDocs(PickWhseWkshLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCreatePickCreateTempLine(PickWhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;
}


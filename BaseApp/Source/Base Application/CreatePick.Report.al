report 5754 "Create Pick"
{
    Caption = 'Create Pick';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

            trigger OnAfterGetRecord()
            begin
                PickWkshLine.SetFilter("Qty. to Handle (Base)", '>%1', 0);
                PickWkshLineFilter.CopyFilters(PickWkshLine);

                if PickWkshLine.Find('-') then begin
                    if PickWkshLine."Location Code" = '' then
                        Location.Init
                    else
                        Location.Get(PickWkshLine."Location Code");
                    repeat
                        PickWkshLine.CheckBin(PickWkshLine."Location Code", PickWkshLine."To Bin Code", true);
                        TempNo := TempNo + 1;

                        if PerWhseDoc then begin
                            PickWkshLine.SetRange("Whse. Document Type", PickWkshLine."Whse. Document Type");
                            PickWkshLine.SetRange("Whse. Document No.", PickWkshLine."Whse. Document No.");
                        end;
                        if PerDestination then begin
                            PickWkshLine.SetRange("Destination Type", PickWkshLine."Destination Type");
                            PickWkshLine.SetRange("Destination No.", PickWkshLine."Destination No.");
                            SetPickFilters;
                            PickWkshLineFilter.CopyFilter("Destination Type", PickWkshLine."Destination Type");
                            PickWkshLineFilter.CopyFilter("Destination No.", PickWkshLine."Destination No.");
                        end else begin
                            PickWkshLineFilter.CopyFilter("Destination Type", PickWkshLine."Destination Type");
                            PickWkshLineFilter.CopyFilter("Destination No.", PickWkshLine."Destination No.");
                            SetPickFilters;
                        end;
                        PickWkshLineFilter.CopyFilter("Whse. Document Type", PickWkshLine."Whse. Document Type");
                        PickWkshLineFilter.CopyFilter("Whse. Document No.", PickWkshLine."Whse. Document No.");
                    until not PickWkshLine.Find('-');
                    CheckPickActivity;
                end else
                    Error(Text000);
            end;

            trigger OnPreDataItem()
            begin
                Clear(CreatePick);
                CreatePick.SetValues(
                  AssignedID, 0, SortPick, 1, MaxNoOfSourceDoc, MaxNoOfLines, PerZone,
                  DoNotFillQtytoHandle, BreakbulkFilter, PerBin);
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
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to create pick documents that have no more than the specified number of lines in each document.';
                    }
                    field(MaxNoOfSourceDoc; MaxNoOfSourceDoc)
                    {
                        ApplicationArea = Warehouse;
                        BlankZero = true;
                        Caption = 'Max. No. of Pick Source Docs.';
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
                            if LookupWhseEmployee.RunModal = ACTION::LookupOK then begin
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
                        OptionCaption = ' ,Item,Document,Shelf/Bin No.,Due Date,Destination,Bin Ranking,Action Type';
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
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'There is nothing to handle.';
        Text001: Label 'Pick activity no. %1 has been created.';
        Text002: Label 'Pick activities no. %1 to %2 have been created.';
        Location: Record Location;
        PickWkshLine: Record "Whse. Worksheet Line";
        PickWkshLineFilter: Record "Whse. Worksheet Line";
        Cust: Record Customer;
        CreatePick: Codeunit "Create Pick";
        LocationCode: Code[10];
        AssignedID: Code[50];
        FirstPickNo: Code[20];
        FirstSetPickNo: Code[20];
        LastPickNo: Code[20];
        MaxNoOfLines: Integer;
        MaxNoOfSourceDoc: Integer;
        TempNo: Integer;
        SortPick: Option " ",Item,Document,"Shelf No.","Due Date",Destination,"Bin Ranking","Action Type";
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
        NothingToHandleErr: Label 'There is nothing to handle. %1.';

    local procedure CreateTempLine()
    var
        PickWhseActivHeader: Record "Warehouse Activity Header";
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        PickQty: Decimal;
        PickQtyBase: Decimal;
        TempMaxNoOfSourceDoc: Integer;
        OldFirstSetPickNo: Code[20];
        TotalQtyPickedBase: Decimal;
    begin
        PickWkshLine.LockTable;
        repeat
            if Location."Bin Mandatory" and
               (not Location."Always Create Pick Line")
            then
                if PickWkshLine.CalcAvailableQtyBase < PickWkshLine."Qty. to Handle" then
                    Error(
                      Text003,
                      PickWkshLine.TableCaption, PickWkshLine.FieldCaption("Worksheet Template Name"),
                      PickWkshLine."Worksheet Template Name", PickWkshLine.FieldCaption(Name),
                      PickWkshLine.Name, PickWkshLine.FieldCaption("Location Code"),
                      PickWkshLine."Location Code", PickWkshLine.FieldCaption("Line No."),
                      PickWkshLine."Line No.");

            PickWkshLine.TestField("Qty. per Unit of Measure");
            CreatePick.SetWhseWkshLine(PickWkshLine, TempNo);
            case PickWkshLine."Whse. Document Type" of
                PickWkshLine."Whse. Document Type"::Shipment:
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWkshLine."Whse. Document No.", DATABASE::"Warehouse Shipment Line", '', 0,
                      PickWkshLine."Whse. Document Line No.", PickWkshLine."Location Code");
                PickWkshLine."Whse. Document Type"::Assembly:
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWkshLine."Whse. Document No.", DATABASE::"Assembly Line", '', 0,
                      PickWkshLine."Whse. Document Line No.", PickWkshLine."Location Code");
                PickWkshLine."Whse. Document Type"::"Internal Pick":
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWkshLine."Whse. Document No.", DATABASE::"Whse. Internal Pick Line", '', 0,
                      PickWkshLine."Whse. Document Line No.", PickWkshLine."Location Code");
                PickWkshLine."Whse. Document Type"::Production:
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWkshLine."Source No.", PickWkshLine."Source Type", '', PickWkshLine."Source Line No.",
                      PickWkshLine."Source Subline No.", PickWkshLine."Location Code");
                else // Movement Worksheet Line
                    CreatePick.SetTempWhseItemTrkgLine(
                      PickWkshLine.Name, DATABASE::"Prod. Order Component", PickWkshLine."Worksheet Template Name",
                      0, PickWkshLine."Line No.", PickWkshLine."Location Code");
            end;

            PickQty := PickWkshLine."Qty. to Handle";
            PickQtyBase := PickWkshLine."Qty. to Handle (Base)";
            OnAfterSetQuantityToPick(PickWkshLine, PickQty, PickQtyBase);
            if (PickQty > 0) and
               (PickWkshLine."Destination Type" = PickWkshLine."Destination Type"::Customer)
            then begin
                PickWkshLine.TestField("Destination No.");
                Cust.Get(PickWkshLine."Destination No.");
                Cust.CheckBlockedCustOnDocs(Cust, PickWkshLine."Source Document", false, false);
            end;

            CreatePick.SetCalledFromWksh(true);

            with PickWkshLine do
                CreatePick.CreateTempLine("Location Code", "Item No.", "Variant Code",
                  "Unit of Measure Code", '', "To Bin Code", "Qty. per Unit of Measure", PickQty, PickQtyBase);

            TotalQtyPickedBase := CreatePick.GetActualQtyPickedBase;

            // Update/delete lines
            PickWkshLine."Qty. to Handle (Base)" := PickWkshLine.CalcBaseQty(PickWkshLine."Qty. to Handle");
            if PickWkshLine."Qty. (Base)" =
               PickWkshLine."Qty. Handled (Base)" + TotalQtyPickedBase
            then
                PickWkshLine.Delete(true)
            else begin
                PickWkshLine."Qty. Handled" := PickWkshLine."Qty. Handled" + PickWkshLine.CalcQty(TotalQtyPickedBase);
                PickWkshLine."Qty. Handled (Base)" := PickWkshLine.CalcBaseQty(PickWkshLine."Qty. Handled");
                PickWkshLine."Qty. Outstanding" := PickWkshLine.Quantity - PickWkshLine."Qty. Handled";
                PickWkshLine."Qty. Outstanding (Base)" := PickWkshLine.CalcBaseQty(PickWkshLine."Qty. Outstanding");
                PickWkshLine."Qty. to Handle" := 0;
                PickWkshLine."Qty. to Handle (Base)" := 0;
                PickWkshLine.Modify;
            end;
        until PickWkshLine.Next = 0;

        OldFirstSetPickNo := FirstSetPickNo;
        CreatePick.CreateWhseDocument(FirstSetPickNo, LastPickNo, false);
        if FirstSetPickNo = OldFirstSetPickNo then
            exit;

        if FirstPickNo = '' then
            FirstPickNo := FirstSetPickNo;
        CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
        ItemTrackingMgt.UpdateWhseItemTrkgLines(TempWhseItemTrkgLine);
        Commit;

        TempMaxNoOfSourceDoc := MaxNoOfSourceDoc;
        PickWhseActivHeader.SetRange(Type, PickWhseActivHeader.Type::Pick);
        PickWhseActivHeader.SetRange("No.", FirstSetPickNo, LastPickNo);
        PickWhseActivHeader.Find('-');
        repeat
            if SortPick > 0 then
                PickWhseActivHeader.SortWhseDoc;
            Commit;
            if PrintPick then begin
                REPORT.Run(REPORT::"Picking List", false, false, PickWhseActivHeader);
                TempMaxNoOfSourceDoc -= 1;
            end;
        until ((PickWhseActivHeader.Next = 0) or (TempMaxNoOfSourceDoc = 0));
    end;

    procedure SetWkshPickLine(var PickWkshLine2: Record "Whse. Worksheet Line")
    begin
        PickWkshLine.CopyFilters(PickWkshLine2);
        LocationCode := PickWkshLine2."Location Code";
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

    procedure InitializeReport(AssignedID2: Code[50]; MaxNoOfLines2: Integer; MaxNoOfSourceDoc2: Integer; SortPick2: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; PerDestination2: Boolean; PerItem2: Boolean; PerZone2: Boolean; PerBin2: Boolean; PerWhseDoc2: Boolean; PerDate2: Boolean; PrintPick2: Boolean; DoNotFillQtytoHandle2: Boolean; BreakbulkFilter2: Boolean)
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
        OnBeforeCheckPickActivity(IsHandled);
        if IsHandled then
            exit;

        if FirstPickNo = '' then
            Error(NothingToHandleErr, CreatePick.GetCannotBeHandledReason);
    end;

    local procedure SetPickFilters()
    begin
        if PerItem then begin
            PickWkshLine.SetRange("Item No.", PickWkshLine."Item No.");
            if PerBin then
                SetPerBinFilters
            else begin
                if not Location."Bin Mandatory" then
                    PickWkshLineFilter.CopyFilter("Shelf No.", PickWkshLine."Shelf No.");
                SetPerDateFilters;
            end;
            PickWkshLineFilter.CopyFilter("Item No.", PickWkshLine."Item No.");
        end else begin
            PickWkshLineFilter.CopyFilter("Item No.", PickWkshLine."Item No.");
            if PerBin then
                SetPerBinFilters
            else begin
                if not Location."Bin Mandatory" then
                    PickWkshLineFilter.CopyFilter("Shelf No.", PickWkshLine."Shelf No.");
                SetPerDateFilters;
            end;
        end;
    end;

    local procedure SetPerBinFilters()
    begin
        if not Location."Bin Mandatory" then
            PickWkshLine.SetRange("Shelf No.", PickWkshLine."Shelf No.");
        if PerDate then begin
            PickWkshLine.SetRange("Due Date", PickWkshLine."Due Date");
            CreateTempLine;
            PickWkshLineFilter.CopyFilter("Due Date", PickWkshLine."Due Date");
        end else begin
            PickWkshLineFilter.CopyFilter("Due Date", PickWkshLine."Due Date");
            CreateTempLine;
        end;
        if not Location."Bin Mandatory" then
            PickWkshLineFilter.CopyFilter("Shelf No.", PickWkshLine."Shelf No.");
    end;

    local procedure SetPerDateFilters()
    begin
        if PerDate then begin
            PickWkshLine.SetRange("Due Date", PickWkshLine."Due Date");
            CreateTempLine;
            PickWkshLineFilter.CopyFilter("Due Date", PickWkshLine."Due Date");
        end else begin
            PickWkshLineFilter.CopyFilter("Due Date", PickWkshLine."Due Date");
            CreateTempLine;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetResultMessage(var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQuantityToPick(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var PickQty: Decimal; var PickQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPickActivity(var IsHandled: Boolean)
    begin
    end;
}


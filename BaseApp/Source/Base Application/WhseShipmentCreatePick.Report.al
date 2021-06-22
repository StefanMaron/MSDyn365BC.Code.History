report 7318 "Whse.-Shipment - Create Pick"
{
    Caption = 'Whse.-Shipment - Create Pick';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
        {
            DataItemTableView = SORTING("No.", "Line No.");
            dataitem("Assembly Header"; "Assembly Header")
            {
                DataItemTableView = SORTING("Document Type", "No.");
                dataitem("Assembly Line"; "Assembly Line")
                {
                    DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                    DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        WMSMgt: Codeunit "WMS Management";
                    begin
                        WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "No.", "Variant Code", "Unit of Measure Code");

                        WhseWkshLine.SetRange("Source Line No.", "Line No.");
                        if not WhseWkshLine.FindFirst then
                            CreatePick.CreateAssemblyPickLine("Assembly Line")
                        else
                            WhseWkshLineFound := true;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Type, Type::Item);
                        SetFilter("Remaining Quantity (Base)", '>0');

                        WhseWkshLine.SetCurrentKey(
                          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                        WhseWkshLine.SetRange("Source Type", DATABASE::"Assembly Line");
                        WhseWkshLine.SetRange("Source Subtype", "Assembly Header"."Document Type");
                        WhseWkshLine.SetRange("Source No.", "Assembly Header"."No.");
                    end;
                }

                trigger OnPreDataItem()
                var
                    SalesLine: Record "Sales Line";
                begin
                    if not "Warehouse Shipment Line"."Assemble to Order" then
                        CurrReport.Break();

                    SalesLine.Get("Warehouse Shipment Line"."Source Subtype",
                      "Warehouse Shipment Line"."Source No.",
                      "Warehouse Shipment Line"."Source Line No.");
                    SalesLine.AsmToOrderExists("Assembly Header");
                    SetRange("Document Type", "Document Type");
                    SetRange("No.", "No.");
                end;
            }

            trigger OnAfterGetRecord()
            var
                QtyToPick: Decimal;
                QtyToPickBase: Decimal;
            begin
                if Location."Directed Put-away and Pick" then
                    CheckBin(0, 0);

                WhseWkshLine.Reset();
                WhseWkshLine.SetCurrentKey(
                  "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                WhseWkshLine.SetRange(
                  "Whse. Document Type", WhseWkshLine."Whse. Document Type"::Shipment);
                WhseWkshLine.SetRange("Whse. Document No.", WhseShptHeader."No.");
                WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                OnAfterSetWhseWkshLineFilters(WhseWkshLine, "Warehouse Shipment Line", WhseShptHeader);
                if not WhseWkshLine.FindFirst then begin
                    TestField("Qty. per Unit of Measure");
                    CalcFields("Pick Qty. (Base)", "Pick Qty.");
                    QtyToPickBase := "Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)");
                    QtyToPick := Quantity - ("Qty. Picked" + "Pick Qty.");
                    OnAfterCalculateQuantityToPick("Warehouse Shipment Line", QtyToPick, QtyToPickBase);
                    if QtyToPick > 0 then begin
                        if "Destination Type" = "Destination Type"::Customer then begin
                            TestField("Destination No.");
                            Cust.Get("Destination No.");
                            Cust.CheckBlockedCustOnDocs(Cust, "Source Document", false, false);
                        end;

                        CreatePick.SetWhseShipment(
                          "Warehouse Shipment Line", 1, WhseShptHeader."Shipping Agent Code",
                          WhseShptHeader."Shipping Agent Service Code", WhseShptHeader."Shipment Method Code");
                        if not "Assemble to Order" then begin
                            CreatePick.SetTempWhseItemTrkgLine(
                              "No.", DATABASE::"Warehouse Shipment Line",
                              '', 0, "Line No.", "Location Code");
                            CreatePick.CreateTempLine(
                              "Location Code", "Item No.", "Variant Code", "Unit of Measure Code",
                              '', "Bin Code", "Qty. per Unit of Measure", QtyToPick, QtyToPickBase);
                        end;
                    end;
                end else
                    WhseWkshLineFound := true;
            end;

            trigger OnPostDataItem()
            var
                TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                ItemTrackingMgt: Codeunit "Item Tracking Management";
            begin
                CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
                if TempWhseItemTrkgLine.Find('-') then
                    repeat
                        ItemTrackingMgt.CalcWhseItemTrkgLine(TempWhseItemTrkgLine);
                    until TempWhseItemTrkgLine.Next = 0;
            end;

            trigger OnPreDataItem()
            begin
                CreatePick.SetValues(
                  AssignedID, 1, SortActivity, 1, 0, 0, false, DoNotFillQtytoHandle, BreakbulkFilter, false);

                CopyFilters(WhseShptLine);
                SetFilter("Qty. (Base)", '>0');
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
                            WhseEmployee.SetRange("Location Code", Location.Code);
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
                                WhseEmployee.Get(AssignedID, Location.Code);
                        end;
                    }
                    field(SortingMethodForActivityLines; SortActivity)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sorting Method for Activity Lines';
                        MultiLine = true;
                        OptionCaption = ' ,Item,Document,Shelf or Bin,Due Date,Destination,Bin Ranking,Action Type';
                        ToolTip = 'Specifies the method by which the lines in the instruction will be sorted. The options are by item, document, shelf or bin (if the location uses bins, this functions as the bin code), due date, bin ranking, or action type.';
                    }
                    field(BreakbulkFilter; BreakbulkFilter)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Set Breakbulk Filter';
                        ToolTip = 'Specifies if you want the program to hide intermediate break-bulk lines when an entire larger unit of measure is converted to a smaller unit of measure and picked completely.';
                    }
                    field(DoNotFillQtytoHandle; DoNotFillQtytoHandle)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Do Not Fill Qty. to Handle';
                        ToolTip = 'Specifies if you want to manually fill in the Quantity to Handle field on each line.';
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Print Document';
                        ToolTip = 'Specifies if you want the pick document to be printed. Otherwise, you can print it later from the Whse. Pick window.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Location."Use ADCS" then
                DoNotFillQtytoHandle := true;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        CreatePick.CreateWhseDocument(FirstActivityNo, LastActivityNo, true);

        CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
        ItemTrackingMgt.UpdateWhseItemTrkgLines(TempWhseItemTrkgLine);

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Pick);
        WhseActivHeader.SetRange("No.", FirstActivityNo, LastActivityNo);
        OnBeforeSortWhseActivHeaders(WhseActivHeader, FirstActivityNo, LastActivityNo, HideNothingToHandleErr);
        if WhseActivHeader.Find('-') then begin
            repeat
                if SortActivity > 0 then
                    WhseActivHeader.SortWhseDoc;
            until WhseActivHeader.Next = 0;

            if PrintDoc then begin
                IsHandled := false;
                OnBeforePrintPickingList(WhseActivHeader, IsHandled);
                if not IsHandled then
                    REPORT.Run(REPORT::"Picking List", false, false, WhseActivHeader);
            end;
        end else
            if not HideNothingToHandleErr then
                Error(NothingToHandleErr);

        OnAfterPostReport(FirstActivityNo, LastActivityNo);
    end;

    trigger OnPreReport()
    begin
        Clear(CreatePick);
        EverythingHandled := true;
    end;

    var
        Location: Record Location;
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        Cust: Record Customer;
        CreatePick: Codeunit "Create Pick";
        FirstActivityNo: Code[20];
        LastActivityNo: Code[20];
        AssignedID: Code[50];
        SortActivity: Option " ",Item,Document,"Shelf or Bin","Due Date",Destination,"Bin Ranking","Action Type";
        PrintDoc: Boolean;
        EverythingHandled: Boolean;
        WhseWkshLineFound: Boolean;
        HideValidationDialog: Boolean;
        HideNothingToHandleErr: Boolean;
        DoNotFillQtytoHandle: Boolean;
        BreakbulkFilter: Boolean;
        SingleActivCreatedMsg: Label '%1 activity no. %2 has been created.%3', Comment = '%1=WhseActivHeader.Type;%2=Whse. Activity No.;%3=Concatenates ExpiredItemMessageText';
        SingleActivAndWhseShptCreatedMsg: Label '%1 activity no. %2 has been created.\For Warehouse Shipment lines that have existing Pick Worksheet lines, no %3 lines have been created.%4', Comment = '%1=WhseActivHeader.Type;%2=Whse. Activity No.;%3=WhseActivHeader.Type;%4=Concatenates ExpiredItemMessageText';
        MultipleActivCreatedMsg: Label '%1 activities no. %2 to %3 have been created.%4', Comment = '%1=WhseActivHeader.Type;%2=First Whse. Activity No.;%3=Last Whse. Activity No.;%4=Concatenates ExpiredItemMessageText';
        MultipleActivAndWhseShptCreatedMsg: Label '%1 activities no. %2 to %3 have been created.\For Warehouse Shipment lines that have existing Pick Worksheet lines, no %4 lines have been created.%5', Comment = '%1=WhseActivHeader.Type;%2=First Whse. Activity No.;%3=Last Whse. Activity No.;%4=WhseActivHeader.Type;%5=Concatenates ExpiredItemMessageText';
        NothingToHandleErr: Label 'There is nothing to handle.';

    procedure SetWhseShipmentLine(var WhseShptLine2: Record "Warehouse Shipment Line"; WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptLine.Copy(WhseShptLine2);
        WhseShptHeader := WhseShptHeader2;
        AssignedID := WhseShptHeader2."Assigned User ID";
        GetLocation(WhseShptLine."Location Code");
    end;

    procedure GetResultMessage(): Boolean
    var
        WhseActivHeader: Record "Warehouse Activity Header";
        CannotBeHandledReason: Text;
    begin
        CannotBeHandledReason := CreatePick.GetCannotBeHandledReason;
        if FirstActivityNo = '' then
            exit(false);

        if not HideValidationDialog then begin
            WhseActivHeader.Type := WhseActivHeader.Type::Pick;
            if WhseWkshLineFound then begin
                if FirstActivityNo = LastActivityNo then
                    Message(
                      StrSubstNo(
                        SingleActivAndWhseShptCreatedMsg, Format(WhseActivHeader.Type), FirstActivityNo,
                        Format(WhseActivHeader.Type), CannotBeHandledReason))
                else
                    Message(
                      StrSubstNo(
                        MultipleActivAndWhseShptCreatedMsg, Format(WhseActivHeader.Type), FirstActivityNo, LastActivityNo,
                        Format(WhseActivHeader.Type), CannotBeHandledReason));
            end else begin
                if FirstActivityNo = LastActivityNo then
                    Message(
                      StrSubstNo(SingleActivCreatedMsg, Format(WhseActivHeader.Type), FirstActivityNo, CannotBeHandledReason))
                else
                    Message(
                      StrSubstNo(MultipleActivCreatedMsg, Format(WhseActivHeader.Type),
                        FirstActivityNo, LastActivityNo, CannotBeHandledReason));
            end;
        end;
        exit(EverythingHandled);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure SetHideNothingToHandleError(HideNothingToHandleError: Boolean)
    begin
        HideNothingToHandleErr := HideNothingToHandleError;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then begin
            if LocationCode = '' then
                Clear(Location)
            else
                Location.Get(LocationCode);
        end;
    end;

    procedure Initialize(AssignedID2: Code[50]; SortActivity2: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; PrintDoc2: Boolean; DoNotFillQtytoHandle2: Boolean; BreakbulkFilter2: Boolean)
    begin
        AssignedID := AssignedID2;
        SortActivity := SortActivity2;
        PrintDoc := PrintDoc2;
        DoNotFillQtytoHandle := DoNotFillQtytoHandle2;
        BreakbulkFilter := BreakbulkFilter2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQuantityToPick(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var QtyToPick: Decimal; var QtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(var FirstActivityNo: Code[20]; var LastActivityNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseWkshLineFilters(var WhseWkshLine: Record "Whse. Worksheet Line"; WhseShipmentLine: Record "Warehouse Shipment Line"; WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPickingList(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortWhseActivHeaders(var WhseActivHeader: Record "Warehouse Activity Header"; FirstActivityNo: Code[20]; LastActivityNo: Code[20]; var HideNothingToHandleError: Boolean)
    begin
    end;
}


report 7305 "Whse.-Source - Create Document"
{
    Caption = 'Whse.-Source - Create Document';
    Permissions = TableData "Whse. Item Tracking Line" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
        {
            DataItemTableView = SORTING("No.", "Line No.");

            trigger OnAfterGetRecord()
            var
                PostedWhseReceiptLine2: Record "Posted Whse. Receipt Line";
                TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                WMSMgt: Codeunit "WMS Management";
                ItemTrackingManagement: Codeunit "Item Tracking Management";
            begin
                WMSMgt.CheckOutboundBlockedBin("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");

                WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                if not WhseWkshLine.FindFirst then begin
                    PostedWhseReceiptLine2 := "Posted Whse. Receipt Line";
                    PostedWhseReceiptLine2.TestField("Qty. per Unit of Measure");
                    PostedWhseReceiptLine2.CalcFields("Put-away Qty. (Base)");
                    PostedWhseReceiptLine2."Qty. (Base)" :=
                      PostedWhseReceiptLine2."Qty. (Base)" -
                      (PostedWhseReceiptLine2."Qty. Put Away (Base)" +
                       PostedWhseReceiptLine2."Put-away Qty. (Base)");
                    if PostedWhseReceiptLine2."Qty. (Base)" > 0 then begin
                        PostedWhseReceiptLine2.Quantity :=
                          Round(
                            PostedWhseReceiptLine2."Qty. (Base)" /
                            PostedWhseReceiptLine2."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

                        if ItemTrackingManagement.GetWhseItemTrkgSetup("Item No.") then
                            ItemTrackingManagement.InitItemTrkgForTempWkshLine(
                              WhseWkshLine."Whse. Document Type"::Receipt,
                              PostedWhseReceiptLine2."No.",
                              PostedWhseReceiptLine2."Line No.",
                              PostedWhseReceiptLine2."Source Type",
                              PostedWhseReceiptLine2."Source Subtype",
                              PostedWhseReceiptLine2."Source No.",
                              PostedWhseReceiptLine2."Source Line No.",
                              0);

                        CreatePutAway.SetCrossDockValues(PostedWhseReceiptLine2."Qty. Cross-Docked" <> 0);
                        CreatePutAwayFromDiffSource(PostedWhseReceiptLine2, DATABASE::"Posted Whse. Receipt Line");
                        CreatePutAway.GetQtyHandledBase(TempWhseItemTrkgLine);
                        UpdateWhseItemTrkgLines(PostedWhseReceiptLine2, DATABASE::"Posted Whse. Receipt Line", TempWhseItemTrkgLine);

                        if CreateErrorText = '' then
                            CreatePutAway.GetMessage(CreateErrorText);
                        if EverythingHandled then
                            EverythingHandled := CreatePutAway.EverythingIsHandled;
                    end;
                end;
            end;

            trigger OnPostDataItem()
            begin
                OnAfterPostedWhseReceiptLineOnPostDataItem("Posted Whse. Receipt Line");
            end;

            trigger OnPreDataItem()
            begin
                if WhseDoc <> WhseDoc::"Posted Receipt" then
                    CurrReport.Break();

                CreatePutAway.SetValues(AssignedID, SortActivity, DoNotFillQtytoHandle, BreakbulkFilter);
                CopyFilters(PostedWhseReceiptLine);

                WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                WhseWkshLine.SetRange(
                  "Whse. Document Type", WhseWkshLine."Whse. Document Type"::Receipt);
                WhseWkshLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
            end;
        }
        dataitem("Whse. Mov.-Worksheet Line"; "Whse. Worksheet Line")
        {
            DataItemTableView = SORTING("Worksheet Template Name", Name, "Location Code", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if FEFOLocation("Location Code") and ItemTracking("Item No.") then
                    CreatePick.SetCalledFromWksh(true)
                else
                    CreatePick.SetCalledFromWksh(false);

                TestField("Qty. per Unit of Measure");
                if WhseWkshLine.CheckAvailQtytoMove < 0 then
                    Error(
                      Text004,
                      TableCaption, FieldCaption("Worksheet Template Name"), "Worksheet Template Name",
                      FieldCaption(Name), Name, FieldCaption("Location Code"), "Location Code",
                      FieldCaption("Line No."), "Line No.");

                CheckBin("Location Code", "From Bin Code", false);
                CheckBin("Location Code", "To Bin Code", true);
                CheckAvailabilityWithTracking("Whse. Mov.-Worksheet Line");
                UpdateWkshMovementLineBuffer("Whse. Mov.-Worksheet Line");
            end;

            trigger OnPostDataItem()
            var
                PickQty: Decimal;
                PickQtyBase: Decimal;
                QtyHandled: Decimal;
                QtyHandledBase: Decimal;
            begin
                if TempWhseWorksheetLineMovement.IsEmpty then
                    CurrReport.Skip();

                TempWhseWorksheetLineMovement.FindSet;
                repeat
                    CreateMovementLines(TempWhseWorksheetLineMovement, PickQty, PickQtyBase);
                    QtyHandled := TempWhseWorksheetLineMovement."Qty. to Handle" - PickQty;
                    QtyHandledBase := TempWhseWorksheetLineMovement."Qty. to Handle (Base)" - PickQtyBase;
                    UpdateMovementWorksheet(TempWhseWorksheetLineMovement, QtyHandled, QtyHandledBase);
                until TempWhseWorksheetLineMovement.Next = 0;
            end;

            trigger OnPreDataItem()
            begin
                if WhseDoc <> WhseDoc::"Whse. Mov.-Worksheet" then
                    CurrReport.Break();

                CreatePick.SetValues(
                  AssignedID, 2, SortActivity, 2, 0, 0, false, DoNotFillQtytoHandle, BreakbulkFilter, false);

                CreatePick.SetCalledFromMoveWksh(true);

                CopyFilters(WhseWkshLine);
                SetFilter("Qty. to Handle (Base)", '>0');
                LockTable();

                TempWhseWorksheetLineMovement.Reset();
                TempWhseWorksheetLineMovement.DeleteAll();

                OnBeforeProcessWhseMovWkshLines("Whse. Mov.-Worksheet Line");
            end;
        }
        dataitem("Whse. Put-away Worksheet Line"; "Whse. Worksheet Line")
        {
            DataItemTableView = SORTING("Worksheet Template Name", Name, "Location Code", "Line No.") WHERE("Whse. Document Type" = FILTER(Receipt | "Internal Put-away"));

            trigger OnAfterGetRecord()
            var
                PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
                TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                QtyHandledBase: Decimal;
                SourceType: Integer;
            begin
                LockTable();

                CheckBin("Location Code", "From Bin Code", false);

                InitPostedWhseReceiptLineFromPutAway(PostedWhseRcptLine, "Whse. Put-away Worksheet Line", SourceType);

                CreatePutAway.SetCrossDockValues(PostedWhseRcptLine."Qty. Cross-Docked" <> 0);
                CreatePutAwayFromDiffSource(PostedWhseRcptLine, SourceType);

                if "Qty. to Handle" <> "Qty. Outstanding" then
                    EverythingHandled := false;

                if EverythingHandled then
                    EverythingHandled := CreatePutAway.EverythingIsHandled;

                QtyHandledBase := CreatePutAway.GetQtyHandledBase(TempWhseItemTrkgLine);

                if QtyHandledBase > 0 then begin
                    // update/delete line
                    WhseWkshLine := "Whse. Put-away Worksheet Line";
                    WhseWkshLine.Validate("Qty. Handled (Base)", "Qty. Handled (Base)" + QtyHandledBase);
                    if (WhseWkshLine."Qty. Outstanding" = 0) and
                       (WhseWkshLine."Qty. Outstanding (Base)" = 0)
                    then
                        WhseWkshLine.Delete
                    else
                        WhseWkshLine.Modify();
                    UpdateWhseItemTrkgLines(PostedWhseRcptLine, SourceType, TempWhseItemTrkgLine);
                end else
                    if CreateErrorText = '' then
                        CreatePutAway.GetMessage(CreateErrorText);
            end;

            trigger OnPreDataItem()
            begin
                if WhseDoc <> WhseDoc::"Put-away Worksheet" then
                    CurrReport.Break();

                CreatePutAway.SetValues(AssignedID, SortActivity, DoNotFillQtytoHandle, BreakbulkFilter);

                CopyFilters(WhseWkshLine);
                SetFilter("Qty. to Handle (Base)", '>0');
            end;
        }
        dataitem("Whse. Internal Pick Line"; "Whse. Internal Pick Line")
        {
            DataItemTableView = SORTING("No.", "Line No.");

            trigger OnAfterGetRecord()
            var
                WMSMgt: Codeunit "WMS Management";
                QtyToPick: Decimal;
                QtyToPickBase: Decimal;
            begin
                WMSMgt.CheckInboundBlockedBin("Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");

                CheckBin(false);
                WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                if not WhseWkshLine.FindFirst then begin
                    TestField("Qty. per Unit of Measure");
                    CalcFields("Pick Qty. (Base)");
                    QtyToPickBase := "Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)");
                    QtyToPick :=
                      Round(
                        ("Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)")) /
                        "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    if QtyToPick > 0 then begin
                        CreatePick.SetWhseInternalPickLine("Whse. Internal Pick Line", 1);
                        CreatePick.SetTempWhseItemTrkgLine(
                          "No.", DATABASE::"Whse. Internal Pick Line", '', 0, "Line No.", "Location Code");
                        CreatePick.CreateTempLine(
                          "Location Code", "Item No.", "Variant Code", "Unit of Measure Code",
                          '', "To Bin Code", "Qty. per Unit of Measure", QtyToPick, QtyToPickBase);
                    end;
                end else
                    WhseWkshLineFound := true;
            end;

            trigger OnPreDataItem()
            begin
                if WhseDoc <> WhseDoc::"Internal Pick" then
                    CurrReport.Break();

                CreatePick.SetValues(
                  AssignedID, 3, SortActivity, 1, 0, 0, false, DoNotFillQtytoHandle, BreakbulkFilter, false);

                CopyFilters(WhseInternalPickLine);
                SetFilter("Qty. (Base)", '>0');

                WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                WhseWkshLine.SetRange(
                  "Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Pick");
                WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPickLine."No.");
            end;
        }
        dataitem("Whse. Internal Put-away Line"; "Whse. Internal Put-away Line")
        {
            DataItemTableView = SORTING("No.", "Line No.");

            trigger OnAfterGetRecord()
            var
                TempWhseItemTrkgLine: Record "Whse. Item Tracking Line" temporary;
                WMSMgt: Codeunit "WMS Management";
                QtyToPutAway: Decimal;
            begin
                WMSMgt.CheckOutboundBlockedBin("Location Code", "From Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
                CheckCurrentLineQty;
                WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
                if not WhseWkshLine.FindFirst then begin
                    TestField("Qty. per Unit of Measure");
                    CalcFields("Put-away Qty. (Base)");
                    QtyToPutAway :=
                      Round(
                        ("Qty. (Base)" - ("Qty. Put Away (Base)" + "Put-away Qty. (Base)")) /
                        "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

                    if QtyToPutAway > 0 then begin
                        InitPostedWhseReceiptLineFromInternalPutAway(PostedWhseReceiptLine, "Whse. Internal Put-away Line", QtyToPutAway);

                        CreatePutAwayFromDiffSource(PostedWhseReceiptLine, DATABASE::"Whse. Internal Put-away Line");
                        CreatePutAway.GetQtyHandledBase(TempWhseItemTrkgLine);

                        UpdateWhseItemTrkgLines(PostedWhseReceiptLine, DATABASE::"Whse. Internal Put-away Line", TempWhseItemTrkgLine);
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if WhseDoc <> WhseDoc::"Internal Put-away" then
                    CurrReport.Break();

                CreatePutAway.SetValues(AssignedID, SortActivity, DoNotFillQtytoHandle, BreakbulkFilter);

                SetRange("No.", WhseInternalPutAwayHeader."No.");
                SetFilter("Qty. (Base)", '>0');

                WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                WhseWkshLine.SetRange(
                  "Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Put-away");
                WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPutAwayHeader."No.");

                OnBeforeProcessWhseMovWkshLines("Whse. Put-away Worksheet Line");
            end;
        }
        dataitem("Prod. Order Component"; "Prod. Order Component")
        {
            DataItemTableView = SORTING(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");

            trigger OnAfterGetRecord()
            var
                WMSMgt: Codeunit "WMS Management";
                QtyToPick: Decimal;
                QtyToPickBase: Decimal;
                SkipProdOrderComp: Boolean;
            begin
                if ("Flushing Method" = "Flushing Method"::"Pick + Forward") and ("Routing Link Code" = '') then
                    CurrReport.Skip();

                WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");

                SkipProdOrderComp := false;
                OnAfterGetRecordProdOrderComponent("Prod. Order Component", SkipProdOrderComp);
                if SkipProdOrderComp then
                    CurrReport.Skip();

                WhseWkshLine.SetRange("Source Line No.", "Prod. Order Line No.");
                WhseWkshLine.SetRange("Source Subline No.", "Line No.");
                if not WhseWkshLine.FindFirst then begin
                    TestField("Qty. per Unit of Measure");
                    CalcFields("Pick Qty. (Base)");
                    QtyToPickBase := "Expected Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)");
                    QtyToPick :=
                      Round(
                        ("Expected Qty. (Base)" - ("Qty. Picked (Base)" + "Pick Qty. (Base)")) /
                        "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    if QtyToPick > 0 then begin
                        CreatePick.SetProdOrderCompLine("Prod. Order Component", 1);
                        CreatePick.SetTempWhseItemTrkgLine(
                          "Prod. Order No.", DATABASE::"Prod. Order Component", '',
                          "Prod. Order Line No.", "Line No.", "Location Code");
                        CreatePick.CreateTempLine(
                          "Location Code", "Item No.", "Variant Code", "Unit of Measure Code",
                          '', "Bin Code",
                          "Qty. per Unit of Measure", QtyToPick, QtyToPickBase);
                    end;
                end else
                    WhseWkshLineFound := true;
            end;

            trigger OnPreDataItem()
            begin
                if WhseDoc <> WhseDoc::Production then
                    CurrReport.Break();

                WhseSetup.Get();
                CreatePick.SetValues(
                  AssignedID, 4, SortActivity, 1, 0, 0, false, DoNotFillQtytoHandle, BreakbulkFilter, false);

                SetRange("Prod. Order No.", ProdOrderHeader."No.");
                SetRange(Status, Status::Released);
                SetFilter(
                  "Flushing Method", '%1|%2|%3',
                  "Flushing Method"::Manual,
                  "Flushing Method"::"Pick + Forward",
                  "Flushing Method"::"Pick + Backward");
                SetRange("Planning Level Code", 0);
                SetFilter("Expected Qty. (Base)", '>0');

                WhseWkshLine.SetCurrentKey(
                  "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                WhseWkshLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
                WhseWkshLine.SetRange("Source Subtype", ProdOrderHeader.Status);
                WhseWkshLine.SetRange("Source No.", ProdOrderHeader."No.");
            end;
        }
        dataitem("Assembly Line"; "Assembly Line")
        {
            DataItemTableView = SORTING("Document Type", "Document No.", Type, "Location Code") WHERE(Type = CONST(Item));

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
                if WhseDoc <> WhseDoc::Assembly then
                    CurrReport.Break();

                WhseSetup.Get();
                CreatePick.SetValues(
                  AssignedID, 5, SortActivity, 1, 0, 0, false, DoNotFillQtytoHandle, BreakbulkFilter, false);

                SetRange("Document No.", AssemblyHeader."No.");
                SetRange("Document Type", AssemblyHeader."Document Type");
                SetRange(Type, Type::Item);
                SetFilter("Remaining Quantity (Base)", '>0');

                WhseWkshLine.SetCurrentKey(
                  "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                WhseWkshLine.SetRange("Source Type", DATABASE::"Assembly Line");
                WhseWkshLine.SetRange("Source Subtype", AssemblyHeader."Document Type");
                WhseWkshLine.SetRange("Source No.", AssemblyHeader."No.");
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
                            WhseEmployee.SetRange("Location Code", GetHeaderLocationCode);
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
                                WhseEmployee.Get(AssignedID, GetHeaderLocationCode);
                        end;
                    }
                    field(SortingMethodForActivityLines; SortActivity)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sorting Method for Activity Lines';
                        MultiLine = true;
                        OptionCaption = ' ,Item,Document,Shelf or Bin,Due Date,,Bin Ranking,Action Type';
                        ToolTip = 'Specifies the method by which the lines in the instruction will be sorted. The options are by item, document, shelf or bin (when the location uses bins, this is the bin code), due date, bin ranking, or action type.';
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
                        ToolTip = 'Specifies if you want the instructions to be printed. Otherwise, you can print it later from the warehouse instruction window.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            Location: Record Location;
        begin
            GetLocation(Location, GetHeaderLocationCode);
            if Location."Use ADCS" then
                DoNotFillQtytoHandle := true;

            OnAfterOpenPage(Location);
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
        HideNothingToHandleErr: Boolean;
    begin
        if (CreateErrorText <> '') and (FirstActivityNo = '') and (LastActivityNo = '') then
            Error(CreateErrorText);
        if not (WhseDoc in
                [WhseDoc::"Put-away Worksheet", WhseDoc::"Posted Receipt", WhseDoc::"Internal Put-away"])
        then begin
            CreatePick.CreateWhseDocument(FirstActivityNo, LastActivityNo, true);
            CreatePick.ReturnTempItemTrkgLines(TempWhseItemTrkgLine);
            ItemTrackingMgt.UpdateWhseItemTrkgLines(TempWhseItemTrkgLine);
            Commit();
        end else
            CreatePutAway.GetWhseActivHeaderNo(FirstActivityNo, LastActivityNo);

        HideNothingToHandleErr := false;
        OnBeforeSortWhseDocsForPrints(WhseDoc, FirstActivityNo, LastActivityNo, SortActivity, PrintDoc, HideNothingToHandleErr);

        WhseActivHeader.SetRange("No.", FirstActivityNo, LastActivityNo);

        case WhseDoc of
            WhseDoc::"Internal Pick", WhseDoc::Production, WhseDoc::Assembly:
                WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Pick);
            WhseDoc::"Whse. Mov.-Worksheet":
                WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Movement);
            WhseDoc::"Posted Receipt", WhseDoc::"Put-away Worksheet", WhseDoc::"Internal Put-away":
                WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Put-away");
        end;

        if WhseActivHeader.Find('-') then begin
            repeat
                CreatePutAway.DeleteBlankBinContent(WhseActivHeader);
                OnAfterCreatePutAwayDeleteBlankBinContent(WhseActivHeader);
                if SortActivity > 0 then
                    WhseActivHeader.SortWhseDoc;
                Commit();
            until WhseActivHeader.Next = 0;

            if PrintDoc then begin
                case WhseDoc of
                    WhseDoc::"Internal Pick", WhseDoc::Production, WhseDoc::Assembly:
                        REPORT.Run(REPORT::"Picking List", false, false, WhseActivHeader);
                    WhseDoc::"Whse. Mov.-Worksheet":
                        REPORT.Run(REPORT::"Movement List", false, false, WhseActivHeader);
                    WhseDoc::"Posted Receipt", WhseDoc::"Put-away Worksheet", WhseDoc::"Internal Put-away":
                        REPORT.Run(REPORT::"Put-away List", false, false, WhseActivHeader);
                end
            end
        end else
            Error(Text003);

        OnAfterPostReport(FirstActivityNo, LastActivityNo);
    end;

    trigger OnPreReport()
    begin
        Clear(CreatePick);
        Clear(CreatePutAway);
        EverythingHandled := true;
    end;

    var
        WhseSetup: Record "Warehouse Setup";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        ProdOrderHeader: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        TempWhseWorksheetLineMovement: Record "Whse. Worksheet Line" temporary;
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        CreatePick: Codeunit "Create Pick";
        CreatePutAway: Codeunit "Create Put-away";
        UOMMgt: Codeunit "Unit of Measure Management";
        FirstActivityNo: Code[20];
        LastActivityNo: Code[20];
        AssignedID: Code[50];
        WhseDoc: Option "Whse. Mov.-Worksheet","Posted Receipt","Internal Pick","Internal Put-away",Production,"Put-away Worksheet",Assembly,"Service Order";
        SortActivity: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type";
        SourceTableCaption: Text[30];
        CreateErrorText: Text[80];
        Text000: Label '%1 activity no. %2 has been created.';
        Text001: Label '%1 activities no. %2 to %3 have been created.';
        PrintDoc: Boolean;
        EverythingHandled: Boolean;
        WhseWkshLineFound: Boolean;
        Text002: Label '\For %1 with existing Warehouse Worksheet Lines, no %2 lines have been created.';
        HideValidationDialog: Boolean;
        Text003: Label 'There is nothing to handle.';
        DoNotFillQtytoHandle: Boolean;
        Text004: Label 'You can create a Movement only for the available quantity in %1 %2 = %3,%4 = %5,%6 = %7,%8 = %9.';
        BreakbulkFilter: Boolean;
        TotalPendingMovQtyExceedsBinAvailErr: Label 'Item tracking defined for line %1, lot number %2, serial number %3 cannot be applied.', Comment = '%1=Line No.,%2=Lot No.,%3=Serial No.';

    procedure SetPostedWhseReceiptLine(var PostedWhseReceiptLine2: Record "Posted Whse. Receipt Line"; AssignedID2: Code[50])
    begin
        PostedWhseReceiptLine.Copy(PostedWhseReceiptLine2);
        WhseDoc := WhseDoc::"Posted Receipt";
        SourceTableCaption := PostedWhseReceiptLine.TableCaption;
        AssignedID := AssignedID2;

        OnAfterSetPostedWhseReceiptLine(PostedWhseReceiptLine, SortActivity);
    end;

    procedure SetWhseWkshLine(var WhseWkshLine2: Record "Whse. Worksheet Line")
    begin
        WhseWkshLine.Copy(WhseWkshLine2);
        case WhseWkshLine."Whse. Document Type" of
            WhseWkshLine."Whse. Document Type"::Receipt,
          WhseWkshLine."Whse. Document Type"::"Internal Put-away":
                WhseDoc := WhseDoc::"Put-away Worksheet";
            WhseWkshLine."Whse. Document Type"::" ":
                WhseDoc := WhseDoc::"Whse. Mov.-Worksheet";
        end;

        OnAfterSetWhseWkshLine(WhseWkshLine, SortActivity);
    end;

    procedure SetWhseInternalPickLine(var WhseInternalPickLine2: Record "Whse. Internal Pick Line"; AssignedID2: Code[50])
    begin
        WhseInternalPickLine.Copy(WhseInternalPickLine2);
        WhseDoc := WhseDoc::"Internal Pick";
        SourceTableCaption := WhseInternalPickLine.TableCaption;
        AssignedID := AssignedID2;

        OnAfterSetWhseInternalPickLine(WhseInternalPickLine, SortActivity);
    end;

    procedure SetWhseInternalPutAway(var WhseInternalPutAwayHeader2: Record "Whse. Internal Put-away Header")
    begin
        WhseInternalPutAwayHeader.Copy(WhseInternalPutAwayHeader2);
        WhseDoc := WhseDoc::"Internal Put-away";
        SourceTableCaption := WhseInternalPutAwayHeader.TableCaption;
        AssignedID := WhseInternalPutAwayHeader2."Assigned User ID";

        OnAfterSetWhseInternalPutAway(WhseInternalPutAwayHeader, SortActivity);
    end;

    procedure SetProdOrder(var ProdOrderHeader2: Record "Production Order")
    begin
        ProdOrderHeader.Copy(ProdOrderHeader2);
        WhseDoc := WhseDoc::Production;
        SourceTableCaption := ProdOrderHeader.TableCaption;

        OnAfterSetProdOrder(ProdOrderHeader, SortActivity);
    end;

    procedure SetAssemblyOrder(var AssemblyHeader2: Record "Assembly Header")
    begin
        AssemblyHeader.Copy(AssemblyHeader2);
        WhseDoc := WhseDoc::Assembly;
        SourceTableCaption := AssemblyHeader.TableCaption;
    end;

    procedure GetActivityHeader(var WhseActivityHeader: Record "Warehouse Activity Header"; TypeToFilter: Option " ","Put-away",Pick,Movement,"Invt. Put-away","Invt. Pick","Invt. Movement")
    begin
        WhseActivityHeader.SetRange("No.", FirstActivityNo, LastActivityNo);
        WhseActivityHeader.SetRange(Type, TypeToFilter);
        if not WhseActivityHeader.FindFirst then
            WhseActivityHeader.Init();
    end;

    procedure GetResultMessage(WhseDocType: Option): Boolean
    var
        WhseActivHeader: Record "Warehouse Activity Header";
    begin
        if FirstActivityNo = '' then
            exit(false);

        if not HideValidationDialog then begin
            WhseActivHeader.Type := WhseDocType;
            if WhseWkshLineFound then begin
                if FirstActivityNo = LastActivityNo then
                    Message(
                      StrSubstNo(
                        Text000, Format(WhseActivHeader.Type), FirstActivityNo) +
                      StrSubstNo(
                        Text002, SourceTableCaption, Format(WhseActivHeader.Type)))
                else
                    Message(
                      StrSubstNo(
                        Text001,
                        Format(WhseActivHeader.Type), FirstActivityNo, LastActivityNo) +
                      StrSubstNo(
                        Text002, SourceTableCaption, Format(WhseActivHeader.Type)));
            end else begin
                if FirstActivityNo = LastActivityNo then
                    Message(Text000, Format(WhseActivHeader.Type), FirstActivityNo)
                else
                    Message(Text001, Format(WhseActivHeader.Type), FirstActivityNo, LastActivityNo);
            end;
        end;
        exit(EverythingHandled);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            if LocationCode = '' then
                Clear(Location)
            else
                Location.Get(LocationCode);
    end;

    procedure Initialize(AssignedID2: Code[50]; SortActivity2: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; PrintDoc2: Boolean; DoNotFillQtytoHandle2: Boolean; BreakbulkFilter2: Boolean)
    begin
        AssignedID := AssignedID2;
        SortActivity := SortActivity2;
        PrintDoc := PrintDoc2;
        DoNotFillQtytoHandle := DoNotFillQtytoHandle2;
        BreakbulkFilter := BreakbulkFilter2;
    end;

    local procedure InitPostedWhseReceiptLineFromPutAway(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer)
    begin
        with PostedWhseReceiptLine do begin
            if not Get(WhseWorksheetLine."Whse. Document No.", WhseWorksheetLine."Whse. Document Line No.") then begin
                Init;
                "No." := WhseWorksheetLine."Whse. Document No.";
                "Line No." := WhseWorksheetLine."Whse. Document Line No.";
                "Item No." := WhseWorksheetLine."Item No.";
                Description := WhseWorksheetLine.Description;
                "Description 2" := WhseWorksheetLine."Description 2";
                "Location Code" := WhseWorksheetLine."Location Code";
                "Zone Code" := WhseWorksheetLine."From Zone Code";
                "Bin Code" := WhseWorksheetLine."From Bin Code";
                "Shelf No." := WhseWorksheetLine."Shelf No.";
                "Qty. per Unit of Measure" := WhseWorksheetLine."Qty. per Unit of Measure";
                "Due Date" := WhseWorksheetLine."Due Date";
                "Unit of Measure Code" := WhseWorksheetLine."Unit of Measure Code";
                SourceType := DATABASE::"Whse. Internal Put-away Line";
            end else
                SourceType := DATABASE::"Posted Whse. Receipt Line";

            TestField("Qty. per Unit of Measure");
            Quantity := WhseWorksheetLine."Qty. to Handle";
            "Qty. (Base)" := WhseWorksheetLine."Qty. to Handle (Base)";
        end;

        OnAfterInitPostedWhseReceiptLineFromPutAway(PostedWhseReceiptLine, WhseWorksheetLine);
    end;

    local procedure InitPostedWhseReceiptLineFromInternalPutAway(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; QtyToPutAway: Decimal)
    begin
        with PostedWhseReceiptLine do begin
            Init;
            "No." := WhseInternalPutAwayLine."No.";
            "Line No." := WhseInternalPutAwayLine."Line No.";
            "Location Code" := WhseInternalPutAwayLine."Location Code";
            "Bin Code" := WhseInternalPutAwayLine."From Bin Code";
            "Zone Code" := WhseInternalPutAwayLine."From Zone Code";
            "Item No." := WhseInternalPutAwayLine."Item No.";
            "Shelf No." := WhseInternalPutAwayLine."Shelf No.";
            Quantity := QtyToPutAway;
            "Qty. (Base)" :=
              WhseInternalPutAwayLine."Qty. (Base)" -
              (WhseInternalPutAwayLine."Qty. Put Away (Base)" +
               WhseInternalPutAwayLine."Put-away Qty. (Base)");
            "Qty. Put Away" := WhseInternalPutAwayLine."Qty. Put Away";
            "Qty. Put Away (Base)" := WhseInternalPutAwayLine."Qty. Put Away (Base)";
            "Put-away Qty." := WhseInternalPutAwayLine."Put-away Qty.";
            "Put-away Qty. (Base)" := WhseInternalPutAwayLine."Put-away Qty. (Base)";
            "Unit of Measure Code" := WhseInternalPutAwayLine."Unit of Measure Code";
            "Qty. per Unit of Measure" := WhseInternalPutAwayLine."Qty. per Unit of Measure";
            "Variant Code" := WhseInternalPutAwayLine."Variant Code";
            Description := WhseInternalPutAwayLine.Description;
            "Description 2" := WhseInternalPutAwayLine."Description 2";
            "Due Date" := WhseInternalPutAwayLine."Due Date";
        end;

        OnAfterInitPostedWhseReceiptLineFromInternalPutAway(PostedWhseReceiptLine, WhseInternalPutAwayLine);
    end;

    procedure SetQuantity(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; var QtyToHandleBase: Decimal)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQuantity(PostedWhseRcptLine, SourceType, QtyToHandleBase, IsHandled);
        if IsHandled then
            exit;

        with WhseItemTrackingLine do begin
            Reset;
            SetCurrentKey("Serial No.", "Lot No.");
            SetRange("Serial No.", PostedWhseRcptLine."Serial No.");
            SetRange("Lot No.", PostedWhseRcptLine."Lot No.");
            SetRange("Source Type", SourceType);
            SetRange("Source ID", PostedWhseRcptLine."No.");
            SetRange("Source Ref. No.", PostedWhseRcptLine."Line No.");
            if FindFirst then begin
                if QtyToHandleBase < "Qty. to Handle (Base)" then
                    PostedWhseRcptLine."Qty. (Base)" := QtyToHandleBase
                else
                    PostedWhseRcptLine."Qty. (Base)" := "Qty. to Handle (Base)";
                QtyToHandleBase -= PostedWhseRcptLine."Qty. (Base)";
                PostedWhseRcptLine.Quantity :=
                  Round(PostedWhseRcptLine."Qty. (Base)" / PostedWhseRcptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            end;
        end;

        OnAfterSetQuantity(PostedWhseRcptLine, WhseItemTrackingLine);
    end;

    local procedure CheckAvailabilityWithTracking(WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        TrackedQtyInBin: Decimal;
    begin
        with WhseItemTrackingLine do begin
            SetSourceFilter(DATABASE::"Whse. Worksheet Line", 0, WhseWorksheetLine.Name, -1, false);
            SetRange("Source Batch Name", WhseWorksheetLine."Worksheet Template Name");
            SetRange("Location Code", WhseWorksheetLine."Location Code");
            SetRange("Item No.", WhseWorksheetLine."Item No.");
            SetRange("Variant Code", WhseWorksheetLine."Variant Code");
            if IsEmpty then
                exit;

            FindSet;
            repeat
                TrackedQtyInBin := WarehouseAvailabilityMgt.CalcQtyOnBin(
                    WhseWorksheetLine."Location Code", WhseWorksheetLine."From Bin Code", WhseWorksheetLine."Item No.",
                    WhseWorksheetLine."Variant Code", "Lot No.", "Serial No.");
                if TrackedQtyInBin < "Quantity (Base)" + WarehouseAvailabilityMgt.CalcQtyAssignedToMove(
                     WhseWorksheetLine, WhseItemTrackingLine)
                then
                    Error(TotalPendingMovQtyExceedsBinAvailErr, WhseWorksheetLine."Line No.", "Lot No.", "Serial No.");
            until Next = 0;
        end;
    end;

    procedure UpdateWhseItemTrkgLines(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        with WhseItemTrackingLine do begin
            Reset;
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            SetRange("Source ID", PostedWhseRcptLine."No.");
            SetRange("Source Type", SourceType);
            SetRange("Source Subtype", 0);
            SetRange("Source Batch Name", '');
            SetRange("Source Prod. Order Line", 0);
            SetRange("Source Ref. No.", PostedWhseRcptLine."Line No.");
            if Find('-') then
                repeat
                    TempWhseItemTrkgLine.SetRange("Source Type", "Source Type");
                    TempWhseItemTrkgLine.SetRange("Source ID", "Source ID");
                    TempWhseItemTrkgLine.SetRange("Source Ref. No.", "Source Ref. No.");
                    TempWhseItemTrkgLine.SetRange("Serial No.", "Serial No.");
                    TempWhseItemTrkgLine.SetRange("Lot No.", "Lot No.");
                    if TempWhseItemTrkgLine.Find('-') then
                        "Quantity Handled (Base)" += TempWhseItemTrkgLine."Quantity (Base)";
                    "Qty. to Handle (Base)" := "Quantity (Base)" - "Quantity Handled (Base)";
                    OnBeforeWhseItemTrackingLineModify(WhseItemTrackingLine, TempWhseItemTrkgLine);
                    Modify;
                until Next = 0;
        end
    end;

    local procedure UpdateWkshMovementLineBuffer(WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        with TempWhseWorksheetLineMovement do begin
            FilterWkshLine(TempWhseWorksheetLineMovement, WhseWorksheetLine);
            if FindFirst then begin
                "Qty. (Base)" += WhseWorksheetLine."Qty. (Base)";
                Quantity += WhseWorksheetLine.Quantity;
                "Qty. Outstanding (Base)" += WhseWorksheetLine."Qty. Outstanding (Base)";
                "Qty. Outstanding" += WhseWorksheetLine."Qty. Outstanding";
                "Qty. to Handle (Base)" += WhseWorksheetLine."Qty. to Handle (Base)";
                "Qty. to Handle" += WhseWorksheetLine."Qty. to Handle";
                "Qty. Handled (Base)" += WhseWorksheetLine."Qty. Handled (Base)";
                "Qty. Handled" += WhseWorksheetLine."Qty. Handled (Base)";
                OnBeforeTempWhseWorksheetLineMovementModify(TempWhseWorksheetLineMovement, WhseWorksheetLine);
                Modify;
            end else begin
                TempWhseWorksheetLineMovement := WhseWorksheetLine;
                Insert;
            end;
            UpdateWhseItemTrackingBuffer(WhseWorksheetLine, TempWhseWorksheetLineMovement);
            Reset;
        end;
    end;

    local procedure UpdateWhseItemTrackingBuffer(SourceWhseWorksheetLine: Record "Whse. Worksheet Line"; BufferWhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LastWhseItemTrkgLineNo: Integer;
    begin
        with TempWhseItemTrackingLine do begin
            Reset();
            if FindLast() then
                LastWhseItemTrkgLineNo := "Entry No.";

            WhseItemTrackingLine.SetSourceFilter(
              DATABASE::"Whse. Worksheet Line", 0, SourceWhseWorksheetLine.Name, SourceWhseWorksheetLine."Line No.", true);
            WhseItemTrackingLine.SetSourceFilter(SourceWhseWorksheetLine."Worksheet Template Name", 0);
            WhseItemTrackingLine.SetRange("Location Code", SourceWhseWorksheetLine."Location Code");
            WhseItemTrackingLine.SetFilter("Qty. to Handle (Base)", '>0');
            if WhseItemTrackingLine.FindSet() then
                repeat
                    SetSourceFilter(
                      DATABASE::"Whse. Worksheet Line", 0, BufferWhseWorksheetLine.Name, BufferWhseWorksheetLine."Line No.", false);
                    SetSourceFilter(BufferWhseWorksheetLine."Worksheet Template Name", 0);
                    SetRange("Location Code", BufferWhseWorksheetLine."Location Code");
                    SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
                    SetRange("Lot No.", WhseItemTrackingLine."Lot No.");
                    if FindFirst() then begin
                        "Quantity (Base)" += WhseItemTrackingLine."Quantity (Base)";
                        "Quantity Handled (Base)" += WhseItemTrackingLine."Quantity Handled (Base)";
                        "Qty. to Handle (Base)" += WhseItemTrackingLine."Qty. to Handle (Base)";
                        Modify();
                    end else begin
                        Init();
                        TempWhseItemTrackingLine := WhseItemTrackingLine;
                        "Source Ref. No." := BufferWhseWorksheetLine."Line No.";
                        "Entry No." := LastWhseItemTrkgLineNo + 1;
                        Insert();
                        LastWhseItemTrkgLineNo := "Entry No.";
                    end;
                until WhseItemTrackingLine.Next() = 0;
        end;
    end;

    local procedure CreateMovementLines(WhseWorksheetLine: Record "Whse. Worksheet Line"; var PickQty: Decimal; var PickQtyBase: Decimal)
    begin
        CreatePick.SetCalledFromWksh(true);
        CreatePick.SetWhseWkshLine(WhseWorksheetLine, 1);

        with WhseWorksheetLine do begin
            CreatePick.SetTempWhseItemTrkgLineFromBuffer(
              TempWhseItemTrackingLine,
              Name, DATABASE::"Whse. Worksheet Line", "Worksheet Template Name", 0, "Line No.", "Location Code");
            PickQty := "Qty. to Handle";
            PickQtyBase := "Qty. to Handle (Base)";
            CreatePick.CreateTempLine(
              "Location Code", "Item No.", "Variant Code", "Unit of Measure Code", "From Bin Code", "To Bin Code",
              "Qty. per Unit of Measure", PickQty, PickQtyBase);
        end;
    end;

    local procedure UpdateMovementWorksheet(WhseWorksheetLineBuffer: Record "Whse. Worksheet Line"; QtyHandled: Decimal; QtyHandledBase: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldQtyToHandleBase: Decimal;
        OldQtyHandledBase: Decimal;
    begin
        FilterWkshLine(WhseWorksheetLine, WhseWorksheetLineBuffer);
        with WhseWorksheetLine do begin
            FindSet(true);
            repeat
                if "Qty. to Handle" = "Qty. Outstanding" then begin
                    Delete;
                    ItemTrackingMgt.DeleteWhseItemTrkgLines(
                      DATABASE::"Whse. Worksheet Line", 0, Name, "Worksheet Template Name", 0, "Line No.", "Location Code", true);
                    QtyHandled -= "Qty. to Handle";
                    QtyHandledBase -= "Qty. to Handle (Base)";
                end else begin
                    OldQtyHandledBase := "Qty. Handled (Base)";
                    OldQtyToHandleBase := "Qty. to Handle (Base)";
                    if QtyHandledBase >= "Qty. to Handle (Base)" then begin
                        QtyHandledBase -= "Qty. to Handle (Base)";
                        QtyHandled -= "Qty. to Handle";
                        Validate("Qty. Handled", "Qty. Handled" + "Qty. to Handle");
                        "Qty. Handled (Base)" := OldQtyHandledBase + OldQtyToHandleBase;
                    end else begin
                        Validate("Qty. Handled", "Qty. Handled" + "Qty. to Handle" - QtyHandled);
                        "Qty. Handled (Base)" := OldQtyHandledBase + OldQtyToHandleBase - QtyHandledBase;
                        QtyHandledBase := 0;
                        QtyHandled := 0;
                    end;
                    "Qty. Outstanding (Base)" := "Qty. (Base)" - "Qty. Handled (Base)";
                    Modify;
                end;
            until (Next = 0) or (QtyHandledBase = 0);
        end;
    end;

    local procedure FilterWkshLine(var WhseWorksheetLineToFilter: Record "Whse. Worksheet Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        with WhseWorksheetLineToFilter do begin
            SetRange("Worksheet Template Name", WhseWorksheetLine."Worksheet Template Name");
            SetRange(Name, WhseWorksheetLine.Name);
            SetRange("Location Code", WhseWorksheetLine."Location Code");
            SetRange("Item No.", WhseWorksheetLine."Item No.");
            SetRange("Variant Code", WhseWorksheetLine."Variant Code");
            SetRange("From Bin Code", WhseWorksheetLine."From Bin Code");
            SetRange("To Bin Code", WhseWorksheetLine."To Bin Code");
            SetRange("From Zone Code", WhseWorksheetLine."From Zone Code");
            SetRange("To Zone Code", WhseWorksheetLine."To Zone Code");
            SetRange("Unit of Measure Code", WhseWorksheetLine."Unit of Measure Code");
            SetRange("From Unit of Measure Code", WhseWorksheetLine."From Unit of Measure Code");
        end;
    end;

    procedure CreatePutAwayFromDiffSource(PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer)
    var
        TempPostedWhseRcptLine: Record "Posted Whse. Receipt Line" temporary;
        TempPostedWhseRcptLine2: Record "Posted Whse. Receipt Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        RemQtyToHandleBase: Decimal;
    begin
        case SourceType of
            DATABASE::"Whse. Internal Put-away Line":
                ItemTrackingMgt.SplitInternalPutAwayLine(PostedWhseRcptLine, TempPostedWhseRcptLine);
            DATABASE::"Posted Whse. Receipt Line":
                ItemTrackingMgt.SplitPostedWhseRcptLine(PostedWhseRcptLine, TempPostedWhseRcptLine);
        end;
        RemQtyToHandleBase := PostedWhseRcptLine."Qty. (Base)";

        TempPostedWhseRcptLine.Reset();
        if TempPostedWhseRcptLine.Find('-') then
            repeat
                TempPostedWhseRcptLine2 := TempPostedWhseRcptLine;
                TempPostedWhseRcptLine2."Line No." := PostedWhseRcptLine."Line No.";
                SetQuantity(TempPostedWhseRcptLine2, SourceType, RemQtyToHandleBase);
                if TempPostedWhseRcptLine2."Qty. (Base)" > 0 then begin
                    CreatePutAway.Run(TempPostedWhseRcptLine2);
                    CreatePutAway.UpdateTempWhseItemTrkgLines(TempPostedWhseRcptLine2, SourceType);
                end;
            until TempPostedWhseRcptLine.Next = 0;
    end;

    procedure FEFOLocation(LocCode: Code[10]): Boolean
    var
        Location2: Record Location;
    begin
        if LocCode <> '' then begin
            Location2.Get(LocCode);
            exit(Location2."Pick According to FEFO");
        end;
        exit(false);
    end;

    procedure ItemTracking(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if ItemNo <> '' then begin
            Item.Get(ItemNo);
            if Item."Item Tracking Code" <> '' then begin
                ItemTrackingCode.Get(Item."Item Tracking Code");
                exit((ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking"));
            end;
        end;
        exit(false);
    end;

    local procedure GetHeaderLocationCode(): Code[10]
    begin
        case WhseDoc of
            WhseDoc::"Posted Receipt":
                exit(PostedWhseReceiptLine."Location Code");
            WhseDoc::"Put-away Worksheet",
          WhseDoc::"Whse. Mov.-Worksheet":
                exit(WhseWkshLine."Location Code");
            WhseDoc::"Internal Pick":
                exit(WhseInternalPickLine."Location Code");
            WhseDoc::"Internal Put-away":
                exit(WhseInternalPutAwayHeader."Location Code");
            WhseDoc::Production:
                exit(ProdOrderHeader."Location Code");
            WhseDoc::Assembly:
                exit(AssemblyHeader."Location Code");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayDeleteBlankBinContent(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var SkipProdOrderComp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedWhseReceiptLineFromPutAway(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostedWhseReceiptLineFromInternalPutAway(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterOpenPage(var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(FirstActivityNo: Code[20]; LastActivityNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseReceiptLineOnPostDataItem(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPostedWhseReceiptLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrder(ProductionOrder: Record "Production Order"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQuantity(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseInternalPickLine(WhseInternalPickLine: Record "Whse. Internal Pick Line"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseInternalPutAway(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseWkshLine(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessWhseMovWkshLines(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQuantity(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; var QtyToHandleBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSortWhseDocsForPrints(WhseDoc: Option "Whse. Mov.-Worksheet","Posted Receipt","Internal Pick","Internal Put-away",Production,"Put-away Worksheet",Assembly,"Service Order"; FirstActivityNo: Code[20]; LastActivityNo: Code[20]; SortActivity: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; PrintDoc: Boolean; var HideNothingToHandleErr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseWorksheetLineMovementModify(var TempWhseWorksheetLineMovement: Record "Whse. Worksheet Line" temporary; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseItemTrackingLineModify(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;
}


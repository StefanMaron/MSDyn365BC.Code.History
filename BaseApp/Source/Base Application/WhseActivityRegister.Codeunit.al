codeunit 7307 "Whse.-Activity-Register"
{
    Permissions = TableData "Registered Whse. Activity Hdr." = i,
                  TableData "Registered Whse. Activity Line" = i,
                  TableData "Whse. Item Tracking Line" = rim,
                  TableData "Warehouse Journal Batch" = imd,
                  TableData "Posted Whse. Receipt Header" = m,
                  TableData "Posted Whse. Receipt Line" = m,
                  TableData "Registered Invt. Movement Hdr." = i,
                  TableData "Registered Invt. Movement Line" = i;
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        WhseActivLine.Copy(Rec);
        WhseActivLine.SetAutoCalcFields;
        Code;
        Rec := WhseActivLine;
    end;

    var
        Text000: Label 'Warehouse Activity    #1##########\\';
        Text001: Label 'Checking lines        #2######\';
        Text002: Label 'Registering lines     #3###### @4@@@@@@@@@@@@@';
        Location: Record Location;
        Item: Record Item;
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        RegisteredWhseActivHeader: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseActivLine: Record "Registered Whse. Activity Line";
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        ProdCompLine: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        ProdOrder: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        Cust: Record Customer;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Window: Dialog;
        NoOfRecords: Integer;
        LineCount: Integer;
        HideDialog: Boolean;
        Text003: Label 'There is nothing to register.';
        InsufficientQtyItemTrkgErr: Label 'Item tracking defined for source line %1 of %2 %3 amounts to more than the quantity you have entered.\\You must adjust the existing item tracking specification and then reenter a new quantity.', Comment = '%1=Source Line No.,%2=Source Document,%3=Source No.';
        Text005: Label '%1 %2 is not available on inventory or it has already been reserved for another document.';
        OrderToOrderBindingOnSalesLineQst: Label 'Registering the pick will remove the existing order-to-order reservation for the sales order.\Do you want to continue?';
        RegisterInterruptedErr: Label 'The action has been interrupted to respect the warning.';
        SuppressCommit: Boolean;

    local procedure "Code"()
    var
        OldWhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary;
        TempWhseActivityLineGrouped: Record "Warehouse Activity Line" temporary;
        SkipDelete: Boolean;
    begin
        OnBeforeCode(WhseActivLine);

        with WhseActivHeader do begin
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
            WhseActivLine.SetRange("No.", WhseActivLine."No.");
            WhseActivLine.SetFilter("Qty. to Handle (Base)", '<>0');
            if WhseActivLine.IsEmpty then
                Error(Text003);
            CheckWhseItemTrkgLine(WhseActivLine);

            Get(WhseActivLine."Activity Type", WhseActivLine."No.");
            LocationGet("Location Code");

            UpdateWindow(1, "No.");

            // Check Lines
            CheckLines;

            // Register lines
            SourceCodeSetup.Get();
            LineCount := 0;
            CreateRegActivHeader(WhseActivHeader);

            TempWhseActivLineToReserve.DeleteAll();
            TempWhseActivityLineGrouped.DeleteAll();

            WhseActivLine.LockTable();

            // breakbulk first to provide quantity for pick lines in smaller UoM
            WhseActivLine.SetFilter("Breakbulk No.", '<>0');
            RegisterWhseActivityLines(WhseActivLine, TempWhseActivLineToReserve, TempWhseActivityLineGrouped);

            WhseActivLine.SetRange("Breakbulk No.", 0);
            RegisterWhseActivityLines(WhseActivLine, TempWhseActivLineToReserve, TempWhseActivityLineGrouped);
            WhseActivLine.SetRange("Breakbulk No.");

            TempWhseActivityLineGrouped.Reset();
            if TempWhseActivityLineGrouped.FindSet then
                repeat
                    if Type <> Type::Movement then
                        UpdateWhseSourceDocLine(TempWhseActivityLineGrouped);
                    UpdateWhseDocHeader(TempWhseActivityLineGrouped);
                    TempWhseActivityLineGrouped.DeleteBinContent(TempWhseActivityLineGrouped."Action Type"::Take);
                until TempWhseActivityLineGrouped.Next = 0;

            CheckAndRemoveOrderToOrderBinding(TempWhseActivLineToReserve);
            ItemTrackingMgt.SetPick(WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::Pick);
            ItemTrackingMgt.SynchronizeWhseItemTracking(TempTrackingSpecification, RegisteredWhseActivLine."No.", false);
            AutoReserveForSalesLine(TempWhseActivLineToReserve);

            if Location."Bin Mandatory" then begin
                LineCount := 0;
                Clear(OldWhseActivLine);
                WhseActivLine.Reset();
                WhseActivLine.SetCurrentKey(
                  "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.");
                WhseActivLine.SetRange("Activity Type", Type);
                WhseActivLine.SetRange("No.", "No.");
                if WhseActivLine.Find('-') then
                    repeat
                        if ((LineCount = 1) and
                            ((OldWhseActivLine."Whse. Document Type" <> WhseActivLine."Whse. Document Type") or
                             (OldWhseActivLine."Whse. Document No." <> WhseActivLine."Whse. Document No.")))
                        then begin
                            LineCount := 0;
                            OldWhseActivLine.Delete();
                        end;
                        OldWhseActivLine := WhseActivLine;
                        LineCount := LineCount + 1;
                    until WhseActivLine.Next = 0;
                if LineCount = 1 then
                    OldWhseActivLine.Delete();
            end;
            OnBeforeUpdWhseActivHeader(WhseActivHeader, WhseActivLine);
            WhseActivLine.Reset();
            WhseActivLine.SetRange("Activity Type", Type);
            WhseActivLine.SetRange("No.", "No.");
            WhseActivLine.SetFilter("Qty. Outstanding", '<>%1', 0);
            if not WhseActivLine.Find('-') then begin
                SkipDelete := false;
                OnBeforeWhseActivHeaderDelete(WhseActivHeader, SkipDelete);
                if not SkipDelete then
                    Delete(true);
            end else begin
                "Last Registering No." := "Registering No.";
                "Registering No." := '';
                Modify;
                if not HideDialog then
                    WhseActivLine.AutofillQtyToHandle(WhseActivLine);
                OnAfterAutofillQtyToHandle(WhseActivLine);
            end;
            if not HideDialog then
                Window.Close;

            if not SuppressCommit then begin
                OnBeforeCommit(WhseActivHeader);
                Commit();
            end;
            Clear(WhseJnlRegisterLine);
        end;

        OnAfterRegisterWhseActivity(WhseActivHeader);
    end;

    local procedure RegisterWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var TempWhseActivityLineGrouped: Record "Warehouse Activity Line" temporary)
    var
        QtyDiff: Decimal;
        QtyBaseDiff: Decimal;
        SkipDelete: Boolean;
    begin
        with WarehouseActivityLine do begin
            if not FindSet then
                exit;

            repeat
                LineCount := LineCount + 1;
                UpdateWindow(3, '');
                UpdateWindow(4, '');
                if Location."Bin Mandatory" then
                    RegisterWhseJnlLine(WarehouseActivityLine);
                CreateRegActivLine(WarehouseActivityLine);
                OnAfterCreateRegActivLine(WarehouseActivityLine, RegisteredWhseActivLine, RegisteredInvtMovementLine);

                CopyWhseActivityLineToReservBuf(TempWhseActivLineToReserve, WarehouseActivityLine);
                GroupWhseActivLinesByWhseDocAndSource(TempWhseActivityLineGrouped, WarehouseActivityLine);

                if "Activity Type" <> "Activity Type"::Movement then
                    RegisterWhseItemTrkgLine(WarehouseActivityLine);
                OnAfterFindWhseActivLine(WarehouseActivityLine);
                if "Qty. Outstanding" = "Qty. to Handle" then begin
                    SkipDelete := false;
                    OnBeforeWhseActivLineDelete(WarehouseActivityLine, SkipDelete);
                    if not SkipDelete then
                        Delete;
                end else begin
                    QtyDiff := "Qty. Outstanding" - "Qty. to Handle";
                    QtyBaseDiff := "Qty. Outstanding (Base)" - "Qty. to Handle (Base)";
                    Validate("Qty. Outstanding", QtyDiff);
                    if "Qty. Outstanding (Base)" > QtyBaseDiff then // round off error- qty same, not base qty
                        "Qty. Outstanding (Base)" := QtyBaseDiff;
                    Validate("Qty. to Handle", QtyDiff);
                    if "Qty. to Handle (Base)" > QtyBaseDiff then // round off error- qty same, not base qty
                        "Qty. to Handle (Base)" := QtyBaseDiff;
                    if HideDialog then
                        Validate("Qty. to Handle", 0);
                    Validate("Qty. Handled", Quantity - "Qty. Outstanding");
                    OnBeforeWhseActivLineModify(WarehouseActivityLine);
                    Modify;
                end;
            until Next = 0;
        end;
    end;

    local procedure RegisterWhseJnlLine(WhseActivLine: Record "Warehouse Activity Line")
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        WMSMgt: Codeunit "WMS Management";
    begin
        with WhseActivLine do begin
            WhseJnlLine.Init();
            WhseJnlLine."Location Code" := "Location Code";
            WhseJnlLine."Item No." := "Item No.";
            WhseJnlLine."Registering Date" := WorkDate;
            WhseJnlLine."User ID" := UserId;
            WhseJnlLine."Variant Code" := "Variant Code";
            WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::Movement;
            if "Action Type" = "Action Type"::Take then begin
                WhseJnlLine."From Zone Code" := "Zone Code";
                WhseJnlLine."From Bin Code" := "Bin Code";
            end else begin
                WhseJnlLine."To Zone Code" := "Zone Code";
                WhseJnlLine."To Bin Code" := "Bin Code";
            end;
            WhseJnlLine.Description := Description;

            LocationGet("Location Code");
            if Location."Directed Put-away and Pick" then begin
                WhseJnlLine.Quantity := "Qty. to Handle";
                WhseJnlLine."Unit of Measure Code" := "Unit of Measure Code";
                WhseJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                GetItemUnitOfMeasure("Item No.", "Unit of Measure Code");
                WhseJnlLine.Cubage :=
                  Abs(WhseJnlLine.Quantity) * ItemUnitOfMeasure.Cubage;
                WhseJnlLine.Weight :=
                  Abs(WhseJnlLine.Quantity) * ItemUnitOfMeasure.Weight;
            end else begin
                WhseJnlLine.Quantity := "Qty. to Handle (Base)";
                WhseJnlLine."Unit of Measure Code" := WMSMgt.GetBaseUOM("Item No.");
                WhseJnlLine."Qty. per Unit of Measure" := 1;
            end;
            WhseJnlLine."Qty. (Base)" := "Qty. to Handle (Base)";
            WhseJnlLine."Qty. (Absolute)" := WhseJnlLine.Quantity;
            WhseJnlLine."Qty. (Absolute, Base)" := "Qty. to Handle (Base)";

            WhseJnlLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
            WhseJnlLine."Source Document" := "Source Document";
            WhseJnlLine."Reference No." := RegisteredWhseActivHeader."No.";
            case "Activity Type" of
                "Activity Type"::"Put-away":
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup."Whse. Put-away";
                        WhseJnlLine.SetWhseDoc("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Put-away";
                    end;
                "Activity Type"::Pick:
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup."Whse. Pick";
                        WhseJnlLine.SetWhseDoc("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::Pick;
                    end;
                "Activity Type"::Movement:
                    begin
                        WhseJnlLine."Source Code" := SourceCodeSetup."Whse. Movement";
                        WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::Movement;
                    end;
                "Activity Type"::"Invt. Put-away",
              "Activity Type"::"Invt. Pick",
              "Activity Type"::"Invt. Movement":
                    WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";
            end;
            if "Serial No." <> '' then
                TestField("Qty. per Unit of Measure", 1);
            WhseJnlLine.CopyTrackingFromWhseActivityLine(WhseActivLine);
            WhseJnlLine."Warranty Date" := "Warranty Date";
            WhseJnlLine."Expiration Date" := "Expiration Date";
            OnBeforeWhseJnlRegisterLine(WhseJnlLine, WhseActivLine);
            WhseJnlRegisterLine.Run(WhseJnlLine);
        end;
    end;

    local procedure CreateRegActivHeader(WhseActivHeader: Record "Warehouse Activity Header")
    var
        WhseCommentLine: Record "Warehouse Comment Line";
        WhseCommentLine2: Record "Warehouse Comment Line";
        TableNameFrom: Option;
        TableNameTo: Option;
        RegisteredType: Option;
        RegisteredNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeCreateRegActivHeader(WhseActivHeader, IsHandled, RegisteredWhseActivHeader, RegisteredInvtMovementHdr);
        if IsHandled then
            exit;

        TableNameFrom := WhseCommentLine."Table Name"::"Whse. Activity Header";
        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Movement" then begin
            RegisteredInvtMovementHdr.Init();
            RegisteredInvtMovementHdr.TransferFields(WhseActivHeader);
            RegisteredInvtMovementHdr."No." := WhseActivHeader."Registering No.";
            RegisteredInvtMovementHdr."Invt. Movement No." := WhseActivHeader."No.";
            OnBeforeRegisteredInvtMovementHdrInsert(RegisteredInvtMovementHdr, WhseActivHeader);
            RegisteredInvtMovementHdr.Insert();
            OnAfterRegisteredInvtMovementHdrInsert(RegisteredInvtMovementHdr, WhseActivHeader);

            TableNameTo := WhseCommentLine."Table Name"::"Registered Invt. Movement";
            RegisteredType := 0;
            RegisteredNo := RegisteredInvtMovementHdr."No.";
        end else begin
            RegisteredWhseActivHeader.Init();
            RegisteredWhseActivHeader.TransferFields(WhseActivHeader);
            RegisteredWhseActivHeader.Type := WhseActivHeader.Type;
            RegisteredWhseActivHeader."No." := WhseActivHeader."Registering No.";
            RegisteredWhseActivHeader."Whse. Activity No." := WhseActivHeader."No.";
            RegisteredWhseActivHeader."Registering Date" := WorkDate;
            RegisteredWhseActivHeader."No. Series" := WhseActivHeader."Registering No. Series";
            OnBeforeRegisteredWhseActivHeaderInsert(RegisteredWhseActivHeader, WhseActivHeader);
            RegisteredWhseActivHeader.Insert();
            OnAfterRegisteredWhseActivHeaderInsert(RegisteredWhseActivHeader, WhseActivHeader);

            TableNameTo := WhseCommentLine2."Table Name"::"Rgstrd. Whse. Activity Header";
            RegisteredType := RegisteredWhseActivHeader.Type;
            RegisteredNo := RegisteredWhseActivHeader."No.";
        end;

        WhseCommentLine.SetRange("Table Name", TableNameFrom);
        WhseCommentLine.SetRange(Type, WhseActivHeader.Type);
        WhseCommentLine.SetRange("No.", WhseActivHeader."No.");
        WhseCommentLine.LockTable();

        if WhseCommentLine.Find('-') then
            repeat
                WhseCommentLine2.Init();
                WhseCommentLine2 := WhseCommentLine;
                WhseCommentLine2."Table Name" := TableNameTo;
                WhseCommentLine2.Type := RegisteredType;
                WhseCommentLine2."No." := RegisteredNo;
                WhseCommentLine2.Insert();
            until WhseCommentLine.Next = 0;

        OnAfterCreateRegActivHeader(WhseActivHeader);
    end;

    local procedure CreateRegActivLine(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement" then begin
            RegisteredInvtMovementLine.Init();
            RegisteredInvtMovementLine.TransferFields(WhseActivLine);
            RegisteredInvtMovementLine."No." := RegisteredInvtMovementHdr."No.";
            OnAfterInitRegInvtMovementLine(WhseActivLine, RegisteredInvtMovementLine);
            RegisteredInvtMovementLine.Validate(Quantity, WhseActivLine."Qty. to Handle");
            OnBeforeRegisteredInvtMovementLineInsert(RegisteredInvtMovementLine, WhseActivLine);
            RegisteredInvtMovementLine.Insert();
            OnAfterRegisteredInvtMovementLineInsert(RegisteredInvtMovementLine, WhseActivLine);
        end else begin
            RegisteredWhseActivLine.Init();
            RegisteredWhseActivLine.TransferFields(WhseActivLine);
            RegisteredWhseActivLine."Activity Type" := RegisteredWhseActivHeader.Type;
            RegisteredWhseActivLine."No." := RegisteredWhseActivHeader."No.";
            OnAfterInitRegActLine(WhseActivLine, RegisteredWhseActivLine);
            RegisteredWhseActivLine.Quantity := WhseActivLine."Qty. to Handle";
            RegisteredWhseActivLine."Qty. (Base)" := WhseActivLine."Qty. to Handle (Base)";
            OnBeforeRegisteredWhseActivLineInsert(RegisteredWhseActivLine, WhseActivLine);
            RegisteredWhseActivLine.Insert();
            OnAfterRegisteredWhseActivLineInsert(RegisteredWhseActivLine, WhseActivLine);
        end;
    end;

    procedure UpdateWhseSourceDocLine(WhseActivLine: Record "Warehouse Activity Line")
    var
        WhseDocType2: Option;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseSourceDocLine(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        with WhseActivLine do begin
            if "Original Breakbulk" then
                exit;

            if ("Whse. Document Type" = "Whse. Document Type"::Shipment) and "Assemble to Order" then
                WhseDocType2 := "Whse. Document Type"::Assembly
            else
                WhseDocType2 := "Whse. Document Type";
            case WhseDocType2 of
                "Whse. Document Type"::Shipment:
                    if ("Action Type" <> "Action Type"::Take) and ("Breakbulk No." = 0) then
                        UpdateWhseShptLine(
                          "Whse. Document No.", "Whse. Document Line No.",
                          "Qty. to Handle", "Qty. to Handle (Base)", "Qty. per Unit of Measure");
                "Whse. Document Type"::"Internal Pick":
                    if ("Action Type" <> "Action Type"::Take) and ("Breakbulk No." = 0) then
                        UpdateWhseIntPickLine(WhseActivLine);
                "Whse. Document Type"::Production:
                    if ("Action Type" <> "Action Type"::Take) and ("Breakbulk No." = 0) then
                        UpdateProdCompLine(WhseActivLine);
                "Whse. Document Type"::Assembly:
                    if ("Action Type" <> "Action Type"::Take) and ("Breakbulk No." = 0) then
                        UpdateAssemblyLine(WhseActivLine);
                "Whse. Document Type"::Receipt:
                    if "Action Type" <> "Action Type"::Place then
                        UpdatePostedWhseRcptLine(WhseActivLine);
                "Whse. Document Type"::"Internal Put-away":
                    if "Action Type" <> "Action Type"::Take then
                        UpdateWhseIntPutAwayLine(WhseActivLine);
            end;

            if "Activity Type" = "Activity Type"::"Invt. Movement" then
                UpdateSourceDocForInvtMovement(WhseActivLine);
        end;
    end;

    procedure UpdateWhseDocHeader(WhseActivLine: Record "Warehouse Activity Line")
    var
        WhsePutAwayRqst: Record "Whse. Put-away Request";
        WhsePickRqst: Record "Whse. Pick Request";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseDocHeader(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        with WhseActivLine do
            case "Whse. Document Type" of
                "Whse. Document Type"::Shipment:
                    if "Action Type" <> "Action Type"::Take then begin
                        WhseShptHeader.Get("Whse. Document No.");
                        WhseShptHeader.Validate(
                          "Document Status", WhseShptHeader.GetDocumentStatus(0));
                        WhseShptHeader.Modify();
                    end;
                "Whse. Document Type"::Receipt:
                    if "Action Type" <> "Action Type"::Place then begin
                        PostedWhseRcptHeader.Get("Whse. Document No.");
                        PostedWhseRcptLine.Reset();
                        PostedWhseRcptLine.SetRange("No.", PostedWhseRcptHeader."No.");
                        if PostedWhseRcptLine.FindFirst then begin
                            PostedWhseRcptHeader."Document Status" := PostedWhseRcptHeader.GetHeaderStatus(0);
                            PostedWhseRcptHeader.Modify();
                        end;
                        if PostedWhseRcptHeader."Document Status" =
                           PostedWhseRcptHeader."Document Status"::"Completely Put Away"
                        then begin
                            WhsePutAwayRqst.SetRange("Document Type", WhsePutAwayRqst."Document Type"::Receipt);
                            WhsePutAwayRqst.SetRange("Document No.", PostedWhseRcptHeader."No.");
                            WhsePutAwayRqst.DeleteAll();
                            ItemTrackingMgt.DeleteWhseItemTrkgLines(
                              DATABASE::"Posted Whse. Receipt Line", 0, PostedWhseRcptHeader."No.", '', 0, 0, '', false);
                        end;
                    end;
                "Whse. Document Type"::"Internal Pick":
                    if "Action Type" <> "Action Type"::Take then begin
                        WhseInternalPickHeader.Get("Whse. Document No.");
                        WhseInternalPickLine.Reset();
                        WhseInternalPickLine.SetRange("No.", "Whse. Document No.");
                        if WhseInternalPickLine.FindFirst then begin
                            WhseInternalPickHeader."Document Status" :=
                              WhseInternalPickHeader.GetDocumentStatus(0);
                            WhseInternalPickHeader.Modify();
                            if WhseInternalPickHeader."Document Status" =
                               WhseInternalPickHeader."Document Status"::"Completely Picked"
                            then begin
                                WhseInternalPickHeader.DeleteRelatedLines;
                                WhseInternalPickHeader.Delete();
                            end;
                        end else begin
                            WhseInternalPickHeader.DeleteRelatedLines;
                            WhseInternalPickHeader.Delete();
                        end;
                    end;
                "Whse. Document Type"::"Internal Put-away":
                    if "Action Type" <> "Action Type"::Take then begin
                        WhseInternalPutAwayHeader.Get("Whse. Document No.");
                        WhseInternalPutAwayLine.Reset();
                        WhseInternalPutAwayLine.SetRange("No.", "Whse. Document No.");
                        if WhseInternalPutAwayLine.FindFirst then begin
                            WhseInternalPutAwayHeader."Document Status" :=
                              WhseInternalPutAwayHeader.GetDocumentStatus(0);
                            WhseInternalPutAwayHeader.Modify();
                            if WhseInternalPutAwayHeader."Document Status" =
                               WhseInternalPutAwayHeader."Document Status"::"Completely Put Away"
                            then begin
                                WhseInternalPutAwayHeader.DeleteRelatedLines;
                                WhseInternalPutAwayHeader.Delete();
                            end;
                        end else begin
                            WhseInternalPutAwayHeader.DeleteRelatedLines;
                            WhseInternalPutAwayHeader.Delete();
                        end;
                    end;
                "Whse. Document Type"::Production:
                    if "Action Type" <> "Action Type"::Take then begin
                        ProdOrder.Get("Source Subtype", "Source No.");
                        ProdOrder.CalcFields("Completely Picked");
                        if ProdOrder."Completely Picked" then begin
                            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Production);
                            WhsePickRqst.SetRange("Document No.", ProdOrder."No.");
                            WhsePickRqst.ModifyAll("Completely Picked", true);
                            ItemTrackingMgt.DeleteWhseItemTrkgLines(
                              DATABASE::"Prod. Order Component", "Source Subtype", "Source No.", '', 0, 0, '', false);
                        end;
                    end;
                "Whse. Document Type"::Assembly:
                    if "Action Type" <> "Action Type"::Take then begin
                        AssemblyHeader.Get("Source Subtype", "Source No.");
                        if AssemblyHeader.CompletelyPicked then begin
                            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Assembly);
                            WhsePickRqst.SetRange("Document No.", AssemblyHeader."No.");
                            WhsePickRqst.ModifyAll("Completely Picked", true);
                            ItemTrackingMgt.DeleteWhseItemTrkgLines(
                              DATABASE::"Assembly Line", "Source Subtype", "Source No.", '', 0, 0, '', false);
                        end;
                    end;
            end;
    end;

    procedure UpdateWhseShptLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer; QtyToHandle: Decimal; QtyToHandleBase: Decimal; QtyPerUOM: Decimal)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Get(WhseDocNo, WhseDocLineNo);
        OnBeforeUpdateWhseShptLine(WhseShptLine, QtyToHandle, QtyToHandleBase, QtyPerUOM);
        WhseShptLine."Qty. Picked (Base)" :=
          WhseShptLine."Qty. Picked (Base)" + QtyToHandleBase;
        if QtyPerUOM = WhseShptLine."Qty. per Unit of Measure" then
            WhseShptLine."Qty. Picked" := WhseShptLine."Qty. Picked" + QtyToHandle
        else
            WhseShptLine."Qty. Picked" :=
              Round(WhseShptLine."Qty. Picked" + QtyToHandleBase / QtyPerUOM);

        WhseShptLine."Completely Picked" :=
          (WhseShptLine."Qty. Picked" = WhseShptLine.Quantity) or (WhseShptLine."Qty. Picked (Base)" = WhseShptLine."Qty. (Base)");

        // Handle rounding residual when completely picked
        if WhseShptLine."Completely Picked" and (WhseShptLine."Qty. Picked" <> WhseShptLine.Quantity) then
            WhseShptLine."Qty. Picked" := WhseShptLine.Quantity;

        WhseShptLine.Validate("Qty. to Ship", WhseShptLine."Qty. Picked" - WhseShptLine."Qty. Shipped");
        WhseShptLine."Qty. to Ship (Base)" := WhseShptLine."Qty. Picked (Base)" - WhseShptLine."Qty. Shipped (Base)";
        WhseShptLine.Status := WhseShptLine.CalcStatusShptLine;
        OnBeforeWhseShptLineModify(WhseShptLine, WhseActivLine);
        WhseShptLine.Modify();
        OnAfterWhseShptLineModify(WhseShptLine);
    end;

    local procedure UpdatePostedWhseRcptLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        with WhseActivityLine do begin
            PostedWhseRcptHeader.LockTable();
            PostedWhseRcptHeader.Get("Whse. Document No.");
            PostedWhseRcptLine.LockTable();
            PostedWhseRcptLine.Get("Whse. Document No.", "Whse. Document Line No.");
            PostedWhseRcptLine."Qty. Put Away (Base)" :=
              PostedWhseRcptLine."Qty. Put Away (Base)" + "Qty. to Handle (Base)";
            if "Qty. per Unit of Measure" = PostedWhseRcptLine."Qty. per Unit of Measure" then
                PostedWhseRcptLine."Qty. Put Away" :=
                  PostedWhseRcptLine."Qty. Put Away" + "Qty. to Handle"
            else
                PostedWhseRcptLine."Qty. Put Away" :=
                  Round(
                    PostedWhseRcptLine."Qty. Put Away" +
                    "Qty. to Handle (Base)" / PostedWhseRcptLine."Qty. per Unit of Measure");
            PostedWhseRcptLine.Status := PostedWhseRcptLine.GetLineStatus;
            OnBeforePostedWhseRcptLineModify(PostedWhseRcptLine, WhseActivityLine);
            PostedWhseRcptLine.Modify();
            OnAfterPostedWhseRcptLineModify(PostedWhseRcptLine);
        end;
    end;

    local procedure UpdateWhseIntPickLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        with WhseActivityLine do begin
            WhseInternalPickLine.Get("Whse. Document No.", "Whse. Document Line No.");
            if WhseInternalPickLine."Qty. (Base)" =
               WhseInternalPickLine."Qty. Picked (Base)" + "Qty. to Handle (Base)"
            then
                WhseInternalPickLine.Delete
            else begin
                WhseInternalPickLine."Qty. Picked (Base)" :=
                  WhseInternalPickLine."Qty. Picked (Base)" + "Qty. to Handle (Base)";
                if "Qty. per Unit of Measure" = WhseInternalPickLine."Qty. per Unit of Measure" then
                    WhseInternalPickLine."Qty. Picked" :=
                      WhseInternalPickLine."Qty. Picked" + "Qty. to Handle"
                else
                    WhseInternalPickLine."Qty. Picked" :=
                      Round(
                        WhseInternalPickLine."Qty. Picked" + "Qty. to Handle (Base)" / "Qty. per Unit of Measure");
                WhseInternalPickLine.Validate(
                  "Qty. Outstanding", WhseInternalPickLine."Qty. Outstanding" - "Qty. to Handle");
                WhseInternalPickLine.Status := WhseInternalPickLine.CalcStatusPickLine;
                OnBeforeWhseInternalPickLineModify(WhseInternalPickLine, WhseActivityLine);
                WhseInternalPickLine.Modify();
                OnAfterWhseInternalPickLineModify(WhseInternalPickLine);
            end;
        end;
    end;

    local procedure UpdateWhseIntPutAwayLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        with WhseActivityLine do begin
            WhseInternalPutAwayLine.Get("Whse. Document No.", "Whse. Document Line No.");
            if WhseInternalPutAwayLine."Qty. (Base)" =
               WhseInternalPutAwayLine."Qty. Put Away (Base)" + "Qty. to Handle (Base)"
            then
                WhseInternalPutAwayLine.Delete
            else begin
                WhseInternalPutAwayLine."Qty. Put Away (Base)" :=
                  WhseInternalPutAwayLine."Qty. Put Away (Base)" + "Qty. to Handle (Base)";
                if "Qty. per Unit of Measure" = WhseInternalPutAwayLine."Qty. per Unit of Measure" then
                    WhseInternalPutAwayLine."Qty. Put Away" :=
                      WhseInternalPutAwayLine."Qty. Put Away" + "Qty. to Handle"
                else
                    WhseInternalPutAwayLine."Qty. Put Away" :=
                      Round(
                        WhseInternalPutAwayLine."Qty. Put Away" +
                        "Qty. to Handle (Base)" / WhseInternalPutAwayLine."Qty. per Unit of Measure");
                WhseInternalPutAwayLine.Validate(
                  "Qty. Outstanding", WhseInternalPutAwayLine."Qty. Outstanding" - "Qty. to Handle");
                WhseInternalPutAwayLine.Status := WhseInternalPutAwayLine.CalcStatusPutAwayLine;
                OnBeforeWhseInternalPutAwayLineModify(WhseInternalPutAwayLine, WhseActivityLine);
                WhseInternalPutAwayLine.Modify();
                OnAfterWhseInternalPutAwayLineModify(WhseInternalPutAwayLine);
            end;
        end;
    end;

    local procedure UpdateProdCompLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        with WhseActivityLine do begin
            ProdCompLine.Get("Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
            ProdCompLine."Qty. Picked (Base)" :=
              ProdCompLine."Qty. Picked (Base)" + "Qty. to Handle (Base)";
            if "Qty. per Unit of Measure" = ProdCompLine."Qty. per Unit of Measure" then
                ProdCompLine."Qty. Picked" := ProdCompLine."Qty. Picked" + "Qty. to Handle"
            else
                ProdCompLine."Qty. Picked" :=
                  Round(ProdCompLine."Qty. Picked" + "Qty. to Handle (Base)" / "Qty. per Unit of Measure");
            ProdCompLine."Completely Picked" :=
              ProdCompLine."Qty. Picked" = ProdCompLine."Expected Quantity";
            OnBeforeProdCompLineModify(ProdCompLine, WhseActivityLine);
            ProdCompLine.Modify();
            OnAfterProdCompLineModify(ProdCompLine);
        end;
    end;

    local procedure UpdateAssemblyLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        with WhseActivityLine do begin
            AssemblyLine.Get("Source Subtype", "Source No.", "Source Line No.");
            AssemblyLine."Qty. Picked (Base)" :=
              AssemblyLine."Qty. Picked (Base)" + "Qty. to Handle (Base)";
            if "Qty. per Unit of Measure" = AssemblyLine."Qty. per Unit of Measure" then
                AssemblyLine."Qty. Picked" := AssemblyLine."Qty. Picked" + "Qty. to Handle"
            else
                AssemblyLine."Qty. Picked" :=
                  Round(AssemblyLine."Qty. Picked" + "Qty. to Handle (Base)" / "Qty. per Unit of Measure");
            OnBeforeAssemblyLineModify(AssemblyLine, WhseActivityLine);
            AssemblyLine.Modify();
            OnAfterAssemblyLineModify(AssemblyLine);
        end;
    end;

    procedure LocationGet(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetItemUnitOfMeasure(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    local procedure UpdateTempBinContentBuffer(WhseActivLine: Record "Warehouse Activity Line")
    var
        WMSMgt: Codeunit "WMS Management";
        UOMCode: Code[10];
        Sign: Integer;
    begin
        with WhseActivLine do begin
            if Location."Directed Put-away and Pick" then
                UOMCode := "Unit of Measure Code"
            else
                UOMCode := WMSMgt.GetBaseUOM("Item No.");
            if not TempBinContentBuffer.Get("Location Code", "Bin Code", "Item No.", "Variant Code", UOMCode, "Lot No.", "Serial No.")
            then begin
                TempBinContentBuffer.Init();
                TempBinContentBuffer."Location Code" := "Location Code";
                TempBinContentBuffer."Zone Code" := "Zone Code";
                TempBinContentBuffer."Bin Code" := "Bin Code";
                TempBinContentBuffer."Item No." := "Item No.";
                TempBinContentBuffer."Variant Code" := "Variant Code";
                TempBinContentBuffer."Unit of Measure Code" := UOMCode;
                TempBinContentBuffer.CopyTrackingFromWhseActivityLine(WhseActivLine);
                OnUpdateTempBinContentBufferOnBeforeInsert(TempBinContentBuffer, WhseActivLine);
                TempBinContentBuffer.Insert();
            end;
            Sign := 1;
            if "Action Type" = "Action Type"::Take then
                Sign := -1;

            TempBinContentBuffer."Base Unit of Measure" := WMSMgt.GetBaseUOM("Item No.");
            TempBinContentBuffer."Qty. to Handle (Base)" := TempBinContentBuffer."Qty. to Handle (Base)" + Sign * "Qty. to Handle (Base)";
            TempBinContentBuffer."Qty. Outstanding (Base)" :=
              TempBinContentBuffer."Qty. Outstanding (Base)" + Sign * "Qty. Outstanding (Base)";
            TempBinContentBuffer.Cubage := TempBinContentBuffer.Cubage + Sign * Cubage;
            TempBinContentBuffer.Weight := TempBinContentBuffer.Weight + Sign * Weight;
            TempBinContentBuffer.Modify();
        end;
    end;

    local procedure CheckBin()
    var
        Bin: Record Bin;
    begin
        with TempBinContentBuffer do begin
            SetFilter("Qty. to Handle (Base)", '>0');
            if Find('-') then
                repeat
                    SetRange("Qty. to Handle (Base)");
                    SetRange("Bin Code", "Bin Code");
                    CalcSums(Cubage, Weight);
                    Bin.Get("Location Code", "Bin Code");
                    Bin.CheckIncreaseBin(
                      "Bin Code", '', "Qty. to Handle (Base)", Cubage, Weight, Cubage, Weight, true, false);
                    SetFilter("Qty. to Handle (Base)", '>0');
                    Find('+');
                    SetRange("Bin Code");
                until Next = 0;
        end;
    end;

    local procedure CheckBinContent()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        BreakBulkQtyBaseToPlace: Decimal;
        AbsQtyToHandle: Decimal;
        AbsQtyToHandleBase: Decimal;
    begin
        with TempBinContentBuffer do begin
            SetFilter("Qty. to Handle (Base)", '<>0');
            if Find('-') then
                repeat
                    if "Qty. to Handle (Base)" < 0 then begin
                        BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
                        ItemTrackingMgt.GetWhseItemTrkgSetup(BinContent."Item No.", WhseItemTrackingSetup);

                        BinContent.ClearTrackingFilters();
                        BinContent.SetTrackingFilterFromBinContentBufferIfRequired(WhseItemTrackingSetup, TempBinContentBuffer);

                        BreakBulkQtyBaseToPlace := CalcBreakBulkQtyToPlace(TempBinContentBuffer);
                        GetItem("Item No.");
                        AbsQtyToHandleBase := Abs("Qty. to Handle (Base)");
                        AbsQtyToHandle :=
                          Round(AbsQtyToHandleBase / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"), UOMMgt.QtyRndPrecision);
                        if BreakBulkQtyBaseToPlace > 0 then
                            BinContent.CheckDecreaseBinContent(AbsQtyToHandle, AbsQtyToHandleBase, BreakBulkQtyBaseToPlace - "Qty. to Handle (Base)")
                        else
                            BinContent.CheckDecreaseBinContent(AbsQtyToHandle, AbsQtyToHandleBase, Abs("Qty. Outstanding (Base)"));
                        if AbsQtyToHandleBase <> Abs("Qty. to Handle (Base)") then begin
                            "Qty. to Handle (Base)" := AbsQtyToHandleBase * "Qty. to Handle (Base)" / Abs("Qty. to Handle (Base)");
                            Modify;
                        end;
                    end else begin
                        Bin.Get("Location Code", "Bin Code");
                        Bin.CheckWhseClass("Item No.", false);
                    end;
                until Next = 0;
        end;
    end;

    local procedure CalcBreakBulkQtyToPlace(TempBinContentBuffer: Record "Bin Content Buffer") QtyBase: Decimal
    var
        BreakBulkWhseActivLine: Record "Warehouse Activity Line";
    begin
        with TempBinContentBuffer do begin
            BreakBulkWhseActivLine.SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code",
              "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");
            BreakBulkWhseActivLine.SetRange("Item No.", "Item No.");
            BreakBulkWhseActivLine.SetRange("Bin Code", "Bin Code");
            BreakBulkWhseActivLine.SetRange("Location Code", "Location Code");
            BreakBulkWhseActivLine.SetRange("Action Type", BreakBulkWhseActivLine."Action Type"::Place);
            BreakBulkWhseActivLine.SetRange("Variant Code", "Variant Code");
            BreakBulkWhseActivLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
            BreakBulkWhseActivLine.SetFilter("Breakbulk No.", '<>0');
            BreakBulkWhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
            BreakBulkWhseActivLine.SetRange("No.", WhseActivHeader."No.");
            BreakBulkWhseActivLine.SetTrackingFilterFromBinContentBuffer(TempBinContentBuffer);
            if BreakBulkWhseActivLine.Find('-') then
                repeat
                    QtyBase := QtyBase + BreakBulkWhseActivLine."Qty. to Handle (Base)";
                until BreakBulkWhseActivLine.Next = 0;
        end;
        exit(QtyBase);
    end;

    local procedure CheckWhseItemTrkgLine(var WhseActivLine: Record "Warehouse Activity Line")
    var
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        QtyAvailToRegisterBase: Decimal;
        QtyAvailToInsertBase: Decimal;
        QtyToRegisterBase: Decimal;
    begin
        OnBeforeCheckWhseItemTrkgLine(WhseActivLine);

        if not
           ((WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::Pick) or
            (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement"))
        then
            exit;

        if WhseActivLine.Find('-') then
            repeat
                TempWhseActivLine := WhseActivLine;
                if not (TempWhseActivLine."Action Type" = TempWhseActivLine."Action Type"::Place) then
                    TempWhseActivLine.Insert();
            until WhseActivLine.Next = 0;

        TempWhseActivLine.SetCurrentKey("Item No.");
        if TempWhseActivLine.Find('-') then
            repeat
                TempWhseActivLine.SetRange("Item No.", TempWhseActivLine."Item No.");
                if ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLine."Item No.", WhseItemTrackingSetup) then
                    repeat
                        TempWhseActivLine.TestTrackingIfRequired(WhseItemTrackingSetup);
                    until TempWhseActivLine.Next = 0
                else begin
                    TempWhseActivLine.Find('+');
                    TempWhseActivLine.DeleteAll();
                end;
                TempWhseActivLine.SetRange("Item No.");
            until TempWhseActivLine.Next = 0;

        TempWhseActivLine.Reset();
        TempWhseActivLine.SetCurrentKey(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        TempWhseActivLine.SetRange("Breakbulk No.", 0);
        if TempWhseActivLine.Find('-') then
            repeat
                ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLine."Item No.", WhseItemTrackingSetup);
                // Per document
                TempWhseActivLine.SetSourceFilter(
                  TempWhseActivLine."Source Type", TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.",
                  TempWhseActivLine."Source Line No.", TempWhseActivLine."Source Subline No.", false);
                repeat
                    // Per Lot/SN
                    TempWhseActivLine.SetRange("Item No.", TempWhseActivLine."Item No.");
                    QtyAvailToInsertBase := CalcQtyAvailToInsertBase(TempWhseActivLine);
                    TempWhseActivLine.SetTrackingFilterFromWhseActivityLine(TempWhseActivLine);
                    QtyToRegisterBase := 0;
                    repeat
                        QtyToRegisterBase := QtyToRegisterBase + TempWhseActivLine."Qty. to Handle (Base)";
                    until TempWhseActivLine.Next = 0;

                    QtyAvailToRegisterBase := CalcQtyAvailToRegisterBase(TempWhseActivLine);
                    if QtyToRegisterBase > QtyAvailToRegisterBase then
                        QtyAvailToInsertBase -= QtyToRegisterBase - QtyAvailToRegisterBase;
                    OnBeforeCheckQtyAvailToInsertBase(TempWhseActivLine, QtyAvailToInsertBase);
                    if QtyAvailToInsertBase < 0 then
                        Error(
                          InsufficientQtyItemTrkgErr, TempWhseActivLine."Source Line No.", TempWhseActivLine."Source Document",
                          TempWhseActivLine."Source No.");

                    if TempWhseActivLine.TrackingExists then
                        if not IsQtyAvailToPickNonSpecificReservation(TempWhseActivLine, WhseItemTrackingSetup, QtyToRegisterBase) then
                            AvailabilityError(TempWhseActivLine);

                    // Clear filters, Lot/SN
                    TempWhseActivLine.ClearTrackingFilter;
                    TempWhseActivLine.SetRange("Item No.");
                until TempWhseActivLine.Next = 0; // Per Lot/SN
                                                  // Clear filters, document
                TempWhseActivLine.ClearSourceFilter;
            until TempWhseActivLine.Next = 0;   // Per document
    end;

    local procedure RegisterWhseItemTrkgLine(WhseActivLine2: Record "Warehouse Activity Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        QtyToRegisterBase: Decimal;
        DueDate: Date;
        NextEntryNo: Integer;
        WhseDocType2: Option;
        NeedRegisterWhseItemTrkgLine: Boolean;
    begin
        with WhseActivLine2 do begin
            if (("Whse. Document Type" in
                 ["Whse. Document Type"::Shipment, "Whse. Document Type"::"Internal Pick",
                  "Whse. Document Type"::Production, "Whse. Document Type"::Assembly, "Whse. Document Type"::"Internal Put-away"]) and
                ("Action Type" <> "Action Type"::Take) and ("Breakbulk No." = 0)) or
               (("Whse. Document Type" = "Whse. Document Type"::Receipt) and ("Action Type" <> "Action Type"::Place))
            then
                NeedRegisterWhseItemTrkgLine := true;

            if ("Activity Type" = "Activity Type"::"Invt. Movement") and ("Action Type" <> "Action Type"::Take) and
               ("Source Document" in ["Source Document"::"Prod. Consumption", "Source Document"::"Assembly Consumption"])
            then
                NeedRegisterWhseItemTrkgLine := true;

            if not NeedRegisterWhseItemTrkgLine then
                exit;
        end;

        if not ItemTrackingMgt.GetWhseItemTrkgSetup(WhseActivLine2."Item No.") then
            exit;

        QtyToRegisterBase := InitTempTrackingSpecification(WhseActivLine2, TempTrackingSpecification);

        TempTrackingSpecification.Reset();

        if QtyToRegisterBase > 0 then begin
            if (WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::Pick) or
               (WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::"Invt. Movement")
            then
                InsertRegWhseItemTrkgLine(WhseActivLine2, QtyToRegisterBase);

            if (WhseActivLine2."Whse. Document Type" in
                [WhseActivLine2."Whse. Document Type"::Shipment,
                 WhseActivLine2."Whse. Document Type"::Production,
                 WhseActivLine2."Whse. Document Type"::Assembly]) or
               ((WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::"Invt. Movement") and
                (WhseActivLine2."Source Type" > 0))
            then begin
                if (WhseActivLine2."Whse. Document Type" = WhseActivLine2."Whse. Document Type"::Shipment) and
                   WhseActivLine2."Assemble to Order"
                then
                    WhseDocType2 := WhseActivLine2."Whse. Document Type"::Assembly
                else
                    WhseDocType2 := WhseActivLine2."Whse. Document Type";
                case WhseDocType2 of
                    WhseActivLine2."Whse. Document Type"::Shipment:
                        begin
                            WhseShptLine.Get(WhseActivLine2."Whse. Document No.", WhseActivLine2."Whse. Document Line No.");
                            DueDate := WhseShptLine."Shipment Date";
                        end;
                    WhseActivLine2."Whse. Document Type"::Production:
                        begin
                            ProdOrderComp.Get(WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                              WhseActivLine2."Source Line No.", WhseActivLine2."Source Subline No.");
                            DueDate := ProdOrderComp."Due Date";
                        end;
                    WhseActivLine2."Whse. Document Type"::Assembly:
                        begin
                            AssemblyLine.Get(WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                              WhseActivLine2."Source Line No.");
                            DueDate := AssemblyLine."Due Date";
                        end;
                end;

                if WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::"Invt. Movement" then
                    case WhseActivLine2."Source Type" of
                        DATABASE::"Prod. Order Component":
                            begin
                                ProdOrderComp.Get(WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                                  WhseActivLine2."Source Line No.", WhseActivLine2."Source Subline No.");
                                DueDate := ProdOrderComp."Due Date";
                            end;
                        DATABASE::"Assembly Line":
                            begin
                                AssemblyLine.Get(WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                                  WhseActivLine2."Source Line No.");
                                DueDate := AssemblyLine."Due Date";
                            end;
                    end;

                NextEntryNo := TempTrackingSpecification.GetLastEntryNo() + 1;

                TempTrackingSpecification.Init();
                TempTrackingSpecification."Entry No." := NextEntryNo;
                if WhseActivLine."Source Type" = DATABASE::"Prod. Order Component" then
                    TempTrackingSpecification.SetSource(
                      WhseActivLine2."Source Type", WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                      WhseActivLine2."Source Subline No.", '', WhseActivLine2."Source Line No.")
                else
                    TempTrackingSpecification.SetSource(
                      WhseActivLine2."Source Type", WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                      WhseActivLine2."Source Line No.", '', 0);
                TempTrackingSpecification."Creation Date" := DueDate;
                TempTrackingSpecification."Qty. to Handle (Base)" := QtyToRegisterBase;
                TempTrackingSpecification."Item No." := WhseActivLine2."Item No.";
                TempTrackingSpecification."Variant Code" := WhseActivLine2."Variant Code";
                TempTrackingSpecification."Location Code" := WhseActivLine2."Location Code";
                TempTrackingSpecification.Description := WhseActivLine2.Description;
                TempTrackingSpecification."Qty. per Unit of Measure" := WhseActivLine2."Qty. per Unit of Measure";
                TempTrackingSpecification.CopyTrackingFromWhseActivityLine(WhseActivLine2);
                TempTrackingSpecification."Warranty Date" := WhseActivLine2."Warranty Date";
                TempTrackingSpecification."Expiration Date" := WhseActivLine2."Expiration Date";
                TempTrackingSpecification."Quantity (Base)" := QtyToRegisterBase;
                OnBeforeRegWhseItemTrkgLine(WhseActivLine2, TempTrackingSpecification);
                TempTrackingSpecification.Insert();
                OnAfterRegWhseItemTrkgLine(WhseActivLine2, TempTrackingSpecification);
            end;
        end;
    end;

    local procedure InitTempTrackingSpecification(WhseActivLine2: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary) QtyToRegisterBase: Decimal
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        QtyToHandleBase: Decimal;
    begin
        QtyToRegisterBase := WhseActivLine2."Qty. to Handle (Base)";
        SetPointerFilter(WhseActivLine2, WhseItemTrkgLine);

        with WhseItemTrkgLine do begin
            SetTrackingFilterFromWhseActivityLine(WhseActivLine2);
            if FindSet then
                repeat
                    if "Quantity (Base)" > "Qty. Registered (Base)" then begin
                        if QtyToRegisterBase > ("Quantity (Base)" - "Qty. Registered (Base)") then begin
                            QtyToHandleBase := "Quantity (Base)" - "Qty. Registered (Base)";
                            QtyToRegisterBase := QtyToRegisterBase - QtyToHandleBase;
                            "Qty. Registered (Base)" := "Quantity (Base)";
                        end else begin
                            "Qty. Registered (Base)" += QtyToRegisterBase;
                            QtyToHandleBase := QtyToRegisterBase;
                            QtyToRegisterBase := 0;
                        end;
                        if not UpdateTempTracking(WhseActivLine2, QtyToHandleBase, TempTrackingSpecification) then begin
                            TempTrackingSpecification.SetCurrentKey("Lot No.", "Serial No.");
                            TempTrackingSpecification.SetTrackingFilterFromWhseActivityLine(WhseActivLine2);
                            if TempTrackingSpecification.FindFirst then begin
                                TempTrackingSpecification."Qty. to Handle (Base)" += QtyToHandleBase;
                                TempTrackingSpecification.Modify();
                            end;
                        end;
                        ItemTrackingMgt.SetRegistering(true);
                        ItemTrackingMgt.CalcWhseItemTrkgLine(WhseItemTrkgLine);
                        Modify;
                    end;
                until (Next = 0) or (QtyToRegisterBase = 0);
        end;
    end;

    local procedure CalcQtyAvailToRegisterBase(WhseActivLine: Record "Warehouse Activity Line"): Decimal
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        SetPointerFilter(WhseActivLine, WhseItemTrackingLine);
        WhseItemTrackingLine.SetTrackingFilterFromWhseActivityLine(WhseActivLine);
        WhseItemTrackingLine.CalcSums("Quantity (Base)", "Qty. Registered (Base)");
        exit(WhseItemTrackingLine."Quantity (Base)" - WhseItemTrackingLine."Qty. Registered (Base)");
    end;

    local procedure SourceLineQtyBase(WhseActivLine: Record "Warehouse Activity Line"): Decimal
    var
        WhsePostedRcptLine: Record "Posted Whse. Receipt Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseIntPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseIntPickLine: Record "Whse. Internal Pick Line";
        ProdOrderComponent: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        WhseMovementWksh: Record "Whse. Worksheet Line";
        WhseActivLine2: Record "Warehouse Activity Line";
        QtyBase: Decimal;
        WhseDocType2: Option;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSourceLineQtyBase(WhseActivLine, QtyBase, IsHandled);
        if IsHandled then
            exit(QtyBase);

        if (WhseActivLine."Whse. Document Type" = WhseActivLine."Whse. Document Type"::Shipment) and
           WhseActivLine."Assemble to Order"
        then
            WhseDocType2 := WhseActivLine."Whse. Document Type"::Assembly
        else
            WhseDocType2 := WhseActivLine."Whse. Document Type";

        case WhseDocType2 of
            WhseActivLine."Whse. Document Type"::Receipt:
                if WhsePostedRcptLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhsePostedRcptLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::Shipment:
                if WhseShipmentLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhseShipmentLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::"Internal Put-away":
                if WhseIntPutAwayLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhseIntPutAwayLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::"Internal Pick":
                if WhseIntPickLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhseIntPickLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::Production:
                if ProdOrderComponent.Get(
                     WhseActivLine."Source Subtype", WhseActivLine."Source No.",
                     WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.")
                then
                    exit(ProdOrderComponent."Expected Qty. (Base)");
            WhseActivLine."Whse. Document Type"::Assembly:
                if AssemblyLine.Get(
                     WhseActivLine."Source Subtype", WhseActivLine."Source No.",
                     WhseActivLine."Source Line No.")
                then
                    exit(AssemblyLine."Quantity (Base)");
            WhseActivLine."Whse. Document Type"::"Movement Worksheet":
                if WhseMovementWksh.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Source No.",
                     WhseActivLine."Location Code", WhseActivLine."Source Line No.")
                then
                    exit(WhseMovementWksh."Qty. (Base)");
        end;

        if WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement" then
            case WhseActivLine."Source Document" of
                WhseActivLine."Source Document"::"Prod. Consumption":
                    if ProdOrderComponent.Get(
                         WhseActivLine."Source Subtype", WhseActivLine."Source No.",
                         WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.")
                    then
                        exit(ProdOrderComponent."Expected Qty. (Base)");
                WhseActivLine."Source Document"::"Assembly Consumption":
                    if AssemblyLine.Get(
                         WhseActivLine."Source Subtype", WhseActivLine."Source No.",
                         WhseActivLine."Source Line No.")
                    then
                        exit(AssemblyLine."Quantity (Base)");
                WhseActivLine."Source Document"::" ":
                    begin
                        QtyBase := 0;
                        WhseActivLine2.SetCurrentKey("No.", "Line No.", "Activity Type");
                        WhseActivLine2.SetRange("Activity Type", WhseActivLine."Activity Type");
                        WhseActivLine2.SetRange("No.", WhseActivLine."No.");
                        WhseActivLine2.SetFilter("Action Type", '<%1', WhseActivLine2."Action Type"::Place);
                        WhseActivLine2.SetFilter("Qty. to Handle (Base)", '<>0');
                        WhseActivLine2.SetRange("Breakbulk No.", 0);
                        if WhseActivLine2.Find('-') then
                            repeat
                                QtyBase += WhseActivLine2."Qty. (Base)";
                            until WhseActivLine2.Next = 0;
                        exit(QtyBase);
                    end;
            end;
    end;

    local procedure CalcQtyAvailToInsertBase(WhseActivLine: Record "Warehouse Activity Line"): Decimal
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        SetPointerFilter(WhseActivLine, WhseItemTrkgLine);
        WhseItemTrkgLine.CalcSums(WhseItemTrkgLine."Quantity (Base)");
        exit(SourceLineQtyBase(WhseActivLine) - WhseItemTrkgLine."Quantity (Base)");
    end;

    local procedure CalcQtyReservedOnInventory(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        with WhseActivLine do begin
            GetItem("Item No.");
            Item.SetRange("Location Filter", "Location Code");
            Item.SetRange("Variant Filter", "Variant Code");
            SetTrackingFilterToItemIfRequired(Item, WhseItemTrackingSetup);
            Item.CalcFields("Reserved Qty. on Inventory");
        end;
    end;

    local procedure InsertRegWhseItemTrkgLine(WhseActivLine: Record "Warehouse Activity Line"; QtyToRegisterBase: Decimal)
    var
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
        NextEntryNo: Integer;
    begin
        with WhseItemTrkgLine2 do begin
            NextEntryNo := WhseItemTrkgLine2.GetLastEntryNo() + 1;

            Init;
            "Entry No." := NextEntryNo;
            "Item No." := WhseActivLine."Item No.";
            Description := WhseActivLine.Description;
            "Variant Code" := WhseActivLine."Variant Code";
            "Location Code" := WhseActivLine."Location Code";
            SetPointer(WhseActivLine, WhseItemTrkgLine2);
            CopyTrackingFromWhseActivityLine(WhseActivLine);
            "Warranty Date" := WhseActivLine."Warranty Date";
            "Expiration Date" := WhseActivLine."Expiration Date";
            "Quantity (Base)" := QtyToRegisterBase;
            "Qty. per Unit of Measure" := WhseActivLine."Qty. per Unit of Measure";
            "Qty. Registered (Base)" := QtyToRegisterBase;
            "Created by Whse. Activity Line" := true;
            OnInsertRegWhseItemTrkgLineOnAfterCopyFields(WhseItemTrkgLine2, WhseActivLine);

            ItemTrackingMgt.SetRegistering(true);
            ItemTrackingMgt.CalcWhseItemTrkgLine(WhseItemTrkgLine2);
            Insert;
        end;
        OnAfterInsRegWhseItemTrkgLine(WhseActivLine, WhseItemTrkgLine2);
    end;

    procedure SetPointer(WhseActivLine: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        WhseDocType2: Option;
    begin
        with WhseActivLine do begin
            if ("Whse. Document Type" = "Whse. Document Type"::Shipment) and "Assemble to Order" then
                WhseDocType2 := "Whse. Document Type"::Assembly
            else
                WhseDocType2 := "Whse. Document Type";
            case WhseDocType2 of
                "Whse. Document Type"::Receipt:
                    WhseItemTrkgLine.SetSource(
                      DATABASE::"Posted Whse. Receipt Line", 0, "Whse. Document No.", "Whse. Document Line No.", '', 0);
                "Whse. Document Type"::Shipment:
                    WhseItemTrkgLine.SetSource(
                      DATABASE::"Warehouse Shipment Line", 0, "Whse. Document No.", "Whse. Document Line No.", '', 0);
                "Whse. Document Type"::"Internal Put-away":
                    WhseItemTrkgLine.SetSource(
                      DATABASE::"Whse. Internal Put-away Line", 0, "Whse. Document No.", "Whse. Document Line No.", '', 0);
                "Whse. Document Type"::"Internal Pick":
                    WhseItemTrkgLine.SetSource(
                      DATABASE::"Whse. Internal Pick Line", 0, "Whse. Document No.", "Whse. Document Line No.", '', 0);
                "Whse. Document Type"::Production:
                    WhseItemTrkgLine.SetSource(
                      DATABASE::"Prod. Order Component", "Source Subtype", "Source No.", "Source Subline No.", '', "Source Line No.");
                "Whse. Document Type"::Assembly:
                    WhseItemTrkgLine.SetSource(
                      DATABASE::"Assembly Line", "Source Subtype", "Source No.", "Source Line No.", '', 0);
                "Whse. Document Type"::"Movement Worksheet":
                    WhseItemTrkgLine.SetSource(
                      DATABASE::"Whse. Worksheet Line", 0, "Source No.", "Whse. Document Line No.",
                      CopyStr("Whse. Document No.", 1, MaxStrLen(WhseItemTrkgLine."Source Batch Name")), 0);
            end;
            WhseItemTrkgLine."Location Code" := "Location Code";
            if "Activity Type" = "Activity Type"::"Invt. Movement" then begin
                WhseItemTrkgLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Line No.", '', 0);
                if "Source Type" = DATABASE::"Prod. Order Component" then
                    WhseItemTrkgLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Subline No.", '', "Source Line No.")
                else
                    WhseItemTrkgLine.SetSource("Source Type", "Source Subtype", "Source No.", "Source Line No.", '', 0);
                WhseItemTrkgLine."Location Code" := "Location Code";
            end;
        end;
    end;

    procedure SetPointerFilter(WhseActivLine: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
    begin
        SetPointer(WhseActivLine, WhseItemTrkgLine2);
        WhseItemTrkgLine.SetSourceFilter(
          WhseItemTrkgLine2."Source Type", WhseItemTrkgLine2."Source Subtype",
          WhseItemTrkgLine2."Source ID", WhseItemTrkgLine2."Source Ref. No.", true);
        WhseItemTrkgLine.SetSourceFilter(WhseItemTrkgLine2."Source Batch Name", WhseItemTrkgLine2."Source Prod. Order Line");
        WhseItemTrkgLine.SetRange("Location Code", WhseItemTrkgLine2."Location Code");
    end;

    procedure ShowHideDialog(HideDialog2: Boolean)
    begin
        HideDialog := HideDialog2;
    end;

    local procedure CalcTotalAvailQtyToPick(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        CreatePick: Codeunit "Create Pick";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        BinTypeFilter: Text;
        TotalAvailQtyBase: Decimal;
        QtyInWhseBase: Decimal;
        QtyOnPickBinsBase: Decimal;
        QtyOnOutboundBinsBase: Decimal;
        QtyOnDedicatedBinsBase: Decimal;
        SubTotalBase: Decimal;
        QtyReservedOnPickShipBase: Decimal;
        LineReservedQtyBase: Decimal;
        QtyPickedNotShipped: Decimal;
    begin
        with WhseActivLine do begin
            CalcQtyReservedOnInventory(WhseActivLine, WhseItemTrackingSetup);

            LocationGet("Location Code");
            if Location."Directed Put-away and Pick" or
               ("Activity Type" = "Activity Type"::"Invt. Movement")
            then begin
                WhseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
                WhseEntry.SetRange("Item No.", "Item No.");
                WhseEntry.SetRange("Location Code", "Location Code");
                WhseEntry.SetRange("Variant Code", "Variant Code");
                SetTrackingFilterToWhseEntryIfRequired(WhseEntry, WhseItemTrackingSetup);
                WhseEntry.CalcSums("Qty. (Base)");
                QtyInWhseBase := WhseEntry."Qty. (Base)";

                BinTypeFilter := CreatePick.GetBinTypeFilter(0);
                if BinTypeFilter <> '' then
                    WhseEntry.SetFilter("Bin Type Code", '<>%1', BinTypeFilter); // Pick from all but Receive area
                WhseEntry.CalcSums("Qty. (Base)");
                QtyOnPickBinsBase := WhseEntry."Qty. (Base)";

                QtyOnOutboundBinsBase :=
                    WhseAvailMgt.CalcQtyOnOutboundBins("Location Code", "Item No.", "Variant Code", WhseItemTrackingSetup, true);

                if "Activity Type" <> "Activity Type"::"Invt. Movement" then // Invt. Movement from Dedicated Bin is allowed
                    QtyOnDedicatedBinsBase :=
                        WhseAvailMgt.CalcQtyOnDedicatedBins("Location Code", "Item No.", "Variant Code", "Lot No.", "Serial No.");

                SubTotalBase :=
                  QtyInWhseBase -
                  QtyOnPickBinsBase - QtyOnOutboundBinsBase - QtyOnDedicatedBinsBase;
                if "Activity Type" <> "Activity Type"::"Invt. Movement" then
                    SubTotalBase -= Abs(Item."Reserved Qty. on Inventory");

                if SubTotalBase < 0 then begin
                    CreatePick.FilterWhsePickLinesWithUndefinedBin(
                      WarehouseActivityLine, "Item No.", "Location Code", "Variant Code",
                      WhseItemTrackingSetup."Lot No. Required", "Lot No.",
                      WhseItemTrackingSetup."Serial No. Required", "Serial No.");
                    if WarehouseActivityLine.FindSet then
                        repeat
                            TempWhseActivLine2 := WarehouseActivityLine;
                            TempWhseActivLine2."Qty. Outstanding (Base)" *= -1;
                            TempWhseActivLine2.Insert();
                        until WarehouseActivityLine.Next = 0;

                    QtyReservedOnPickShipBase :=
                      WhseAvailMgt.CalcReservQtyOnPicksShips("Location Code", "Item No.", "Variant Code", TempWhseActivLine2);

                    LineReservedQtyBase :=
                      WhseAvailMgt.CalcLineReservedQtyOnInvt(
                        "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", true, '', '', TempWhseActivLine2);

                    if Abs(SubTotalBase) < QtyReservedOnPickShipBase + LineReservedQtyBase then
                        QtyReservedOnPickShipBase := Abs(SubTotalBase) - LineReservedQtyBase;

                    TotalAvailQtyBase :=
                      QtyOnPickBinsBase +
                      SubTotalBase +
                      QtyReservedOnPickShipBase +
                      LineReservedQtyBase;
                end else
                    TotalAvailQtyBase := QtyOnPickBinsBase;
            end else begin
                ItemLedgEntry.SetCurrentKey(
                  "Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgEntry.SetRange(Open, true);
                ItemLedgEntry.SetRange("Location Code", "Location Code");
                SetTrackingFilterToItemLedgEntryIfRequired(ItemLedgEntry, WhseItemTrackingSetup);
                ItemLedgEntry.CalcSums("Remaining Quantity");
                QtyInWhseBase := ItemLedgEntry."Remaining Quantity";

                QtyPickedNotShipped := CalcQtyPickedNotShipped(WhseActivLine, WhseItemTrackingSetup);

                LineReservedQtyBase :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", false, '', '', TempWhseActivLine2);

                TotalAvailQtyBase :=
                  QtyInWhseBase -
                  QtyPickedNotShipped -
                  Abs(Item."Reserved Qty. on Inventory") +
                  LineReservedQtyBase;
            end;

            exit(TotalAvailQtyBase);
        end;
    end;

    local procedure IsQtyAvailToPickNonSpecificReservation(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToRegister: Decimal): Boolean
    var
        QtyAvailToPick: Decimal;
    begin
        QtyAvailToPick := CalcTotalAvailQtyToPick(WhseActivLine, WhseItemTrackingSetup);
        if QtyAvailToPick < QtyToRegister then
            if ReleaseNonSpecificReservations(WhseActivLine, WhseItemTrackingSetup, QtyToRegister - QtyAvailToPick) then
                QtyAvailToPick := CalcTotalAvailQtyToPick(WhseActivLine, WhseItemTrackingSetup);

        exit(QtyAvailToPick >= QtyToRegister);
    end;

    local procedure CalcQtyPickedNotShipped(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyBasePicked: Decimal
    var
        ReservEntry: Record "Reservation Entry";
        RegWhseActivLine: Record "Registered Whse. Activity Line";
        QtyHandled: Decimal;
    begin
        with WhseActivLine do begin
            ReservEntry.Reset();
            ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
            ReservEntry.SetRange("Item No.", "Item No.");
            ReservEntry.SetRange("Variant Code", "Variant Code");
            ReservEntry.SetRange("Location Code", "Location Code");
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Surplus);
            ReservEntry.SetTrackingFilterFromWhseActivityLineIfRequired(WhseActivLine, WhseItemTrackingSetup);
            if ReservEntry.Find('-') then
                repeat
                    if not ((ReservEntry."Source Type" = "Source Type") and
                            (ReservEntry."Source Subtype" = "Source Subtype") and
                            (ReservEntry."Source ID" = "Source No.") and
                            ((ReservEntry."Source Ref. No." = "Source Line No.") or
                             (ReservEntry."Source Ref. No." = "Source Subline No."))) and
                       not ReservEntry.Positive
                    then
                        QtyBasePicked := QtyBasePicked + Abs(ReservEntry."Quantity (Base)");
                until ReservEntry.Next = 0;

            if WhseItemTrackingSetup."Serial No. Required" or WhseItemTrackingSetup."Lot No. Required" then begin
                RegWhseActivLine.SetRange("Activity Type", "Activity Type");
                RegWhseActivLine.SetRange("No.", "No.");
                RegWhseActivLine.SetRange("Line No.", "Line No.");
                RegWhseActivLine.SetTrackingFilterFromWhseActivityLine(WhseActivLine);
                RegWhseActivLine.SetRange("Bin Code", "Bin Code");
                if RegWhseActivLine.FindSet then
                    repeat
                        QtyHandled := QtyHandled + RegWhseActivLine."Qty. (Base)";
                    until RegWhseActivLine.Next = 0;
                QtyBasePicked := QtyBasePicked + QtyHandled;
            end else
                QtyBasePicked := QtyBasePicked + "Qty. Handled (Base)";
        end;

        exit(QtyBasePicked);
    end;

    procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    local procedure UpdateTempTracking(WhseActivLine2: Record "Warehouse Activity Line"; QtyToHandleBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        NextEntryNo: Integer;
        Inserted: Boolean;
    begin
        with WhseActivLine2 do begin
            NextEntryNo := TempTrackingSpecification.GetLastEntryNo() + 1;
            TempTrackingSpecification.Init();
            if WhseActivLine."Source Type" = DATABASE::"Prod. Order Component" then
                TempTrackingSpecification.SetSource("Source Type", "Source Subtype", "Source No.", "Source Subline No.", '', "Source Line No.")
            else
                TempTrackingSpecification.SetSource("Source Type", "Source Subtype", "Source No.", "Source Line No.", '', 0);

            ItemTrackingMgt.SetPointerFilter(TempTrackingSpecification);
            TempTrackingSpecification.SetTrackingFilterFromWhseActivityLine(WhseActivLine2);
            if TempTrackingSpecification.IsEmpty then begin
                TempTrackingSpecification."Entry No." := NextEntryNo;
                TempTrackingSpecification."Creation Date" := Today;
                TempTrackingSpecification."Qty. to Handle (Base)" := QtyToHandleBase;
                TempTrackingSpecification."Item No." := "Item No.";
                TempTrackingSpecification."Variant Code" := "Variant Code";
                TempTrackingSpecification."Location Code" := "Location Code";
                TempTrackingSpecification.Description := Description;
                TempTrackingSpecification."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                TempTrackingSpecification.CopyTrackingFromWhseActivityLine(WhseActivLine2);
                TempTrackingSpecification."Warranty Date" := "Warranty Date";
                TempTrackingSpecification."Expiration Date" := "Expiration Date";
                TempTrackingSpecification.Correction := true;
                OnBeforeTempTrackingSpecificationInsert(TempTrackingSpecification, WhseActivLine2);
                TempTrackingSpecification.Insert();
                Inserted := true;
                TempTrackingSpecification.Reset();
                OnAfterRegWhseItemTrkgLine(WhseActivLine2, TempTrackingSpecification);
            end;
        end;
        exit(Inserted);
    end;

    local procedure CheckItemTrackingInfoBlocked(ItemNo: Code[20]; VariantCode: Code[10]; SerialNo: Code[50]; LotNo: Code[50])
    var
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
    begin
        if (SerialNo = '') and (LotNo = '') then
            exit;

        if SerialNo <> '' then
            if SerialNoInfo.Get(ItemNo, VariantCode, SerialNo) then
                SerialNoInfo.TestField(Blocked, false);

        if LotNo <> '' then
            if LotNoInfo.Get(ItemNo, VariantCode, LotNo) then
                LotNoInfo.TestField(Blocked, false);
    end;

    local procedure UpdateWindow(ControlNo: Integer; Value: Code[20])
    begin
        if not HideDialog then
            case ControlNo of
                1:
                    begin
                        Window.Open(Text000 + Text001 + Text002);
                        Window.Update(1, Value);
                    end;
                2:
                    Window.Update(2, LineCount);
                3:
                    Window.Update(3, LineCount);
                4:
                    Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            end;
    end;

    local procedure CheckLines()
    begin
        OnBeforeCheckLines(WhseActivHeader, WhseActivLine, TempBinContentBuffer);

        with WhseActivHeader do begin
            TempBinContentBuffer.DeleteAll();
            LineCount := 0;
            if WhseActivLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    UpdateWindow(2, '');
                    WhseActivLine.CheckBinInSourceDoc;
                    WhseActivLine.TestField("Item No.");
                    if (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::Pick) and
                       (WhseActivLine."Destination Type" = WhseActivLine."Destination Type"::Customer)
                    then begin
                        WhseActivLine.TestField("Destination No.");
                        Cust.Get(WhseActivLine."Destination No.");
                        Cust.CheckBlockedCustOnDocs(Cust, "Source Document", false, false);
                    end;
                    if Location."Bin Mandatory" then begin
                        WhseActivLine.TestField("Unit of Measure Code");
                        WhseActivLine.TestField("Bin Code");
                        WhseActivLine.CheckWhseDocLine;
                        UpdateTempBinContentBuffer(WhseActivLine);
                    end;
                    OnAfterCheckWhseActivLine(WhseActivLine);

                    if ((WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::Pick) or
                        (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Pick") or
                        (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement")) and
                       (WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take)
                    then
                        CheckItemTrackingInfoBlocked(
                          WhseActivLine."Item No.", WhseActivLine."Variant Code", WhseActivLine."Serial No.", WhseActivLine."Lot No.");
                until WhseActivLine.Next = 0;
            NoOfRecords := LineCount;

            if Location."Bin Mandatory" then begin
                CheckBinContent;
                CheckBin;
            end;

            if "Registering No." = '' then begin
                TestField("Registering No. Series");
                "Registering No." := NoSeriesMgt.GetNextNo("Registering No. Series", "Assignment Date", true);
                Modify;
                if not SuppressCommit then
                    Commit();
            end;
        end;
    end;

    local procedure UpdateSourceDocForInvtMovement(WhseActivityLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSourceDocForInvtMovement(WhseActivityLine, IsHandled);
        if IsHandled then
            exit;

        if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take) or
           (WhseActivityLine."Source Document" = WhseActivityLine."Source Document"::" ")
        then
            exit;

        with WhseActivityLine do
            case "Source Document" of
                "Source Document"::"Prod. Consumption":
                    UpdateProdCompLine(WhseActivityLine);
                "Source Document"::"Assembly Consumption":
                    UpdateAssemblyLine(WhseActivityLine);
            end;
    end;

    local procedure AutoReserveForSalesLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary)
    var
        SalesLine: Record "Sales Line";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserveForSalesLine(TempWhseActivLineToReserve, IsHandled);
        if IsHandled then
            exit;

        if TempWhseActivLineToReserve.FindSet then
            repeat
                SalesLine.Get(
                  SalesLine."Document Type"::Order, TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.");

                if not IsSalesLineCompletelyReserved(SalesLine) then begin
                    ReservMgt.SetReservSource(SalesLine);
                    ReservMgt.SetTrackingFromWhseActivityLine(TempWhseActivLineToReserve);
                    ReservMgt.AutoReserve(
                      FullAutoReservation, '', SalesLine."Shipment Date", TempWhseActivLineToReserve."Qty. to Handle",
                      TempWhseActivLineToReserve."Qty. to Handle (Base)");
                end;
            until TempWhseActivLineToReserve.Next = 0;
    end;

    local procedure CheckAndRemoveOrderToOrderBinding(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary)
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        IsConfirmed: Boolean;
    begin
        if TempWhseActivLineToReserve.FindSet then
            repeat
                SalesLine.Get(
                  SalesLine."Document Type"::Order, TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.");
                ReservationEntry.SetSourceFilter(
                  DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", true);
                ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
                ReservationEntry.SetRange(Binding, ReservationEntry.Binding::"Order-to-Order");

                if ReservationEntry.FindSet() then
                    if not ReservMgt.ReservEntryPositiveTypeIsItemLedgerEntry(ReservationEntry."Entry No.") then begin
                        if not IsConfirmed and GuiAllowed then
                            if not Confirm(OrderToOrderBindingOnSalesLineQst) then
                                Error(RegisterInterruptedErr);
                        IsConfirmed := true;
                        repeat
                            ReservationEngineMgt.CancelReservation(ReservationEntry);
                            ReservMgt.SetReservSource(SalesLine);
                            ReservMgt.SetItemTrackingHandling(1);
                            ReservMgt.ClearSurplus();
                        until ReservationEntry.Next() = 0;
                    end;
            until TempWhseActivLineToReserve.Next() = 0;
    end;

    local procedure CopyWhseActivityLineToReservBuf(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyWhseActivityLineToReservBuf(TempWhseActivLineToReserve, WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        if not IsPickPlaceForSalesOrderTrackedItem(WhseActivLine) then
            exit;

        TempWhseActivLineToReserve.TransferFields(WhseActivLine);
        TempWhseActivLineToReserve.Insert();
    end;

    local procedure GroupWhseActivLinesByWhseDocAndSource(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        with TempWarehouseActivityLine do begin
            SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type");
            SetRange("Whse. Document No.", WarehouseActivityLine."Whse. Document No.");
            SetRange("Whse. Document Line No.", WarehouseActivityLine."Whse. Document Line No.");
            SetRange("Source Document", WarehouseActivityLine."Source Document");
            SetSourceFilter(
              WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
              WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.", false);
            SetRange("Action Type", WarehouseActivityLine."Action Type");
            SetRange("Original Breakbulk", WarehouseActivityLine."Original Breakbulk");
            SetRange("Breakbulk No.", WarehouseActivityLine."Breakbulk No.");
            if FindFirst then begin
                "Qty. to Handle" += WarehouseActivityLine."Qty. to Handle";
                "Qty. to Handle (Base)" += WarehouseActivityLine."Qty. to Handle (Base)";
                Modify;
            end else begin
                TempWarehouseActivityLine := WarehouseActivityLine;
                Insert;
            end;
        end;
    end;

    local procedure ReleaseNonSpecificReservations(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToRelease: Decimal): Boolean
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        xReservedQty: Decimal;
    begin
        if QtyToRelease <= 0 then
            exit;

        CalcQtyReservedOnInventory(WhseActivLine, WhseItemTrackingSetup);

        if WhseItemTrackingSetup.TrackingRequired() then
            if Item."Reserved Qty. on Inventory" > 0 then begin
                xReservedQty := Item."Reserved Qty. on Inventory";
                LateBindingMgt.ReleaseForReservation(
                  WhseActivLine."Item No.", WhseActivLine."Variant Code", WhseActivLine."Location Code",
                  WhseActivLine."Serial No.", WhseActivLine."Lot No.", QtyToRelease);
                Item.CalcFields("Reserved Qty. on Inventory");
            end;

        exit(xReservedQty > Item."Reserved Qty. on Inventory");
    end;

    local procedure AvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Serial No." <> '' then
            Error(Text005, WhseActivLine.FieldCaption("Serial No."), WhseActivLine."Serial No.");

        if WhseActivLine."Lot No." <> '' then
            Error(Text005, WhseActivLine.FieldCaption("Lot No."), WhseActivLine."Lot No.");
    end;

    local procedure IsPickPlaceForSalesOrderTrackedItem(WhseActivityLine: Record "Warehouse Activity Line"): Boolean
    begin
        exit(
          (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Pick) and
          (WhseActivityLine."Action Type" in [WhseActivityLine."Action Type"::Place, WhseActivityLine."Action Type"::" "]) and
          (WhseActivityLine."Source Document" = WhseActivityLine."Source Document"::"Sales Order") and
          WhseActivityLine.TrackingExists);
    end;

    local procedure IsSalesLineCompletelyReserved(SalesLine: Record "Sales Line"): Boolean
    begin
        SalesLine.CalcFields("Reserved Quantity");
        exit(SalesLine.Quantity = SalesLine."Reserved Quantity");
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineDelete(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SkipDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineModify(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRegActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRegActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RegisteredWhseActivLine: Record "Registered Whse. Activity Line"; var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLines(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempBinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegWhseItemTrkgLine(var WhseActivLine2: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsRegWhseItemTrkgLine(var WhseActivLine2: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseRcptLineModify(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdCompLineModify(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterWhseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredInvtMovementHdrInsert(var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredInvtMovementLineInsert(var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredWhseActivHeaderInsert(var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredWhseActivLineInsert(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseInternalPickLineModify(var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseInternalPutAwayLineModify(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssemblyLineModify(var AssemblyLine: Record "Assembly Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveForSalesLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseRcptLineModify(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdCompLineModify(var ProdOrderComponent: Record "Prod. Order Component"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegWhseItemTrkgLine(var WhseActivLine2: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredInvtMovementHdrInsert(var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredInvtMovementLineInsert(var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredWhseActivHeaderInsert(var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredWhseActivLineInsert(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyWhseActivityLineToReservBuf(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyAvailToInsertBase(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var QtyAvailToInsertBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdWhseActivHeader(var WhseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; QtyToHandle: Decimal; QtyToHandleBase: Decimal; QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivHeaderDelete(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var SkipDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRegActLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRegInvtMovementLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseItemTrkgLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommit(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRegActivHeader(var WhseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean; var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSourceLineQtyBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineModify(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseJnlRegisterLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSourceDocForInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseDocHeader(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseSourceDocLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseInternalPickLineModify(var WhseInternalPickLine: Record "Whse. Internal Pick Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseInternalPutAwayLineModify(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRegWhseItemTrkgLineOnAfterCopyFields(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTempBinContentBufferOnBeforeInsert(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}


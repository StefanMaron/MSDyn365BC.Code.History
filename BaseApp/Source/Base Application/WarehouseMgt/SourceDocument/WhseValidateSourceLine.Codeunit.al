codeunit 5777 "Whse. Validate Source Line"
{

    trigger OnRun()
    begin
    end;

    var
        WhseActivLine: Record "Warehouse Activity Line";
        TableCaptionValue: Text;

        Text000: Label 'must not be changed when a %1 for this %2 exists: ';
        Text001: Label 'The %1 cannot be deleted when a related %2 exists.';
        Text002: Label 'You cannot post consumption for order no. %1 because a quantity of %2 remains to be picked.';
        JobPostQtyPickRemainErr: Label 'You cannot post usage for job number %1 because a quantity of %2 remains to be picked.', Comment = '%1 = Job number, %2 = remaining quantity to pick';

    procedure SalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineVerifyChange(NewSalesLine, OldSalesLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseLinesExist(
             DATABASE::"Sales Line", NewSalesLine."Document Type".AsInteger(), NewSalesLine."Document No.", NewSalesLine."Line No.", 0,
             NewSalesLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewSalesLine);
        OldRecRef.GetTable(OldSalesLine);
        with NewSalesLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Type));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Drop Shipment"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Purchase Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Purch. Order Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Job No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Qty. to Ship"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Qty. to Assemble to Order"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Shipment Date"));
        end;

        OnAfterSalesLineVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure SalesLineDelete(var SalesLine: Record "Sales Line")
    begin
        if WhseLinesExist(
             DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.",
             SalesLine."Line No.", 0, SalesLine.Quantity)
        then
            Error(Text001, SalesLine.TableCaption(), TableCaptionValue);

        OnAfterSalesLineDelete(SalesLine);
    end;

    procedure ServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceLineVerifyChange(NewServiceLine, OldServiceLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseLinesExist(
             DATABASE::"Service Line", NewServiceLine."Document Type".AsInteger(), NewServiceLine."Document No.", NewServiceLine."Line No.", 0,
             NewServiceLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewServiceLine);
        OldRecRef.GetTable(OldServiceLine);
        with NewServiceLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Type));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
        end;

        OnAfterServiceLineVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure ServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
        if WhseLinesExist(
             DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.",
             ServiceLine."Line No.", 0, ServiceLine.Quantity)
        then
            Error(Text001, ServiceLine.TableCaption(), TableCaptionValue);

        OnAfterServiceLineDelete(ServiceLine);
    end;

    procedure VerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNumber, IsHandled);
        if IsHandled then
            exit;

        VerifyFieldHasSameValue(NewRecRef, OldRecRef, FieldNumber, StrSubstNo(Text000, TableCaptionValue, NewRecRef.Caption));
    end;

    procedure VerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer; ErrorMessage: Text)
    begin
        VerifyFieldHasSameValue(NewRecRef, OldRecRef, FieldNumber, ErrorMessage);
    end;

    local procedure VerifyFieldHasSameValue(FirstRecordRef: RecordRef; SecondRecordRef: RecordRef; FieldNumber: Integer; ErrorMessage: Text)
    var
        FirstFieldRef: FieldRef;
        SecondFieldRef: FieldRef;
    begin
        FirstFieldRef := FirstRecordRef.Field(FieldNumber);
        SecondFieldRef := SecondRecordRef.Field(FieldNumber);

        if Format(FirstFieldRef.Value) <> Format(SecondFieldRef.Value) then
            FirstFieldRef.FieldError(ErrorMessage);
    end;

    local procedure FieldValueIsChanged(FirstRecordRef: RecordRef; SecondRecordRef: RecordRef; FieldNumber: Integer): Boolean
    var
        FirstFieldRef: FieldRef;
        SecondFieldRef: FieldRef;
    begin
        FirstFieldRef := FirstRecordRef.Field(FieldNumber);
        SecondFieldRef := SecondRecordRef.Field(FieldNumber);

        if Format(FirstFieldRef.Value) <> Format(SecondFieldRef.Value) then
            exit(true);

        exit(false);
    end;

    procedure PurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line")
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseLineVerifyChange(NewPurchLine, OldPurchLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseLinesExist(
             DATABASE::"Purchase Line", NewPurchLine."Document Type".AsInteger(), NewPurchLine."Document No.",
             NewPurchLine."Line No.", 0, NewPurchLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewPurchLine);
        OldRecRef.GetTable(OldPurchLine);
        with NewPurchLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Type));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Drop Shipment"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Sales Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Sales Order Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Special Order"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Special Order Sales No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Special Order Sales Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Job No."));
            if not OverReceiptMgt.IsQuantityUpdatedFromWarehouseOverReceipt(NewPurchLine) then
                VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Qty. to Receive"));
        end;

        OnAfterPurchaseLineVerifyChange(NewPurchLine, OldPurchLine, NewRecRef, OldRecRef);
    end;

    procedure PurchaseLineDelete(var PurchLine: Record "Purchase Line")
    begin
        if WhseLinesExist(
             DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.", 0, PurchLine.Quantity)
        then
            Error(Text001, PurchLine.TableCaption(), TableCaptionValue);

        OnAfterPurchaseLineDelete(PurchLine);
    end;

    procedure TransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransLineVerifyChange(NewTransLine, OldTransLine, IsHandled);
        if IsHandled then
            exit;

        with NewTransLine do begin
            if WhseLinesExist(DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0, Quantity) then begin
                TransLineCommonVerification(NewTransLine, OldTransLine);
                if "Qty. to Ship" <> OldTransLine."Qty. to Ship" then
                    FieldError("Qty. to Ship", StrSubstNo(Text000, TableCaptionValue, TableCaption));
            end;

            if WhseLinesExist(DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0, Quantity) then begin
                TransLineCommonVerification(NewTransLine, OldTransLine);
                if "Qty. to Receive" <> OldTransLine."Qty. to Receive" then
                    FieldError("Qty. to Receive", StrSubstNo(Text000, TableCaptionValue, TableCaption));
            end;
        end;

        OnAfterTransLineVerifyChange(NewTransLine, OldTransLine);
    end;

    local procedure TransLineCommonVerification(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        with NewTransLine do begin
            if "Item No." <> OldTransLine."Item No." then
                FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, TableCaption));

            if "Variant Code" <> OldTransLine."Variant Code" then
                FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

            if "Unit of Measure Code" <> OldTransLine."Unit of Measure Code" then
                FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

            IsHandled := false;
            OnTransLineCommonVerificationOnBeforeQuantityCheck(OldTransLine, NewTransLine, IsHandled);
            if not IsHandled then
                if Quantity <> OldTransLine.Quantity then
                    FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, TableCaption));
        end;
    end;

    procedure TransLineDelete(var TransLine: Record "Transfer Line")
    begin
        with TransLine do begin
            if WhseLinesExist(DATABASE::"Transfer Line", 0, "Document No.", "Line No.", 0, Quantity) then
                Error(Text001, TableCaption(), TableCaptionValue);
            if WhseLinesExist(DATABASE::"Transfer Line", 1, "Document No.", "Line No.", 0, Quantity) then
                Error(Text001, TableCaption(), TableCaptionValue);
        end;

        OnAfterTransLineDelete(TransLine);
    end;

    procedure WhseLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal) Result: Boolean
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty, TableCaptionValue, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 1) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 5) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 1) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 5) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 1))
        then begin
            WhseManagement.SetSourceFilterForWhseRcptLine(WhseRcptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            OnWhseLinesExistOnAfterWhseRcptLineSetFilters(WhseRcptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceQty);
            if not WhseRcptLine.IsEmpty() then begin
                TableCaptionValue := WhseRcptLine.TableCaption();
                exit(true);
            end;
        end;

        if ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 1) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Purchase Line") and (SourceSubType = 5) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 1) and (SourceQty >= 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 5) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 0)) or
           ((SourceType = DATABASE::"Service Line") and (SourceSubType = 1))
        then begin
            WhseShptLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            OnWhseLinesExistOnAfterWhseShptLineSetFilters(WhseShptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceQty, IsHandled);
            if not IsHandled then
                if not WhseShptLine.IsEmpty() then begin
                    TableCaptionValue := WhseShptLine.TableCaption();
                    exit(true);
                end;
        end;

        WhseActivLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, true);
        if not WhseActivLine.IsEmpty() then begin
            TableCaptionValue := WhseActivLine.TableCaption();
            exit(true);
        end;

        TableCaptionValue := '';
        exit(false);
    end;

    procedure WhseLinesExistWithTableCaptionOut(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValueOut: Text[100]): Boolean
    var
        Success: Boolean;
    begin
        Success := WhseLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty);
        TableCaptionValueOut := TableCaptionValue;
        exit(Success);
    end;

    procedure WhseWorkSheetLinesExistForJobOrProdOrderComponent(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal): Boolean
    var
    begin
        if not (SourceType in [Database::Job, Database::"Prod. Order Component"]) then begin
            TableCaptionValue := '';
            exit(false);
        end;

        exit(WhseWorkSheetLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty));
    end;

    local procedure WhseWorkSheetLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal) Result: Boolean
    var
        WhseWorkSheetLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseWorkSheetLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty, TableCaptionValue, Result, IsHandled);
        if IsHandled then
            exit(Result);

        WhseWorkSheetLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
        if not WhseWorkSheetLine.IsEmpty() then begin
            TableCaptionValue := WhseWorkSheetLine.TableCaption();
            exit(true);
        end;

        TableCaptionValue := '';
        exit(false);
    end;

    procedure ProdComponentVerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProdComponentVerifyChange(NewProdOrderComp, OldProdOrderComp, IsHandled);
        if IsHandled then
            exit;

        if not WhseLinesExist(
             DATABASE::"Prod. Order Component", OldProdOrderComp.Status.AsInteger(), OldProdOrderComp."Prod. Order No.",
             OldProdOrderComp."Prod. Order Line No.", OldProdOrderComp."Line No.", OldProdOrderComp.Quantity)
        then begin
            NewRecRef.GetTable(NewProdOrderComp);
            OldRecRef.GetTable(OldProdOrderComp);
            if FieldValueIsChanged(NewRecRef, OldRecRef, NewProdOrderComp.FieldNo(Status)) then begin
                if not WhseWorkSheetLinesExist(
                    Database::"Prod. Order Component", OldProdOrderComp.Status.AsInteger(), OldProdOrderComp."Prod. Order No.",
                    OldProdOrderComp."Prod. Order Line No.", OldProdOrderComp."Line No.", OldProdOrderComp.Quantity)
                then
                    exit;
            end else
                exit;
        end;

        NewRecRef.GetTable(NewProdOrderComp);
        OldRecRef.GetTable(OldProdOrderComp);
        with NewProdOrderComp do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Status));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Prod. Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Prod. Order Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Item No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Due Date"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Quantity per"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Expected Quantity"));
        end;

        OnAfterProdComponentVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure ProdComponentDelete(var ProdOrderComp: Record "Prod. Order Component")
    begin
        if WhseLinesExist(
             DATABASE::"Prod. Order Component",
             ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.",
             ProdOrderComp."Line No.", ProdOrderComp.Quantity)
        then
            Error(Text001, ProdOrderComp.TableCaption(), TableCaptionValue);

        if WhseWorkSheetLinesExist(
            Database::"Prod. Order Component",
            ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.",
            ProdOrderComp."Line No.", ProdOrderComp.Quantity)
        then
            Error(Text001, ProdOrderComp.TableCaption(), TableCaptionValue);

        OnAfterProdComponentDelete(ProdOrderComp);
    end;

    procedure JobPlanningLineVerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; FieldNo: Integer)
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if not WhseLinesExist(
             DATABASE::Job, 0, NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Contract Entry No.", NewJobPlanningLine."Line No.", NewJobPlanningLine.Quantity)
        then
            if not WhseWorkSheetLinesExist(
                Database::Job, 0, NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Contract Entry No.", NewJobPlanningLine."Line No.", NewJobPlanningLine.Quantity)
            then
                exit;

        NewRecRef.GetTable(NewJobPlanningLine);
        OldRecRef.GetTable(OldJobPlanningLine);
        VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo);
    end;

    procedure JobPlanningLineDelete(var JobPlanningLine: Record "Job Planning Line")
    begin
        if WhseLinesExist(DATABASE::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", JobPlanningLine.Quantity) then
            Error(Text001, JobPlanningLine.TableCaption(), TableCaptionValue);

        if WhseWorkSheetLinesExist(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", JobPlanningLine.Quantity) then
            Error(Text001, JobPlanningLine.TableCaption(), TableCaptionValue);
    end;

    procedure ItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    var
        AssemblyLine: Record "Assembly Line";
        ProdOrderComp: Record "Prod. Order Component";
        Location: Record Location;
        LinesExist: Boolean;
        QtyChecked: Boolean;
        QtyRemainingToBePicked: Decimal;
        IsHandled: Boolean;
    begin
        with NewItemJnlLine do begin
            case "Entry Type" of
                "Entry Type"::"Assembly Consumption":
                    begin
                        TestField("Order Type", "Order Type"::Assembly);
                        if Location.Get("Location Code") and Location."Require Pick" and Location."Require Shipment" then
                            if AssemblyLine.Get(AssemblyLine."Document Type"::Order, "Order No.", "Order Line No.") and
                               (Quantity >= 0)
                            then begin
                                QtyRemainingToBePicked := Quantity - AssemblyLine."Qty. Picked";
                                CheckQtyRemainingToBePickedForAssemblyConsumption(NewItemJnlLine, OldItemJnlLine, QtyRemainingToBePicked);
                                QtyChecked := true;
                            end;

                        LinesExist := false;
                    end;
                "Entry Type"::Consumption:
                    begin
                        TestField("Order Type", "Order Type"::Production);
                        IsHandled := false;
                        OnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJnlLine, Location, QtyChecked, IsHandled);
                        if not Ishandled then
                            if Location.Get("Location Code") and Location."Require Pick" and Location."Require Shipment" then
                                if ProdOrderComp.Get(
                                    ProdOrderComp.Status::Released,
                                    "Order No.", "Order Line No.", "Prod. Order Comp. Line No.") and
                                    (ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::Manual) and
                                    (Quantity >= 0)
                                then begin
                                    QtyRemainingToBePicked :=
                                        Quantity - CalcNextLevelProdOutput(ProdOrderComp) -
                                        ProdOrderComp."Qty. Picked" + ProdOrderComp."Expected Quantity" - ProdOrderComp."Remaining Quantity";
                                    CheckQtyRemainingToBePickedForConsumption(NewItemJnlLine, OldItemJnlLine, ProdOrderComp, QtyRemainingToBePicked);
                                    QtyChecked := true;
                                end;

                        LinesExist :=
                          WhseLinesExist(
                            DATABASE::"Prod. Order Component", 3, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.", Quantity) or
                          WhseWorkSheetLinesExist(
                            Database::"Prod. Order Component", 3, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.", Quantity);
                    end;
                "Entry Type"::Output:
                    begin
                        TestField("Order Type", "Order Type"::Production);
                        LinesExist :=
                          WhseLinesExist(
                            DATABASE::"Prod. Order Line", 3, "Order No.", "Order Line No.", 0, Quantity);
                    end;
                else
                    LinesExist := false;
            end;

            if LinesExist then begin
                if ("Item No." <> OldItemJnlLine."Item No.") and
                   (OldItemJnlLine."Item No." <> '')
                then
                    FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if ("Variant Code" <> OldItemJnlLine."Variant Code") and
                   (OldItemJnlLine."Variant Code" <> '')
                then
                    FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if ("Location Code" <> OldItemJnlLine."Location Code") and
                   (OldItemJnlLine."Location Code" <> '')
                then
                    FieldError("Location Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if ("Unit of Measure Code" <> OldItemJnlLine."Unit of Measure Code") and
                   (OldItemJnlLine."Unit of Measure Code" <> '')
                then
                    FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, TableCaption));

                if (Quantity <> OldItemJnlLine.Quantity) and
                   (OldItemJnlLine.Quantity <> 0) and
                   not QtyChecked
                then
                    FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, TableCaption));
            end;
        end;

        OnAfterItemLineVerifyChange(NewItemJnlLine, OldItemJnlLine);
    end;

    internal procedure JobJnlLineVerifyChangeForWhsePick(var NewJobJnlLine: Record "Job Journal Line"; var OldJobJnlLine: Record "Job Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        QtyRemainingToBePicked: Decimal;
    begin
        if IsWhsePickRequiredForJobJnlLine(NewJobJnlLine) and (NewJobJnlLine.Quantity > 0) then
            if JobPlanningLine.Get(NewJobJnlLine."Job No.", NewJobJnlLine."Job Task No.", NewJobJnlLine."Job Planning Line No.") and (NewJobJnlLine.Quantity >= 0) then begin
                QtyRemainingToBePicked := NewJobJnlLine.Quantity + JobPlanningLine."Qty. Posted" - JobPlanningLine."Qty. Picked";
                CheckQtyRemainingToBePickedForJob(NewJobJnlLine, QtyRemainingToBePicked);
            end;
    end;

    internal procedure IsWhsePickRequiredForJobJnlLine(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Location: Record Location;
        Item: Record Item;
    begin
        if (JobJournalLine."Line Type" in [JobJournalLine."Line Type"::Budget, JobJournalLine."Line Type"::"Both Budget and Billable"]) and (JobJournalLine.Type = JobJournalLine.Type::Item) then
            if Location.Get(JobJournalLine."Location Code") then
                if Location."Require Pick" and Location."Require Shipment" then
                    if Item.Get(JobJournalLine."No.") then
                        if Item.IsInventoriableType() then
                            exit(true);
    end;

    internal procedure IsInventoryPickRequiredForJobJnlLine(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Location: Record Location;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if (JobJournalLine."Line Type" in [JobJournalLine."Line Type"::Budget, JobJournalLine."Line Type"::"Both Budget and Billable"]) and (JobJournalLine.Type = JobJournalLine.Type::Item) then
            if Location.RequirePicking(JobJournalLine."Location Code") and (not Location.RequireShipment(JobJournalLine."Location Code")) then begin
                if JobJournalLine."Job Planning Line No." <> 0 then
                    WarehouseActivityLine.SetRange("Source Subline No.", JobJournalLine."Job Planning Line No.");
                WarehouseActivityLine.SetRange("Source Type", Database::Job);
                WarehouseActivityLine.SetRange("Source No.", JobJournalLine."Job No.");
                exit(not WarehouseActivityLine.IsEmpty());
            end;
    end;

    local procedure CheckQtyRemainingToBePickedForAssemblyConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; QtyRemainingToBePicked: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, QtyRemainingToBePicked);
        if IsHandled then
            exit;

        CheckQtyRemainingToBePicked(QtyRemainingToBePicked, NewItemJnlLine."Order No.");
    end;

    local procedure CheckQtyRemainingToBePickedForConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; ProdOrderComp: Record "Prod. Order Component"; QtyRemainingToBePicked: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyRemainingToBePickedForConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, ProdOrderComp, QtyRemainingToBePicked);
        if IsHandled then
            exit;

        CheckQtyRemainingToBePicked(QtyRemainingToBePicked, NewItemJnlLine."Order No.");
    end;

    local procedure CheckQtyRemainingToBePickedForJob(NewJobJnlLine: Record "Job Journal Line"; QtyRemainingToBePicked: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyRemainingToBePickedForJob(NewJobJnlLine, QtyRemainingToBePicked, IsHandled);
        if IsHandled then
            exit;

        if QtyRemainingToBePicked > 0 then
            Error(JobPostQtyPickRemainErr, NewJobJnlLine."Job No.", QtyRemainingToBePicked);
    end;

    local procedure CheckQtyRemainingToBePicked(QtyRemainingToBePicked: Decimal; OrderNo: Code[20])
    begin
        if QtyRemainingToBePicked > 0 then
            Error(Text002, OrderNo, QtyRemainingToBePicked);
    end;

    procedure ProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if not WhseLinesExist(
             DATABASE::"Prod. Order Line", OldProdOrderLine.Status.AsInteger(), OldProdOrderLine."Prod. Order No.",
             OldProdOrderLine."Line No.", 0, OldProdOrderLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewProdOrderLine);
        OldRecRef.GetTable(OldProdOrderLine);
        with NewProdOrderLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Status));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Prod. Order No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Item No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Due Date"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
        end;

        OnAfterProdOrderLineVerifyChange(NewProdOrderLine, OldProdOrderLine, NewRecRef, OldRecRef);
    end;

    procedure ProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
        with ProdOrderLine do
            if WhseLinesExist(
                 DATABASE::"Prod. Order Line", Status.AsInteger(), "Prod. Order No.", "Line No.", 0, Quantity)
            then
                Error(Text001, TableCaption(), TableCaptionValue);

        OnAfterProdOrderLineDelete(ProdOrderLine);
    end;

    procedure AssemblyLineVerifyChange(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        Location: Record Location;
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        if OldAssemblyLine.Type <> OldAssemblyLine.Type::Item then
            exit;

        if not WhseLinesExist(
             DATABASE::"Assembly Line", NewAssemblyLine."Document Type".AsInteger(), NewAssemblyLine."Document No.",
             NewAssemblyLine."Line No.", 0, NewAssemblyLine.Quantity)
        then
            exit;

        NewRecRef.GetTable(NewAssemblyLine);
        OldRecRef.GetTable(OldAssemblyLine);
        with NewAssemblyLine do begin
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Document Type"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Document No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Line No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("No."));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Variant Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Location Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Unit of Measure Code"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Due Date"));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo(Quantity));
            VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Quantity per"));
            if Location.Get("Location Code") and not Location."Require Shipment" then
                VerifyFieldNotChanged(NewRecRef, OldRecRef, FieldNo("Quantity to Consume"));
        end;

        OnAfterAssemblyLineVerifyChange(NewRecRef, OldRecRef);
    end;

    procedure AssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
        if AssemblyLine.Type <> AssemblyLine.Type::Item then
            exit;

        if WhseLinesExist(
             DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", 0,
             AssemblyLine.Quantity)
        then
            Error(Text001, AssemblyLine.TableCaption(), TableCaptionValue);

        OnAfterAssemblyLineDelete(AssemblyLine);
    end;

    procedure CalcNextLevelProdOutput(ProdOrderComp: Record "Prod. Order Component"): Decimal
    var
        Item: Record Item;
        WhseEntry: Record "Warehouse Entry";
        ProdOrderLine: Record "Prod. Order Line";
        OutputBase: Decimal;
    begin
        Item.Get(ProdOrderComp."Item No.");
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            exit(0);

        ProdOrderLine.SetRange(Status, ProdOrderComp.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderComp."Prod. Order No.");
        ProdOrderLine.SetRange("Item No.", ProdOrderComp."Item No.");
        ProdOrderLine.SetRange("Planning Level Code", ProdOrderComp."Planning Level Code");
        if ProdOrderLine.FindFirst() then begin
            WhseEntry.SetSourceFilter(
              DATABASE::"Item Journal Line", 5, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", true); // Output Journal
            WhseEntry.SetRange("Reference No.", ProdOrderLine."Prod. Order No.");
            WhseEntry.SetRange("Item No.", ProdOrderLine."Item No.");
            WhseEntry.CalcSums(Quantity);
            OutputBase := WhseEntry.Quantity;
        end;

        exit(OutputBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineDelete(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLineDelete(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineDelete(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentDelete(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForAssemblyConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var QtyRemainingToBePicked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; ProdOrderComp: Record "Prod. Order Component"; QtyRemainingToBePicked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForJob(NewJobJnlLine: Record "Job Journal Line"; QtyRemainingToBePicked: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyFieldNotChanged(NewRecRef: RecordRef; OldRecRef: RecordRef; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValue: Text[100]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJournalLine: Record "Item Journal Line"; Location: Record Location; var QtyChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransLineCommonVerificationOnBeforeQuantityCheck(var OldTransferLine: Record "Transfer Line"; var NewTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLinesExistOnAfterWhseRcptLineSetFilters(var WhseRcptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLinesExistOnAfterWhseShptLineSetFilters(var WhseShptLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdComponentVerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseWorkSheetLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValue: Text[100]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}


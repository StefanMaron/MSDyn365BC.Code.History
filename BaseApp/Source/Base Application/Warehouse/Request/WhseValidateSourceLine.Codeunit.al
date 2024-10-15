﻿namespace Microsoft.Warehouse.Request;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
#if not CLEAN23
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
#endif
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Worksheet;

codeunit 5777 "Whse. Validate Source Line"
{
#if not CLEAN23
    var
        AssemblyWarehouseMgt: Codeunit "Assembly Warehouse Mgt.";
        JobWarehouseMgt: Codeunit "Job Warehouse Mgt.";
        ServiceWarehouseMgt: Codeunit "Service Warehouse Mgt.";
        SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
        PurchasesWarehouseMgt: Codeunit "Purchases Warehouse Mgt.";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
#endif

    trigger OnRun()
    begin
    end;

    var
        WhseActivLine: Record "Warehouse Activity Line";
        TableCaptionValue: Text;

        Text000: Label 'must not be changed when a %1 for this %2 exists: ';
        Text001: Label 'The %1 cannot be deleted when a related %2 exists.';
        Text002: Label 'You cannot post consumption for order no. %1 because a quantity of %2 remains to be picked.';
        JobPostQtyPickRemainErr: Label 'You cannot post usage for project number %1 because a quantity of %2 remains to be picked.', Comment = '%1 = Project number, %2 = remaining quantity to pick';

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Sales Warehouse Mgt.', '23.0')]
    procedure SalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    begin
        SalesWarehouseMgt.SalesLineVerifyChange(NewSalesLine, OldSalesLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Sales Warehouse Mgt.', '23.0')]
    procedure SalesLineDelete(var SalesLine: Record "Sales Line")
    begin
        SalesWarehouseMgt.SalesLineDelete(SalesLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Service Warehouse Mgt.', '23.0')]
    procedure ServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    begin
        ServiceWarehouseMgt.ServiceLineVerifyChange(NewServiceLine, OldServiceLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Service Warehouse Mgt.', '23.0')]
    procedure ServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
        ServiceWarehouseMgt.ServiceLineDelete(ServiceLine);
    end;
#endif

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

    internal procedure FieldValueIsChanged(FirstRecordRef: RecordRef; SecondRecordRef: RecordRef; FieldNumber: Integer): Boolean
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

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Purchases Warehouse Mgt.', '23.0')]
    procedure PurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line")
    begin
        PurchasesWarehouseMgt.PurchaseLineVerifyChange(NewPurchLine, OldPurchLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Purchases Warehouse Mgt.', '23.0')]
    procedure PurchaseLineDelete(var PurchLine: Record "Purchase Line")
    begin
        PurchasesWarehouseMgt.PurchaseLineDelete(PurchLine);
    end;
#endif

    procedure TransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransLineVerifyChange(NewTransLine, OldTransLine, IsHandled);
        if IsHandled then
            exit;

        if WhseLinesExist(Database::"Transfer Line", 0, NewTransLine."Document No.", NewTransLine."Line No.", 0, NewTransLine.Quantity) then begin
            TransLineCommonVerification(NewTransLine, OldTransLine);
            if NewTransLine."Qty. to Ship" <> OldTransLine."Qty. to Ship" then
                NewTransLine.FieldError("Qty. to Ship", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));
        end;

        if WhseLinesExist(Database::"Transfer Line", 1, NewTransLine."Document No.", NewTransLine."Line No.", 0, NewTransLine.Quantity) then begin
            TransLineCommonVerification(NewTransLine, OldTransLine);
            if NewTransLine."Qty. to Receive" <> OldTransLine."Qty. to Receive" then
                NewTransLine.FieldError("Qty. to Receive", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));
        end;

        OnAfterTransLineVerifyChange(NewTransLine, OldTransLine);
    end;

    local procedure TransLineCommonVerification(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        IsHandled: Boolean;
    begin
        if NewTransLine."Item No." <> OldTransLine."Item No." then
            NewTransLine.FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));

        if NewTransLine."Variant Code" <> OldTransLine."Variant Code" then
            NewTransLine.FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));

        if NewTransLine."Unit of Measure Code" <> OldTransLine."Unit of Measure Code" then
            NewTransLine.FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));

        IsHandled := false;
        OnTransLineCommonVerificationOnBeforeQuantityCheck(OldTransLine, NewTransLine, IsHandled);
        if not IsHandled then
            if NewTransLine.Quantity <> OldTransLine.Quantity then
                NewTransLine.FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, NewTransLine.TableCaption));
    end;

    procedure TransLineDelete(var TransLine: Record "Transfer Line")
    begin
        if WhseLinesExist(Database::"Transfer Line", 0, TransLine."Document No.", TransLine."Line No.", 0, TransLine.Quantity) then
            Error(Text001, TransLine.TableCaption(), TableCaptionValue);
        if WhseLinesExist(Database::"Transfer Line", 1, TransLine."Document No.", TransLine."Line No.", 0, TransLine.Quantity) then
            Error(Text001, TransLine.TableCaption(), TableCaptionValue);

        OnAfterTransLineDelete(TransLine);
    end;

    procedure WhseLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal) Result: Boolean
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
        CheckReceipt: Boolean;
        CheckShipment: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhseLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty, TableCaptionValue, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CheckReceipt := false;
        OnWhseLineExistOnBeforeCheckReceipt(SourceType, SourceSubType, SourceQty, CheckReceipt);
        if CheckReceipt then begin
            WhseManagement.SetSourceFilterForWhseRcptLine(WhseRcptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, true);
            OnWhseLinesExistOnAfterWhseRcptLineSetFilters(WhseRcptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceQty);
            if not WhseRcptLine.IsEmpty() then begin
                TableCaptionValue := WhseRcptLine.TableCaption();
                exit(true);
            end;
        end;

        CheckShipment := false;
        OnWhseLineExistOnBeforeCheckShipment(SourceType, SourceSubType, SourceQty, CheckShipment);
        if CheckShipment then begin
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
    begin
        if not (SourceType in [Database::Job, Database::"Prod. Order Component"]) then begin
            TableCaptionValue := '';
            exit(false);
        end;

        exit(WhseWorkSheetLinesExist(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, SourceQty));
    end;

    internal procedure WhseWorkSheetLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal) Result: Boolean
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

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    procedure ProdComponentVerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    begin
        ProdOrderWarehouseMgt.ProdComponentVerifyChange(NewProdOrderComp, OldProdOrderComp);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    procedure ProdComponentDelete(var ProdOrderComp: Record "Prod. Order Component")
    begin
        ProdOrderWarehouseMgt.ProdComponentDelete(ProdOrderComp);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Job Warehouse Mgt.', '23.0')]
    procedure JobPlanningLineVerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; FieldNo: Integer)
    begin
        JobWarehouseMgt.JobPlanningLineVerifyChange(NewJobPlanningLine, OldJobPlanningLine, FieldNo);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Job Warehouse Mgt.', '23.0')]
    procedure JobPlanningLineDelete(var JobPlanningLine: Record "Job Planning Line")
    begin
        JobWarehouseMgt.JobPlanningLineDelete(JobPlanningLine);
    end;
#endif

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
        case NewItemJnlLine."Entry Type" of
            NewItemJnlLine."Entry Type"::"Assembly Consumption":
                begin
                    NewItemJnlLine.TestField("Order Type", NewItemJnlLine."Order Type"::Assembly);
                    if Location.Get(NewItemJnlLine."Location Code") and (Location."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then
                        if AssemblyLine.Get(AssemblyLine."Document Type"::Order, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.") and
                           (NewItemJnlLine.Quantity >= 0)
                        then begin
                            QtyRemainingToBePicked := NewItemJnlLine.Quantity - AssemblyLine."Qty. Picked";
                            CheckQtyRemainingToBePickedForAssemblyConsumption(NewItemJnlLine, OldItemJnlLine, QtyRemainingToBePicked);
                            QtyChecked := true;
                        end;

                    LinesExist := false;
                end;
            NewItemJnlLine."Entry Type"::Consumption:
                begin
                    NewItemJnlLine.TestField("Order Type", NewItemJnlLine."Order Type"::Production);
                    IsHandled := false;
                    OnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJnlLine, Location, QtyChecked, IsHandled);
                    if not Ishandled then
                        if Location.Get(NewItemJnlLine."Location Code") and (Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then
                            if ProdOrderComp.Get(
                                ProdOrderComp.Status::Released,
                                NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", NewItemJnlLine."Prod. Order Comp. Line No.") and
                                (ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::Manual) and
                                (NewItemJnlLine.Quantity >= 0)
                            then begin
                                QtyRemainingToBePicked :=
                                    NewItemJnlLine.Quantity - CalcNextLevelProdOutput(ProdOrderComp) -
                                    ProdOrderComp."Qty. Picked" + ProdOrderComp."Expected Quantity" - ProdOrderComp."Remaining Quantity";
                                CheckQtyRemainingToBePickedForConsumption(NewItemJnlLine, OldItemJnlLine, ProdOrderComp, QtyRemainingToBePicked);
                                QtyChecked := true;
                            end;

                    LinesExist :=
                      WhseLinesExist(
                        Database::"Prod. Order Component", 3, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", NewItemJnlLine."Prod. Order Comp. Line No.", NewItemJnlLine.Quantity) or
                      WhseWorkSheetLinesExist(
                        Database::"Prod. Order Component", 3, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", NewItemJnlLine."Prod. Order Comp. Line No.", NewItemJnlLine.Quantity);
                end;
            NewItemJnlLine."Entry Type"::Output:
                begin
                    NewItemJnlLine.TestField("Order Type", NewItemJnlLine."Order Type"::Production);
                    LinesExist :=
                      WhseLinesExist(
                        Database::"Prod. Order Line", 3, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", 0, NewItemJnlLine.Quantity);
                end;
            else
                LinesExist := false;
        end;

        if LinesExist then begin
            if (NewItemJnlLine."Item No." <> OldItemJnlLine."Item No.") and
               (OldItemJnlLine."Item No." <> '')
            then
                NewItemJnlLine.FieldError("Item No.", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine."Variant Code" <> OldItemJnlLine."Variant Code") and
               (OldItemJnlLine."Variant Code" <> '')
            then
                NewItemJnlLine.FieldError("Variant Code", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine."Location Code" <> OldItemJnlLine."Location Code") and
               (OldItemJnlLine."Location Code" <> '')
            then
                NewItemJnlLine.FieldError("Location Code", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine."Unit of Measure Code" <> OldItemJnlLine."Unit of Measure Code") and
               (OldItemJnlLine."Unit of Measure Code" <> '')
            then
                NewItemJnlLine.FieldError("Unit of Measure Code", StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));

            if (NewItemJnlLine.Quantity <> OldItemJnlLine.Quantity) and
               (OldItemJnlLine.Quantity <> 0) and
               not QtyChecked
            then
                NewItemJnlLine.FieldError(Quantity, StrSubstNo(Text000, TableCaptionValue, NewItemJnlLine.TableCaption));
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
                QtyRemainingToBePicked := NewJobJnlLine.Quantity + JobPlanningLine."Qty. Posted" - JobPlanningLine."Qty. Picked" - JobPlanningLine."Qty. to Assemble";
                CheckQtyRemainingToBePickedForJob(NewJobJnlLine, QtyRemainingToBePicked);
            end;
    end;

    internal procedure IsWhsePickRequiredForJobJnlLine(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Item: Record Item;
    begin
        if (JobJournalLine."Line Type" in [JobJournalLine."Line Type"::Budget, JobJournalLine."Line Type"::"Both Budget and Billable"]) and (JobJournalLine.Type = JobJournalLine.Type::Item) then
            if RequireWarehousePicking(JobJournalLine) then
                if Item.Get(JobJournalLine."No.") then
                    if Item.IsInventoriableType() then
                        exit(true);
    end;

    internal procedure IsInventoryPickRequiredForJobJnlLine(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if (JobJournalLine."Line Type" in [JobJournalLine."Line Type"::Budget, JobJournalLine."Line Type"::"Both Budget and Billable"]) and (JobJournalLine.Type = JobJournalLine.Type::Item) then
            if RequireInventoryPicking(JobJournalLine) then begin
                if JobJournalLine."Job Planning Line No." <> 0 then
                    WarehouseActivityLine.SetRange("Source Subline No.", JobJournalLine."Job Planning Line No.");
                WarehouseActivityLine.SetRange("Source Type", Database::Job);
                WarehouseActivityLine.SetRange("Source No.", JobJournalLine."Job No.");
                exit(not WarehouseActivityLine.IsEmpty());
            end;
    end;

    local procedure RequireInventoryPicking(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
    begin
        if Location.Get(JobJournalLine."Location Code") then
            exit(Location."Job Consump. Whse. Handling" = Enum::"Job Consump. Whse. Handling"::"Inventory Pick");
        WarehouseSetup.Get();
        exit(WarehouseSetup."Require Pick" and not WarehouseSetup."Require Shipment");
    end;

    local procedure RequireWarehousePicking(var JobJournalLine: Record "Job Journal Line"): Boolean
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
    begin
        if Location.Get(JobJournalLine."Location Code") then
            exit(Location."Job Consump. Whse. Handling" = Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        WarehouseSetup.Get();
        exit(WarehouseSetup."Require Pick" and WarehouseSetup."Require Shipment");
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


#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    procedure ProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        NewRecRef: RecordRef;
        OldRecRef: RecordRef;
    begin
        ProdOrderWarehouseMgt.ProdOrderLineVerifyChange(NewProdOrderLine, OldProdOrderLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    procedure ProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderWarehouseMgt.ProdOrderLineDelete(ProdOrderLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Assembly Warehouse Mgt.', '23.0')]
    procedure AssemblyLineVerifyChange(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    begin
        AssemblyWarehouseMgt.AssemblyLineVerifyChange(NewAssemblyLine, OldAssemblyLine);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Assembly Warehouse Mgt.', '23.0')]
    procedure AssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
        AssemblyWarehouseMgt.AssemblyLineDelete(AssemblyLine);
    end;
#endif

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
              Database::"Item Journal Line", 5, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", true); // Output Journal
            WhseEntry.SetRange("Reference No.", ProdOrderLine."Prod. Order No.");
            WhseEntry.SetRange("Item No.", ProdOrderLine."Item No.");
            WhseEntry.CalcSums(Quantity);
            OutputBase := WhseEntry.Quantity;
        end;

        exit(OutputBase);
    end;

#if not CLEAN23
    internal procedure RunOnAfterSalesLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
        OnAfterSalesLineVerifyChange(NewRecRef, OldRecRef);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnAfterSalesLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterServiceLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
        OnAfterServiceLineVerifyChange(NewRecRef, OldRecRef);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Service Warehouse Mgt.', '23.0')]
    local procedure OnAfterServiceLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterPurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
        OnAfterPurchaseLineVerifyChange(NewPurchLine, OldPurchLine, NewRecRef, OldRecRef);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnAfterPurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterProdComponentVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
        OnAfterProdComponentVerifyChange(NewRecRef, OldRecRef);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    local procedure OnAfterProdComponentVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
        OnAfterProdOrderLineVerifyChange(NewProdOrderLine, OldProdOrderLine, NewRecRef, OldRecRef);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    local procedure OnAfterProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line"; var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineVerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    begin
    end;

#if not CLEAN23
    internal procedure RunOnAfterAssemblyLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
        OnAfterAssemblyLineVerifyChange(NewRecRef, OldRecRef);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Assembly Warehouse Mgt.', '23.0')]
    local procedure OnAfterAssemblyLineVerifyChange(var NewRecRef: RecordRef; var OldRecRef: RecordRef)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterSalesLineDelete(var SalesLine: Record "Sales Line")
    begin
        OnAfterSalesLineDelete(SalesLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnAfterSalesLineDelete(var SalesLine: Record "Sales Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
        OnAfterServiceLineDelete(ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Service Warehouse Mgt.', '23.0')]
    local procedure OnAfterServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterPurchaseLineDelete(var PurchaseLine: Record "Purchase Line")
    begin
        OnAfterPurchaseLineDelete(PurchaseLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchase Warehouse Mgt.', '23.0')]
    local procedure OnAfterPurchaseLineDelete(var PurchaseLine: Record "Purchase Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineDelete(var TransferLine: Record "Transfer Line")
    begin
    end;

#if not CLEAN23
    internal procedure RunOnAfterProdComponentDelete(var ProdOrderComp: Record "Prod. Order Component")
    begin
        OnAfterProdComponentDelete(ProdOrderComp);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    local procedure OnAfterProdComponentDelete(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
        OnAfterProdOrderLineDelete(ProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    local procedure OnAfterProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterAssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
        OnAfterAssemblyLineDelete(AssemblyLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Assembly Warehouse Mgt.', '23.0')]
    local procedure OnAfterAssemblyLineDelete(var AssemblyLine: Record "Assembly Line")
    begin
    end;
#endif

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

#if not CLEAN23
    internal procedure RunOnBeforePurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        OnBeforePurchaseLineVerifyChange(NewPurchLine, OldPurchLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnBeforePurchaseLineVerifyChange(var NewPurchLine: Record "Purchase Line"; var OldPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeSalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforeSalesLineVerifyChange(NewSalesLine, OldSalesLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeSalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
        OnBeforeServiceLineVerifyChange(NewServiceLine, OldServiceLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Service Warehouse Mgt.', '23.0')]
    local procedure OnBeforeServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif

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

#if not CLEAN23
    internal procedure RunOnBeforeProdComponentVerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
        OnBeforeProdComponentVerifyChange(NewProdOrderComp, OldProdOrderComp, IsHandled)
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Prod. Order Warehouse Mgt.', '23.0')]
    local procedure OnBeforeProdComponentVerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseWorkSheetLinesExist(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; SourceQty: Decimal; var TableCaptionValue: Text[100]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    internal procedure RaiseCannotBeDeletedErr(SourceTableCaption: Text)
    begin
        Error(Text001, SourceTableCaption, TableCaptionValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLineExistOnBeforeCheckReceipt(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckReceipt: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
    end;
}


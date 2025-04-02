// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;

tableextension 99000759 "Mfg. Stockkeeping Unit" extends "Stockkeeping Unit"
{
    fields
    {
        field(5417; "Flushing Method"; Enum "Flushing Method")
        {
            Caption = 'Flushing Method';
            DataClassification = CustomerContent;
        }
        field(5420; "Scheduled Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = filter(Planned .. Released),
                                                                                "Item No." = field("Item No."),
                                                                                "Location Code" = field("Location Code"),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Ending Date" = field("Date Filter")));
            Caption = 'Scheduled Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
#if not CLEANSCHEMA28
        field(5421; "Scheduled Need (Qty.)"; Decimal)
        {
            ObsoleteReason = 'Use the field ''Qty. on Component Lines'' instead';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            CalcFormula = sum("Prod. Order Component"."Remaining Qty. (Base)" where(Status = filter(Planned .. Released),
                                                                                     "Item No." = field("Item No."),
                                                                                     "Location Code" = field("Location Code"),
                                                                                     "Variant Code" = field("Variant Code"),
                                                                                     "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                     "Due Date" = field("Date Filter")));
            Caption = 'Scheduled Need (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
        }
        field(99000751; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            DataClassification = CustomerContent;
            TableRelation = "Production BOM Header";
        }
        field(99000765; "Planned Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const(Planned),
                                                                                "Item No." = field("Item No."),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Code"),
                                                                                "Ending Date" = field("Date Filter")));
            Caption = 'Planned Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000766; "FP Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const("Firm Planned"),
                                                                                "Item No." = field("Item No."),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Code"),
                                                                                "Ending Date" = field("Date Filter")));
            Caption = 'FP Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000767; "Rel. Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const(Released),
                                                                                "Item No." = field("Item No."),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Code"),
                                                                                "Ending Date" = field("Date Filter")));
            Caption = 'Rel. Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000769; "Planned Order Release (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = const(Planned),
                                                                                "Item No." = field("Item No."),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Code"),
                                                                                "Starting Date" = field("Date Filter")));
            Caption = 'Planned Order Release (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000777; "Qty. on Prod. Order"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line"."Remaining Qty. (Base)" where(Status = filter(Planned .. Released),
                                                                                "Item No." = field("Item No."),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Location Code" = field("Location Code"),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Due Date" = field("Date Filter")));
            Caption = 'Qty. on Prod. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000778; "Qty. on Component Lines"; Decimal)
        {
            CalcFormula = sum("Prod. Order Component"."Remaining Qty. (Base)" where(Status = filter(Planned .. Released),
                                                                                     "Item No." = field("Item No."),
                                                                                     "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                     "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                     "Location Code" = field("Location Code"),
                                                                                     "Variant Code" = field("Variant Code"),
                                                                                     "Due Date" = field("Date Filter")));
            Caption = 'Qty. on Component Lines';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000752; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000753; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Capacity Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000754; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Subcontrd. Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000755; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Cap. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000756; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000758; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            AutoFormatType = 2;
            Caption = 'Rolled-up Subcontracted Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000759; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000760; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Cap. Overhead Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99000779; "Single-Lvl Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Non-Inventory Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    var
        HideNonInventoryValidateOnStdCost: Boolean;
        NoActiveBOMVersionFoundErr: Label 'There is no active Production BOM for the item %1', Comment = '%1 - Item No.';

    procedure SetHideNonInventoryValidateOnStdCost(NewHideNonInventoryValidateOnStdCost: Boolean)
    begin
        HideNonInventoryValidateOnStdCost := NewHideNonInventoryValidateOnStdCost;
    end;

    procedure CanHideNonInventoryValidateOnStdCost(): Boolean
    begin
        exit(HideNonInventoryValidateOnStdCost);
    end;

    internal procedure OpenProductionBOMForSKUItem(ProductionBOMNo: Code[20]; ItemNo: Code[20])
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        if ProductionBOMNo = '' then begin
            Item.SetLoadFields("Production BOM No.");
            if Item.Get(ItemNo) then
                ProductionBOMNo := Item."Production BOM No.";
        end;

        ProductionBOMHeader.SetRange("No.", ProductionBOMNo);
        Page.RunModal(Page::"Production BOM", ProductionBOMHeader);
    end;

    internal procedure OpenActiveProductionBOMForSKUItem(ProductionBOMNo: Code[20]; ItemNo: Code[20])
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        VersionManagement: Codeunit VersionManagement;
        ActiveVersionNo: Code[20];
    begin
        if ProductionBOMNo = '' then begin
            Item.SetLoadFields("Production BOM No.");
            if Item.Get(ItemNo) then
                ProductionBOMNo := Item."Production BOM No.";
        end;

        if ProductionBOMNo = '' then
            Error(NoActiveBOMVersionFoundErr, ItemNo);

        ActiveVersionNo := VersionManagement.GetBOMVersion(ProductionBOMNo, WorkDate(), true);

        if ActiveVersionNo <> '' then begin
            ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
            ProductionBOMVersion.SetRange("Version Code", ActiveVersionNo);
            Page.RunModal(Page::"Production BOM Version", ProductionBOMVersion);
        end else begin
            ProductionBOMHeader.SetRange("No.", ProductionBOMNo);
            ProductionBOMHeader.SetRange(Status, ProductionBOMHeader.Status::Certified);
            if ProductionBOMHeader.IsEmpty() then
                Error(NoActiveBOMVersionFoundErr, ItemNo);

            Page.RunModal(Page::"Production BOM", ProductionBOMHeader);
        end;
    end;

    procedure TransferManufCostsFromItem(Item: Record Item)
    begin
        "Single-Level Material Cost" := Item."Single-Level Material Cost";
        "Single-Level Capacity Cost" := Item."Single-Level Capacity Cost";
        "Single-Level Subcontrd. Cost" := Item."Single-Level Subcontrd. Cost";
        "Single-Level Cap. Ovhd Cost" := Item."Single-Level Cap. Ovhd Cost";
        "Single-Level Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";
        "Single-Lvl Mat. Non-Invt. Cost" := Item."Single-Lvl Mat. Non-Invt. Cost";

        "Rolled-up Material Cost" := Item."Rolled-up Material Cost";
        "Rolled-up Capacity Cost" := Item."Rolled-up Capacity Cost";
        "Rolled-up Subcontracted Cost" := Item."Rolled-up Subcontracted Cost";
        "Rolled-up Mfg. Ovhd Cost" := Item."Rolled-up Mfg. Ovhd Cost";
        "Rolled-up Cap. Overhead Cost" := Item."Rolled-up Cap. Overhead Cost";
        "Rolled-up Mat. Non-Invt. Cost" := Item."Rolled-up Mat. Non-Invt. Cost";
    end;
}
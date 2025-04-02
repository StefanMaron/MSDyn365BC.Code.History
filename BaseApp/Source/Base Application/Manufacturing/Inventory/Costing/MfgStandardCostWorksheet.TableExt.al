// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Inventory.Item;

tableextension 99000802 "Mfg. Standard Cost Worksheet" extends "Standard Cost Worksheet"
{
    fields
    {
        modify("No.")
        {
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center";
        }
    }

    procedure TransferManufCostsFromItem(var Item: Record Item)
    begin
        "Single-Lvl Material Cost" := Item."Single-Level Material Cost";
        "New Single-Lvl Material Cost" := Item."Single-Level Material Cost";
        "Single-Lvl Cap. Cost" := Item."Single-Level Capacity Cost";
        "New Single-Lvl Cap. Cost" := Item."Single-Level Capacity Cost";
        "Single-Lvl Subcontrd Cost" := Item."Single-Level Subcontrd. Cost";
        "New Single-Lvl Subcontrd Cost" := Item."Single-Level Subcontrd. Cost";
        "Single-Lvl Cap. Ovhd Cost" := Item."Single-Level Cap. Ovhd Cost";
        "New Single-Lvl Cap. Ovhd Cost" := Item."Single-Level Cap. Ovhd Cost";
        "Single-Lvl Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";
        "New Single-Lvl Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";

        "Rolled-up Material Cost" := Item."Rolled-up Material Cost";
        "New Rolled-up Material Cost" := Item."Rolled-up Material Cost";
        "Rolled-up Cap. Cost" := Item."Rolled-up Capacity Cost";
        "New Rolled-up Cap. Cost" := Item."Rolled-up Capacity Cost";
        "Rolled-up Subcontrd Cost" := Item."Rolled-up Subcontracted Cost";
        "New Rolled-up Subcontrd Cost" := Item."Rolled-up Subcontracted Cost";
        "Rolled-up Cap. Ovhd Cost" := Item."Rolled-up Cap. Overhead Cost";
        "New Rolled-up Cap. Ovhd Cost" := Item."Rolled-up Cap. Overhead Cost";
        "Rolled-up Mfg. Ovhd Cost" := Item."Rolled-up Mfg. Ovhd Cost";
        "New Rolled-up Mfg. Ovhd Cost" := Item."Rolled-up Mfg. Ovhd Cost";

        OnAfterTransferManufCostsFromItem(Rec, Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferManufCostsFromItem(var StandardCostWorksheet: Record "Standard Cost Worksheet"; Item: Record Item)
    begin
    end;

    procedure GetWorkCenterCosts(var WorkCenter: Record "Work Center")
    begin
        OnBeforeGetWorkCtrCosts(Rec, WorkCenter);

        "Standard Cost" := WorkCenter."Unit Cost";
        "New Standard Cost" := WorkCenter."Unit Cost";
        "Overhead Rate" := WorkCenter."Overhead Rate";
        "New Overhead Rate" := WorkCenter."Overhead Rate";
        "Indirect Cost %" := WorkCenter."Indirect Cost %";
        "New Indirect Cost %" := WorkCenter."Indirect Cost %";
    end;

    procedure GetMachineCenterCosts(var MachineCenter: Record "Machine Center")
    begin
        OnBeforeGetMachCtrCosts(Rec, MachineCenter);

        "Standard Cost" := MachineCenter."Unit Cost";
        "New Standard Cost" := MachineCenter."Unit Cost";
        "Overhead Rate" := MachineCenter."Overhead Rate";
        "New Overhead Rate" := MachineCenter."Overhead Rate";
        "Indirect Cost %" := MachineCenter."Indirect Cost %";
        "New Indirect Cost %" := MachineCenter."Indirect Cost %";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWorkCtrCosts(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMachCtrCosts(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var MachineCenter: Record "Machine Center")
    begin
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Manufacturing.Document;

tableextension 99000760 "Mfg. Inventory Posting Setup" extends "Inventory Posting Setup"
{
    fields
    {
        field(99000750; "WIP Account"; Code[20])
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'WIP Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(99000753; "Material Variance Account"; Code[20])
        {
            Caption = 'Material Variance Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(99000754; "Capacity Variance Account"; Code[20])
        {
            Caption = 'Capacity Variance Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(99000755; "Mfg. Overhead Variance Account"; Code[20])
        {
            Caption = 'Mfg. Overhead Variance Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(99000756; "Cap. Overhead Variance Account"; Code[20])
        {
            Caption = 'Cap. Overhead Variance Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(99000757; "Subcontracted Variance Account"; Code[20])
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Subcontracted Variance Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(99000758; "Mat. Non-Inv. Variance Acc."; Code[20])
        {
            Caption = 'Material Non-Inventory Variance Account';
            ToolTip = 'Specifies the general ledger account number to which to post material non-inventory variance transactions for items in this combination.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
    }

    procedure GetCapacityVarianceAccount(): Code[20]
    begin
        if "Capacity Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Capacity Variance Account"));

        exit("Capacity Variance Account");
    end;

    procedure GetCapOverheadVarianceAccount(): Code[20]
    begin
        if "Cap. Overhead Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Cap. Overhead Variance Account"));

        exit("Cap. Overhead Variance Account");
    end;

    procedure GetMaterialVarianceAccount(): Code[20]
    begin
        if "Material Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Material Variance Account"));

        exit("Material Variance Account");
    end;

    procedure GetMaterialNonInventoryVarianceAccount(): Code[20]
    begin
        if "Mat. Non-Inv. Variance Acc." = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Mat. Non-Inv. Variance Acc."));

        exit("Mat. Non-Inv. Variance Acc.");
    end;

    procedure GetMfgOverheadVarianceAccount(): Code[20]
    begin
        if "Mfg. Overhead Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Mfg. Overhead Variance Account"));

        exit("Mfg. Overhead Variance Account");
    end;

    procedure GetSubcontractedVarianceAccount(): Code[20]
    begin
        if "Subcontracted Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Subcontracted Variance Account"));

        exit("Subcontracted Variance Account");
    end;

    procedure GetWIPAccount(): Code[20]
    begin
        if "WIP Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("WIP Account"));

        exit("WIP Account");
    end;

}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Ledger;

table 94 "Inventory Posting Group"
{
    Caption = 'Inventory Posting Group';
    LookupPageID = "Inventory Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Used in Items"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count (Item where("Inventory Posting Group" = field(Code)));
            Caption = 'Used in Items';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Used in Value Entries"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count ("Value Entry" where("Inventory Posting Group" = field(Code)));
            Caption = 'Used in Value Entries';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12406; "Purch. PD Charge FCY (Item)"; Code[20])
        {
            Caption = 'Purch. PD Charge FCY (Item)';
            TableRelation = "Item Charge";
        }
        field(12407; "Purch. PD Charge Conv. (Item)"; Code[20])
        {
            Caption = 'Purch. PD Charge Conv. (Item)';
            TableRelation = "Item Charge";
        }
        field(12408; "Sales PD Charge FCY (Item)"; Code[20])
        {
            Caption = 'Sales PD Charge FCY (Item)';
            TableRelation = "Item Charge";
        }
        field(12409; "Sales PD Charge Conv. (Item)"; Code[20])
        {
            Caption = 'Sales PD Charge Conv. (Item)';
            TableRelation = "Item Charge";
        }
        field(12410; "Sales Corr. Doc. Charge (Item)"; Code[20])
        {
            Caption = 'Sales Corr. Doc. Charge (Item)';
            TableRelation = "Item Charge";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        CheckGroupUsage();
    end;

    var
        YouCannotDeleteErr: Label 'You cannot delete %1.', Comment = '%1 = Code';

    [Scope('OnPrem')]
    procedure GetPDAccount(NeedGainAccount: Boolean; LocationCode: Code[10]): Code[20]
    var
        InvPostingSetup: Record "Inventory Posting Setup";
    begin
        InvPostingSetup.Get(LocationCode, Code);
        with InvPostingSetup do
            if NeedGainAccount then begin
                TestField("Purch. PD Gains Acc.");
                exit("Purch. PD Gains Acc.");
            end else begin
                TestField("Purch. PD Losses Acc.");
                exit("Purch. PD Losses Acc.");
            end;
    end;

    local procedure CheckGroupUsage()
    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        Item.SetRange("Inventory Posting Group", Code);
        if not Item.IsEmpty() then
            Error(YouCannotDeleteErr, Code);

        ValueEntry.SetRange("Inventory Posting Group", Code);
        if not ValueEntry.IsEmpty() then
            Error(YouCannotDeleteErr, Code);
    end;
}


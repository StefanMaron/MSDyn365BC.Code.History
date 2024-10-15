﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 171 "Standard Sales Line"
{
    Caption = 'Standard Sales Line';

    fields
    {
        field(1; "Standard Sales Code"; Code[10])
        {
            Caption = 'Standard Sales Code';
            Editable = false;
            TableRelation = "Standard Sales Code";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                OldType: Enum "Sales Line Type";
            begin
                OldType := Type;
                Init();
                Type := OldType;
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item where(Blocked = const(false))
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge";

            trigger OnValidate()
            var
                GLAcc: Record "G/L Account";
                Item: Record Item;
                Res: Record Resource;
                ItemCharge: Record "Item Charge";
                FA: Record "Fixed Asset";
                StdTxt: Record "Standard Text";
                StdSalesCode: Record "Standard Sales Code";
            begin
                Quantity := 0;
                "Amount Excl. VAT" := 0;
                "Unit of Measure Code" := '';
                Description := '';
                if "No." = '' then
                    exit;
                StdSalesCode.Get("Standard Sales Code");
                case Type of
                    Type::" ":
                        begin
                            StdTxt.Get("No.");
                            Description := StdTxt.Description;
                        end;
                    Type::"G/L Account":
                        begin
                            GLAcc.Get("No.");
                            GLAcc.CheckGLAcc();
                            GLAcc.TestField("Direct Posting", true);
                            Description := GLAcc.Name;
                        end;
                    Type::Item:
                        begin
                            Item.Get("No.");
                            Item.TestField(Blocked, false);
                            Item.TestField("Gen. Prod. Posting Group");
                            if Item.Type = Item.Type::Inventory then
                                Item.TestField("Inventory Posting Group");
                            "Unit of Measure Code" := Item."Sales Unit of Measure";
                            Description := Item.Description;
                            "Variant Code" := '';
                        end;
                    Type::Resource:
                        begin
                            Res.Get("No.");
                            Res.CheckResourcePrivacyBlocked(false);
                            Res.TestField(Blocked, false);
                            Res.TestField("Gen. Prod. Posting Group");
                            "Unit of Measure Code" := Res."Base Unit of Measure";
                            Description := Res.Name;
                        end;
                    Type::"Fixed Asset":
                        begin
                            FA.Get("No.");
                            FA.TestField(Inactive, false);
                            FA.TestField(Blocked, false);
                            Description := FA.Description;
                        end;
                    Type::"Charge (Item)":
                        begin
                            ItemCharge.Get("No.");
                            Description := ItemCharge.Description;
                        end;
                end;
                OnAfterValidateNo(Rec, GLAcc);
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Quantity; Decimal)
        {
            BlankZero = true;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField(Type);
            end;
        }
        field(7; "Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Amount Excl. VAT';

            trigger OnValidate()
            begin
                if (Type <> Type::"G/L Account") and (Type <> Type::"Charge (Item)") then
                    Error(Text001, FieldCaption(Type), Type);
            end;
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            begin
                TestField(Type);
            end;
        }
        field(9; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(10; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));

            trigger OnValidate()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
            begin
                if Rec."Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        Item.Get("No.");
                        Description := Item.Description;
                    end;
                    exit;
                end;

                TestField(Type, Type::Item);
                ItemVariant.SetLoadFields(Description, Blocked);
                ItemVariant.Get("No.", "Variant Code");
                ItemVariant.TestField(Blocked, false);
                Description := ItemVariant.Description;
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Standard Sales Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        StdSalesCode.Get("Standard Sales Code");
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        StdSalesCode: Record "Standard Sales Code";
        DimMgt: Codeunit DimensionManagement;
        Text000: Label 'You cannot rename a %1.';
        Text001: Label '%1 must not be %2.';
        CommentLbl: Label 'Comment';

    procedure EmptyLine(): Boolean
    begin
        exit(("No." = '') and (Quantity = 0))
    end;

    procedure InsertLine(): Boolean
    begin
        exit((Type = Type::" ") or (not EmptyLine()));
    end;

    local procedure GetCurrency(): Code[10]
    var
        StdSalesCode: Record "Standard Sales Code";
    begin
        if StdSalesCode.Get("Standard Sales Code") then
            exit(StdSalesCode."Currency Code");

        exit('');
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Standard Sales Code", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, DimMgt);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure FormatType(): Text[20]
    begin
        if Type = Type::" " then
            exit(CommentLbl);

        exit(Format(Type));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var StandardSalesLine: Record "Standard Sales Line"; var xStandardSalesLine: Record "Standard Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var StandardSalesLine: Record "Standard Sales Line"; xStandardSalesLine: Record "Standard Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNo(var StandardSalesLine: Record "Standard Sales Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var StandardSalesLine: Record "Standard Sales Line"; var DimMgt: Codeunit DimensionManagement)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var StandardSalesLine: Record "Standard Sales Line"; xStandardSalesLine: Record "Standard Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}


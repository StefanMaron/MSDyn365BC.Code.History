// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

table 5478 "Purch. Inv. Line Aggregate"
{
    Caption = 'Purch. Inv. Line Aggregate';
    TableType = Temporary;
    ReplicateData = false;

    fields
    {
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                "API Type" := Type;
            end;
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                UpdateItemId();
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(10; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Qty. to Receive"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
        }
        field(60; "Quantity Received"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Quantity Received';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item),
                                "No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
        }
        field(8000; "Document Id"; Guid)
        {
            Caption = 'Document Id';
        }
        field(8001; Id; Text[50])
        {
            Caption = 'Id';
        }
        field(8002; "Variant Id"; Guid)
        {
            Caption = 'Variant Id';
            TableRelation = if (Type = const(Item)) "Item Variant".SystemId where("Item No." = field("No."));

            trigger OnValidate()
            begin
                UpdateVariantCode();
            end;
        }
        field(9020; "Tax Code"; Code[50])
        {
            Caption = 'Tax Code';
        }
        field(9021; "Tax Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Tax Amount';
        }
        field(9022; "Discount Applied Before Tax"; Boolean)
        {
            Caption = 'Discount Applied Before Tax';
        }
        field(9029; "API Type"; Enum "Invoice Line Agg. Line Type")
        {
            Caption = 'API Type';

            trigger OnValidate()
            begin
                Type := "API Type";
            end;
        }
        field(9030; "Item Id"; Guid)
        {
            Caption = 'Item Id';
            TableRelation = Item.SystemId;

            trigger OnValidate()
            begin
                Validate(Type, Type::Item);
                UpdateNo();
            end;
        }
        field(9031; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            TableRelation = "G/L Account".SystemId;

            trigger OnValidate()
            begin
                Validate(Type, Type::"G/L Account");
                UpdateNo();
            end;
        }
        field(9032; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            TableRelation = "Unit of Measure".SystemId;

            trigger OnValidate()
            begin
                UpdateUnitOfMeasureCode();
            end;
        }
        field(9039; "Line Tax Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Tax Amount';
        }
        field(9040; "Line Amount Including Tax"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount Including Tax';
        }
        field(9041; "Line Amount Excluding Tax"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount Excluding Tax';
        }
        field(9042; "Prices Including Tax"; Boolean)
        {
            Caption = 'Prices Including Tax';
        }
        field(9043; "Inv. Discount Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount Excl. VAT';
        }
        field(9044; "Tax Id"; Guid)
        {
            Caption = 'Tax Id';

            trigger OnValidate()
            var
                TempTaxGroupBuffer: Record "Tax Group Buffer" temporary;
            begin
                TempTaxGroupBuffer.GetCodesFromTaxGroupId("Tax Id", "Tax Group Code", "VAT Prod. Posting Group");
            end;
        }
        field(9070; "Location Id"; Guid)
        {
            Caption = 'Location Id';
            TableRelation = Location.SystemId;

            trigger OnValidate()
            begin
                UpdateLocationCode();
            end;
        }
    }

    keys
    {
        key(Key1; "Document Id", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Id)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        UpdateCalculatedFields();
    end;

    trigger OnModify()
    begin
        UpdateCalculatedFields();
    end;

    trigger OnRename()
    begin
        UpdateCalculatedFields();
    end;

    procedure UpdateItemId()
    var
        Item: Record Item;
    begin
        if ("No." = '') or (Type <> Type::Item) then begin
            Clear("Item Id");
            exit;
        end;

        if not Item.Get("No.") then
            exit;

        "Item Id" := Item.SystemId;
    end;

    procedure UpdateAccountId()
    var
        GLAccount: Record "G/L Account";
    begin
        if ("No." = '') or (Type <> Type::"G/L Account") then begin
            Clear("Account Id");
            exit;
        end;

        if not GLAccount.Get("No.") then
            exit;

        "Account Id" := GLAccount.SystemId;
    end;

    procedure UpdateNo()
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
    begin
        case Type of
            Type::Item:
                begin
                    if not Item.GetBySystemId("Item Id") then
                        exit;

                    "No." := Item."No.";
                end;
            Type::"G/L Account":
                begin
                    if not GLAccount.GetBySystemId("Account Id") then
                        exit;

                    "No." := GLAccount."No.";
                end;
        end;
    end;

    local procedure UpdateCalculatedFields()
    begin
        UpdateReferencedRecordIds();
        "API Type" := Type;
    end;

    local procedure UpdateVariantCode()
    var
        ItemVariant: Record "Item Variant";
    begin
        if IsNullGuid("Variant Id") then begin
            Validate("Variant Code", '');
            exit;
        end;

        if ItemVariant.GetBySystemId("Variant Id") then
            "Variant Code" := ItemVariant.Code;
    end;

    procedure UpdateReferencedRecordIds()
    begin
        UpdateItemId();
        UpdateAccountId();
        UpdateUnitOfMeasureId();
        UpdateLocationId();
    end;

    local procedure UpdateUnitOfMeasureId()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        Clear("Unit of Measure Id");
        if "Unit of Measure Code" = '' then
            exit;

        if not UnitOfMeasure.Get("Unit of Measure Code") then
            exit;

        "Unit of Measure Id" := UnitOfMeasure.SystemId;
    end;

    local procedure UpdateLocationId()
    var
        Location: Record Location;
    begin
        Clear("Location Id");
        if "Location Code" = '' then
            exit;

        if not Location.Get("Location Code") then
            exit;

        "Location Id" := Location.SystemId;
    end;

    local procedure UpdateUnitOfMeasureCode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if IsNullGuid("Unit of Measure Id") then begin
            Validate("Unit of Measure Code", '');
            exit;
        end;

        UnitOfMeasure.GetBySystemId("Unit of Measure Id");
        Validate("Unit of Measure Code", UnitOfMeasure.Code);
    end;

    local procedure UpdateLocationCode()
    var
        Location: Record Location;
    begin
        if IsNullGuid("Location Id") then begin
            Validate("Location Code", '');
            exit;
        end;

        Location.GetBySystemId("Location Id");
        "Location Code" := Location.Code;
    end;
}


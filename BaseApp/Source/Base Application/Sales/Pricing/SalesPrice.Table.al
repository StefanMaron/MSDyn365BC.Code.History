﻿namespace Microsoft.Sales.Pricing;

#if not CLEAN23
using Microsoft.CRM.Campaign;
#endif
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
#if not CLEAN23
using Microsoft.Sales.Customer;
#endif

table 7002 "Sales Price"
{
    Caption = 'Sales Price';
#if not CLEAN23
    LookupPageID = "Sales Prices";
    ObsoleteState = Pending;
    ObsoleteTag = '16.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
#endif    
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation: table Price List Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;

#if not CLEAN23
            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeItemNoOnValidate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Item No." <> xRec."Item No." then begin
                    Item.Get("Item No.");
                    "Unit of Measure Code" := Item."Sales Unit of Measure";
                    "Variant Code" := '';
                end;

                if "Sales Type" = "Sales Type"::"Customer Price Group" then
                    if CustPriceGr.Get("Sales Code") and
                       (CustPriceGr."Allow Invoice Disc." = "Allow Invoice Disc.")
                    then
                        exit;

                UpdateValuesFromItem();
            end;
#endif
        }
        field(2; "Sales Code"; Code[20])
        {
            Caption = 'Sales Code';
#if not CLEAN23
            TableRelation = if ("Sales Type" = const("Customer Price Group")) "Customer Price Group"
            else
            if ("Sales Type" = const(Customer)) Customer
            else
            if ("Sales Type" = const(Campaign)) Campaign;

            trigger OnValidate()
            begin
                if "Sales Code" <> '' then
                    case "Sales Type" of
                        "Sales Type"::"All Customers":
                            Error(Text001, FieldCaption("Sales Code"));
                        "Sales Type"::"Customer Price Group":
                            begin
                                CustPriceGr.Get("Sales Code");
                                OnValidateSalesCodeOnAfterGetCustomerPriceGroup(Rec, CustPriceGr);
                                "Price Includes VAT" := CustPriceGr."Price Includes VAT";
                                "VAT Bus. Posting Gr. (Price)" := CustPriceGr."VAT Bus. Posting Gr. (Price)";
                                "Allow Line Disc." := CustPriceGr."Allow Line Disc.";
                                "Allow Invoice Disc." := CustPriceGr."Allow Invoice Disc.";
                            end;
                        "Sales Type"::Customer:
                            begin
                                Cust.Get("Sales Code");
                                "Currency Code" := Cust."Currency Code";
                                "Price Includes VAT" := Cust."Prices Including VAT";
                                "VAT Bus. Posting Gr. (Price)" := Cust."VAT Bus. Posting Group";
                                "Allow Line Disc." := Cust."Allow Line Disc.";
                            end;
                        "Sales Type"::Campaign:
                            begin
                                Campaign.Get("Sales Code");
                                "Starting Date" := Campaign."Starting Date";
                                "Ending Date" := Campaign."Ending Date";
                            end;
                    end;
            end;
#endif
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));

                if CurrFieldNo = 0 then
                    exit;

                if "Starting Date" <> 0D then
                    if "Sales Type" = "Sales Type"::Campaign then
                        Error(Text002, "Sales Type");
            end;
        }
        field(5; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Cost-plus %" := 0;
                "Discount Amount" := 0;
            end;
        }
        field(7; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
        }
        field(10; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(11; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";
        }
        field(13; "Sales Type"; Enum "Sales Price Type")
        {
            Caption = 'Sales Type';

#if not CLEAN23
            trigger OnValidate()
            begin
                if "Sales Type" <> xRec."Sales Type" then begin
                    Validate("Sales Code", '');
                    UpdateValuesFromItem();
                end;
            end;
#endif
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(15; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if CurrFieldNo = 0 then
                    exit;

                Validate("Starting Date");

                if "Ending Date" <> 0D then
                    if "Sales Type" = "Sales Type"::Campaign then
                        Error(Text002, "Sales Type");
            end;
        }
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
#if not CLEAN23
            ObsoleteState = Pending;
            ObsoleteTag = '23.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
        }
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(7002)));
        }
        field(5400; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
#if not CLEAN23
                UpdateUnitPrice();
#endif
            end;
        }
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        field(28060; "Published Price"; Decimal)
        {
            CalcFormula = Lookup(Item."Unit Price" where("No." = field("Item No.")));
            Caption = 'Published Price';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28061; Cost; Decimal)
        {
            CalcFormula = Lookup(Item."Unit Cost" where("No." = field("Item No.")));
            Caption = 'Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28062; "Cost-plus %"; Decimal)
        {
            Caption = 'Cost-plus %';
            DecimalPlaces = 0 : 1;
            MinValue = 0;

            trigger OnValidate()
            begin
#if not CLEAN23
                UpdateUnitPrice();
#endif
            end;
        }
        field(28063; "Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Discount Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
#if not CLEAN23
                UpdateUnitPrice();
#endif
            end;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Sales Type", "Sales Code", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
            Clustered = true;
        }
        key(Key2; "Sales Type", "Sales Code", "Item No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
        key(Key3; SystemModifiedAt)
        {
        }
#if not CLEAN23
        key(Key4; "Coupled to CRM")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteTag = '23.0';
        }
#endif
    }

    fieldgroups
    {
        fieldgroup(Brick; "Sales Type", "Sales Code", "Item No.", "Starting Date", "Unit Price", "Ending Date")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Sales Type" = "Sales Type"::"All Customers" then
            "Sales Code" := ''
        else
            TestField("Sales Code");
        TestField("Item No.");
    end;

    trigger OnRename()
    begin
        if "Sales Type" <> "Sales Type"::"All Customers" then
            TestField("Sales Code");
        TestField("Item No.");
    end;

    var
#if not CLEAN23
        CustPriceGr: Record "Customer Price Group";
        Cust: Record Customer;
        Campaign: Record Campaign;
        ItemUnitOfMeasure: Record "Item Unit of Measure";

        Text001: Label '%1 must be blank.';
#endif
        Text000: Label '%1 cannot be after %2';
        Text002: Label 'If Sales Type = %1, then you can only change Starting Date and Ending Date from the Campaign Card.';

#if not CLEAN23
    protected var
        Item: Record Item;
#endif

#if not CLEAN23
    [Scope('OnPrem')]
    [Obsolete('Function is removed as implementation is replaced by (V16) of price calculation: table Price List Line', '22.0')]
    procedure UpdateUnitPrice()
    begin
        if ("Cost-plus %" <> 0) then begin
            CalcFields(Cost);
            "Discount Amount" := 0;
            if "Unit of Measure Code" = Item."Base Unit of Measure" then
                "Unit Price" := Cost * (1 + "Cost-plus %" / 100)
            else begin
                ItemUnitOfMeasure.Reset();
                ItemUnitOfMeasure.SetRange("Item No.", "Item No.");
                ItemUnitOfMeasure.SetRange(Code, "Unit of Measure Code");
                if ItemUnitOfMeasure.FindFirst() then
                    "Unit Price" := ItemUnitOfMeasure."Qty. per Unit of Measure" * (Cost * (1 + "Cost-plus %" / 100))
            end;
        end else begin
            CalcFields("Published Price");
            "Cost-plus %" := 0;
            if "Unit of Measure Code" = Item."Base Unit of Measure" then
                "Unit Price" := "Published Price" - "Discount Amount"
            else begin
                ItemUnitOfMeasure.Reset();
                ItemUnitOfMeasure.SetRange("Item No.", "Item No.");
                ItemUnitOfMeasure.SetRange(Code, "Unit of Measure Code");
                if ItemUnitOfMeasure.FindFirst() then
                    "Unit Price" := (ItemUnitOfMeasure."Qty. per Unit of Measure" * "Published Price") - "Discount Amount";
            end;
        end;
    end;
#endif

#if not CLEAN23
    local procedure UpdateValuesFromItem()
    begin
        if Item.Get("Item No.") then begin
            "Allow Invoice Disc." := Item."Allow Invoice Disc.";
            if "Sales Type" = "Sales Type"::"All Customers" then begin
                "Price Includes VAT" := Item."Price Includes VAT";
                "VAT Bus. Posting Gr. (Price)" := Item."VAT Bus. Posting Gr. (Price)";
            end;
        end;
    end;

    procedure CopySalesPriceToCustomersSalesPrice(var SalesPrice: Record "Sales Price"; CustNo: Code[20])
    var
        NewSalesPrice: Record "Sales Price";
    begin
        if SalesPrice.FindSet() then
            repeat
                NewSalesPrice := SalesPrice;
                NewSalesPrice."Sales Type" := NewSalesPrice."Sales Type"::Customer;
                NewSalesPrice."Sales Code" := CustNo;
                OnBeforeNewSalesPriceInsert(NewSalesPrice, SalesPrice);
                if NewSalesPrice.Insert() then;
            until SalesPrice.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemNoOnValidate(var SalesPrice: Record "Sales Price"; var xSalesPrice: Record "Sales Price"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewSalesPriceInsert(var NewSalesPrice: Record "Sales Price"; SalesPrice: Record "Sales Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSalesCodeOnAfterGetCustomerPriceGroup(var Salesprice: Record "Sales Price"; CustPriceGroup: Record "Customer Price Group")
    begin
    end;
#endif
}


table 5476 "Sales Invoice Line Aggregate"
{
    Caption = 'Sales Invoice Line Aggregate';

    fields
    {
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Sales Line Type")
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
        }
        field(10; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
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
        field(18; "Qty. to Ship"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
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
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
        }
        field(60; "Quantity Shipped"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Quantity Shipped';
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
            AutoFormatExpression = "Currency Code";
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
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
        }
        field(180; "Line Discount Calculation"; Option)
        {
            Caption = 'Line Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;

            trigger OnValidate()
            begin
                UpdateLineDiscounts;
            end;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item),
                                "No." = FILTER(<> '')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Resource),
                                         "No." = FILTER(<> '')) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."))
            ELSE
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
        field(9020; "Tax Code"; Code[50])
        {
            Caption = 'Tax Code';
        }
        field(9021; "Tax Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Tax Amount';
        }
        field(9022; "Discount Applied Before Tax"; Boolean)
        {
            Caption = 'Discount Applied Before Tax';
        }
        field(9029; "API Type"; Option)
        {
            Caption = 'API Type';
            OptionCaption = 'Comment,Account,Item,Resource,Fixed Asset,Charge';
            OptionMembers = Comment,Account,Item,Resource,"Fixed Asset",Charge;

            trigger OnValidate()
            begin
                Type := "API Type";
            end;
        }
        field(9030; "Item Id"; Guid)
        {
            Caption = 'Item Id';
            TableRelation = Item.Id;

            trigger OnValidate()
            begin
                Validate(Type, Type::Item);
                UpdateNo;
            end;
        }
        field(9031; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            TableRelation = "G/L Account".Id;

            trigger OnValidate()
            begin
                Validate(Type, Type::"G/L Account");
                UpdateNo;
            end;
        }
        field(9032; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            TableRelation = "Unit of Measure".Id;

            trigger OnValidate()
            begin
                UpdateUnitOfMeasureCode;
            end;
        }
        field(9039; "Line Tax Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Tax Amount';
        }
        field(9040; "Line Amount Including Tax"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount Including Tax';
        }
        field(9041; "Line Amount Excluding Tax"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount Excluding Tax';
        }
        field(9042; "Prices Including Tax"; Boolean)
        {
            Caption = 'Prices Including Tax';
        }
        field(9043; "Inv. Discount Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
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
        field(9050; "Line Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Discount Value';

            trigger OnValidate()
            begin
                UpdateLineDiscounts;
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
        UpdateCalculatedFields;
    end;

    trigger OnModify()
    begin
        UpdateCalculatedFields;
    end;

    trigger OnRename()
    begin
        UpdateCalculatedFields;
    end;

    var
        LineDiscountPctMustBePositiveErr: Label 'Line discount percentage must be positive.', Locked = true;
        LineDiscountPctMustBeBelowHundredErr: Label 'Line discount percentage must be below 100.', Locked = true;
        LineDiscountAmtMustBePositiveErr: Label 'Line discount amount must be positive.', Locked = true;

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

        "Item Id" := Item.Id;
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

        "Account Id" := GLAccount.Id;
    end;

    procedure UpdateNo()
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
    begin
        case Type of
            Type::Item:
                begin
                    Item.SetRange(Id, "Item Id");
                    if not Item.FindFirst then
                        exit;

                    "No." := Item."No.";
                end;
            Type::"G/L Account":
                begin
                    GLAccount.SetRange(Id, "Account Id");
                    if not GLAccount.FindFirst then
                        exit;

                    "No." := GLAccount."No.";
                end;
        end;
    end;

    local procedure UpdateCalculatedFields()
    begin
        UpdateReferencedRecordIds;
        "API Type" := Type;
    end;

    procedure UpdateReferencedRecordIds()
    begin
        UpdateItemId;
        UpdateAccountId;
        UpdateUnitOfMeasureId;
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

        "Unit of Measure Id" := UnitOfMeasure.Id;
    end;

    local procedure UpdateUnitOfMeasureCode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if IsNullGuid("Unit of Measure Id") then begin
            Validate("Unit of Measure Code", '');
            exit;
        end;

        UnitOfMeasure.SetRange(Id, "Unit of Measure Id");
        UnitOfMeasure.FindFirst;
        "Unit of Measure Code" := UnitOfMeasure.Code;
    end;

    procedure UpdateLineDiscounts()
    var
        Currency: Record Currency;
        LineAmount: Decimal;
    begin
        if "Currency Code" = '' then
            Currency.InitRoundingPrecision;
        case "Line Discount Calculation" of
            "Line Discount Calculation"::"%":
                begin
                    "Line Discount %" := "Line Discount Value";
                    "Line Discount Amount" :=
                      Round(
                        Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") *
                        "Line Discount %" / 100, Currency."Amount Rounding Precision");
                end;
            "Line Discount Calculation"::Amount, "Line Discount Calculation"::None:
                begin
                    "Line Discount Amount" := "Line Discount Value";
                    LineAmount := Quantity * "Unit Price";
                    if LineAmount <> 0 then
                        "Line Discount %" :=
                          Round("Line Discount Amount" / Round(LineAmount, Currency."Amount Rounding Precision") * 100, 0.00001)
                end;
        end;

        if "Line Discount %" < 0 then
            Error(LineDiscountPctMustBePositiveErr);

        if "Line Discount %" > 100 then
            Error(LineDiscountPctMustBeBelowHundredErr);

        if "Line Discount Amount" < 0 then
            Error(LineDiscountAmtMustBePositiveErr);
    end;

    procedure SetDiscountValue()
    begin
        case "Line Discount Calculation" of
            "Line Discount Calculation"::"%":
                "Line Discount Value" := "Line Discount %";
            "Line Discount Calculation"::Amount, "Line Discount Calculation"::None:
                begin
                    "Line Discount Calculation" := "Line Discount Calculation"::Amount;
                    "Line Discount Value" := "Line Discount Amount";
                end;
        end;
    end;
}


table 5478 "Purch. Inv. Line Aggregate"
{
    Caption = 'Purch. Inv. Line Aggregate';

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
                UpdateItemId;
            end;
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
            AutoFormatExpression = "Currency Code";
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
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
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
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item),
                                "No." = FILTER(<> '')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
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
    end;
}


table 1304 "Sales Price and Line Disc Buff"
{
    Caption = 'Sales Price and Line Disc Buff';
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = IF (Type = CONST(Item)) Item
            ELSE
            IF (Type = CONST("Item Disc. Group")) "Item Discount Group";

            trigger OnLookup()
            var
                Item: Record Item;
                ItemDiscountGroup: Record "Item Discount Group";
            begin
                case Type of
                    Type::Item:
                        if PAGE.RunModal(PAGE::"Item List", Item) = ACTION::LookupOK then
                            Validate(Code, Item."No.");
                    Type::"Item Disc. Group":
                        if PAGE.RunModal(PAGE::"Item Disc. Groups", ItemDiscountGroup) = ACTION::LookupOK then
                            Validate(Code, ItemDiscountGroup.Code);
                    else
                        OnLookupCodeCaseElse();
                end;
            end;

            trigger OnValidate()
            var
                Item: Record Item;
                CustPriceGr: Record "Customer Price Group";
            begin
                "Unit of Measure Code" := '';
                "Variant Code" := '';

                if Type = Type::Item then
                    if Item.Get(Code) then
                        "Unit of Measure Code" := Item."Sales Unit of Measure";

                if "Line Type" = "Line Type"::"Sales Price" then begin
                    if "Sales Type" = "Sales Type"::"Customer Price/Disc. Group" then
                        if CustPriceGr.Get("Sales Code") and
                           (CustPriceGr."Allow Invoice Disc." = "Allow Invoice Disc.")
                        then
                            exit;

                    UpdateValuesFromItem;
                end;
            end;
        }
        field(2; "Sales Code"; Code[20])
        {
            Caption = 'Sales Code';
            DataClassification = SystemMetadata;
            TableRelation = IF ("Sales Type" = CONST("Customer Price/Disc. Group"),
                                "Line Type" = CONST("Sales Line Discount")) "Customer Discount Group"
            ELSE
            IF ("Sales Type" = CONST("Customer Price/Disc. Group"),
                                         "Line Type" = CONST("Sales Price")) "Customer Price Group"
            ELSE
            IF ("Sales Type" = CONST(Customer)) Customer;

            trigger OnValidate()
            var
                CustPriceGr: Record "Customer Price Group";
                Cust: Record Customer;
            begin
                if "Sales Code" <> '' then
                    case "Sales Type" of
                        "Sales Type"::"All Customers":
                            Error(MustBeBlankErr, FieldCaption("Sales Code"));
                        "Sales Type"::"Customer Price/Disc. Group":
                            if "Line Type" = "Line Type"::"Sales Price" then begin
                                CustPriceGr.Get("Sales Code");
                                "Price Includes VAT" := CustPriceGr."Price Includes VAT";
                                "VAT Bus. Posting Gr. (Price)" := CustPriceGr."VAT Bus. Posting Gr. (Price)";
                                "Allow Line Disc." := CustPriceGr."Allow Line Disc.";
                                "Allow Invoice Disc." := CustPriceGr."Allow Invoice Disc.";
                            end;
                        "Sales Type"::Customer:
                            begin
                                Cust.Get("Sales Code");
                                "Currency Code" := Cust."Currency Code";
                                if "Line Type" = "Line Type"::"Sales Price" then begin
                                    "Price Includes VAT" := Cust."Prices Including VAT";
                                    "VAT Bus. Posting Gr. (Price)" := Cust."VAT Bus. Posting Group";
                                    "Allow Line Disc." := Cust."Allow Line Disc.";
                                end;
                            end;
                    end;
            end;
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(EndDateErr, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
            end;
        }
        field(5; "Line Discount %"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Line Discount %';
            DataClassification = SystemMetadata;
            MaxValue = 100;
            MinValue = 0;
        }
        field(6; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
        field(7; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            DataClassification = SystemMetadata;
        }
        field(10; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(11; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(13; "Sales Type"; Option)
        {
            Caption = 'Sales Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Customer,Customer Price/Disc. Group,All Customers,Campaign';
            OptionMembers = Customer,"Customer Price/Disc. Group","All Customers",Campaign;

            trigger OnValidate()
            begin
                case "Sales Type" of
                    "Sales Type"::Customer:
                        Validate("Sales Code", "Loaded Customer No.");
                    "Sales Type"::"All Customers":
                        Validate("Sales Code", '');
                    "Sales Type"::"Customer Price/Disc. Group":
                        if "Loaded Customer No." = '' then
                            Validate("Sales Code", '')
                        else begin
                            if "Line Type" = "Line Type"::"Sales Price" then begin
                                if "Loaded Price Group" = '' then
                                    Error(CustNotInPriceGrErr);
                                Validate("Sales Code", "Loaded Price Group");
                            end;

                            if "Line Type" = "Line Type"::"Sales Line Discount" then begin
                                if "Loaded Disc. Group" = '' then
                                    Error(CustNotInDiscGrErr);
                                Validate("Sales Code", "Loaded Disc. Group");
                            end;
                        end;
                end;

                UpdateValuesFromItem;
            end;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
        field(15; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Validate("Starting Date");
            end;
        }
        field(21; Type; Enum "Sales Line Discount Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                case Type of
                    Type::Item:
                        Validate(Code, "Loaded Item No.");
                    Type::"Item Disc. Group":
                        begin
                            Validate(Code, '');
                            if "Loaded Item No." <> '' then begin
                                if "Loaded Disc. Group" = '' then
                                    Error(ItemNotInDiscGrErr);

                                TestField("Line Type", "Line Type"::"Sales Line Discount");
                                Validate(Code, "Loaded Disc. Group");
                            end;
                        end;
                    else
                        OnValidateTypeCaseElse();
                end;
            end;
        }
        field(1300; "Line Type"; Option)
        {
            Caption = 'Line Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Sales Line Discount,Sales Price';
            OptionMembers = " ","Sales Line Discount","Sales Price";

            trigger OnValidate()
            begin
                TestField("Line Type");
                case "Line Type" of
                    "Line Type"::"Sales Price":
                        begin
                            TestField(Type, Type::Item);
                            "Line Discount %" := 0;
                        end;
                    "Line Type"::"Sales Line Discount":
                        "Unit Price" := 0;
                end;
                Validate("Sales Type", "Sales Type");
                Validate(Type, Type);
            end;
        }
        field(1301; "Loaded Item No."; Code[20])
        {
            Caption = 'Loaded Item No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1302; "Loaded Disc. Group"; Code[20])
        {
            Caption = 'Loaded Disc. Group';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1303; "Loaded Customer No."; Code[20])
        {
            Caption = 'Loaded Customer No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1304; "Loaded Price Group"; Code[20])
        {
            Caption = 'Loaded Price Group';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5400; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD(Code));

            trigger OnValidate()
            begin
                TestField(Type, Type::Item);
            end;
        }
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD(Code));

            trigger OnValidate()
            begin
                TestField(Type, Type::Item);
            end;
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Line Type", Type, "Code", "Sales Type", "Sales Code", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity", "Loaded Item No.", "Loaded Disc. Group", "Loaded Customer No.", "Loaded Price Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteOldRecordVersion;
    end;

    trigger OnInsert()
    begin
        if "Sales Type" = "Sales Type"::"All Customers" then
            "Sales Code" := ''
        else
            TestField("Sales Code");
        TestField(Code);

        InsertNewRecordVersion;
    end;

    trigger OnModify()
    begin
        DeleteOldRecordVersion;
        InsertNewRecordVersion;
    end;

    trigger OnRename()
    begin
        if "Sales Type" <> "Sales Type"::"All Customers" then
            TestField("Sales Code");

        TestField(Code);

        DeleteOldRecordVersion;
        InsertNewRecordVersion;
    end;

    var
        EndDateErr: Label '%1 cannot be after %2.';
        MustBeBlankErr: Label '%1 must be blank.';
        CustNotInPriceGrErr: Label 'This customer is not assigned to any price group, therefore a price group could not be used in context of this customer.';
        CustNotInDiscGrErr: Label 'This customer is not assigned to any discount group, therefore a discount group could not be used in context of this customer.';
        ItemNotInDiscGrErr: Label 'This item is not assigned to any discount group, therefore a discount group could not be used in context of this item.';
        IncludeVATQst: Label 'One or more of the sales prices do not include VAT.\Do you want to update all sales prices to include VAT?';
        ExcludeVATQst: Label 'One or more of the sales prices include VAT.\Do you want to update all sales prices to exclude VAT?';
        PricesAndDiscountsCountLbl: Label 'Prices and Discounts', Locked = true;
        PricesAndDiscountsCountMsg: Label 'Total count of Prices and Discounts loaded are: %1', Locked = true;

    local procedure UpdateValuesFromItem()
    var
        Item: Record Item;
    begin
        if "Line Type" <> "Line Type"::"Sales Price" then
            exit;

        if Item.Get(Code) then begin
            "Allow Invoice Disc." := Item."Allow Invoice Disc.";
            if "Sales Type" = "Sales Type"::"All Customers" then begin
                "Price Includes VAT" := Item."Price Includes VAT";
                "VAT Bus. Posting Gr. (Price)" := Item."VAT Bus. Posting Gr. (Price)";
            end;
        end;
    end;

    procedure LoadDataForItem(Item: Record Item)
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscountItem: Record "Sales Line Discount";
        SalesLineDiscountItemGroup: Record "Sales Line Discount";
    begin
        Reset;
        DeleteAll();

        "Loaded Item No." := Item."No.";
        "Loaded Disc. Group" := Item."Item Disc. Group";

        SetFiltersOnSalesPrice(SalesPrice);
        LoadSalesPrice(SalesPrice);

        SetFiltersOnSalesLineDiscountItem(SalesLineDiscountItem);
        LoadSalesLineDiscount(SalesLineDiscountItem);

        SetFiltersOnSalesLineDiscountItemGroup(SalesLineDiscountItemGroup);
        LoadSalesLineDiscount(SalesLineDiscountItemGroup);

        if FindFirst then;

        SendTraceTag('0000AI4', PricesAndDiscountsCountLbl, VERBOSITY::Normal, StrSubstNo(PricesAndDiscountsCountMsg, Count), DATACLASSIFICATION::SystemMetadata);
    end;

    procedure LoadDataForCustomer(Customer: Record Customer)
    begin
        Reset;
        DeleteAll();

        "Loaded Customer No." := Customer."No.";
        "Loaded Disc. Group" := Customer."Customer Disc. Group";
        "Loaded Price Group" := Customer."Customer Price Group";

        LoadSalesPriceForCustomer;
        LoadSalesPriceForAllCustomers;
        LoadSalesPriceForCustPriceGr;

        LoadSalesLineDiscForCustomer;
        LoadSalesLineDiscForAllCustomers;
        LoadSalesLineDiscForCustDiscGr;

        GetCustomerCampaignSalesPrice;

        SendTraceTag('0000AI3', PricesAndDiscountsCountLbl, VERBOSITY::Normal, StrSubstNo(PricesAndDiscountsCountMsg, Count), DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure LoadSalesLineDiscForCustomer()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SetFiltersForSalesLineDiscForCustomer(SalesLineDiscount);
        LoadSalesLineDiscount(SalesLineDiscount);
    end;

    local procedure LoadSalesLineDiscForAllCustomers()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SetFiltersForSalesLineDiscForAllCustomers(SalesLineDiscount);
        LoadSalesLineDiscount(SalesLineDiscount);
    end;

    local procedure LoadSalesLineDiscForCustDiscGr()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SetFiltersForSalesLineDiscForCustDiscGr(SalesLineDiscount);
        LoadSalesLineDiscount(SalesLineDiscount);
    end;

    local procedure LoadSalesPriceForCustomer()
    var
        SalesPrice: Record "Sales Price";
    begin
        SetFiltersForSalesPriceForCustomer(SalesPrice);
        LoadSalesPrice(SalesPrice);
    end;

    local procedure LoadSalesPriceForAllCustomers()
    var
        SalesPrice: Record "Sales Price";
    begin
        SetFiltersForSalesPriceForAllCustomers(SalesPrice);
        LoadSalesPrice(SalesPrice);
    end;

    local procedure LoadSalesPriceForCustPriceGr()
    var
        SalesPrice: Record "Sales Price";
    begin
        SetFiltersForSalesPriceForCustPriceGr(SalesPrice);
        LoadSalesPrice(SalesPrice);
    end;

    local procedure SetFiltersForSalesLineDiscForCustomer(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLineDiscount.SetRange("Sales Type", "Sales Type"::Customer);
        SalesLineDiscount.SetRange("Sales Code", "Loaded Customer No.");
    end;

    local procedure SetFiltersForSalesLineDiscForAllCustomers(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLineDiscount.SetRange("Sales Type", "Sales Type"::"All Customers");
    end;

    local procedure SetFiltersForSalesLineDiscForCustDiscGr(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLineDiscount.SetRange("Sales Code", "Loaded Disc. Group");
        SalesLineDiscount.SetRange("Sales Type", "Sales Type"::"Customer Price/Disc. Group");
    end;

    local procedure SetFiltersForSalesPriceForCustomer(var SalesPrice: Record "Sales Price")
    begin
        SalesPrice.SetRange("Sales Type", "Sales Type"::Customer);
        SalesPrice.SetRange("Sales Code", "Loaded Customer No.");
    end;

    local procedure SetFiltersForSalesPriceForAllCustomers(var SalesPrice: Record "Sales Price")
    begin
        SalesPrice.SetRange("Sales Type", "Sales Type"::"All Customers");
    end;

    local procedure SetFiltersForSalesPriceForCustPriceGr(var SalesPrice: Record "Sales Price")
    begin
        SalesPrice.SetRange("Sales Code", "Loaded Price Group");
        SalesPrice.SetRange("Sales Type", "Sales Type"::"Customer Price/Disc. Group");
    end;

    local procedure LoadSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        if SalesLineDiscount.FindSet then
            repeat
                Init;
                "Line Type" := "Line Type"::"Sales Line Discount";

                Code := SalesLineDiscount.Code;
                Type := SalesLineDiscount.Type;
                "Sales Code" := SalesLineDiscount."Sales Code";
                "Sales Type" := SalesLineDiscount."Sales Type";

                "Starting Date" := SalesLineDiscount."Starting Date";
                "Minimum Quantity" := SalesLineDiscount."Minimum Quantity";
                "Unit of Measure Code" := SalesLineDiscount."Unit of Measure Code";

                "Line Discount %" := SalesLineDiscount."Line Discount %";
                "Currency Code" := SalesLineDiscount."Currency Code";
                "Ending Date" := SalesLineDiscount."Ending Date";
                "Variant Code" := SalesLineDiscount."Variant Code";
                OnLoadSalesLineDiscountOnBeforeInsert(Rec, SalesLineDiscount);
                Insert;
            until SalesLineDiscount.Next = 0;
    end;

    local procedure LoadSalesPrice(var SalesPrice: Record "Sales Price")
    begin
        if SalesPrice.FindSet then
            repeat
                Init;
                "Line Type" := "Line Type"::"Sales Price";

                Code := SalesPrice."Item No.";
                Type := Type::Item;
                "Sales Code" := SalesPrice."Sales Code";
                "Sales Type" := SalesPrice."Sales Type";

                "Starting Date" := SalesPrice."Starting Date";
                "Minimum Quantity" := SalesPrice."Minimum Quantity";
                "Unit of Measure Code" := SalesPrice."Unit of Measure Code";
                "Unit Price" := SalesPrice."Unit Price";
                "Currency Code" := SalesPrice."Currency Code";
                "Ending Date" := SalesPrice."Ending Date";
                "Variant Code" := SalesPrice."Variant Code";

                "Price Includes VAT" := SalesPrice."Price Includes VAT";
                "VAT Bus. Posting Gr. (Price)" := SalesPrice."VAT Bus. Posting Gr. (Price)";

                "Allow Invoice Disc." := SalesPrice."Allow Invoice Disc.";
                "Allow Line Disc." := SalesPrice."Allow Line Disc.";
                OnLoadSalesPriceOnBeforeInsert(Rec, SalesPrice);
                Insert;
            until SalesPrice.Next = 0;
    end;

    local procedure InsertNewPriceLine()
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.Init();

        SalesPrice."Item No." := Code;
        SalesPrice."Sales Code" := "Sales Code";
        SalesPrice."Sales Type" := "Sales Type";
        SalesPrice."Starting Date" := "Starting Date";
        SalesPrice."Minimum Quantity" := "Minimum Quantity";
        SalesPrice."Unit of Measure Code" := "Unit of Measure Code";
        SalesPrice."Unit Price" := "Unit Price";
        SalesPrice."Currency Code" := "Currency Code";
        SalesPrice."Ending Date" := "Ending Date";
        SalesPrice."Variant Code" := "Variant Code";

        SalesPrice."Allow Invoice Disc." := "Allow Invoice Disc.";
        SalesPrice."Allow Line Disc." := "Allow Line Disc.";
        SalesPrice."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
        SalesPrice."Price Includes VAT" := "Price Includes VAT";

        OnInsertNewPriceLineOnBeforeInsert(SalesPrice, Rec);
        SalesPrice.Insert(true);
    end;

    local procedure InsertNewDiscountLine()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SalesLineDiscount.Init();

        SalesLineDiscount.Code := Code;
        SalesLineDiscount.Type := Type;
        SalesLineDiscount."Sales Code" := "Sales Code";
        SalesLineDiscount."Sales Type" := "Sales Type";
        SalesLineDiscount."Starting Date" := "Starting Date";
        SalesLineDiscount."Minimum Quantity" := "Minimum Quantity";
        SalesLineDiscount."Unit of Measure Code" := "Unit of Measure Code";
        SalesLineDiscount."Line Discount %" := "Line Discount %";
        SalesLineDiscount."Currency Code" := "Currency Code";
        SalesLineDiscount."Ending Date" := "Ending Date";
        SalesLineDiscount."Variant Code" := "Variant Code";
        OnInsertNewDiscountLineOnBeforeInsert(SalesLineDiscount, Rec);
        SalesLineDiscount.Insert(true);
    end;

    local procedure SetFiltersOnSalesPrice(var SalesPrice: Record "Sales Price")
    begin
        SalesPrice.SetRange("Item No.", "Loaded Item No.");
        SalesPrice.SetFilter("Sales Type", '<> %1', SalesPrice."Sales Type"::Campaign);
    end;

    local procedure SetFiltersOnSalesLineDiscountItem(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.SetRange(Code, "Loaded Item No.");
        SalesLineDiscount.SetFilter("Sales Type", '<> %1', SalesLineDiscount."Sales Type"::Campaign);
    end;

    local procedure SetFiltersOnSalesLineDiscountItemGroup(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::"Item Disc. Group");
        SalesLineDiscount.SetRange(Code, "Loaded Disc. Group");
        SalesLineDiscount.SetFilter("Sales Type", '<> %1', SalesLineDiscount."Sales Type"::Campaign);
    end;

    procedure FilterToActualRecords()
    begin
        SetFilter("Ending Date", '%1|%2..', 0D, Today)
    end;

    local procedure DeleteOldRecordVersion()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteOldRecordVersion(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        TestField("Line Type");
        if xRec."Line Type" = xRec."Line Type"::"Sales Line Discount" then
            DeleteOldRecordVersionFromDiscounts
        else
            DeleteOldRecordVersionFromPrices;
    end;

    local procedure DeleteOldRecordVersionFromDiscounts()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SalesLineDiscount.Get(
          xRec.Type,
          xRec.Code,
          xRec."Sales Type",
          xRec."Sales Code",
          xRec."Starting Date",
          xRec."Currency Code",
          xRec."Variant Code",
          xRec."Unit of Measure Code",
          xRec."Minimum Quantity");

        SalesLineDiscount.Delete(true);
    end;

    local procedure DeleteOldRecordVersionFromPrices()
    var
        SalesPrice: Record "Sales Price";
        IsHandled: Boolean;
    begin
        OnBeforeDeleteOldRecordVersionFromPrices(xRec, IsHandled);
        if IsHandled then
            exit;

        SalesPrice.Get(
          xRec.Code,
          xRec."Sales Type",
          xRec."Sales Code",
          xRec."Starting Date",
          xRec."Currency Code",
          xRec."Variant Code",
          xRec."Unit of Measure Code",
          xRec."Minimum Quantity");

        SalesPrice.Delete(true);
    end;

    local procedure InsertNewRecordVersion()
    begin
        TestField("Line Type");
        if "Line Type" = "Line Type"::"Sales Line Discount" then
            InsertNewDiscountLine
        else
            InsertNewPriceLine
    end;

    procedure CustHasLines(Cust: Record Customer): Boolean
    var
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPrice: Record "Sales Price";
    begin
        Reset;

        "Loaded Customer No." := Cust."No.";
        "Loaded Disc. Group" := Cust."Customer Disc. Group";
        "Loaded Price Group" := Cust."Customer Price Group";

        SetFiltersForSalesLineDiscForAllCustomers(SalesLineDiscount);
        if SalesLineDiscount.Count > 0 then
            exit(true);
        Clear(SalesLineDiscount);

        SetFiltersForSalesPriceForAllCustomers(SalesPrice);
        if SalesPrice.Count > 0 then
            exit(true);
        Clear(SalesPrice);

        SetFiltersForSalesLineDiscForCustDiscGr(SalesLineDiscount);
        if SalesLineDiscount.Count > 0 then
            exit(true);
        Clear(SalesLineDiscount);

        SetFiltersForSalesPriceForCustPriceGr(SalesPrice);
        if SalesPrice.Count > 0 then
            exit(true);
        Clear(SalesPrice);

        SetFiltersForSalesLineDiscForCustomer(SalesLineDiscount);
        if SalesLineDiscount.Count > 0 then
            exit(true);
        Clear(SalesLineDiscount);

        SetFiltersForSalesPriceForCustomer(SalesPrice);
        if SalesPrice.Count > 0 then
            exit(true);

        exit(false);
    end;

    procedure ItemHasLines(Item: Record Item): Boolean
    var
        SalesLineDiscount: Record "Sales Line Discount";
        SalesPrice: Record "Sales Price";
    begin
        Reset;

        "Loaded Item No." := Item."No.";
        "Loaded Disc. Group" := Item."Item Disc. Group";

        SetFiltersOnSalesPrice(SalesPrice);
        if not SalesPrice.IsEmpty then
            exit(true);

        SetFiltersOnSalesLineDiscountItem(SalesLineDiscount);
        if not SalesLineDiscount.IsEmpty then
            exit(true);
        Clear(SalesLineDiscount);

        SetFiltersOnSalesLineDiscountItemGroup(SalesLineDiscount);
        if not SalesLineDiscount.IsEmpty then
            exit(true);

        exit(false);
    end;

    procedure UpdatePriceIncludesVatAndPrices(Item: Record Item; IncludesVat: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        MsgQst: Text;
    begin
        SetRange("Price Includes VAT", not IncludesVat);
        SetRange("Line Type", "Line Type"::"Sales Price");
        SetRange(Type, Type::Item);
        SetFilter("Unit Price", '>0');

        if not FindSet then
            exit;

        if IncludesVat then
            MsgQst := IncludeVATQst
        else
            MsgQst := ExcludeVATQst;

        if not Confirm(MsgQst, false) then
            exit;

        repeat
            VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group");
            OnAfterVATPostingSetupGet(VATPostingSetup);

            "Price Includes VAT" := IncludesVat;

            if IncludesVat then
                "Unit Price" := "Unit Price" * (100 + VATPostingSetup."VAT %") / 100
            else
                "Unit Price" := "Unit Price" * 100 / (100 + VATPostingSetup."VAT %");

            Modify(true);
        until Next = 0;
    end;

    local procedure GetCustomerCampaignSalesPrice()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        SalesPrice: Record "Sales Price";
        TempCampaign: Record Campaign temporary;
    begin
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, "Loaded Customer No.");
        GetContactCampaigns(TempCampaign, ContactBusinessRelation."Contact No.");

        TempCampaign.SetAutoCalcFields(Activated);
        if TempCampaign.FindSet then
            repeat
                if TempCampaign.Activated then begin
                    SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
                    SalesPrice.SetRange("Sales Code", TempCampaign."No.");
                    LoadSalesPrice(SalesPrice);
                end;
            until TempCampaign.Next = 0;
    end;

    local procedure GetContactCampaigns(var TempCampaign: Record Campaign temporary; CompanyContactNo: Code[20])
    var
        Contact: Record Contact;
        SegmentLine: Record "Segment Line";
    begin
        Contact.SetRange("Company No.", CompanyContactNo);
        if Contact.FindSet then begin
            SegmentLine.SetFilter("Campaign No.", '<>%1', '');
            SegmentLine.SetRange("Campaign Target", true);
            repeat
                SegmentLine.SetRange("Contact No.", Contact."No.");
                InsertTempCampaignFromSegmentLines(TempCampaign, SegmentLine);
            until Contact.Next = 0;
        end;
    end;

    local procedure InsertTempCampaignFromSegmentLines(var TempCampaign: Record Campaign temporary; SegmentLine: Record "Segment Line")
    begin
        if SegmentLine.FindSet then
            repeat
                TempCampaign.Init();
                TempCampaign."No." := SegmentLine."Campaign No.";
                if TempCampaign.Insert() then;
            until SegmentLine.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOldRecordVersion(var SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff"; xSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOldRecordVersionFromPrices(xSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewDiscountLineOnBeforeInsert(var SalesLineDiscount: Record "Sales Line Discount"; SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewPriceLineOnBeforeInsert(var SalesPrice: Record "Sales Price"; SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadSalesLineDiscountOnBeforeInsert(var SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff"; SalesLineDiscount: Record "Sales Line Discount")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadSalesPriceOnBeforeInsert(var SalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff"; SalesPrice: Record "Sales Price")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnLookupCodeCaseElse()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateTypeCaseElse()
    begin
    end;
}


table 1003 "Job Planning Line"
{
    Caption = 'Job Planning Line';
    DrillDownPageID = "Job Planning Lines";
    LookupPageID = "Job Planning Lines";

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            NotBlank = true;
            TableRelation = Job;
        }
        field(3; "Planning Date"; Date)
        {
            Caption = 'Planning Date';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Planning Date" <> "Planning Date");

                Validate("Document Date", "Planning Date");
                if ("Currency Date" = 0D) or ("Currency Date" = xRec."Planning Date") then
                    Validate("Currency Date", "Planning Date");
                if (Type <> Type::Text) and ("No." <> '') then
                    UpdateAllAmounts;
                if "Planning Date" <> 0D then
                    CheckItemAvailable(FieldNo("Planning Date"));
                if CurrFieldNo = FieldNo("Planned Delivery Date") then
                    UpdateReservation(CurrFieldNo)
                else
                    UpdateReservation(FieldNo("Planning Date"));
                "Planned Delivery Date" := "Planning Date";
            end;
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Document No." <> "Document No.");
            end;
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Resource,Item,G/L Account,Text';
            OptionMembers = Resource,Item,"G/L Account",Text;

            trigger OnValidate()
            begin
                ValidateModification(xRec.Type <> Type);

                UpdateReservation(FieldNo(Type));

                Validate("No.", '');
                if Type = Type::Item then begin
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick", false);
                end;
            end;
        }
        field(7; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST(Item)) Item WHERE(Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Text)) "Standard Text";

            trigger OnValidate()
            begin
                ValidateModification(xRec."No." <> "No.");

                CheckUsageLinkRelations;

                UpdateReservation(FieldNo("No."));

                UpdateDescription;

                if ("No." = '') or ("No." <> xRec."No.") then begin
                    "Unit of Measure Code" := '';
                    "Qty. per Unit of Measure" := 1;
                    "Variant Code" := '';
                    "Work Type Code" := '';
                    "Gen. Bus. Posting Group" := '';
                    "Gen. Prod. Posting Group" := '';
                    DeleteAmounts;
                    "Cost Factor" := 0;
                    if "No." = '' then
                        exit;
                end;

                GetJob;
                "Customer Price Group" := Job."Customer Price Group";
                "Price Calculation Method" := Job.GetPriceCalculationMethod();
                "Cost Calculation Method" := Job.GetCostCalculationMethod();

                case Type of
                    Type::Resource:
                        begin
                            Res.Get("No.");
                            Res.CheckResourcePrivacyBlocked(false);
                            Res.TestField(Blocked, false);
                            Res.TestField("Gen. Prod. Posting Group");
                            if Description = '' then
                                Description := Res.Name;
                            if "Description 2" = '' then
                                "Description 2" := Res."Name 2";
                            "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
                            "Resource Group No." := Res."Resource Group No.";
                            Validate("Unit of Measure Code", Res."Base Unit of Measure");
                        end;
                    Type::Item:
                        begin
                            GetItem;
                            Item.TestField(Blocked, false);
                            Item.TestField("Gen. Prod. Posting Group");
                            Description := Item.Description;
                            "Description 2" := Item."Description 2";
                            if Job."Language Code" <> '' then
                                GetItemTranslation;
                            "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                            Validate("Unit of Measure Code", Item."Base Unit of Measure");
                            if "Usage Link" then
                                if Item.Reserve = Item.Reserve::Optional then
                                    Reserve := Job.Reserve
                                else
                                    Reserve := Item.Reserve;
                        end;
                    Type::"G/L Account":
                        begin
                            GLAcc.Get("No.");
                            GLAcc.CheckGLAcc;
                            GLAcc.TestField("Direct Posting", true);
                            GLAcc.TestField("Gen. Prod. Posting Group");
                            Description := GLAcc.Name;
                            "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
                            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
                            "Unit of Measure Code" := '';
                            "Direct Unit Cost (LCY)" := 0;
                            "Unit Cost (LCY)" := 0;
                            "Unit Price" := 0;
                        end;
                    Type::Text:
                        begin
                            StandardText.Get("No.");
                            Description := StandardText.Description;
                        end;
                end;

                if Type <> Type::Text then
                    Validate(Quantity);
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                ValidateModification(xRec.Description <> Description);
            end;
        }
        field(9; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                Delta: Decimal;
            begin
                if "Usage Link" then
                    if not BypassQtyValidation then begin
                        if ("Qty. Posted" > 0) and (Quantity < "Qty. Posted") then
                            Error(QtyLessErr, FieldCaption(Quantity), FieldCaption("Qty. Posted"));
                        if ("Qty. Posted" < 0) and (Quantity > "Qty. Posted") then
                            Error(QtyGreaterErr, FieldCaption(Quantity), FieldCaption("Qty. Posted"));
                    end;

                CalcFields("Qty. Transferred to Invoice");
                if ("Qty. Transferred to Invoice" > 0) and (Quantity < "Qty. Transferred to Invoice") then
                    Error(QtyLessErr, FieldCaption(Quantity), FieldCaption("Qty. Transferred to Invoice"));
                if ("Qty. Transferred to Invoice" < 0) and (Quantity > "Qty. Transferred to Invoice") then
                    Error(QtyGreaterErr, FieldCaption(Quantity), FieldCaption("Qty. Transferred to Invoice"));

                case Type of
                    Type::Item:
                        if not Item.Get("No.") then
                            Error(MissingItemResourceGLErr, Type, Item.FieldCaption("No."));
                    Type::Resource:
                        if not Res.Get("No.") then
                            Error(MissingItemResourceGLErr, Type, Res.FieldCaption("No."));
                    Type::"G/L Account":
                        if not GLAcc.Get("No.") then
                            Error(MissingItemResourceGLErr, Type, GLAcc.FieldCaption("No."));
                end;

                "Quantity (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");

                if "Usage Link" and (xRec."No." = "No.") then begin
                    Delta := Quantity - xRec.Quantity;
                    Validate("Remaining Qty.", "Remaining Qty." + Delta);
                    Validate("Qty. to Transfer to Journal", "Qty. to Transfer to Journal" + Delta);
                end;

                UpdateQtyToTransfer;
                UpdateQtyToInvoice;

                CheckItemAvailable(FieldNo(Quantity));
                UpdateReservation(FieldNo(Quantity));

                UpdateAllAmounts;
                BypassQtyValidation := false;
            end;
        }
        field(11; "Direct Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost (LCY)';
        }
        field(12; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Cost (LCY)" <> "Unit Cost (LCY)");

                if (Type = Type::Item) and
                   Item.Get("No.") and
                   (Item."Costing Method" = Item."Costing Method"::Standard)
                then
                    UpdateAllAmounts
                else begin
                    InitRoundingPrecisions;
                    "Unit Cost" := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          "Currency Date", "Currency Code",
                          "Unit Cost (LCY)", "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                    UpdateAllAmounts;
                end;
            end;
        }
        field(13; "Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost (LCY)';
            Editable = false;
        }
        field(14; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Price (LCY)" <> "Unit Price (LCY)");

                InitRoundingPrecisions;
                "Unit Price" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Currency Date", "Currency Code",
                      "Unit Price (LCY)", "Currency Factor"),
                    UnitAmountRoundingPrecisionFCY);
                UpdateAllAmounts;
            end;
        }
        field(15; "Total Price (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price (LCY)';
            Editable = false;
        }
        field(16; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            Editable = false;
            TableRelation = "Resource Group";
        }
        field(17; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Resource)) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."))
            ELSE
            "Unit of Measure";

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                ValidateModification(xRec."Unit of Measure Code" <> "Unit of Measure Code");

                GetGLSetup;
                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            "Qty. per Unit of Measure" :=
                              UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                        end;
                    Type::Resource:
                        begin
                            if CurrFieldNo <> FieldNo("Work Type Code") then
                                if "Work Type Code" <> '' then begin
                                    WorkType.Get("Work Type Code");
                                    if WorkType."Unit of Measure Code" <> '' then
                                        TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
                                end else
                                    TestField("Work Type Code", '');
                            if "Unit of Measure Code" = '' then begin
                                Resource.Get("No.");
                                "Unit of Measure Code" := Resource."Base Unit of Measure";
                            end;
                            ResourceUnitOfMeasure.Get("No.", "Unit of Measure Code");
                            "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";
                            "Quantity (Base)" := Quantity * "Qty. per Unit of Measure";
                        end;
                    Type::"G/L Account":
                        "Qty. per Unit of Measure" := 1;
                end;
                CheckItemAvailable(FieldNo("Unit of Measure Code"));
                UpdateReservation(FieldNo("Unit of Measure Code"));
                Validate(Quantity);
            end;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                ValidateModification(xRec."Location Code" <> "Location Code");

                "Bin Code" := '';
                if Type = Type::Item then begin
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick", false);
                    CheckItemAvailable(FieldNo("Location Code"));
                    UpdateReservation(FieldNo("Location Code"));
                    Validate(Quantity);
                end;
            end;
        }
        field(29; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(30; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(32; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            begin
                ValidateModification(xRec."Work Type Code" <> "Work Type Code");
                TestField(Type, Type::Resource);

                Validate("Line Discount %", 0);
                if ("Work Type Code" = '') and (xRec."Work Type Code" <> '') then begin
                    Res.Get("No.");
                    "Unit of Measure Code" := Res."Base Unit of Measure";
                    Validate("Unit of Measure Code");
                end;
                if WorkType.Get("Work Type Code") then
                    if WorkType."Unit of Measure Code" <> '' then begin
                        "Unit of Measure Code" := WorkType."Unit of Measure Code";
                        if ResourceUnitOfMeasure.Get("No.", "Unit of Measure Code") then
                            "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";
                    end else begin
                        Res.Get("No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure";
                        Validate("Unit of Measure Code");
                    end;
                Validate(Quantity);
            end;
        }
        field(33; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if (Type = Type::Item) and ("No." <> '') then
                    UpdateAllAmounts;
            end;
        }
        field(79; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region";
        }
        field(80; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(81; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        field(83; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(1000; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            NotBlank = true;
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(1001; "Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Amount (LCY)" <> "Line Amount (LCY)");

                InitRoundingPrecisions;
                "Line Amount" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Currency Date", "Currency Code",
                      "Line Amount (LCY)", "Currency Factor"),
                    AmountRoundingPrecisionFCY);
                UpdateAllAmounts;
            end;
        }
        field(1002; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Cost" <> "Unit Cost");

                UpdateAllAmounts;
            end;
        }
        field(1003; "Total Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Cost';
            Editable = false;
        }
        field(1004; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Price" <> "Unit Price");

                UpdateAllAmounts;
            end;
        }
        field(1005; "Total Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Price';
            Editable = false;
        }
        field(1006; "Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Amount" <> "Line Amount");

                UpdateAllAmounts;
            end;
        }
        field(1007; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Discount Amount" <> "Line Discount Amount");

                UpdateAllAmounts;
            end;
        }
        field(1008; "Line Discount Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Discount Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Discount Amount (LCY)" <> "Line Discount Amount (LCY)");

                InitRoundingPrecisions;
                "Line Discount Amount" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Currency Date", "Currency Code",
                      "Line Discount Amount (LCY)", "Currency Factor"),
                    AmountRoundingPrecisionFCY);
                UpdateAllAmounts;
            end;
        }
        field(1015; "Cost Factor"; Decimal)
        {
            Caption = 'Cost Factor';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Cost Factor" <> "Cost Factor");

                UpdateAllAmounts;
            end;
        }
        field(1019; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            Editable = false;
        }
        field(1020; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            Editable = false;
        }
        field(1021; "Line Discount %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Discount %" <> "Line Discount %");

                UpdateAllAmounts;
            end;
        }
        field(1022; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Budget,Billable,Both Budget and Billable';
            OptionMembers = Budget,Billable,"Both Budget and Billable";

            trigger OnValidate()
            begin
                "Schedule Line" := true;
                "Contract Line" := true;
                if "Line Type" = "Line Type"::Budget then
                    "Contract Line" := false;
                if "Line Type" = "Line Type"::Billable then
                    "Schedule Line" := false;

                if not "Contract Line" and (("Qty. Transferred to Invoice" <> 0) or ("Qty. Invoiced" <> 0)) then
                    Error(LineTypeErr, TableCaption, FieldCaption("Line Type"), "Line Type");

                ControlUsageLink;
            end;
        }
        field(1023; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Currency Code" <> "Currency Code");

                UpdateCurrencyFactor;
                UpdateAllAmounts;
            end;
        }
        field(1024; "Currency Date"; Date)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Date';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Currency Date" <> "Currency Date");

                UpdateCurrencyFactor;
                if (CurrFieldNo <> FieldNo("Planning Date")) and ("No." <> '') then
                    UpdateFromCurrency;
            end;
        }
        field(1025; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Currency Factor" <> "Currency Factor");

                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(CurrencyFactorErr, FieldCaption("Currency Code")));
                UpdateAllAmounts;
            end;
        }
        field(1026; "Schedule Line"; Boolean)
        {
            Caption = 'Budget Line';
            Editable = false;
            InitValue = true;
        }
        field(1027; "Contract Line"; Boolean)
        {
            Caption = 'Billable Line';
            Editable = false;
        }
        field(1030; "Job Contract Entry No."; Integer)
        {
            Caption = 'Job Contract Entry No.';
            Editable = false;
        }
        field(1035; "Invoiced Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Job Planning Line Invoice"."Invoiced Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                                         "Job Task No." = FIELD("Job Task No."),
                                                                                         "Job Planning Line No." = FIELD("Line No.")));
            Caption = 'Invoiced Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1036; "Invoiced Cost Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Job Planning Line Invoice"."Invoiced Cost Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                                              "Job Task No." = FIELD("Job Task No."),
                                                                                              "Job Planning Line No." = FIELD("Line No.")));
            Caption = 'Invoiced Cost Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1037; "VAT Unit Price"; Decimal)
        {
            Caption = 'VAT Unit Price';
        }
        field(1038; "VAT Line Discount Amount"; Decimal)
        {
            Caption = 'VAT Line Discount Amount';
        }
        field(1039; "VAT Line Amount"; Decimal)
        {
            Caption = 'VAT Line Amount';
        }
        field(1041; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
        }
        field(1042; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(1043; "Job Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Job Ledger Entry No.';
            Editable = false;
            TableRelation = "Job Ledger Entry";
        }
        field(1048; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            InitValue = "Order";
            OptionCaption = 'Planning,Quote,Order,Completed';
            OptionMembers = Planning,Quote,"Order",Completed;
        }
        field(1050; "Ledger Entry Type"; Option)
        {
            Caption = 'Ledger Entry Type';
            OptionCaption = ' ,Resource,Item,G/L Account';
            OptionMembers = " ",Resource,Item,"G/L Account";
        }
        field(1051; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = IF ("Ledger Entry Type" = CONST(Resource)) "Res. Ledger Entry"
            ELSE
            IF ("Ledger Entry Type" = CONST(Item)) "Item Ledger Entry"
            ELSE
            IF ("Ledger Entry Type" = CONST("G/L Account")) "G/L Entry";
        }
        field(1052; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
        }
        field(1053; "Usage Link"; Boolean)
        {
            Caption = 'Usage Link';

            trigger OnValidate()
            begin
                if "Usage Link" and ("Line Type" = "Line Type"::Billable) then
                    Error(UsageLinkErr, FieldCaption("Usage Link"), TableCaption, FieldCaption("Line Type"), "Line Type");

                ControlUsageLink;

                CheckItemAvailable(FieldNo("Usage Link"));
                UpdateReservation(FieldNo("Usage Link"));
            end;
        }
        field(1060; "Remaining Qty."; Decimal)
        {
            Caption = 'Remaining Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Validate("Remaining Qty. (Base)",
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Remaining Qty.", "Qty. per Unit of Measure"));
            end;
        }
        field(1061; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1062; "Remaining Total Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Total Cost';
            Editable = false;
        }
        field(1063; "Remaining Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Total Cost (LCY)';
            Editable = false;
        }
        field(1064; "Remaining Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Line Amount';
            Editable = false;
        }
        field(1065; "Remaining Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Line Amount (LCY)';
            Editable = false;
        }
        field(1070; "Qty. Posted"; Decimal)
        {
            Caption = 'Qty. Posted';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1071; "Qty. to Transfer to Journal"; Decimal)
        {
            Caption = 'Qty. to Transfer to Journal';
            DecimalPlaces = 0 : 5;
        }
        field(1072; "Posted Total Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Posted Total Cost';
            Editable = false;
        }
        field(1073; "Posted Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Posted Total Cost (LCY)';
            Editable = false;
        }
        field(1074; "Posted Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Posted Line Amount';
            Editable = false;
        }
        field(1075; "Posted Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Posted Line Amount (LCY)';
            Editable = false;
        }
        field(1080; "Qty. Transferred to Invoice"; Decimal)
        {
            CalcFormula = Sum ("Job Planning Line Invoice"."Quantity Transferred" WHERE("Job No." = FIELD("Job No."),
                                                                                        "Job Task No." = FIELD("Job Task No."),
                                                                                        "Job Planning Line No." = FIELD("Line No.")));
            Caption = 'Qty. Transferred to Invoice';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1081; "Qty. to Transfer to Invoice"; Decimal)
        {
            Caption = 'Qty. to Transfer to Invoice';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Transfer to Invoice" = 0 then
                    exit;

                if "Contract Line" then begin
                    if Quantity = "Qty. Transferred to Invoice" then
                        Error(QtyAlreadyTransferredErr, TableCaption);

                    if Quantity > 0 then begin
                        if ("Qty. to Transfer to Invoice" > 0) and ("Qty. to Transfer to Invoice" > (Quantity - "Qty. Transferred to Invoice")) or
                           ("Qty. to Transfer to Invoice" < 0)
                        then
                            Error(QtyToTransferToInvoiceErr, FieldCaption("Qty. to Transfer to Invoice"), 0, Quantity - "Qty. Transferred to Invoice");
                    end else begin
                        if ("Qty. to Transfer to Invoice" > 0) or
                           ("Qty. to Transfer to Invoice" < 0) and ("Qty. to Transfer to Invoice" < (Quantity - "Qty. Transferred to Invoice"))
                        then
                            Error(QtyToTransferToInvoiceErr, FieldCaption("Qty. to Transfer to Invoice"), Quantity - "Qty. Transferred to Invoice", 0);
                    end;
                end else
                    Error(NoContractLineErr, FieldCaption("Qty. to Transfer to Invoice"), TableCaption, "Line Type");
            end;
        }
        field(1090; "Qty. Invoiced"; Decimal)
        {
            CalcFormula = Sum ("Job Planning Line Invoice"."Quantity Transferred" WHERE("Job No." = FIELD("Job No."),
                                                                                        "Job Task No." = FIELD("Job Task No."),
                                                                                        "Job Planning Line No." = FIELD("Line No."),
                                                                                        "Document Type" = FILTER("Posted Invoice" | "Posted Credit Memo")));
            Caption = 'Qty. Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1091; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1100; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData Item = R;
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source Type" = CONST(1003),
                                                                   "Source Subtype" = FIELD(Status),
                                                                   "Source ID" = FIELD("Job No."),
                                                                   "Source Ref. No." = FIELD("Job Contract Entry No."),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1101; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Item = R;
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source Type" = CONST(1003),
                                                                            "Source Subtype" = FIELD(Status),
                                                                            "Source ID" = FIELD("Job No."),
                                                                            "Source Ref. No." = FIELD("Job Contract Entry No."),
                                                                            "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure");
                UpdatePlanned;
            end;
        }
        field(1102; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';

            trigger OnValidate()
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                    TestField("Usage Link");
                end;
                CalcFields("Reserved Qty. (Base)");
                if (Reserve = Reserve::Never) and ("Reserved Qty. (Base)" > 0) then
                    TestField("Reserved Qty. (Base)", 0);

                if xRec.Reserve = Reserve::Always then begin
                    GetItem;
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(1103; Planned; Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            begin
                ValidateModification(xRec."Variant Code" <> "Variant Code");

                if "Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        Item.Get("No.");
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                        GetItemTranslation;
                    end
                end else begin
                    TestField(Type, Type::Item);

                    ItemVariant.Get("No.", "Variant Code");
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end;
                Validate(Quantity);
                CheckItemAvailable(FieldNo("Variant Code"));
                UpdateReservation(FieldNo("Variant Code"));
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                ValidateModification(xRec."Bin Code" <> "Bin Code");

                TestField("Location Code");
                CheckItemAvailable(FieldNo("Bin Code"));
                UpdateReservation(FieldNo("Bin Code"));
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5410; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                if ("Requested Delivery Date" <> xRec."Requested Delivery Date") and
                   ("Promised Delivery Date" <> 0D)
                then
                    Error(
                      RequestedDeliveryDateErr,
                      FieldCaption("Requested Delivery Date"),
                      FieldCaption("Promised Delivery Date"));

                if "Requested Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Requested Delivery Date")
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            begin
                if "Promised Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Promised Delivery Date")
                else
                    Validate("Requested Delivery Date");
            end;
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            begin
                Validate("Planning Date", "Planned Delivery Date");
            end;
        }
        field(5900; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Cost Calculation Method';
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Job No.", "Job Task No.", "Schedule Line", "Planning Date")
        {
            SumIndexFields = "Total Price (LCY)", "Total Cost (LCY)", "Line Amount (LCY)", "Remaining Total Cost (LCY)", "Remaining Line Amount (LCY)", "Total Cost", "Line Amount";
        }
        key(Key3; "Job No.", "Job Task No.", "Contract Line", "Planning Date")
        {
            SumIndexFields = "Total Price (LCY)", "Total Cost (LCY)", "Line Amount (LCY)", "Remaining Total Cost (LCY)", "Remaining Line Amount (LCY)", "Total Cost", "Line Amount";
        }
        key(Key4; "Job No.", "Job Task No.", "Schedule Line", "Currency Date")
        {
        }
        key(Key5; "Job No.", "Job Task No.", "Contract Line", "Currency Date")
        {
        }
        key(Key6; "Job No.", "Schedule Line", Type, "No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key7; "Job No.", "Schedule Line", Type, "Resource Group No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key8; Status, "Schedule Line", Type, "No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key9; Status, "Schedule Line", Type, "Resource Group No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key10; "Job No.", "Contract Line")
        {
        }
        key(Key11; "Job Contract Entry No.")
        {
        }
        key(Key12; Type, "No.", "Job No.", "Job Task No.", "Usage Link", "System-Created Entry")
        {
        }
        key(Key13; Status, Type, "No.", "Variant Code", "Location Code", "Planning Date")
        {
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key14; "Job No.", "Planning Date", "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        ValidateModification(true);
        CheckRelatedJobPlanningLineInvoice;

        if "Usage Link" then begin
            JobUsageLink.SetRange("Job No.", "Job No.");
            JobUsageLink.SetRange("Job Task No.", "Job Task No.");
            JobUsageLink.SetRange("Line No.", "Line No.");
            if not JobUsageLink.IsEmpty then
                Error(JobUsageLinkErr, TableCaption);
        end;

        if (Quantity <> 0) and ItemExists("No.") then begin
            JobPlanningLineReserve.DeleteLine(Rec);
            CalcFields("Reserved Qty. (Base)");
            TestField("Reserved Qty. (Base)", 0);
        end;

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");
    end;

    trigger OnInsert()
    begin
        LockTable();
        GetJob;
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked;
        JobTask.Get("Job No.", "Job Task No.");
        JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
        InitJobPlanningLine;
        if Quantity <> 0 then
            UpdateReservation(0);

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "User ID" := UserId;

        if ((Quantity <> 0) or (xRec.Quantity <> 0)) and ItemExists(xRec."No.") then
            UpdateReservation(0);

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");
    end;

    trigger OnRename()
    begin
        Error(RecordRenameErr, FieldCaption("Job No."), FieldCaption("Job Task No."), TableCaption);
    end;

    var
        GLAcc: Record "G/L Account";
        Location: Record Location;
        Item: Record Item;
        JobTask: Record "Job Task";
        ItemVariant: Record "Item Variant";
        Res: Record Resource;
        WorkType: Record "Work Type";
        Job: Record Job;
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CurrExchRate: Record "Currency Exchange Rate";
        SKU: Record "Stockkeeping Unit";
        StandardText: Record "Standard Text";
        ItemTranslation: Record "Item Translation";
        GLSetup: Record "General Ledger Setup";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        CurrencyFactorErr: Label 'cannot be specified without %1', Comment = '%1 = Currency Code field name';
        RecordRenameErr: Label 'You cannot change the %1 or %2 of this %3.', Comment = '%1 = Job Number field name; %2 = Job Task Number field name; %3 = Job Planning Line table name';
        CurrencyDate: Date;
        MissingItemResourceGLErr: Label 'You must specify %1 %2 in planning line.', Comment = '%1 = Document Type (Item, Resoure, or G/L); %2 = Field name';
        HasGotGLSetup: Boolean;
        UnitAmountRoundingPrecision: Decimal;
        AmountRoundingPrecision: Decimal;
        QtyLessErr: Label '%1 cannot be less than %2.', Comment = '%1 = Name of first field to compare; %2 = Name of second field to compare';
        ControlUsageLinkErr: Label 'The %1 must be a %2 and %3 must be enabled, because linked Job Ledger Entries exist.', Comment = '%1 = Job Planning Line table name; %2 = Caption for field Schedule Line; %3 = Captiion for field Usage Link';
        JobUsageLinkErr: Label 'This %1 cannot be deleted because linked job ledger entries exist.', Comment = '%1 = Job Planning Line table name';
        BypassQtyValidation: Boolean;
        LinkedJobLedgerErr: Label 'You cannot change this value because linked job ledger entries exist.';
        LineTypeErr: Label 'The %1 cannot be of %2 %3 because it is transferred to an invoice.', Comment = 'The Job Planning Line cannot be of Line Type Schedule, because it is transferred to an invoice.';
        QtyToTransferToInvoiceErr: Label '%1 may not be lower than %2 and may not exceed %3.', Comment = '%1 = Qty. to Transfer to Invoice field name; %2 = First value in comparison; %3 = Second value in comparison';
        AutoReserveQst: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        NoContractLineErr: Label '%1 cannot be set on a %2 of type %3.', Comment = '%1 = Qty. to Transfer to Invoice field name; %2 = Job Planning Line table name; %3 = The job''s line type';
        QtyAlreadyTransferredErr: Label 'The %1 has already been completely transferred.', Comment = '%1 = Job Planning Line table name';
        UsageLinkErr: Label '%1 cannot be enabled on a %2 with %3 %4.', Comment = 'Usage Link cannot be enabled on a Job Planning Line with Line Type Schedule';
        QtyGreaterErr: Label '%1 cannot be higher than %2.', Comment = '%1 = Caption for field Quantity; %2 = Captiion for field Qty. Transferred to Invoice';
        RequestedDeliveryDateErr: Label 'You cannot change the %1 when the %2 has been filled in.', Comment = '%1 = Caption for field Requested Delivery Date; %2 = Captiion for field Promised Delivery Date';
        UnitAmountRoundingPrecisionFCY: Decimal;
        AmountRoundingPrecisionFCY: Decimal;
        NotPossibleJobPlanningLineErr: Label 'It is not possible to deleted job planning line transferred to an invoice.';

    local procedure CheckItemAvailable(CalledByFieldNo: Integer)
    begin
        if CurrFieldNo <> CalledByFieldNo then
            exit;
        if Reserve = Reserve::Always then
            exit;
        if (Type <> Type::Item) or ("No." = '') then
            exit;
        if Quantity <= 0 then
            exit;
        if not (Status in [Status::Order]) then
            exit;

        if ItemCheckAvail.JobPlanningLineCheck(Rec) then
            ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetJob()
    begin
        if ("Job No." <> Job."No.") and ("Job No." <> '') then
            Job.Get("Job No.");
    end;

    procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            if "Currency Date" = 0D then
                CurrencyDate := WorkDate
            else
                CurrencyDate := "Currency Date";
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;
    end;

    local procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type = Type::Item then
            if not Item2.Get(ItemNo) then
                exit(false);
        exit(true);
    end;

    local procedure GetItem()
    begin
        if "No." <> Item."No." then
            if not Item.Get("No.") then
                Clear(Item);
    end;

    local procedure GetSKU(): Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);

        if SKU.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        exit(false);
    end;

    local procedure InitRoundingPrecisions()
    var
        Currency: Record Currency;
    begin
        if (AmountRoundingPrecision = 0) or
           (UnitAmountRoundingPrecision = 0) or
           (AmountRoundingPrecisionFCY = 0) or
           (UnitAmountRoundingPrecisionFCY = 0)
        then begin
            Clear(Currency);
            Currency.InitRoundingPrecision;
            AmountRoundingPrecision := Currency."Amount Rounding Precision";
            UnitAmountRoundingPrecision := Currency."Unit-Amount Rounding Precision";

            if "Currency Code" <> '' then begin
                Currency.Get("Currency Code");
                Currency.TestField("Amount Rounding Precision");
                Currency.TestField("Unit-Amount Rounding Precision");
            end;

            AmountRoundingPrecisionFCY := Currency."Amount Rounding Precision";
            UnitAmountRoundingPrecisionFCY := Currency."Unit-Amount Rounding Precision";
        end;
    end;

    procedure Caption(): Text
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if not Job.Get("Job No.") then
            exit('');
        if not JobTask.Get("Job No.", "Job Task No.") then
            exit('');
        exit(StrSubstNo('%1 %2 %3 %4',
            Job."No.",
            Job.Description,
            JobTask."Job Task No.",
            JobTask.Description));
    end;

    procedure SetUpNewLine(LastJobPlanningLine: Record "Job Planning Line")
    begin
        "Document Date" := LastJobPlanningLine."Planning Date";
        "Document No." := LastJobPlanningLine."Document No.";
        Type := LastJobPlanningLine.Type;
        Validate("Line Type", LastJobPlanningLine."Line Type");
        GetJob;
        "Currency Code" := Job."Currency Code";
        UpdateCurrencyFactor;
        if LastJobPlanningLine."Planning Date" <> 0D then
            Validate("Planning Date", LastJobPlanningLine."Planning Date");
        "Price Calculation Method" := Job.GetPriceCalculationMethod();
        "Cost Calculation Method" := Job.GetCostCalculationMethod();

        OnAfterSetupNewLine(Rec, LastJobPlanningLine);
    end;

    procedure InitJobPlanningLine()
    var
        JobJnlManagement: Codeunit JobJnlManagement;
    begin
        GetJob;
        if "Planning Date" = 0D then
            Validate("Planning Date", WorkDate);
        "Currency Code" := Job."Currency Code";
        UpdateCurrencyFactor;
        "VAT Unit Price" := 0;
        "VAT Line Discount Amount" := 0;
        "VAT Line Amount" := 0;
        "VAT %" := 0;
        "Job Contract Entry No." := JobJnlManagement.GetNextEntryNo;
        "User ID" := UserId;
        "Last Date Modified" := 0D;
        Status := Job.Status;
        ControlUsageLink;
        "Country/Region Code" := Job."Bill-to Country/Region Code";

        OnAfterInitJobPlanningLine(Rec);
    end;

    local procedure DeleteAmounts()
    begin
        Quantity := 0;
        "Quantity (Base)" := 0;

        "Direct Unit Cost (LCY)" := 0;
        "Unit Cost (LCY)" := 0;
        "Unit Cost" := 0;

        "Total Cost (LCY)" := 0;
        "Total Cost" := 0;

        "Unit Price (LCY)" := 0;
        "Unit Price" := 0;

        "Total Price (LCY)" := 0;
        "Total Price" := 0;

        "Line Amount (LCY)" := 0;
        "Line Amount" := 0;

        "Line Discount %" := 0;

        "Line Discount Amount (LCY)" := 0;
        "Line Discount Amount" := 0;

        "Remaining Qty." := 0;
        "Remaining Qty. (Base)" := 0;
        "Remaining Total Cost" := 0;
        "Remaining Total Cost (LCY)" := 0;
        "Remaining Line Amount" := 0;
        "Remaining Line Amount (LCY)" := 0;

        "Qty. Posted" := 0;
        "Qty. to Transfer to Journal" := 0;
        "Posted Total Cost" := 0;
        "Posted Total Cost (LCY)" := 0;
        "Posted Line Amount" := 0;
        "Posted Line Amount (LCY)" := 0;

        "Qty. to Transfer to Invoice" := 0;
        "Qty. to Invoice" := 0;

        OnAfterDeleteAmounts(Rec);
    end;

    local procedure UpdateFromCurrency()
    begin
        UpdateAllAmounts;
    end;

    local procedure GetItemTranslation()
    begin
        GetJob;
        if ItemTranslation.Get("No.", "Variant Code", Job."Language Code") then begin
            Description := ItemTranslation.Description;
            "Description 2" := ItemTranslation."Description 2";
        end;
    end;

    local procedure GetGLSetup()
    begin
        if HasGotGLSetup then
            exit;
        GLSetup.Get();
        HasGotGLSetup := true;
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Qty." - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Qty.";
        QtyToReserveBase := "Remaining Qty. (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', Status, "Job No.", "No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Job Planning Line", Status, "Job No.", "Job Contract Entry No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Planning Date";
        ReservEntry."Shipment Date" := "Planning Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Job Planning Line", Status, "Job No.", "Job Contract Entry No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure UpdateAllAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllAmounts(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        InitRoundingPrecisions;

        UpdateUnitCost;
        UpdateTotalCost;
        FindPriceAndDiscount(Rec, CurrFieldNo);
        HandleCostFactor;
        UpdateUnitPrice;
        UpdateTotalPrice;
        UpdateAmountsAndDiscounts;
        UpdateRemainingCostsAndAmounts("Currency Date", "Currency Factor");
        if Type = Type::Text then
            FieldError(Type);

        OnAfterUpdateAllAmounts(Rec);
    end;

    local procedure UpdateUnitCost()
    var
        ResCost: Record "Resource Cost";
        RetrievedCost: Decimal;
    begin
        GetJob;
        if (Type = Type::Item) and Item.Get("No.") then
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                if RetrieveCostPrice then begin
                    if GetSKU then
                        "Unit Cost (LCY)" := Round(SKU."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision)
                    else
                        "Unit Cost (LCY)" := Round(Item."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision);
                    "Unit Cost" := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          "Currency Date", "Currency Code",
                          "Unit Cost (LCY)", "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                end else
                    RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)");
            end else begin
                if RetrieveCostPrice then begin
                    if GetSKU then
                        RetrievedCost := SKU."Unit Cost" * "Qty. per Unit of Measure"
                    else
                        RetrievedCost := Item."Unit Cost" * "Qty. per Unit of Measure";
                    "Unit Cost" := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          "Currency Date", "Currency Code",
                          RetrievedCost, "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                    "Unit Cost (LCY)" := Round(RetrievedCost, UnitAmountRoundingPrecision);
                end else
                    RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)");
            end
        else
            if (Type = Type::Resource) and Res.Get("No.") then begin
                if RetrieveCostPrice then begin
                    ResCost.Init();
                    ResCost.Code := "No.";
                    ResCost."Work Type Code" := "Work Type Code";
                    CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
                    OnAfterResourceFindCost(Rec, ResCost);
                    "Direct Unit Cost (LCY)" := Round(ResCost."Direct Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision);
                    RetrievedCost := ResCost."Unit Cost" * "Qty. per Unit of Measure";
                    "Unit Cost" := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          "Currency Date", "Currency Code",
                          RetrievedCost, "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                    "Unit Cost (LCY)" := Round(RetrievedCost, UnitAmountRoundingPrecision);
                end else
                    RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)");
            end else
                RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)");
    end;

    local procedure RetrieveCostPrice(): Boolean
    var
        ShouldRetrieveCostPrice: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ShouldRetrieveCostPrice := false;
        OnBeforeRetrieveCostPrice(Rec, xRec, ShouldRetrieveCostPrice, IsHandled);
        if IsHandled then
            exit(ShouldRetrieveCostPrice);

        case Type of
            Type::Item:
                ShouldRetrieveCostPrice :=
                  ("No." <> xRec."No.") or
                  ("Location Code" <> xRec."Location Code") or
                  ("Variant Code" <> xRec."Variant Code") or
                  (not BypassQtyValidation and (Quantity <> xRec.Quantity)) or
                  ("Unit of Measure Code" <> xRec."Unit of Measure Code");
            Type::Resource:
                ShouldRetrieveCostPrice :=
                  ("No." <> xRec."No.") or
                  ("Work Type Code" <> xRec."Work Type Code") or
                  ("Unit of Measure Code" <> xRec."Unit of Measure Code");
            Type::"G/L Account":
                ShouldRetrieveCostPrice := "No." <> xRec."No.";
            else
                exit(false);
        end;
        exit(ShouldRetrieveCostPrice);
    end;

    local procedure UpdateTotalCost()
    begin
        "Total Cost" := Round("Unit Cost" * Quantity, AmountRoundingPrecisionFCY);
        "Total Cost (LCY)" := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Currency Date", "Currency Code",
              "Total Cost", "Currency Factor"),
            AmountRoundingPrecision);
    end;

    local procedure FindPriceAndDiscount(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
    begin
        if RetrieveCostPrice and ("No." <> '') then begin
            ApplyPrice(PriceType::Sale, CalledByFieldNo);
            ApplyPrice(PriceType::Purchase, CalledByFieldNo);
            if Type = Type::"G/L Account" then begin
                UpdateUnitCost;
                UpdateTotalCost;
            end;
        end;
    end;

    procedure ApplyPrice(PriceType: enum "Price Type"; CalledByFieldNo: Integer)
    var
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        JobPlanningLinePrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(JobPlanningLinePrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        if PriceType = PriceType::Sale then
            PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    local procedure HandleCostFactor()
    begin
        if ("Cost Factor" <> 0) and (("Unit Cost" <> xRec."Unit Cost") or ("Cost Factor" <> xRec."Cost Factor")) then
            "Unit Price" := Round("Unit Cost" * "Cost Factor", UnitAmountRoundingPrecisionFCY)
        else
            if (Item."Price/Profit Calculation" = Item."Price/Profit Calculation"::"Price=Cost+Profit") and
               (Item."Profit %" < 100) and
               ("Unit Cost" <> xRec."Unit Cost")
            then
                "Unit Price" := Round("Unit Cost" / (1 - Item."Profit %" / 100), UnitAmountRoundingPrecisionFCY);
    end;

    local procedure UpdateUnitPrice()
    begin
        GetJob;
        RecalculateAmounts(Job."Exch. Calculation (Price)", xRec."Unit Price", "Unit Price", "Unit Price (LCY)");
    end;

    local procedure RecalculateAmounts(JobExchCalculation: Option "Fixed FCY","Fixed LCY"; xAmount: Decimal; var Amount: Decimal; var AmountLCY: Decimal)
    begin
        if (xRec."Currency Factor" <> "Currency Factor") and
           (Amount = xAmount) and (JobExchCalculation = JobExchCalculation::"Fixed LCY")
        then
            Amount := Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  "Currency Date", "Currency Code",
                  AmountLCY, "Currency Factor"),
                UnitAmountRoundingPrecisionFCY)
        else
            AmountLCY := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  "Currency Date", "Currency Code",
                  Amount, "Currency Factor"),
                UnitAmountRoundingPrecision);
    end;

    local procedure UpdateTotalPrice()
    begin
        "Total Price" := Round(Quantity * "Unit Price", AmountRoundingPrecisionFCY);
        "Total Price (LCY)" := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Currency Date", "Currency Code",
              "Total Price", "Currency Factor"),
            AmountRoundingPrecision);

        OnAfterUpdateTotalPrice(Rec);
    end;

    local procedure UpdateAmountsAndDiscounts()
    begin
        if "Total Price" = 0 then begin
            "Line Amount" := 0;
            "Line Discount Amount" := 0;
        end else
            if ("Line Amount" <> xRec."Line Amount") and ("Line Discount Amount" = xRec."Line Discount Amount") then begin
                "Line Amount" := Round("Line Amount", AmountRoundingPrecisionFCY);
                "Line Discount Amount" := "Total Price" - "Line Amount";
                "Line Discount %" :=
                  Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
            end else
                if ("Line Discount Amount" <> xRec."Line Discount Amount") and ("Line Amount" = xRec."Line Amount") then begin
                    "Line Discount Amount" := Round("Line Discount Amount", AmountRoundingPrecisionFCY);
                    "Line Amount" := "Total Price" - "Line Discount Amount";
                    "Line Discount %" :=
                      Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
                end else
                    if ("Line Discount Amount" = xRec."Line Discount Amount") and
                       (("Line Amount" <> xRec."Line Amount") or ("Line Discount %" <> xRec."Line Discount %") or
                        ("Total Price" <> xRec."Total Price"))
                    then begin
                        "Line Discount Amount" :=
                          Round("Total Price" * "Line Discount %" / 100, AmountRoundingPrecisionFCY);
                        "Line Amount" := "Total Price" - "Line Discount Amount";
                    end;

        "Line Amount (LCY)" := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Currency Date", "Currency Code",
              "Line Amount", "Currency Factor"),
            AmountRoundingPrecision);

        "Line Discount Amount (LCY)" := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Currency Date", "Currency Code",
              "Line Discount Amount", "Currency Factor"),
            AmountRoundingPrecision);
    end;

    procedure Use(PostedQty: Decimal; PostedTotalCost: Decimal; PostedLineAmount: Decimal; PostingDate: Date; CurrencyFactor: Decimal)
    begin
        if "Usage Link" then begin
            InitRoundingPrecisions;
            // Update Quantity Posted
            Validate("Qty. Posted", "Qty. Posted" + PostedQty);

            // Update Posted Costs and Amounts.
            "Posted Total Cost" += Round(PostedTotalCost, AmountRoundingPrecisionFCY);
            "Posted Total Cost (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PostingDate, "Currency Code",
                  "Posted Total Cost", CurrencyFactor),
                AmountRoundingPrecision);

            "Posted Line Amount" += Round(PostedLineAmount, AmountRoundingPrecisionFCY);
            "Posted Line Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PostingDate, "Currency Code",
                  "Posted Line Amount", CurrencyFactor),
                AmountRoundingPrecision);

            // Update Remaining Quantity
            if (PostedQty >= 0) = ("Remaining Qty." >= 0) then
                if Abs(PostedQty) <= Abs("Remaining Qty.") then
                    Validate("Remaining Qty.", "Remaining Qty." - PostedQty)
                else begin
                    Validate(Quantity, Quantity + PostedQty - "Remaining Qty.");
                    Validate("Remaining Qty.", 0);
                end
            else
                Validate("Remaining Qty.", "Remaining Qty." - PostedQty);

            // Update Remaining Costs and Amounts
            UpdateRemainingCostsAndAmounts(PostingDate, CurrencyFactor);

            // Update Quantity to Post
            Validate("Qty. to Transfer to Journal", "Remaining Qty.");
        end else
            ClearValues;

        Modify(true);
    end;

    local procedure UpdateRemainingCostsAndAmounts(PostingDate: Date; CurrencyFactor: Decimal)
    begin
        if "Usage Link" then begin
            InitRoundingPrecisions;
            "Remaining Total Cost" := Round("Unit Cost" * "Remaining Qty.", AmountRoundingPrecisionFCY);
            "Remaining Total Cost (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PostingDate, "Currency Code",
                  "Remaining Total Cost", CurrencyFactor),
                AmountRoundingPrecision);
            "Remaining Line Amount" := CalcLineAmount("Remaining Qty.");
            "Remaining Line Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PostingDate, "Currency Code",
                  "Remaining Line Amount", CurrencyFactor),
                AmountRoundingPrecision);
        end else
            ClearValues;
    end;

    procedure UpdateQtyToTransfer()
    begin
        if "Contract Line" then begin
            CalcFields("Qty. Transferred to Invoice");
            Validate("Qty. to Transfer to Invoice", Quantity - "Qty. Transferred to Invoice");
        end else
            Validate("Qty. to Transfer to Invoice", 0);
    end;

    procedure UpdateQtyToInvoice()
    begin
        if "Contract Line" then begin
            CalcFields("Qty. Invoiced");
            Validate("Qty. to Invoice", Quantity - "Qty. Invoiced")
        end else
            Validate("Qty. to Invoice", 0);
    end;

    procedure UpdatePostedTotalCost(AdjustJobCost: Decimal; AdjustJobCostLCY: Decimal)
    begin
        if "Usage Link" then begin
            InitRoundingPrecisions;
            "Posted Total Cost" += Round(AdjustJobCost, AmountRoundingPrecisionFCY);
            "Posted Total Cost (LCY)" += Round(AdjustJobCostLCY, AmountRoundingPrecision);
        end;
    end;

    local procedure ValidateModification(FieldChanged: Boolean)
    begin
        if FieldChanged then begin
            CalcFields("Qty. Transferred to Invoice");
            TestField("Qty. Transferred to Invoice", 0);
        end;

        OnAfterValidateModification(Rec, FieldChanged);
    end;

    local procedure CheckUsageLinkRelations()
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        JobUsageLink.SetRange("Job No.", "Job No.");
        JobUsageLink.SetRange("Job Task No.", "Job Task No.");
        JobUsageLink.SetRange("Line No.", "Line No.");
        if not JobUsageLink.IsEmpty then
            Error(LinkedJobLedgerErr);
    end;

    local procedure ControlUsageLink()
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        GetJob;

        if Job."Apply Usage Link" then begin
            if "Schedule Line" then
                "Usage Link" := true
            else
                "Usage Link" := false;
        end else begin
            if not "Schedule Line" then
                "Usage Link" := false;
        end;

        JobUsageLink.SetRange("Job No.", "Job No.");
        JobUsageLink.SetRange("Job Task No.", "Job Task No.");
        JobUsageLink.SetRange("Line No.", "Line No.");
        if not JobUsageLink.IsEmpty and not "Usage Link" then
            Error(ControlUsageLinkErr, TableCaption, FieldCaption("Schedule Line"), FieldCaption("Usage Link"));

        Validate("Remaining Qty.", Quantity - "Qty. Posted");
        Validate("Qty. to Transfer to Journal", Quantity - "Qty. Posted");
        UpdateRemainingCostsAndAmounts("Currency Date", "Currency Factor");

        UpdateQtyToTransfer;
        UpdateQtyToInvoice;
    end;

    local procedure CalcLineAmount(Qty: Decimal): Decimal
    var
        TotalPrice: Decimal;
    begin
        InitRoundingPrecisions;
        TotalPrice := Round(Qty * "Unit Price", AmountRoundingPrecisionFCY);
        exit(TotalPrice - Round(TotalPrice * "Line Discount %" / 100, AmountRoundingPrecisionFCY));
    end;

    procedure Overdue(): Boolean
    begin
        if ("Planning Date" < WorkDate) and ("Remaining Qty." > 0) then
            exit(true);
        exit(false);
    end;

    procedure SetBypassQtyValidation(Bypass: Boolean)
    begin
        BypassQtyValidation := Bypass;
    end;

    local procedure UpdateReservation(CalledByFieldNo: Integer)
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
    begin
        if (CurrFieldNo <> CalledByFieldNo) and (CurrFieldNo <> 0) then
            exit;
        case CalledByFieldNo of
            FieldNo("Planning Date"), FieldNo("Planned Delivery Date"):
                if (xRec."Planning Date" <> "Planning Date") and
                   (Quantity <> 0) and
                   (Reserve <> Reserve::Never)
                then
                    ReservationCheckDateConfl.JobPlanningLineCheck(Rec, true);
            FieldNo(Quantity):
                JobPlanningLineReserve.VerifyQuantity(Rec, xRec);
            FieldNo("Usage Link"):
                if (Type = Type::Item) and "Usage Link" then begin
                    GetItem;
                    if Item.Reserve = Item.Reserve::Optional then begin
                        GetJob;
                        Reserve := Job.Reserve
                    end else
                        Reserve := Item.Reserve;
                end else
                    Reserve := Reserve::Never;
        end;
        JobPlanningLineReserve.VerifyChange(Rec, xRec);
        UpdatePlanned;
    end;

    local procedure UpdateDescription()
    begin
        if (xRec.Type = xRec.Type::Resource) and (xRec."No." <> '') then begin
            Res.Get(xRec."No.");
            if Description = Res.Name then
                Description := '';
            if "Description 2" = Res."Name 2" then
                "Description 2" := '';
        end;
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField(Reserve);
        TestField("Usage Link");
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure AutoReserve()
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        if Reserve = Reserve::Never then
            FieldError(Reserve);
        JobPlanningLineReserve.ReservQuantity(Rec, QtyToReserve, QtyToReserveBase);
        if QtyToReserveBase <> 0 then begin
            TestField("Planning Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Planning Date", QtyToReserve, QtyToReserveBase);
            Find;
            if not FullAutoReservation then begin
                Commit();
                if Confirm(AutoReserveQst, true) then begin
                    ShowReservation;
                    Find;
                end;
            end;
            UpdatePlanned;
        end;
    end;

    procedure ShowTracking()
    var
        OrderTrackingForm: Page "Order Tracking";
    begin
        OrderTrackingForm.SetJobPlanningLine(Rec);
        OrderTrackingForm.RunModal;
    end;

    procedure ShowOrderPromisingLine()
    var
        OrderPromisingLine: Record "Order Promising Line";
        OrderPromisingLines: Page "Order Promising Lines";
    begin
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::Job);
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::Job);
        OrderPromisingLine.SetRange("Source ID", "Job No.");
        OrderPromisingLine.SetRange("Source Line No.", "Job Contract Entry No.");

        OrderPromisingLines.SetSourceType(OrderPromisingLine."Source Type"::Job);
        OrderPromisingLines.SetTableView(OrderPromisingLine);
        OrderPromisingLines.RunModal;
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item)
    begin
        Reset;
        SetCurrentKey(Status, Type, "No.", "Variant Code", "Location Code", "Planning Date");
        SetRange(Status, Status::Order);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Planning Date", Item.GetFilter("Date Filter"));
        SetFilter("Remaining Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset;
        SetCurrentKey(Status, Type, "No.", "Variant Code", "Location Code", "Planning Date");
        SetRange(Status, NewStatus);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Planning Date", AvailabilityFilter);
        if Positive then
            SetFilter("Quantity (Base)", '<0')
        else
            SetFilter("Quantity (Base)", '>0');
    end;

    procedure DrillDownJobInvoices()
    var
        JobInvoices: Page "Job Invoices";
    begin
        JobInvoices.SetShowDetails(false);
        JobInvoices.SetPrJobPlanningLine(Rec);
        JobInvoices.Run;
    end;

    local procedure CheckRelatedJobPlanningLineInvoice()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", "Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", "Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", "Line No.");
        if not JobPlanningLineInvoice.IsEmpty then
            Error(NotPossibleJobPlanningLineErr);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(DATABASE::"Job Planning Line", Status,
            "Job No.", '', 0, "Job Contract Entry No."));
    end;

    procedure UpdatePlanned(): Boolean
    begin
        CalcFields("Reserved Quantity");
        if Planned = ("Reserved Quantity" = "Remaining Qty.") then
            exit(false);
        Planned := not Planned;
        exit(true);
    end;

    procedure ClearValues()
    begin
        Validate("Remaining Qty.", 0);
        "Remaining Total Cost" := 0;
        "Remaining Total Cost (LCY)" := 0;
        "Remaining Line Amount" := 0;
        "Remaining Line Amount (LCY)" := 0;
        Validate("Qty. Posted", 0);
        Validate("Qty. to Transfer to Journal", 0);
        "Posted Total Cost" := 0;
        "Posted Total Cost (LCY)" := 0;
        "Posted Line Amount" := 0;
        "Posted Line Amount (LCY)" := 0;
    end;

    procedure InitFromJobPlanningLine(FromJobPlanningLine: Record "Job Planning Line"; NewQuantity: Decimal)
    var
        ToJobPlanningLine: Record "Job Planning Line";
        JobJnlManagement: Codeunit JobJnlManagement;
    begin
        ToJobPlanningLine := Rec;

        ToJobPlanningLine.Init();
        ToJobPlanningLine.TransferFields(FromJobPlanningLine);
        ToJobPlanningLine."Line No." := GetNextJobLineNo(FromJobPlanningLine);
        ToJobPlanningLine.Validate("Line Type", "Line Type"::Billable);
        ToJobPlanningLine.ClearValues;
        ToJobPlanningLine."Job Contract Entry No." := JobJnlManagement.GetNextEntryNo;
        if ToJobPlanningLine.Type <> ToJobPlanningLine.Type::Text then begin
            ToJobPlanningLine.Validate(Quantity, NewQuantity);
            ToJobPlanningLine.Validate("Currency Code", FromJobPlanningLine."Currency Code");
            ToJobPlanningLine.Validate("Currency Date", FromJobPlanningLine."Currency Date");
            ToJobPlanningLine.Validate("Currency Factor", FromJobPlanningLine."Currency Factor");
            ToJobPlanningLine.Validate("Unit Cost", FromJobPlanningLine."Unit Cost");
            ToJobPlanningLine.Validate("Unit Price", FromJobPlanningLine."Unit Price");
        end;

        Rec := ToJobPlanningLine;
    end;

    local procedure GetNextJobLineNo(FromJobPlanningLine: Record "Job Planning Line"): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", FromJobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", FromJobPlanningLine."Job Task No.");
        if JobPlanningLine.FindLast then;
        exit(JobPlanningLine."Line No." + 10000);
    end;

    procedure IsNonInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem;
        exit(Item.IsNonInventoriableType);
    end;

    procedure CopyTrackingFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        "Serial No." := JobJnlLine."Serial No.";
        "Lot No." := JobJnlLine."Lot No.";

        OnAfterCopyTrackingFromJobJnlLine(Rec, JobJnlLine);
    end;

    procedure CopyTrackingFromJobLedgEntry(JobLedgEntry: Record "Job Ledger Entry")
    begin
        "Serial No." := JobLedgEntry."Serial No.";
        "Lot No." := JobLedgEntry."Lot No.";

        OnAfterCopyTrackingFromJobLedgEntry(Rec, JobLedgEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobJnlLine(var JobPlanningLine: Record "Job Planning Line"; JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobLedgEntry(var JobPlanningLine: Record "Job Planning Line"; JobLedgEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAmounts(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var JobPlanningLine: Record "Job Planning Line"; var Item: Record Item);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterResourceFindCost(var JobPlanningLine: Record "Job Planning Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; JobPlanningLine: Record "Job Planning Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var JobPlanningLine: Record "Job Planning Line"; LastJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAllAmounts(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalPrice(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateModification(var JobPlanningLine: Record "Job Planning Line"; FieldChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPrice(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var ShouldRetrieveCostPrice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllAmounts(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;
}


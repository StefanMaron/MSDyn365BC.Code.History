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
                    UpdateAllAmounts();
                if "Planning Date" <> 0D then
                    CheckItemAvailable(FieldNo("Planning Date"));
                if CurrFieldNo = FieldNo("Planned Delivery Date") then
                    UpdateReservation(CurrFieldNo)
                else
                    UpdateReservation(FieldNo("Planning Date"));
                "Planned Delivery Date" := "Planning Date";

                UpdatePlannedDueDate();
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
        field(5; Type; Enum "Job Planning Line Type")
        {
            Caption = 'Type';

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
                    if Type = Type::Item then begin
                        "Bin Code" := '';
                        SetDefaultBin();
                        WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("No."));
                    end;
                    if "No." = '' then
                        exit;
                end;

                GetJob;
                "Customer Price Group" := Job."Customer Price Group";
                "Price Calculation Method" := Job.GetPriceCalculationMethod();
                "Cost Calculation Method" := Job.GetCostCalculationMethod();

                case Type of
                    Type::Resource:
                        CopyFromResource();
                    Type::Item:
                        CopyFromItem();
                    Type::"G/L Account":
                        CopyFromGLAccount();
                    Type::Text:
                        CopyFromStandardText();
                end;

                OnValidateNoOnAfterCopyFromAccount(Rec, xRec, Job);

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
            begin
                if (Quantity <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                CheckQuantityPosted();

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

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                CalcQuantityBase();

                "Completely Picked" := "Qty. Picked" >= Quantity;

                UpdateRemainingQuantity();

                UpdateQtyToTransfer;
                UpdateQtyToInvoice;

                CheckItemAvailable(FieldNo(Quantity));
                UpdateReservation(FieldNo(Quantity));

                UpdateAllAmounts();
                BypassQtyValidation := false;
                WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo(Quantity));
            end;
        }
        field(11; "Direct Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost (LCY)';

            trigger OnValidate()
            begin
                if ("Direct Unit Cost (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
            end;
        }
        field(12; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Cost (LCY)" <> "Unit Cost (LCY)");

                if ("Unit Cost (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                if (Type = Type::Item) and
                   Item.Get("No.") and
                   (Item."Costing Method" = Item."Costing Method"::Standard)
                then
                    UpdateAllAmounts
                else begin
                    InitRoundingPrecisions();
                    "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);
                    UpdateAllAmounts();
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
                if ("Unit Price (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                InitRoundingPrecisions();
                "Unit Price" := ConvertAmountToFCY("Unit Price (LCY)", UnitAmountRoundingPrecisionFCY);
                UpdateAllAmounts();
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

                GetGLSetup();
                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            "Qty. per Unit of Measure" :=
                              UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                            WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Unit of Measure Code"));
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
        field(18; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(19; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
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
                    EnsureDirectedPutawayandPickFalse(Location);
                    CheckItemAvailable(FieldNo("Location Code"));
                    UpdateReservation(FieldNo("Location Code"));
                    Validate(Quantity);
                    SetDefaultBin();
                    WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Location Code"));

#if not CLEAN20
                    if FeatureManagement.IsEnabled(PicksForJobsFeatureIdLbl) then begin
#endif
                        DeleteWarehouseRequest(xRec);
                        CreateWarehouseRequest();
#if not CLEAN20
                    end;
#endif
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWorkTypeCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

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
                    UpdateAllAmounts();
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
        field(84; "Planning Due Date"; Date)
        {
            Caption = 'Planning Due Date';

            trigger OnValidate()
            begin
                WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Planning Due Date"));
            end;
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
                if ("Line Amount (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                InitRoundingPrecisions();
                "Line Amount" := ConvertAmountToFCY("Line Amount (LCY)", AmountRoundingPrecisionFCY);
                UpdateAllAmounts();
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
                if ("Unit Cost" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
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
                if ("Unit Price" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
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
                if ("Line Amount" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                UpdateAllAmounts();
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
                if ("Line Discount Amount" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
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
                if ("Line Discount Amount (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                InitRoundingPrecisions();
                "Line Discount Amount" :=
                    ConvertAmountToFCY("Line Discount Amount (LCY)", AmountRoundingPrecisionFCY);
                UpdateAllAmounts();
            end;
        }
        field(1015; "Cost Factor"; Decimal)
        {
            Caption = 'Cost Factor';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Cost Factor" <> "Cost Factor");

                UpdateAllAmounts();
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
                if ("Line Discount %" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
            end;
        }
        field(1022; "Line Type"; Enum "Job Planning Line Line Type")
        {
            Caption = 'Line Type';

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

                ControlUsageLink();
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

                UpdateCurrencyFactor();
                UpdateAllAmounts();
            end;
        }
        field(1024; "Currency Date"; Date)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Date';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Currency Date" <> "Currency Date");

                UpdateCurrencyFactor();
                if (CurrFieldNo <> FieldNo("Planning Date")) and (Type <> Type::Text) and ("No." <> '') then
                    UpdateFromCurrency();
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
                UpdateAllAmounts();
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
            CalcFormula = Sum("Job Planning Line Invoice"."Invoiced Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                                         "Job Task No." = FIELD("Job Task No."),
                                                                                         "Job Planning Line No." = FIELD("Line No.")));
            Caption = 'Invoiced Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1036; "Invoiced Cost Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("Job Planning Line Invoice"."Invoiced Cost Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
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
        field(1048; Status; Enum "Job Planning Line Status")
        {
            Caption = 'Status';
            Editable = false;
            InitValue = "Order";

            trigger OnValidate()
            begin
                WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo(Status));
            end;
        }
        field(1050; "Ledger Entry Type"; Enum "Job Ledger Entry Type")
        {
            Caption = 'Ledger Entry Type';
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

                ControlUsageLink();

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
                Validate("Remaining Qty. (Base)", CalcBaseQty("Remaining Qty.", FieldCaption("Remaining Qty."), FieldCaption("Remaining Qty. (Base)")));
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

            trigger OnValidate()
            begin
                if ("Qty. to Transfer to Journal" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
            end;
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
            CalcFormula = Sum("Job Planning Line Invoice"."Quantity Transferred" WHERE("Job No." = FIELD("Job No."),
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToTransferToInvoice(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Qty. to Transfer to Invoice" = 0 then
                    exit;

                if Type = Type::Text then
                    FieldError(Type);

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
            CalcFormula = Sum("Job Planning Line Invoice"."Quantity Transferred" WHERE("Job No." = FIELD("Job No."),
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
            CalcFormula = - Sum("Reservation Entry".Quantity WHERE("Source Type" = CONST(1003),
#pragma warning disable
                                                                   "Source Subtype" = FIELD(Status),
#pragma warning restore
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
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Source Type" = CONST(1003),
#pragma warning disable
                                                                            "Source Subtype" = FIELD(Status),
#pragma warning restore
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
                        GetItemTranslation();
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
                WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Variant Code"));
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
                BinCodeCaption: Text[30];
            begin
                ValidateModification(xRec."Bin Code" <> "Bin Code");
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    GetLocation("Location Code");
                    TestField(Type, Type::Item);
                    GetItem();
                    Item.TestField(Type, Item.Type::Inventory);
                    CheckItemAvailable(FieldNo("Bin Code"));
                    WMSManagement.FindBin("Location Code", "Bin Code", '');
                    BinCodeCaption := CopyStr(FieldCaption("Bin Code"), 1, 30);
                    WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Job Planning Line",
                      BinCodeCaption,
                      "Location Code",
                      "Bin Code", 0);
                    CheckBin();
                end;

                UpdateReservation(FieldNo("Bin Code"));
                WhseValidateSourceLine.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Bin Code"));
            end;

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);

                if Item.Get(Rec."No.") then
                    if BinCode <> '' then
                        Item.TestField(Type, Item.Type::Inventory);

                if Quantity > 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

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
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            Editable = false;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Cost Calculation Method';
        }
        field(7300; "Pick Qty."; Decimal)
        {
            CalcFormula = Sum("Warehouse Activity Line"."Qty. Outstanding" WHERE("Activity Type" = FILTER(<> "Put-away"),
                                                                                  "Source Type" = CONST(167),
                                                                                  "Source No." = FIELD("Job No."),
                                                                                  "Source Line No." = FIELD("Job Contract Entry No."),
                                                                                  "Source Subline No." = FIELD("Line No."),
                                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                                  "Action Type" = FILTER(" " | Place),
                                                                                  "Original Breakbulk" = CONST(false),
                                                                                  "Breakbulk No." = CONST(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7301; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. Picked", "Qty. per Unit of Measure");

                "Completely Picked" := "Qty. Picked" >= Quantity;
            end;
        }
        field(7302; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(7303; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(7304; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum("Warehouse Activity Line"."Qty. Outstanding (Base)" WHERE("Activity Type" = FILTER(<> "Put-away"),
                                                                                         "Source Type" = CONST(167),
                                                                                         "Source No." = FIELD("Job No."),
                                                                                         "Source Line No." = FIELD("Job Contract Entry No."),
                                                                                         "Source Subline No." = FIELD("Line No."),
                                                                                         "Action Type" = FILTER(" " | Place),
                                                                                         "Original Breakbulk" = CONST(false),
                                                                                         "Breakbulk No." = CONST(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7305; "Qty. on Journal"; Decimal)
        {
            CalcFormula = Sum("Job Journal Line"."Quantity (Base)" WHERE("Job No." = field("Job No."),
                                                                  "Job Task No." = field("Job Task No."),
                                                                  "Job Planning Line No." = field("Line No."),
                                                                  Type = field(Type),
                                                                  "No." = field("No.")));
            Caption = 'Qty. on Journal';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
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
            if not JobUsageLink.IsEmpty() then
                Error(JobUsageLinkErr, TableCaption);
        end;

        if (Quantity <> 0) and ItemExists("No.") then begin
            JobPlanningLineReserve.DeleteLine(Rec);
            CalcFields("Reserved Qty. (Base)");
            TestField("Reserved Qty. (Base)", 0);
        end;

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");

        WhseValidateSourceLine.JobPlanningLineDelete(Rec);

#if not CLEAN20
        if FeatureManagement.IsEnabled(PicksForJobsFeatureIdLbl) then
#endif
        DeleteWarehouseRequest(Rec);
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

#if not CLEAN20
        if FeatureManagement.IsEnabled(PicksForJobsFeatureIdLbl) then
#endif
        CreateWarehouseRequest();
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "User ID" := UserId;

        if ((Quantity <> 0) or (xRec.Quantity <> 0)) and ItemExists(xRec."No.") then
            UpdateReservation(0);

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");

#if not CLEAN20
        if FeatureManagement.IsEnabled(PicksForJobsFeatureIdLbl) then
#endif
        if xRec."Location Code" <> Rec."Location Code" then begin
                DeleteWarehouseRequest(xRec);
                CreateWarehouseRequest();
            end;
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
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
#if not CLEAN20
        FeatureManagement: Codeunit "Feature Management Facade";
        PicksForJobsFeatureIdLbl: Label 'PicksForJobs', Locked = true;
#endif
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

    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    begin
        if CurrFieldNo <> CalledByFieldNo then
            exit;
        if (Type <> Type::Item) or ("No." = '') then
            exit;
        if Quantity <= 0 then
            exit;
        if not (Status in [Status::Order]) then
            exit;

        if ItemCheckAvail.JobPlanningLineCheck(Rec) then
            ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure CheckBin()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
    begin
        if "Bin Code" <> '' then begin
            GetLocation("Location Code");
            if not Location."Directed Put-away and Pick" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "No.", "Variant Code", "Unit of Measure Code")
            then begin
                if not BinContent.CheckWhseClass(false) then
                    "Bin Code" := '';
            end else begin
                Bin.Get("Location Code", "Bin Code");
                if not Bin.CheckWhseClass("No.", false) then
                    "Bin Code" := '';
            end;
        end;
    end;

    local procedure CheckQuantityPosted()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQuantityPosted(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "Usage Link" then
            if not BypassQtyValidation then begin
                if ("Qty. Posted" > 0) and (Quantity < "Qty. Posted") then
                    Error(QtyLessErr, FieldCaption(Quantity), FieldCaption("Qty. Posted"));
                if ("Qty. Posted" < 0) and (Quantity > "Qty. Posted") then
                    Error(QtyGreaterErr, FieldCaption(Quantity), FieldCaption("Qty. Posted"));
            end;
    end;

    local procedure CopyFromResource()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromResource(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

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

    local procedure CopyFromItem()
    begin
        GetItem;
        Item.TestField(Blocked, false);
        Item.TestField("Gen. Prod. Posting Group");
        Description := Item.Description;
        "Description 2" := Item."Description 2";
        if Job."Language Code" <> '' then
            GetItemTranslation();
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        Validate("Unit of Measure Code", Item."Base Unit of Measure");
        if "Usage Link" then
            if Item.Reserve = Item.Reserve::Optional then
                Reserve := Job.Reserve
            else
                Reserve := Item.Reserve;
        OnAfterCopyFromItem(Rec, Job, Item);
    end;

    local procedure CopyFromGLAccount()
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

        OnAfterCopyFromGLAccount(Rec, Job, GLAcc);
    end;

    local procedure CopyFromStandardText()
    begin
        StandardText.Get("No.");
        Description := StandardText.Description;
    end;

    local procedure CalcQuantityBase()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure EnsureDirectedPutawayandPickFalse(var LocationToCheck: Record Location)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnsureDirectedPutawayandPickFalse(Rec, LocationToCheck, IsHandled);
        if IsHandled then
            exit;

        LocationToCheck.TestField("Directed Put-away and Pick", false);
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
            OnUpdateCurrencyFactorOnBeforeGetExchangeRate(Rec, CurrExchRate);
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

    local procedure GetSKU() Result: Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);

        if SKU.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        Result := false;
        OnAfterGetSKU(Rec, Result);
    end;

    procedure InitRoundingPrecisions()
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
        UpdateCurrencyFactor();
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
        UpdateCurrencyFactor();
        "VAT Unit Price" := 0;
        "VAT Line Discount Amount" := 0;
        "VAT Line Amount" := 0;
        "VAT %" := 0;
        "Job Contract Entry No." := JobJnlManagement.GetNextEntryNo;
        "User ID" := UserId;
        "Last Date Modified" := 0D;
        Status := Job.Status;
        ControlUsageLink();
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
        UpdateAllAmounts();
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
        OnAfterGetRemainingQty(Rec, RemainingQty, RemainingQtyBase);
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
        ReservEntry.SetSource(DATABASE::"Job Planning Line", Status.AsInteger(), "Job No.", "Job Contract Entry No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Planning Date";
        ReservEntry."Shipment Date" := "Planning Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Job Planning Line", Status.AsInteger(), "Job No.", "Job Contract Entry No.", false);
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

        InitRoundingPrecisions();

        UpdateUnitCost;
        FindPriceAndDiscount(CurrFieldNo);
        UpdateTotalCost;
        HandleCostFactor;
        UpdateUnitPrice;
        UpdateTotalPrice;
        UpdateAmountsAndDiscounts;
        UpdateRemainingCostsAndAmounts("Currency Date", "Currency Factor");

        OnAfterUpdateAllAmounts(Rec, xRec);
    end;

    local procedure UpdateUnitCost()
    var
        RetrievedCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(Rec, IsHandled);
        if IsHandled then
            exit;

        GetJob;
        if (Type = Type::Item) and Item.Get("No.") then
            if Item."Costing Method" = Item."Costing Method"::Standard then
                if RetrieveCostPrice(CurrFieldNo) then begin
                    if GetSKU then
                        "Unit Cost (LCY)" := Round(SKU."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision)
                    else
                        "Unit Cost (LCY)" := Round(Item."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision);
                    "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);
                end else
                    RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)")
            else
                if RetrieveCostPrice(CurrFieldNo) then begin
                    if GetSKU then
                        RetrievedCost := SKU."Unit Cost" * "Qty. per Unit of Measure"
                    else
                        RetrievedCost := Item."Unit Cost" * "Qty. per Unit of Measure";
                    "Unit Cost" := ConvertAmountToFCY(RetrievedCost, UnitAmountRoundingPrecisionFCY);
                    "Unit Cost (LCY)" := Round(RetrievedCost, UnitAmountRoundingPrecision);
                end else
                    RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)")
        else
            RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)");
    end;

#if not CLEAN19
    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '17.0')]
    procedure AfterResourceFindCost(var ResourceCost: Record "Resource Cost");
    begin
        OnAfterResourceFindCost(Rec, ResourceCost);
    end;
#endif
    local procedure RetrieveCostPrice(CalledByFieldNo: Integer): Boolean
    var
        ShouldRetrieveCostPrice: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ShouldRetrieveCostPrice := false;
        OnBeforeRetrieveCostPrice(Rec, xRec, ShouldRetrieveCostPrice, IsHandled, CalledByFieldNo);
        if IsHandled then
            exit(ShouldRetrieveCostPrice);

        if CalledByFieldNo <> 0 then
            case Type of
                Type::Item:
                    if not (CalledByFieldNo in
                            [FieldNo("No."), FieldNo(Quantity), FieldNo("Location Code"),
                            FieldNo("Variant Code"), FieldNo("Unit of Measure Code")])
                    then
                        exit(false);
                Type::Resource:
                    if not (CalledByFieldNo in
                         [FieldNo("No."), FieldNo(Quantity), FieldNo("Work Type Code"), FieldNo("Unit of Measure Code")])
                    then
                        exit(false);
                Type::"G/L Account":
                    if not (CalledByFieldNo in [FieldNo("No."), FieldNo(Quantity)]) then
                        exit(false);
            end;

        case Type of
            Type::Item:
                ShouldRetrieveCostPrice :=
                    ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice() or
                    ("Location Code" <> xRec."Location Code") or
                    ("Variant Code" <> xRec."Variant Code") or
                    (not BypassQtyValidation and (Quantity <> xRec.Quantity)) or
                    ("Unit of Measure Code" <> xRec."Unit of Measure Code");
            Type::Resource:
                ShouldRetrieveCostPrice :=
                    ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice() or
                    ("Work Type Code" <> xRec."Work Type Code") or
                    ("Unit of Measure Code" <> xRec."Unit of Measure Code");
            Type::"G/L Account":
                ShouldRetrieveCostPrice :=
                    ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice();
            else
                exit(false);
        end;
        exit(ShouldRetrieveCostPrice);
    end;

    local procedure IsQuantityChangedForPrice(): Boolean;
#if not CLEAN19
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
#endif
    begin
        if Quantity = xRec.Quantity then
            exit(false);
#if not CLEAN19
        exit(PriceCalculationMgt.IsExtendedPriceCalculationEnabled());
#else
        exit(true);
#endif
    end;

    local procedure UpdateTotalCost()
    begin
        "Total Cost" := Round("Unit Cost" * Quantity, AmountRoundingPrecisionFCY);
        "Total Cost (LCY)" := ConvertAmountToLCY("Total Cost", AmountRoundingPrecision);
    end;

    local procedure FindPriceAndDiscount(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
        IsHandled: Boolean;
    begin
        if RetrieveCostPrice(CalledByFieldNo) and ("No." <> '') then begin
            IsHandled := false;
            OnBeforeFindPriceAndDiscount(CalledByFieldNo, IsHandled, Rec, xRec);
            if IsHandled then
                exit;

            ApplyPrice(PriceType::Sale, CalledByFieldNo);
            ApplyPrice(PriceType::Purchase, CalledByFieldNo);
            if Type = Type::Resource then
                "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);

        end;
    end;

    procedure ApplyPrice(PriceType: enum "Price Type"; CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        if PriceType = PriceType::Sale then
            PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
    begin
        LineWithPrice := JobPlanningLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    local procedure HandleCostFactor()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleCostFactor(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if ("Cost Factor" <> 0) and
           ((("Unit Cost" <> xRec."Unit Cost") or ("Cost Factor" <> xRec."Cost Factor")) or
            ((Quantity <> xRec.Quantity) or ("Location Code" <> xRec."Location Code")))
        then
            "Unit Price" := Round("Unit Cost" * "Cost Factor", UnitAmountRoundingPrecisionFCY)
        else
            if (Item."Price/Profit Calculation" = Item."Price/Profit Calculation"::"Price=Cost+Profit") and
               (Item."Profit %" < 100) and
               ("Unit Cost" <> xRec."Unit Cost")
            then
                "Unit Price" := Round("Unit Cost" / (1 - Item."Profit %" / 100), UnitAmountRoundingPrecisionFCY);

        OnAfterHandleCostFactor(Rec, xRec, Item);
    end;

    local procedure UpdateUnitPrice()
    begin
        GetJob;
        RecalculateAmounts(Job."Exch. Calculation (Price)", xRec."Unit Price", "Unit Price", "Unit Price (LCY)");
    end;

    local procedure RecalculateAmounts(JobExchCalculation: Option "Fixed FCY","Fixed LCY"; xAmount: Decimal; var Amount: Decimal; var AmountLCY: Decimal)
    begin
        OnBeforeRecalculateAmounts(Rec, xRec);
        if (xRec."Currency Factor" <> "Currency Factor") and
           (Amount = xAmount) and (JobExchCalculation = JobExchCalculation::"Fixed LCY")
        then
            Amount := ConvertAmountToFCY(AmountLCY, UnitAmountRoundingPrecisionFCY)
        else
            AmountLCY := ConvertAmountToLCY(Amount, UnitAmountRoundingPrecision);
    end;

    local procedure ConvertAmountToFCY(AmountLCY: Decimal; Precision: Decimal) AmountFCY: Decimal;
    begin
        AmountFCY :=
            Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                    "Currency Date", "Currency Code", AmountLCY, "Currency Factor"),
                Precision);
    end;

    local procedure ConvertAmountToLCY(AmountFCY: Decimal; Precision: Decimal): Decimal;
    begin
        exit(ConvertAmountToLCY("Currency Date", AmountFCY, "Currency Factor", Precision));
    end;

    local procedure ConvertAmountToLCY(PostingDate: Date; AmountFCY: Decimal; CurrencyFactor: Decimal; Precision: Decimal) AmountLCY: Decimal;
    begin
        AmountLCY :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PostingDate, "Currency Code", AmountFCY, CurrencyFactor),
                Precision);
    end;

    local procedure UpdateTotalPrice()
    begin
        "Total Price" := Round(Quantity * "Unit Price", AmountRoundingPrecisionFCY);
        "Total Price (LCY)" := ConvertAmountToLCY("Total Price", AmountRoundingPrecision);
        OnAfterUpdateTotalPrice(Rec);
    end;

    local procedure UpdateAmountsAndDiscounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmountsAndDiscounts(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

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

        "Line Amount (LCY)" := ConvertAmountToLCY("Line Amount", AmountRoundingPrecision);
        "Line Discount Amount (LCY)" := ConvertAmountToLCY("Line Discount Amount", AmountRoundingPrecision);
    end;

    procedure Use(PostedQty: Decimal; PostedTotalCost: Decimal; PostedLineAmount: Decimal; PostingDate: Date; CurrencyFactor: Decimal)
    begin
        if "Usage Link" then begin
            InitRoundingPrecisions();
            // Update Quantity Posted
            Validate("Qty. Posted", "Qty. Posted" + PostedQty);

            // Update Posted Costs and Amounts.
            "Posted Total Cost" += Round(PostedTotalCost, AmountRoundingPrecisionFCY);
            "Posted Total Cost (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Posted Total Cost", CurrencyFactor, AmountRoundingPrecision);

            "Posted Line Amount" += Round(PostedLineAmount, AmountRoundingPrecisionFCY);
            "Posted Line Amount (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Posted Line Amount", CurrencyFactor, AmountRoundingPrecision);

            // Update Remaining Quantity
            UpdateRemainingQuantityFromUse(PostedQty);

            // Update Remaining Costs and Amounts
            UpdateRemainingCostsAndAmounts(PostingDate, CurrencyFactor);

            // Update Quantity to Post
            Validate("Qty. to Transfer to Journal", "Remaining Qty.");
        end else
            ClearValues;

        OnUseOnBeforeModify(Rec);
        Modify(true);
    end;

    local procedure UpdateRemainingQuantityFromUse(PostedQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRemainingQuantityFromUse(Rec, xRec, PostedQty, IsHandled);
        if IsHandled then
            exit;

        if (PostedQty >= 0) = ("Remaining Qty." >= 0) then
            if Abs(PostedQty) <= Abs("Remaining Qty.") then
                Validate("Remaining Qty.", "Remaining Qty." - PostedQty)
            else begin
                Validate(Quantity, Quantity + PostedQty - "Remaining Qty.");
                Validate("Remaining Qty.", 0);
            end
        else
            Validate("Remaining Qty.", "Remaining Qty." - PostedQty);
    end;

    local procedure UpdateRemainingCostsAndAmounts(PostingDate: Date; CurrencyFactor: Decimal)
    begin
        if "Usage Link" then begin
            InitRoundingPrecisions();
            "Remaining Total Cost" := Round("Unit Cost" * "Remaining Qty.", AmountRoundingPrecisionFCY);
            "Remaining Total Cost (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Remaining Total Cost", CurrencyFactor, AmountRoundingPrecision);
            "Remaining Line Amount" := CalcLineAmount("Remaining Qty.");
            "Remaining Line Amount (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Remaining Line Amount", CurrencyFactor, AmountRoundingPrecision);
        end else
            ClearValues;
    end;

    local procedure UpdateRemainingQuantity()
    var
        Delta: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRemainingQuantity(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "Usage Link" and (xRec."No." = "No.") then begin
            Delta := Quantity - xRec.Quantity;
            Validate("Remaining Qty.", "Remaining Qty." + Delta);
            Validate("Qty. to Transfer to Journal", "Qty. to Transfer to Journal" + Delta);
        end;
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
            InitRoundingPrecisions();
            "Posted Total Cost" += Round(AdjustJobCost, AmountRoundingPrecisionFCY);
            "Posted Total Cost (LCY)" += Round(AdjustJobCostLCY, AmountRoundingPrecision);
        end;
    end;

    local procedure ValidateModification(FieldChanged: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateModification(Rec, IsHandled);
        if IsHandled then
            exit;

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
        if not JobUsageLink.IsEmpty() then
            Error(LinkedJobLedgerErr);
    end;

    local procedure ControlUsageLink()
    var
        JobUsageLink: Record "Job Usage Link";
        IsHandled: Boolean;
    begin
        GetJob;

        IsHandled := false;
        OnControlUsageLinkOnAfterGetJob(Rec, Job, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

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
        InitRoundingPrecisions();
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

    procedure UpdateReservation(CalledByFieldNo: Integer)
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReservation(Rec, xRec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

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
                        GetJob();
                        Reserve := Job.Reserve
                    end else
                        Reserve := Item.Reserve;
                end else
                    Reserve := Reserve::Never;
        end;
        JobPlanningLineReserve.VerifyChange(Rec, xRec);
        UpdatePlanned();
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
                    ShowReservation();
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
        OrderTrackingForm.RunModal();
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

        OrderPromisingLines.SetSourceType(OrderPromisingLine."Source Type"::Job.AsInteger());
        OrderPromisingLines.SetTableView(OrderPromisingLine);
        OrderPromisingLines.RunModal();
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

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, NewStatus, AvailabilityFilter, Positive);
    end;

    procedure DrillDownJobInvoices()
    var
        JobInvoices: Page "Job Invoices";
    begin
        JobInvoices.SetShowDetails(false);
        JobInvoices.SetPrJobPlanningLine(Rec);
        JobInvoices.Run();
    end;

    local procedure CheckRelatedJobPlanningLineInvoice()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", "Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", "Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", "Line No.");
        if not JobPlanningLineInvoice.IsEmpty() then
            Error(NotPossibleJobPlanningLineErr);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(DATABASE::"Job Planning Line", Status.AsInteger(),
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

    [Scope('OnPrem')]
    procedure UpdatePlannedDueDate() Changed: Boolean;
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DueDateCalculation: DateFormula;
        xPlanningDueDate: Date;
    begin
        xPlanningDueDate := "Planning Due Date";
        if "Planning Date" = 0D then
            exit(false);
        "Planning Due Date" := "Planning Date";
        GetJob();
        if Job."No." = '' then
            exit(false);
        Customer.SetLoadFields("Payment Terms Code");
        if not Customer.Get(Job."Bill-to Customer No.") then
            exit(false);
        PaymentTerms.SetLoadFields("Due Date Calculation");
        if PaymentTerms.Get(Customer."Payment Terms Code") then begin
            PaymentTerms.GetDueDateCalculation(DueDateCalculation);
            "Planning Due Date" := CalcDate(DueDateCalculation, "Planning Date");
        end;
        exit("Planning Due Date" <> xPlanningDueDate);
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

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';

        OnAfterClearTracking(Rec);
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

        OnAfterInitFromJobPlanningLine(ToJobPlanningLine, FromJobPlanningLine);
        Rec := ToJobPlanningLine;
    end;

    protected procedure GetNextJobLineNo(FromJobPlanningLine: Record "Job Planning Line"): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", FromJobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", FromJobPlanningLine."Job Task No.");
        if JobPlanningLine.FindLast() then;
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

    procedure ConvertToJobLineType() JobLineType: Enum "Job Line Type"
    begin
        JobLineType := "Job Line Type".FromInteger("Line Type".AsInteger() + 1);

        OnAfterConvertToJobLineType(Rec, JobLineType);
    end;

    procedure ConvertFromJobLineType(JobLineType: Enum "Job Line Type") JobPlanningLineLineType: Enum "Job Planning Line Line Type"
    begin
        JobPlanningLineLineType := "Job Planning Line Line Type".FromInteger(JobLineType.AsInteger() - 1);

        OnAfterConvertFromJobLineType(Rec, JobLineType, JobPlanningLineLineType);
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

    local procedure SetDefaultBin()
    begin
        if (Rec."No." <> '') then begin
            GetItem();
            if Item.IsInventoriableType() then
                Validate("Bin Code", FindBin());
        end;
    end;

    local procedure FindBin() NewBinCode: Code[20]
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        if (Rec."No." <> '') and (Rec."Location Code" <> '') then begin
            GetLocation(Rec."Location Code");
            if Location."To-Job Bin Code" <> '' then
                NewBinCode := Location."To-Job Bin Code"
            else
                if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                    WMSManagement.GetDefaultBin(Rec."No.", Rec."Variant Code", Rec."Location Code", NewBinCode);
        end;
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure DeleteWarehouseRequest(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine2: Record "Job Planning Line";
        WarehouseRequest: Record "Warehouse Request";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        JobPlanningLine2.SetFilter("Job Contract Entry No.", '<>%1', JobPlanningLine."Job Contract Entry No.");
        JobPlanningLine2.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine2.SetRange("Location Code", JobPlanningLine."Location Code");

        if JobPlanningLine2.IsEmpty() then
            if WarehouseRequest.Get("Warehouse Request Type"::Outbound, JobPlanningLine."Location Code", Database::Job, 0, JobPlanningLine."Job No.") then
                WarehouseRequest.Delete(true)
            else
                if WhsePickRequest.Get(WhsePickRequest."Document Type"::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Location Code") then
                    WhsePickRequest.Delete(true);
    end;

    internal procedure CreateWarehouseRequest()
    var
        WhsePickRequest: Record "Whse. Pick Request";
        WarehouseRequest: Record "Warehouse Request";
    begin
        if Rec."Location Code" = '' then
            exit;

        GetLocation(Rec."Location Code");

        if Location."Require Pick" then
            if Location."Require Shipment" then begin
                if not WhsePickRequest.Get(WhsePickRequest."Document Type"::Job, 0, Rec."Job No.", Rec."Location Code") then begin
                    WhsePickRequest.Init();
                    WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Job;
                    WhsePickRequest."Document Subtype" := 0;
                    WhsePickRequest."Document No." := Rec."Job No.";
                    WhsePickRequest.Status := WhsePickRequest.Status::Released;
                    WhsePickRequest."Location Code" := Location.Code;
                    if WhsePickRequest.Insert() then;
                end
            end
            else
                if not GetWarehouseRequest(WarehouseRequest) then begin
                    WarehouseRequest.Init();
                    WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
                    WarehouseRequest."Location Code" := Rec."Location Code";
                    WarehouseRequest."Source Type" := Database::Job;
                    WarehouseRequest."Source No." := Rec."Job No.";
                    WarehouseRequest."Source Subtype" := 0;
                    WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Job Usage";
                    WarehouseRequest."Document Status" := WarehouseRequest."Document Status"::Released;
                    if WarehouseRequest.Insert() then;
                end;
    end;

    local procedure GetWarehouseRequest(var WarehouseRequest: Record "Warehouse Request"): Boolean
    begin
        if WarehouseRequest.Get(WarehouseRequest.Type::Outbound, Rec."Location Code", Database::Job, 0, Rec."Job No.") then
            if (WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Job Usage") and (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released) then
                exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGLAccount(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobJnlLine(var JobPlanningLine: Record "Job Planning Line"; JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertToJobLineType(var JobPlanningLine: Record "Job Planning Line"; var JobLineType: Enum "Job Line Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertFromJobLineType(var JobPlanningLine: Record "Job Planning Line"; var JobLineType: Enum "Job Line Type"; var JobPlanningLineLineType: Enum "Job Planning Line Line Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var JobPlanningLine: Record "Job Planning Line")
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
    local procedure OnAfterGetSKU(JobPlanningLine: Record "Job Planning Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRemainingQty(JobPlanningLine: Record "Job Planning Line"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var JobPlanningLine: Record "Job Planning Line"; var Item: Record Item);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFilterLinesForReservation(var JobPlaningLine: Record "Job Planning Line"; ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleCostFactor(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobPlanningLine(var ToJobPlanningLine: Record "Job Planning Line"; FromJobPlanningLine: Record "Job Planning Line")
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '17.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterResourceFindCost(var JobPlanningLine: Record "Job Planning Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; JobPlanningLine: Record "Job Planning Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var JobPlanningLine: Record "Job Planning Line"; LastJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAllAmounts(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line")
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
    local procedure OnBeforeCalcQuantityBase(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQuantityPosted(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromResource(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnsureDirectedPutawayandPickFalse(var JobPlanningLine: Record "Job Planning Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindPriceAndDiscount(CalledByFieldNo: Integer; var IsHandled: Boolean; var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleCostFactor(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateAmounts(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmountsAndDiscounts(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateModification(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWorkTypeCode(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPrice(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var ShouldRetrieveCostPrice: Boolean; var IsHandled: Boolean; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRemainingQuantity(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRemainingQuantityFromUse(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; PostedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllAmounts(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReservation(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToTransferToInvoice(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnControlUsageLinkOnAfterGetJob(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; CallingFieldNo: Integer; var IsHandling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCurrencyFactorOnBeforeGetExchangeRate(JobPlanningLine: Record "Job Planning Line"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUseOnBeforeModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterCopyFromAccount(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var Job: Record Job)
    begin
    end;
}


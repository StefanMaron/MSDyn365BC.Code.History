table 210 "Job Journal Line"
{
    Caption = 'Job Journal Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Job Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Job No." = '' then begin
                    Validate("Currency Code", '');
                    Validate("Job Task No.", '');
                    CreateDim(
                      DATABASE::Job, "Job No.",
                      DimMgt.TypeToTableID2(Type), "No.",
                      DATABASE::"Resource Group", "Resource Group No.");
                    exit;
                end;

                GetJob;
                Job.TestBlocked;
                IsHandled := false;
                OnValidateJobNoOnBeforeCheckJob(Rec, xRec, Cust, IsHandled);
                if not IsHandled then begin
                    Job.TestField("Bill-to Customer No.");
                    Cust.Get(Job."Bill-to Customer No.");
                    Validate("Job Task No.", '');
                end;
                "Customer Price Group" := Job."Customer Price Group";
                Validate("Currency Code", Job."Currency Code");
                CreateDim(
                  DATABASE::Job, "Job No.",
                  DimMgt.TypeToTableID2(Type), "No.",
                  DATABASE::"Resource Group", "Resource Group No.");
                Validate("Country/Region Code", Job."Bill-to Country/Region Code");
                "Price Calculation Method" := Job.GetPriceCalculationMethod();
                "Cost Calculation Method" := Job.GetCostCalculationMethod();
            end;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if not IsTemporary() then
                    TestField("Posting Date");
                Validate("Document Date", "Posting Date");
                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor();
                    UpdateAllAmounts();
                end
            end;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Resource,Item,G/L Account';
            OptionMembers = Resource,Item,"G/L Account";

            trigger OnValidate()
            begin
                Validate("No.", '');
                if Type = Type::Item then begin
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick", false);
                end;
            end;
        }
        field(8; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST(Item)) Item WHERE(Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account";

            trigger OnValidate()
            begin
                if ("No." = '') or ("No." <> xRec."No.") then begin
                    Description := '';
                    "Unit of Measure Code" := '';
                    "Qty. per Unit of Measure" := 1;
                    "Variant Code" := '';
                    "Work Type Code" := '';
                    DeleteAmounts;
                    "Cost Factor" := 0;
                    "Applies-to Entry" := 0;
                    "Applies-from Entry" := 0;
                    CheckedAvailability := false;
                    "Job Planning Line No." := 0;
                    if "No." = '' then begin
                        UpdateDimensions;
                        exit;
                    end
                end;

                case Type of
                    Type::Resource:
                        CopyFromResource;
                    Type::Item:
                        CopyFromItem;
                    Type::"G/L Account":
                        CopyFromGLAccount;
                end;

                Validate(Quantity);
                UpdateDimensions;
            end;
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Quantity (Base)" :=
                  UOMMgt.CalcBaseQty(
                    "No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
                UpdateAllAmounts;

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");

                CheckItemAvailable;
                if Item."Item Tracking Code" <> '' then
                    ReserveJobJnlLine.VerifyQuantity(Rec, xRec);
            end;
        }
        field(12; "Direct Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost (LCY)';
            MinValue = 0;
        }
        field(13; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if (Type = Type::Item) and
                   Item.Get("No.") and
                   (Item."Costing Method" = Item."Costing Method"::Standard)
                then
                    UpdateAllAmounts
                else begin
                    InitRoundingPrecisions;
                    "Unit Cost" := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          "Posting Date", "Currency Code",
                          "Unit Cost (LCY)", "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                    UpdateAllAmounts;
                end;
            end;
        }
        field(14; "Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost (LCY)';
            Editable = false;
        }
        field(15; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                InitRoundingPrecisions;
                "Unit Price" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Posting Date", "Currency Code",
                      "Unit Price (LCY)", "Currency Factor"),
                    UnitAmountRoundingPrecisionFCY);
                UpdateAllAmounts;
            end;
        }
        field(16; "Total Price (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price (LCY)';
            Editable = false;
        }
        field(17; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            Editable = false;
            TableRelation = "Resource Group";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Resource Group", "Resource Group No.",
                  DATABASE::Job, "Job No.",
                  DimMgt.TypeToTableID2(Type), "No.");
            end;
        }
        field(18; "Unit of Measure Code"; Code[10])
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
                GetGLSetup;
                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                            OnAfterAssignItemUoM(Rec, Item);
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
                            ResUnitofMeasure.Get("No.", "Unit of Measure Code");
                            "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";
                            "Quantity (Base)" := Quantity * "Qty. per Unit of Measure";
                            OnAfterAssignResourceUoM(Rec, Res);
                        end;
                    Type::"G/L Account":
                        begin
                            "Qty. per Unit of Measure" := 1;
                            OnAfterAssignGLAccountUoM(Rec);
                        end;
                end;
                Validate(Quantity);
            end;
        }
        field(21; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                "Bin Code" := '';
                if "Location Code" <> '' then
                    if IsNonInventoriableItem then
                        Item.TestField(Type, Item.Type::Inventory);
                GetLocation("Location Code");
                Location.TestField("Directed Put-away and Pick", false);
                Validate(Quantity);
            end;
        }
        field(22; Chargeable; Boolean)
        {
            Caption = 'Chargeable';
            InitValue = true;

            trigger OnValidate()
            begin
                if Chargeable <> xRec.Chargeable then
                    if not Chargeable then
                        Validate("Unit Price", 0)
                    else
                        Validate("No.");
            end;
        }
        field(30; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Type = CONST(Item)) "Inventory Posting Group";
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(32; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(33; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                IsHandled: Boolean;
                IsLineDiscountHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWorkTypeCode(Rec, xRec, IsLineDiscountHandled, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type, Type::Resource);
                if not IsLineDiscountHandled then
                    Validate("Line Discount %", 0);
                if ("Work Type Code" = '') and (xRec."Work Type Code" <> '') then begin
                    Res.Get("No.");
                    "Unit of Measure Code" := Res."Base Unit of Measure";
                    Validate("Unit of Measure Code");
                end;
                if WorkType.Get("Work Type Code") then
                    if WorkType."Unit of Measure Code" <> '' then begin
                        "Unit of Measure Code" := WorkType."Unit of Measure Code";
                        if ResUnitofMeasure.Get("No.", "Unit of Measure Code") then
                            "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";
                    end else begin
                        Res.Get("No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure";
                        Validate("Unit of Measure Code");
                    end;
                OnBeforeValidateWorkTypeCodeQty(Rec, xRec, Res, WorkType);
                Validate(Quantity);
            end;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if (Type = Type::Item) and ("No." <> '') then
                    UpdateAllAmounts;
            end;
        }
        field(37; "Applies-to Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Applies-to Entry';

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-to Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                InitRoundingPrecisions;
                TestField(Type, Type::Item);
                if "Applies-to Entry" <> 0 then begin
                    ItemLedgEntry.Get("Applies-to Entry");
                    TestField(Quantity);
                    if Quantity < 0 then
                        FieldError(Quantity, Text002);
                    ItemLedgEntry.TestField(Open, true);
                    ItemLedgEntry.TestField(Positive, true);
                    "Location Code" := ItemLedgEntry."Location Code";
                    "Variant Code" := ItemLedgEntry."Variant Code";
                    GetItem;
                    if Item."Costing Method" <> Item."Costing Method"::Standard then begin
                        "Unit Cost" := Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              "Posting Date", "Currency Code",
                              CalcUnitCost(ItemLedgEntry), "Currency Factor"),
                            UnitAmountRoundingPrecisionFCY);
                        UpdateAllAmounts;
                    end;
                end;
            end;
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(61; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            Editable = false;
            OptionCaption = 'Usage,Sale';
            OptionMembers = Usage,Sale;
        }
        field(62; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(73; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Job Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(74; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(75; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(76; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(77; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(79; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(80; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(81; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(82; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(83; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(86; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(87; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(88; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(89; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(90; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(91; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                TestField(Type, Type::Item);
                SelectItemEntry(FieldNo("Serial No."));
            end;
        }
        field(92; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(93; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(94; "Source Currency Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Total Cost';
            Editable = false;
        }
        field(95; "Source Currency Total Price"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Total Price';
            Editable = false;
        }
        field(96; "Source Currency Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Line Amount';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(950; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(951; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            TableRelation = "Time Sheet Line"."Line No." WHERE("Time Sheet No." = FIELD("Time Sheet No."));
        }
        field(952; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            TableRelation = "Time Sheet Detail".Date WHERE("Time Sheet No." = FIELD("Time Sheet No."),
                                                            "Time Sheet Line No." = FIELD("Time Sheet Line No."));
        }
        field(1000; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
            begin
                if ("Job Task No." = '') or (("Job Task No." <> xRec."Job Task No.") and (xRec."Job Task No." <> '')) then begin
                    Validate("No.", '');
                    exit;
                end;

                TestField("Job No.");
                JobTask.Get("Job No.", "Job Task No.");
                JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
                UpdateDimensions;
            end;
        }
        field(1001; "Total Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Cost';
            Editable = false;
        }
        field(1002; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateAllAmounts;
            end;
        }
        field(1003; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = ' ,Budget,Billable,Both Budget and Billable';
            OptionMembers = " ",Budget,Billable,"Both Budget and Billable";

            trigger OnValidate()
            begin
                if "Job Planning Line No." <> 0 then
                    Error(Text006, FieldCaption("Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(1004; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-from Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                InitRoundingPrecisions;
                TestField(Type, Type::Item);
                if "Applies-from Entry" <> 0 then begin
                    TestField(Quantity);
                    if Quantity > 0 then
                        FieldError(Quantity, Text003);
                    ItemLedgEntry.Get("Applies-from Entry");
                    ItemLedgEntry.TestField(Positive, false);
                    if Item."Costing Method" <> Item."Costing Method"::Standard then begin
                        "Unit Cost" := Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              "Posting Date", "Currency Code",
                              CalcUnitCostFrom(ItemLedgEntry), "Currency Factor"),
                            UnitAmountRoundingPrecisionFCY);
                        UpdateAllAmounts;
                    end;
                end;
            end;
        }
        field(1005; "Job Posting Only"; Boolean)
        {
            Caption = 'Job Posting Only';
        }
        field(1006; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
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
                UpdateAllAmounts;
            end;
        }
        field(1008; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                UpdateCurrencyFactor;
            end;
        }
        field(1009; "Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';

            trigger OnValidate()
            begin
                UpdateAllAmounts;
            end;
        }
        field(1010; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text001, FieldCaption("Currency Code")));
                UpdateAllAmounts;
            end;
        }
        field(1011; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                UpdateAllAmounts;
            end;
        }
        field(1012; "Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                InitRoundingPrecisions;
                "Line Amount" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Posting Date", "Currency Code",
                      "Line Amount (LCY)", "Currency Factor"),
                    AmountRoundingPrecisionFCY);
                UpdateAllAmounts;
            end;
        }
        field(1013; "Line Discount Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Discount Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                InitRoundingPrecisions;
                "Line Discount Amount" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      "Posting Date", "Currency Code",
                      "Line Discount Amount (LCY)", "Currency Factor"),
                    AmountRoundingPrecisionFCY);
                UpdateAllAmounts;
            end;
        }
        field(1014; "Total Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Price';
            Editable = false;
        }
        field(1015; "Cost Factor"; Decimal)
        {
            Caption = 'Cost Factor';
            Editable = false;
        }
        field(1016; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(1017; "Ledger Entry Type"; Option)
        {
            Caption = 'Ledger Entry Type';
            OptionCaption = ' ,Resource,Item,G/L Account';
            OptionMembers = " ",Resource,Item,"G/L Account";
        }
        field(1018; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = IF ("Ledger Entry Type" = CONST(Resource)) "Res. Ledger Entry"
            ELSE
            IF ("Ledger Entry Type" = CONST(Item)) "Item Ledger Entry"
            ELSE
            IF ("Ledger Entry Type" = CONST("G/L Account")) "G/L Entry";
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Job Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
                Resource: Record Resource;
                "Filter": Text;
            begin
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                JobPlanningLine.SetRange(Type, Type);
                JobPlanningLine.SetRange("No.", "No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);
                if Type = Type::Resource then begin
                    Filter := Resource.GetUnitOfMeasureFilter("No.", "Unit of Measure Code");
                    JobPlanningLine.SetFilter("Unit of Measure Code", Filter);
                end;

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if "Job Planning Line No." <> 0 then begin
                    ValidateJobPlanningLineLink;
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");

                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    JobPlanningLine.TestField(Type, Type);
                    JobPlanningLine.TestField("No.", "No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);

                    "Line Type" := JobPlanningLine."Line Type" + 1;
                    Validate("Remaining Qty.", CalcQtyFromBaseQty(JobPlanningLine."Remaining Qty. (Base)" - "Quantity (Base)"));
                end else
                    Validate("Remaining Qty.", 0);
            end;
        }
        field(1030; "Remaining Qty."; Decimal)
        {
            Caption = 'Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text004, FieldCaption("Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Remaining Qty." < 0 then
                            "Remaining Qty." := 0;
                    end else begin
                        if "Remaining Qty." > 0 then
                            "Remaining Qty." := 0;
                    end;
                end;
                "Remaining Qty. (Base)" :=
                  UOMMgt.CalcBaseQty(
                    "No.", "Variant Code", "Unit of Measure Code", "Remaining Qty.", "Qty. per Unit of Measure");

                CheckItemAvailable;
            end;
        }
        field(1031; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';

            trigger OnValidate()
            begin
                Validate("Remaining Qty.", CalcQtyFromBaseQty("Remaining Qty. (Base)"));
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            begin
                if "Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        Item.Get("No.");
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                        GetItemTranslation;
                    end;
                    exit;
                end;

                TestField(Type, Type::Item);

                ItemVariant.Get("No.", "Variant Code");
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";

                Validate(Quantity);
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Code';

            trigger OnLookup()
            var
                BinCode: Code[20];
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);
                BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code");
                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            begin
                TestField("Location Code");
                if "Bin Code" <> '' then begin
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                end;
                TestField(Type, Type::Item);
                CheckItemAvailable;
                WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
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
                Validate(Quantity, CalcQtyFromBaseQty("Quantity (Base)"));
            end;
        }
        field(5468; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Item = R;
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Journal Template Name"),
                                                                           "Source Ref. No." = FIELD("Line No."),
                                                                           "Source Type" = CONST(1011),
                                                                           "Source Subtype" = FIELD("Entry Type"),
                                                                           "Source Batch Name" = FIELD("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = CONST(0),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5900; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
        }
        field(5901; "Posted Service Shipment No."; Code[20])
        {
            Caption = 'Posted Service Shipment No.';
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
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
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", Type, "No.", "Unit of Measure Code", "Work Type Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; Type, "No.", "Variant Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Type = Type::Item then
            ReserveJobJnlLine.DeleteLine(Rec);
    end;

    trigger OnInsert()
    begin
        LockTable();
        JobJnlTemplate.Get("Journal Template Name");
        JobJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        if (Type = Type::Item) and (xRec.Type = Type::Item) then
            ReserveJobJnlLine.VerifyChange(Rec, xRec)
        else
            if (Type <> Type::Item) and (xRec.Type = Type::Item) then
                ReserveJobJnlLine.DeleteLine(xRec);
    end;

    trigger OnRename()
    begin
        ReserveJobJnlLine.RenameLine(Rec, xRec);
    end;

    var
        Text000: Label 'You cannot change %1 when %2 is %3.';
        Location: Record Location;
        Item: Record Item;
        Res: Record Resource;
        Cust: Record Customer;
        ItemJnlLine: Record "Item Journal Line";
        GLAcc: Record "G/L Account";
        Job: Record Job;
        WorkType: Record "Work Type";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlLine: Record "Job Journal Line";
        ItemVariant: Record "Item Variant";
        ResUnitofMeasure: Record "Resource Unit of Measure";
        ItemTranslation: Record "Item Translation";
        CurrExchRate: Record "Currency Exchange Rate";
        SKU: Record "Stockkeeping Unit";
        GLSetup: Record "General Ledger Setup";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        ReserveJobJnlLine: Codeunit "Job Jnl. Line-Reserve";
        WMSManagement: Codeunit "WMS Management";
        DontCheckStandardCost: Boolean;
        Text001: Label 'cannot be specified without %1';
        Text002: Label 'must be positive';
        Text003: Label 'must be negative';
        HasGotGLSetup: Boolean;
        CurrencyDate: Date;
        UnitAmountRoundingPrecision: Decimal;
        AmountRoundingPrecision: Decimal;
        UnitAmountRoundingPrecisionFCY: Decimal;
        AmountRoundingPrecisionFCY: Decimal;
        CheckedAvailability: Boolean;
        Text004: Label '%1 is only editable when a %2 is defined.';
        Text006: Label '%1 cannot be changed when %2 is set.';
        Text007: Label '%1 %2 is already linked to %3 %4. Hence %5 cannot be calculated correctly. Posting the line may update the linked %3 unexpectedly. Do you want to continue?', Comment = 'Job Journal Line job DEFAULT 30000 is already linked to Job Planning Line  DEERFIELD, 8 WP 1120 10000. Hence Remaining Qty. cannot be calculated correctly. Posting the line may update the linked %3 unexpectedly. Do you want to continue?';

    local procedure CalcQtyFromBaseQty(BaseQty: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(Round(BaseQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    local procedure CopyFromResource()
    var
        Resource: Record Resource;
    begin
        Resource.Get("No.");
        Resource.CheckResourcePrivacyBlocked(false);
        Resource.TestField(Blocked, false);
        Description := Resource.Name;
        "Description 2" := Resource."Name 2";
        "Resource Group No." := Resource."Resource Group No.";
        "Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
        Validate("Unit of Measure Code", Resource."Base Unit of Measure");
        if "Time Sheet No." = '' then
            Resource.TestField("Use Time Sheet", false);

        OnAfterAssignResourceValues(Rec, Resource);
    end;

    local procedure CopyFromItem()
    begin
        GetItem;
        Item.TestField(Blocked, false);
        Description := Item.Description;
        "Description 2" := Item."Description 2";
        GetJob;
        if Job."Language Code" <> '' then
            GetItemTranslation;
        "Posting Group" := Item."Inventory Posting Group";
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        Validate("Unit of Measure Code", Item."Base Unit of Measure");

        OnAfterAssignItemValues(Rec, Item);
    end;

    local procedure CopyFromGLAccount()
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc;
        GLAcc.TestField("Direct Posting", true);
        Description := GLAcc.Name;
        "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "Unit of Measure Code" := '';
        "Direct Unit Cost (LCY)" := 0;
        "Unit Cost (LCY)" := 0;
        "Unit Price" := 0;

        OnAfterAssignGLAccountValues(Rec, GLAcc);
    end;

    local procedure CheckItemAvailable()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        OnBeforeCheckItemAvailable(Rec, ItemJnlLine);

        if (CurrFieldNo <> 0) and (Type = Type::Item) and (Quantity > 0) and not CheckedAvailability then begin
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            if "Job Planning Line No." = 0 then
                ItemJnlLine.Quantity := Quantity
            else begin
                JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                if JobPlanningLine."Remaining Qty." < (Quantity + "Remaining Qty.") then
                    ItemJnlLine.Quantity := (Quantity + "Remaining Qty.") - JobPlanningLine."Remaining Qty."
                else
                    exit;
            end;
            if ItemCheckAvail.ItemJnlCheckLine(ItemJnlLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError;
            CheckedAvailability := true;
        end;
    end;

    procedure EmptyLine(): Boolean
    var
        LineIsEmpty: Boolean;
    begin
        LineIsEmpty := ("Job No." = '') and ("No." = '') and (Quantity = 0);
        OnBeforeEmptyLine(Rec, LineIsEmpty);
        exit(LineIsEmpty);
    end;

    procedure SetUpNewLine(LastJobJnlLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUpNewLine(Rec, xRec, LastJobJnlLine, IsHandled);
        if IsHandled then
            exit;

        JobJnlTemplate.Get("Journal Template Name");
        JobJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        JobJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if JobJnlLine.FindFirst then begin
            "Posting Date" := LastJobJnlLine."Posting Date";
            "Document Date" := LastJobJnlLine."Posting Date";
            "Document No." := LastJobJnlLine."Document No.";
            Type := LastJobJnlLine.Type;
            Validate("Line Type", LastJobJnlLine."Line Type");
        end else begin
            "Posting Date" := WorkDate;
            "Document Date" := WorkDate;
            if JobJnlBatch."No. Series" <> '' then begin
                Clear(NoSeriesMgt);
                "Document No." := NoSeriesMgt.TryGetNextNo(JobJnlBatch."No. Series", "Posting Date");
            end;
        end;
        "Recurring Method" := LastJobJnlLine."Recurring Method";
        "Entry Type" := "Entry Type"::Usage;
        "Source Code" := JobJnlTemplate."Source Code";
        "Reason Code" := JobJnlBatch."Reason Code";
        "Posting No. Series" := JobJnlBatch."Posting No. Series";
        "Price Calculation Method" := Job.GetPriceCalculationMethod();
        "Cost Calculation Method" := Job.GetCostCalculationMethod();

        OnAfterSetUpNewLine(Rec, LastJobJnlLine, JobJnlTemplate, JobJnlBatch);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
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
        TestField("Job No.");
        if "Job No." <> Job."No." then
            Job.Get("Job No.");
    end;

    local procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            if "Posting Date" = 0D then
                CurrencyDate := WorkDate
            else
                CurrencyDate := "Posting Date";
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;
    end;

    local procedure GetItem()
    begin
        TestField("No.");
        if "No." <> Item."No." then
            Item.Get("No.");
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

    procedure IsInbound(): Boolean
    begin
        if "Entry Type" in ["Entry Type"::Usage, "Entry Type"::Sale] then
            exit("Quantity (Base)" < 0);

        exit(false);
    end;

    procedure OpenItemTrackingLines(IsReclass: Boolean)
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        ReserveJobJnlLine.CallItemTracking(Rec, IsReclass);
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

    procedure DontCheckStdCost()
    begin
        DontCheckStandardCost := true;
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        UnitCost :=
          (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / ItemLedgEntry.Quantity;

        exit(Abs(UnitCost * "Qty. per Unit of Measure"));
    end;

    local procedure CalcUnitCostFrom(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        exit(
          (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)") /
          ItemLedgEntry.Quantity * "Qty. per Unit of Measure");
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        JobJnlLine2: Record "Job Journal Line";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code");
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Correction, false);

        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");

        if CurrentFieldNo = FieldNo("Applies-to Entry") then begin
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetRange(Open, true);
        end else
            ItemLedgEntry.SetRange(Positive, false);

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            JobJnlLine2 := Rec;
            if CurrentFieldNo = FieldNo("Applies-to Entry") then
                JobJnlLine2.Validate("Applies-to Entry", ItemLedgEntry."Entry No.")
            else
                JobJnlLine2.Validate("Applies-from Entry", ItemLedgEntry."Entry No.");
            Rec := JobJnlLine2;
        end;
    end;

    procedure DeleteAmounts()
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

        OnAfterDeleteAmounts(Rec);
    end;

    procedure SetCurrencyFactor(Factor: Decimal)
    begin
        "Currency Factor" := Factor;
    end;

    procedure GetItemTranslation()
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

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Job Journal Line", "Entry Type", "Journal Template Name", "Line No.", "Journal Batch Name", 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Posting Date";
        ReservEntry."Shipment Date" := "Posting Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Job Journal Line", "Entry Type", "Journal Template Name", "Line No.", false);
        ReservEntry.SetSourceFilter("Journal Batch Name", 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        ReservEntry.ClearTrackingFilter;
        exit(not ReservEntry.IsEmpty);
    end;

    procedure UpdateAllAmounts()
    begin
        OnBeforeUpdateAllAmounts(Rec, xRec);
        InitRoundingPrecisions;

        UpdateUnitCost;
        UpdateTotalCost;
        FindPriceAndDiscount(Rec, CurrFieldNo);
        HandleCostFactor;
        UpdateUnitPrice;
        UpdateTotalPrice;
        UpdateAmountsAndDiscounts;

        OnAfterUpdateAllAmounts(Rec, xRec);
    end;

    procedure UpdateUnitCost()
    var
        ResCost: Record "Resource Cost";
        RetrievedCost: Decimal;
    begin
        if (Type = Type::Item) and Item.Get("No.") then begin
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                if not DontCheckStandardCost then begin
                    // Prevent manual change of unit cost on items with standard cost
                    if (("Unit Cost" <> xRec."Unit Cost") or ("Unit Cost (LCY)" <> xRec."Unit Cost (LCY)")) and
                       (("No." = xRec."No.") and ("Location Code" = xRec."Location Code") and
                        ("Variant Code" = xRec."Variant Code") and ("Unit of Measure Code" = xRec."Unit of Measure Code"))
                    then
                        Error(
                          Text000,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                end;
                if RetrieveCostPrice then begin
                    if GetSKU then
                        "Unit Cost (LCY)" := Round(SKU."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision)
                    else
                        "Unit Cost (LCY)" := Round(Item."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision);
                    "Unit Cost" := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          "Posting Date", "Currency Code",
                          "Unit Cost (LCY)", "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                end else begin
                    if "Unit Cost" <> xRec."Unit Cost" then
                        "Unit Cost (LCY)" := Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              "Posting Date", "Currency Code",
                              "Unit Cost", "Currency Factor"),
                            UnitAmountRoundingPrecision)
                    else
                        "Unit Cost" := Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              "Posting Date", "Currency Code",
                              "Unit Cost (LCY)", "Currency Factor"),
                            UnitAmountRoundingPrecisionFCY);
                end;
            end else begin
                if RetrieveCostPrice then begin
                    if GetSKU then
                        RetrievedCost := SKU."Unit Cost" * "Qty. per Unit of Measure"
                    else
                        RetrievedCost := Item."Unit Cost" * "Qty. per Unit of Measure";
                    "Unit Cost" := Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          "Posting Date", "Currency Code",
                          RetrievedCost, "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                    "Unit Cost (LCY)" := Round(RetrievedCost, UnitAmountRoundingPrecision);
                end else
                    "Unit Cost (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          "Unit Cost", "Currency Factor"),
                        UnitAmountRoundingPrecision);
            end;
        end else
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
                          "Posting Date", "Currency Code",
                          RetrievedCost, "Currency Factor"),
                        UnitAmountRoundingPrecisionFCY);
                    "Unit Cost (LCY)" := Round(RetrievedCost, UnitAmountRoundingPrecision);
                end else
                    "Unit Cost (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          "Unit Cost", "Currency Factor"),
                        UnitAmountRoundingPrecision);
            end else
                "Unit Cost (LCY)" := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      "Posting Date", "Currency Code",
                      "Unit Cost", "Currency Factor"),
                    UnitAmountRoundingPrecision);

        OnAfterUpdateUnitCost(Rec, UnitAmountRoundingPrecision, CurrFieldNo);
    end;

    local procedure RetrieveCostPrice(): Boolean
    var
        ShouldRetrieveCostPrice: Boolean;
    begin
        OnBeforeRetrieveCostPrice(Rec, xRec, ShouldRetrieveCostPrice);
        if ShouldRetrieveCostPrice then
            exit(true);

        case Type of
            Type::Item:
                if ("No." <> xRec."No.") or
                   ("Location Code" <> xRec."Location Code") or
                   ("Variant Code" <> xRec."Variant Code") or
                   (Quantity <> xRec.Quantity) or
                   ("Unit of Measure Code" <> xRec."Unit of Measure Code") and
                   (("Applies-to Entry" = 0) and ("Applies-from Entry" = 0))
                then
                    exit(true);
            Type::Resource:
                if ("No." <> xRec."No.") or
                   ("Work Type Code" <> xRec."Work Type Code") or
                   ("Unit of Measure Code" <> xRec."Unit of Measure Code")
                then
                    exit(true);
            Type::"G/L Account":
                if "No." <> xRec."No." then
                    exit(true);
            else
                exit(false);
        end;
        exit(false);
    end;

    procedure UpdateTotalCost()
    begin
        "Total Cost" := Round("Unit Cost" * Quantity, AmountRoundingPrecisionFCY);
        "Total Cost (LCY)" := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Posting Date", "Currency Code", "Total Cost", "Currency Factor"), AmountRoundingPrecision);

        OnAfterUpdateTotalCost(Rec);
    end;

    local procedure FindPriceAndDiscount(var JobJnlLine: Record "Job Journal Line"; CalledByFieldNo: Integer)
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
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        JobJournalLinePrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(JobJournalLinePrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        if PriceType = PriceType::Sale then
            PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    local procedure HandleCostFactor()
    begin
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
    end;

    local procedure UpdateUnitPrice()
    begin
        "Unit Price (LCY)" := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Posting Date", "Currency Code",
              "Unit Price", "Currency Factor"),
            UnitAmountRoundingPrecision);
    end;

    local procedure UpdateTotalPrice()
    begin
        "Total Price" := Round(Quantity * "Unit Price", AmountRoundingPrecisionFCY);
        "Total Price (LCY)" := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Posting Date", "Currency Code", "Total Price", "Currency Factor"), AmountRoundingPrecision);

        OnAfterUpdateTotalPrice(Rec);
    end;

    local procedure UpdateAmountsAndDiscounts()
    begin
        if "Total Price" <> 0 then begin
            if ("Line Amount" <> xRec."Line Amount") and ("Line Discount Amount" = xRec."Line Discount Amount") then begin
                "Line Amount" := Round("Line Amount", AmountRoundingPrecisionFCY);
                "Line Discount Amount" := "Total Price" - "Line Amount";
                "Line Amount (LCY)" := Round("Line Amount (LCY)", AmountRoundingPrecision);
                "Line Discount Amount (LCY)" := "Total Price (LCY)" - "Line Amount (LCY)";
                "Line Discount %" := Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
            end else
                if ("Line Discount Amount" <> xRec."Line Discount Amount") and ("Line Amount" = xRec."Line Amount") then begin
                    "Line Discount Amount" := Round("Line Discount Amount", AmountRoundingPrecisionFCY);
                    "Line Amount" := "Total Price" - "Line Discount Amount";
                    "Line Discount Amount (LCY)" := Round("Line Discount Amount (LCY)", AmountRoundingPrecision);
                    "Line Amount (LCY)" := "Total Price (LCY)" - "Line Discount Amount (LCY)";
                    "Line Discount %" := Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
                end else
                    if ("Line Discount Amount" <> xRec."Line Discount Amount") or ("Line Amount" <> xRec."Line Amount") or
                       ("Total Price" <> xRec."Total Price") or ("Line Discount %" <> xRec."Line Discount %")
                    then begin
                        "Line Discount Amount" := Round("Total Price" * "Line Discount %" / 100, AmountRoundingPrecisionFCY);
                        "Line Amount" := "Total Price" - "Line Discount Amount";
                        "Line Discount Amount (LCY)" := Round("Total Price (LCY)" * "Line Discount %" / 100, AmountRoundingPrecision);
                        "Line Amount (LCY)" := "Total Price (LCY)" - "Line Discount Amount (LCY)";
                    end;
        end else begin
            "Line Amount" := 0;
            "Line Discount Amount" := 0;
            "Line Amount (LCY)" := 0;
            "Line Discount Amount (LCY)" := 0;
        end;

        OnAfterUpdateAmountsAndDiscounts(Rec);
    end;

    local procedure ValidateJobPlanningLineLink()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Job No.", "Job No.");
        JobJournalLine.SetRange("Job Task No.", "Job Task No.");
        JobJournalLine.SetRange("Job Planning Line No.", "Job Planning Line No.");

        if JobJournalLine.FindFirst then
            if ("Journal Template Name" <> JobJournalLine."Journal Template Name") or
               ("Journal Batch Name" <> JobJournalLine."Journal Batch Name") or
               ("Line No." <> JobJournalLine."Line No.")
            then begin
                JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                if not Confirm(Text007, false,
                     TableCaption,
                     StrSubstNo('%1, %2, %3', "Journal Template Name", "Journal Batch Name", "Line No."),
                     JobPlanningLine.TableCaption,
                     StrSubstNo('%1, %2, %3', JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."),
                     FieldCaption("Remaining Qty."))
                then
                    Error('');
            end;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure UpdateDimensions()
    var
        DimensionSetIDArr: array[10] of Integer;
    begin
        CreateDim(
          DimMgt.TypeToTableID2(Type), "No.",
          DATABASE::Job, "Job No.",
          DATABASE::"Resource Group", "Resource Group No.");
        if "Job Task No." <> '' then begin
            DimensionSetIDArr[1] := "Dimension Set ID";
            DimensionSetIDArr[2] :=
              DimMgt.CreateDimSetFromJobTaskDim("Job No.",
                "Job Task No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            DimMgt.CreateDimForJobJournalLineWithHigherPriorities(
              Rec, CurrFieldNo, DimensionSetIDArr[3], "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Source Code", DATABASE::Job);
            "Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(
                DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;

        OnAfterUpdateDimensions(Rec, DimensionSetIDArr);
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        JobJournalBatch: Record "Job Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                JobJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            JobJournalBatch.SetFilter(Name, BatchFilter);
            JobJournalBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
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

    procedure IsInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem;
        exit(Item.IsInventoriableType);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(DATABASE::"Job Journal Line", "Entry Type",
            "Journal Template Name", "Journal Batch Name", 0, "Line No."));
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        "Serial No." := JobPlanningLine."Serial No.";
        "Lot No." := JobPlanningLine."Lot No.";

        OnAfterCopyTrackingFromJobPlanningLine(rec, JobPlanningLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var JobJournalLine: Record "Job Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var JobJournalLine: Record "Job Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var JobJournalLine: Record "Job Journal Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemUoM(var JobJournalLine: Record "Job Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceUoM(var JobJournalLine: Record "Job Journal Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountUoM(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var JobJournalLine: Record "Job Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobPlanningLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAmounts(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterResourceFindCost(var JobJournalLine: Record "Job Journal Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var JobJournalLine: Record "Job Journal Line"; LastJobJournalLine: Record "Job Journal Line"; JobJournalTemplate: Record "Job Journal Template"; JobJournalBatch: Record "Job Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimensions(var JobJournalLine: Record "Job Journal Line"; var DimensionSetIDArr: array[10] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalCost(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalPrice(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsAndDiscounts(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var JobJournalLine: Record "Job Journal Line"; var FieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(var JobJournalLine: Record "Job Journal Line"; UnitAmountRoundingPrecision: Decimal; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(var JobJournalLine: Record "Job Journal Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmptyLine(var JobJournalLine: Record "Job Journal Line"; var LineIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPrice(JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var ShouldRetrieveCostPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpNewLine(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; LastJobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWorkTypeCodeQty(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; Resource: Record Resource; WorkType: Record "Work Type")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeUpdateAllAmounts(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; JobJournalLine: Record "Job Journal Line");
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterUpdateAllAmounts(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWorkTypeCode(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; var IsLineDiscountHandled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateJobNoOnBeforeCheckJob(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;
}


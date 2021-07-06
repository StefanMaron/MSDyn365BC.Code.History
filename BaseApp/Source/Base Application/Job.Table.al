table 167 Job
{
    Caption = 'Job';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Job List";
    LookupPageID = "Job List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    JobsSetup.Get();
                    NoSeriesMgt.TestManual(JobsSetup."Job Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
            end;
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToCustomerNo(Rec, IsHandled, xRec, CurrFieldNo);
                if IsHandled then
                    exit;

                if ("Bill-to Customer No." = '') or ("Bill-to Customer No." <> xRec."Bill-to Customer No.") then
                    if JobLedgEntryExist or JobPlanningLineExist then
                        Error(AssociatedEntriesExistErr, FieldCaption("Bill-to Customer No."), TableCaption);

                UpdateCust;
            end;
        }
        field(12; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(13; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                CheckDate;
            end;
        }
        field(14; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckDate;
            end;
        }
        field(19; Status; Enum "Job Status")
        {
            Caption = 'Status';
            InitValue = Open;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
            begin
                if xRec.Status <> Status then begin
                    if Status = Status::Completed then
                        Validate(Complete, true);
                    if xRec.Status = xRec.Status::Completed then
                        if DIALOG.Confirm(StatusChangeQst) then
                            Validate(Complete, false)
                        else
                            Status := xRec.Status;
                    Modify;
                    JobPlanningLine.SetCurrentKey("Job No.");
                    JobPlanningLine.SetRange("Job No.", "No.");
                    if JobPlanningLine.FindSet() then begin
                        if CheckReservationEntries() then
                            repeat
                                JobPlanningLineReserve.DeleteLine(JobPlanningLine);
                            until JobPlanningLine.Next() = 0;
                        JobPlanningLine.ModifyAll(Status, Status);
                        PerformAutoReserve(JobPlanningLine);
                    end;
                end;
            end;
        }
        field(20; "Person Responsible"; Code[20])
        {
            Caption = 'Person Responsible';
            TableRelation = Resource WHERE(Type = CONST(Person));
        }
        field(21; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(22; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(23; "Job Posting Group"; Code[20])
        {
            Caption = 'Job Posting Group';
            TableRelation = "Job Posting Group";
        }
        field(24; Blocked; Enum "Job Blocked")
        {
            Caption = 'Blocked';
        }
        field(29; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = Exist("Comment Line" WHERE("Table Name" = CONST(Job),
                                                      "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(32; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(49; "Scheduled Res. Qty."; Decimal)
        {
            CalcFormula = Sum("Job Planning Line"."Quantity (Base)" WHERE("Job No." = FIELD("No."),
                                                                           "Schedule Line" = CONST(true),
                                                                           Type = CONST(Resource),
                                                                           "No." = FIELD("Resource Filter"),
                                                                           "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Scheduled Res. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(51; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(55; "Resource Gr. Filter"; Code[20])
        {
            Caption = 'Resource Gr. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(56; "Scheduled Res. Gr. Qty."; Decimal)
        {
            CalcFormula = Sum("Job Planning Line"."Quantity (Base)" WHERE("Job No." = FIELD("No."),
                                                                           "Schedule Line" = CONST(true),
                                                                           Type = CONST(Resource),
                                                                           "Resource Group No." = FIELD("Resource Gr. Filter"),
                                                                           "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Scheduled Res. Gr. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; Picture; BLOB)
        {
            Caption = 'Picture';
            ObsoleteReason = 'Replaced by Image field';
            ObsoleteState = Removed;
            SubType = Bitmap;
            ObsoleteTag = '18.0';
        }
        field(58; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(59; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(60; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(61; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = IF ("Bill-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Bill-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Bill-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(63; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(64; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = IF ("Bill-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Bill-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Bill-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(66; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(67; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            Editable = true;
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", xRec."Bill-to Country/Region Code");
            end;
        }
        field(68; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(1000; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            TableRelation = "Job WIP Method".Code WHERE(Valid = CONST(true));

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
                JobWIPMethod: Record "Job WIP Method";
                NewWIPMethod: Code[20];
            begin
                if "WIP Posting Method" = "WIP Posting Method"::"Per Job Ledger Entry" then begin
                    JobWIPMethod.Get("WIP Method");
                    if not JobWIPMethod."WIP Cost" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Cost"));
                    if not JobWIPMethod."WIP Sales" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Sales"));
                end;

                JobTask.SetRange("Job No.", "No.");
                JobTask.SetRange("WIP-Total", JobTask."WIP-Total"::Total);
                if JobTask.FindFirst() then
                    if Confirm(WIPMethodQst, true, JobTask.FieldCaption("WIP Method"), JobTask.TableCaption, JobTask."WIP-Total") then begin
                        JobTask.ModifyAll("WIP Method", "WIP Method", true);
                        // An additional FIND call requires since JobTask.MODIFYALL changes the Job's information
                        NewWIPMethod := "WIP Method";
                        Find();
                        "WIP Method" := NewWIPMethod;
                    end;
            end;
        }
        field(1001; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> xRec."Currency Code" then
                    if not JobLedgEntryExist then begin
                        CurrencyUpdatePlanningLines;
                        CurrencyUpdatePurchLines;
                    end else
                        Error(AssociatedEntriesExistErr, FieldCaption("Currency Code"), TableCaption);
                if "Currency Code" <> '' then
                    Validate("Invoice Currency Code", '');
            end;
        }
        field(1002; "Bill-to Contact No."; Code[20])
        {
            AccessByPermission = TableData Contact = R;
            Caption = 'Bill-to Contact No.';

            trigger OnLookup()
            begin
                BilltoContactLookup();
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToContactNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then
                    if ("Bill-to Contact No." = '') and ("Bill-to Customer No." = '') then begin
                        Init;
                        "No. Series" := xRec."No. Series";
                        Validate(Description, xRec.Description);
                    end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then begin
                    Cont.Get("Bill-to Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                        if ContBusinessRelation."Contact No." <> Cont."Company No." then
                            Error(ContactBusRelDiffCompErr, Cont."No.", Cont.Name, "Bill-to Customer No.");
                end;
                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(1003; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(1004; "Planning Date Filter"; Date)
        {
            Caption = 'Planning Date Filter';
            FieldClass = FlowFilter;
        }
        field(1005; "Total WIP Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Job WIP Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                         "Job Complete" = CONST(false),
                                                                         Type = FILTER("Accrued Costs" | "Applied Costs" | "Recognized Costs")));
            Caption = 'Total WIP Cost Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1006; "Total WIP Cost G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Job WIP G/L Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                             Reversed = CONST(false),
                                                                             "Job Complete" = CONST(false),
                                                                             Type = FILTER("Accrued Costs" | "Applied Costs" | "Recognized Costs")));
            Caption = 'Total WIP Cost G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1007; "WIP Entries Exist"; Boolean)
        {
            CalcFormula = Exist("Job WIP Entry" WHERE("Job No." = FIELD("No.")));
            Caption = 'WIP Entries Exist';
            FieldClass = FlowField;
        }
        field(1008; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
            Editable = false;
        }
        field(1009; "WIP G/L Posting Date"; Date)
        {
            CalcFormula = Min("Job WIP G/L Entry"."WIP Posting Date" WHERE(Reversed = CONST(false),
                                                                            "Job No." = FIELD("No.")));
            Caption = 'WIP G/L Posting Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1011; "Invoice Currency Code"; Code[10])
        {
            Caption = 'Invoice Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Invoice Currency Code" <> '' then
                    Validate("Currency Code", '');
            end;
        }
        field(1012; "Exch. Calculation (Cost)"; Option)
        {
            Caption = 'Exch. Calculation (Cost)';
            OptionCaption = 'Fixed FCY,Fixed LCY';
            OptionMembers = "Fixed FCY","Fixed LCY";
        }
        field(1013; "Exch. Calculation (Price)"; Option)
        {
            Caption = 'Exch. Calculation (Price)';
            OptionCaption = 'Fixed FCY,Fixed LCY';
            OptionMembers = "Fixed FCY","Fixed LCY";
        }
        field(1014; "Allow Schedule/Contract Lines"; Boolean)
        {
            Caption = 'Allow Budget/Billable Lines';
        }
        field(1015; Complete; Boolean)
        {
            Caption = 'Complete';

            trigger OnValidate()
            begin
                if Complete <> xRec.Complete then
                    ChangeJobCompletionStatus;
            end;
        }
        field(1017; "Recog. Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Job WIP Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                         Type = FILTER("Recognized Sales")));
            Caption = 'Recog. Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1018; "Recog. Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Job WIP G/L Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                             Reversed = CONST(false),
                                                                             Type = FILTER("Recognized Sales")));
            Caption = 'Recog. Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1019; "Recog. Costs Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job WIP Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                        Type = FILTER("Recognized Costs")));
            Caption = 'Recog. Costs Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1020; "Recog. Costs G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job WIP G/L Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                            Reversed = CONST(false),
                                                                            Type = FILTER("Recognized Costs")));
            Caption = 'Recog. Costs G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1021; "Total WIP Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job WIP Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                        "Job Complete" = CONST(false),
                                                                        Type = FILTER("Accrued Sales" | "Applied Sales" | "Recognized Sales")));
            Caption = 'Total WIP Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1022; "Total WIP Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job WIP G/L Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                            Reversed = CONST(false),
                                                                            "Job Complete" = CONST(false),
                                                                            Type = FILTER("Accrued Sales" | "Applied Sales" | "Recognized Sales")));
            Caption = 'Total WIP Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1023; "WIP Completion Calculated"; Boolean)
        {
            CalcFormula = Exist("Job WIP Entry" WHERE("Job No." = FIELD("No."),
                                                       "Job Complete" = CONST(true)));
            Caption = 'WIP Completion Calculated';
            FieldClass = FlowField;
        }
        field(1024; "Next Invoice Date"; Date)
        {
            CalcFormula = Min("Job Planning Line"."Planning Date" WHERE("Job No." = FIELD("No."),
                                                                         "Contract Line" = CONST(true),
                                                                         "Qty. to Invoice" = FILTER(<> 0)));
            Caption = 'Next Invoice Date';
            FieldClass = FlowField;
        }
        field(1025; "Apply Usage Link"; Boolean)
        {
            Caption = 'Apply Usage Link';

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                JobLedgerEntry: Record "Job Ledger Entry";
                JobUsageLink: Record "Job Usage Link";
            begin
                if "Apply Usage Link" then begin
                    JobLedgerEntry.SetCurrentKey("Job No.");
                    JobLedgerEntry.SetRange("Job No.", "No.");
                    JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
                    if JobLedgerEntry.FindFirst() then begin
                        JobUsageLink.SetRange("Entry No.", JobLedgerEntry."Entry No.");
                        if JobUsageLink.IsEmpty() then
                            Error(ApplyUsageLinkErr, TableCaption);
                    end;

                    JobPlanningLine.SetCurrentKey("Job No.");
                    JobPlanningLine.SetRange("Job No.", "No.");
                    JobPlanningLine.SetRange("Schedule Line", true);
                    if JobPlanningLine.FindSet then
                        repeat
                            JobPlanningLine.Validate("Usage Link", true);
                            if JobPlanningLine."Planning Date" = 0D then
                                JobPlanningLine.Validate("Planning Date", WorkDate);
                            JobPlanningLine.Modify(true);
                        until JobPlanningLine.Next() = 0;
                end;
            end;
        }
        field(1026; "WIP Warnings"; Boolean)
        {
            CalcFormula = Exist("Job WIP Warning" WHERE("Job No." = FIELD("No.")));
            Caption = 'WIP Warnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1027; "WIP Posting Method"; Option)
        {
            Caption = 'WIP Posting Method';
            OptionCaption = 'Per Job,Per Job Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";

            trigger OnValidate()
            var
                JobLedgerEntry: Record "Job Ledger Entry";
                JobWIPEntry: Record "Job WIP Entry";
                JobWIPMethod: Record "Job WIP Method";
            begin
                if xRec."WIP Posting Method" = "WIP Posting Method"::"Per Job Ledger Entry" then begin
                    JobLedgerEntry.SetRange("Job No.", "No.");
                    JobLedgerEntry.SetFilter("Amt. Posted to G/L", '<>%1', 0);
                    if not JobLedgerEntry.IsEmpty() then
                        Error(WIPAlreadyPostedErr, FieldCaption("WIP Posting Method"), xRec."WIP Posting Method");
                end;

                JobWIPEntry.SetRange("Job No.", "No.");
                if not JobWIPEntry.IsEmpty() then
                    Error(WIPAlreadyAssociatedErr, FieldCaption("WIP Posting Method"));

                if "WIP Posting Method" = "WIP Posting Method"::"Per Job Ledger Entry" then begin
                    JobWIPMethod.Get("WIP Method");
                    if not JobWIPMethod."WIP Cost" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Cost"));
                    if not JobWIPMethod."WIP Sales" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Sales"));
                end;
            end;
        }
        field(1028; "Applied Costs G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Job WIP G/L Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                             Reverse = CONST(false),
                                                                             "Job Complete" = CONST(false),
                                                                             Type = FILTER("Applied Costs")));
            Caption = 'Applied Costs G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1029; "Applied Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Job WIP G/L Entry"."WIP Entry Amount" WHERE("Job No." = FIELD("No."),
                                                                             Reverse = CONST(false),
                                                                             "Job Complete" = CONST(false),
                                                                             Type = FILTER("Applied Sales")));
            Caption = 'Applied Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1030; "Calc. Recog. Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job Task"."Recognized Sales Amount" WHERE("Job No." = FIELD("No.")));
            Caption = 'Calc. Recog. Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1031; "Calc. Recog. Costs Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job Task"."Recognized Costs Amount" WHERE("Job No." = FIELD("No.")));
            Caption = 'Calc. Recog. Costs Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1032; "Calc. Recog. Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job Task"."Recognized Sales G/L Amount" WHERE("Job No." = FIELD("No.")));
            Caption = 'Calc. Recog. Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1033; "Calc. Recog. Costs G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Job Task"."Recognized Costs G/L Amount" WHERE("Job No." = FIELD("No.")));
            Caption = 'Calc. Recog. Costs G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1034; "WIP Completion Posted"; Boolean)
        {
            CalcFormula = Exist("Job WIP G/L Entry" WHERE("Job No." = FIELD("No."),
                                                           "Job Complete" = CONST(true)));
            Caption = 'WIP Completion Posted';
            FieldClass = FlowField;
        }
        field(1035; "Over Budget"; Boolean)
        {
            Caption = 'Over Budget';
        }
        field(1036; "Project Manager"; Code[50])
        {
            Caption = 'Project Manager';
            TableRelation = "User Setup";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Price Calculation Method" <> "Price Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Sale);
            end;
        }
        field(7001; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Cost Calculation Method';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Cost Calculation Method" <> "Cost Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Cost Calculation Method", PriceType::Purchase);
            end;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "Bill-to Customer No.")
        {
        }
        key(Key4; Description)
        {
        }
        key(Key5; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Bill-to Customer No.", "Starting Date", Status)
        {
        }
        fieldgroup(Brick; "No.", Description, "Bill-to Customer No.", "Starting Date", Status, Image)
        {
        }
    }

    trigger OnDelete()
    var
        JobTask: Record "Job Task";
    begin
        MoveEntries.MoveJobEntries(Rec);

        JobTask.SetCurrentKey("Job No.");
        JobTask.SetRange("Job No.", "No.");
        JobTask.DeleteAll(true);

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Job);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::Job, "No.");

        if "Project Manager" <> '' then
            RemoveFromMyJobs();
    end;

    trigger OnInsert()
    begin
        JobsSetup.Get();

        InitJobNo();
        InitBillToCustomerNo();

        if not "Apply Usage Link" then
            Validate("Apply Usage Link", JobsSetup."Apply Usage Link by Default");
        if not "Allow Schedule/Contract Lines" then
            Validate("Allow Schedule/Contract Lines", JobsSetup."Allow Sched/Contract Lines Def");
        if "WIP Method" = '' then
            Validate("WIP Method", JobsSetup."Default WIP Method");
        if "Job Posting Group" = '' then
            Validate("Job Posting Group", JobsSetup."Default Job Posting Group");
        Validate("WIP Posting Method", JobsSetup."Default WIP Posting Method");

        InitGlobalDimFromDefalutDim();
        InitWIPFields();

        "Creation Date" := Today;
        "Last Date Modified" := "Creation Date";

        if ("Project Manager" <> '') and (Status = Status::Open) then
            AddToMyJobs("Project Manager");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        CheckRemoveFromMyJobsFromModify();

        if ("Project Manager" <> '') and (xRec."Project Manager" <> "Project Manager") then
            if Status = Status::Open then
                AddToMyJobs("Project Manager");
    end;

    trigger OnRename()
    begin
        UpdateJobNoInReservationEntries;
        DimMgt.RenameDefaultDim(DATABASE::Job, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Job, xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        AssociatedEntriesExistErr: Label 'You cannot change %1 because one or more entries are associated with this %2.', Comment = '%1 = Name of field used in the error; %2 = The name of the Job table';
        JobsSetup: Record "Jobs Setup";
        PostCode: Record "Post Code";
        Job: Record Job;
        Cust: Record Customer;
        Cont: Record Contact;
        ContBusinessRelation: Record "Contact Business Relation";
        CommentLine: Record "Comment Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        StatusChangeQst: Label 'This will delete any unposted WIP entries for this job and allow you to reverse the completion postings for this job.\\Do you wish to continue?';
        ContactBusRelDiffCompErr: Label 'Contact %1 %2 is related to a different company than customer %3.', Comment = '%1 = The contact number; %2 = The contact''s name; %3 = The Bill-To Customer Number associated with this job';
        ContactBusRelErr: Label 'Contact %1 %2 is not related to customer %3.', Comment = '%1 = The contact number; %2 = The contact''s name; %3 = The Bill-To Customer Number associated with this job';
        ContactBusRelMissingErr: Label 'Contact %1 %2 is not related to a customer.', Comment = '%1 = The contact number; %2 = The contact''s name';
        TestBlockedErr: Label '%1 %2 must not be blocked with type %3.', Comment = '%1 = The Job table name; %2 = The Job number; %3 = The value of the Blocked field';
        ReverseCompletionEntriesMsg: Label 'You must run the %1 function to reverse the completion entries that have already been posted for this job.', Comment = '%1 = The name of the Job Post WIP to G/L report';
        MoveEntries: Codeunit MoveEntries;
        OnlineMapMsg: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
        CheckDateErr: Label '%1 must be equal to or earlier than %2.', Comment = '%1 = The job''s starting date; %2 = The job''s ending date';
        BlockedCustErr: Label 'You cannot set %1 to %2, as this %3 has set %4 to %5.', Comment = '%1 = The Bill-to Customer No. field name; %2 = The job''s Bill-to Customer No. value; %3 = The Customer table name; %4 = The Blocked field name; %5 = The job''s customer''s Blocked value';
        ApplyUsageLinkErr: Label 'A usage link cannot be enabled for the entire %1 because usage without the usage link already has been posted.', Comment = '%1 = The name of the Job table';
        WIPMethodQst: Label 'Do you want to set the %1 on every %2 of type %3?', Comment = '%1 = The WIP Method field name; %2 = The name of the Job Task table; %3 = The current job task''s WIP Total type';
        WIPAlreadyPostedErr: Label '%1 must be %2 because job WIP general ledger entries already were posted with this setting.', Comment = '%1 = The name of the WIP Posting Method field; %2 = The previous WIP Posting Method value of this job';
        WIPAlreadyAssociatedErr: Label '%1 cannot be modified because the job has associated job WIP entries.', Comment = '%1 = The name of the WIP Posting Method field';
        WIPPostMethodErr: Label 'The selected %1 requires the %2 to have %3 enabled.', Comment = '%1 = The name of the WIP Posting Method field; %2 = The name of the WIP Method field; %3 = The field caption represented by the value of this job''s WIP method';
        EndingDateChangedMsg: Label '%1 is set to %2.', Comment = '%1 = The name of the Ending Date field; %2 = This job''s Ending Date value';
        UpdateJobTaskDimQst: Label 'You have changed a dimension.\\Do you want to update the lines?';
        RunWIPFunctionsQst: Label 'You must run the %1 function to create completion entries for this job. \Do you want to run this function now?', Comment = '%1 = The name of the Job Calculate WIP report';
        ReservationEntriesDeleteQst: Label 'Any reservation entries that exist for this job will be deleted. \Do you want to continue?';
        ReservationEntriesExistErr: Label 'You cannot set the status to %1 because the job has reservations on the job planning lines.', Comment = '%1=The job status name';
        AutoReserveNotPossibleMsg: Label 'Automatic reservation is not possible for one or more job planning lines. \Please reserve manually.';

    procedure AssistEdit(OldJob: Record Job): Boolean
    begin
        with Job do begin
            Job := Rec;
            JobsSetup.Get();
            JobsSetup.TestField("Job Nos.");
            if NoSeriesMgt.SelectSeries(JobsSetup."Job Nos.", OldJob."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := Job;
                exit(true);
            end;
        end;
    end;

    procedure GetCostCalculationMethod() Method: Enum "Price Calculation Method";
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        if "Cost Calculation Method" <> Method::" " then
            Method := "Cost Calculation Method"
        else begin
            PurchasesPayablesSetup.Get();
            Method := PurchasesPayablesSetup."Price Calculation Method";
        end;
    end;

    procedure GetPriceCalculationMethod() Method: Enum "Price Calculation Method";
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if "Price Calculation Method" <> Method::" " then
            Method := "Price Calculation Method"
        else begin
            Method := GetCustomerPriceGroupPriceCalcMethod();
            if Method = Method::" " then begin
                SalesReceivablesSetup.Get();
                Method := SalesReceivablesSetup."Price Calculation Method";
            end;
        end;
    end;

    local procedure GetCustomerPriceGroupPriceCalcMethod(): Enum "Price Calculation Method";
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        if "Customer Price Group" <> '' then
            if CustomerPriceGroup.Get("Customer Price Group") then
                exit(CustomerPriceGroup."Price Calculation Method");
    end;

    local procedure CheckRemoveFromMyJobsFromModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRemoveFromMyJobsFromModify(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if (("Project Manager" <> xRec."Project Manager") and (xRec."Project Manager" <> '')) or (Status <> Status::Open) then
            RemoveFromMyJobs();
    end;

    local procedure InitJobNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitJobNo(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            JobsSetup.TestField("Job Nos.");
            NoSeriesMgt.InitSeries(JobsSetup."Job Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

    local procedure InitBillToCustomerNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitBillToCustomerNo(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if GetFilter("Bill-to Customer No.") <> '' then
            if GetRangeMin("Bill-to Customer No.") = GetRangeMax("Bill-to Customer No.") then
                Validate("Bill-to Customer No.", GetRangeMin("Bill-to Customer No."));

    end;

    local procedure AsPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Source Type" := PriceSource."Source Type"::Job;
        PriceSource."Source No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AssetType: Enum "Price Asset Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceAsset.InitAsset();
        PriceAsset.Validate("Asset Type", AssetType);
        AsPriceSource(PriceSource);
        PriceSource."Price Type" := PriceType;
        PriceUXManagement.ShowPriceListLines(PriceSource, PriceAsset, AmountType);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Job, "No.", FieldNumber, ShortcutDimCode);
            UpdateJobTaskDimension(FieldNumber, ShortcutDimCode);
            Modify;
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure UpdateBillToContact(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
    begin
        if Cust.Get(CustomerNo) then begin
            if Cust."Primary Contact No." <> '' then
                "Bill-to Contact No." := Cust."Primary Contact No."
            else begin
                ContBusRel.Reset();
                ContBusRel.SetCurrentKey("Link to Table", "No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("No.", "Bill-to Customer No.");
                if ContBusRel.FindFirst() then
                    "Bill-to Contact No." := ContBusRel."Contact No.";
            end;
            "Bill-to Contact" := Cust.Contact;
        end;
    end;

    procedure JobLedgEntryExist(): Boolean
    var
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        Clear(JobLedgEntry);
        JobLedgEntry.SetCurrentKey("Job No.");
        JobLedgEntry.SetRange("Job No.", "No.");
        exit(not JobLedgEntry.IsEmpty());
    end;

    procedure JobPlanningLineExist(): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine.SetRange("Job No.", "No.");
        exit(not JobPlanningLine.IsEmpty());
    end;

    procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cust: Record Customer;
        Cont: Record Contact;
    begin
        if Cont.Get(ContactNo) then begin
            "Bill-to Contact No." := Cont."No.";
            if Cont.Type = Cont.Type::Person then
                "Bill-to Contact" := Cont.Name
            else
                if Cust.Get("Bill-to Customer No.") then
                    "Bill-to Contact" := Cust.Contact
                else
                    "Bill-to Contact" := '';
        end else begin
            "Bill-to Contact" := '';
            exit;
        end;

        OnUpdateBillToCustOnAfterAssignBillToContact(Rec, Cont);

        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
            if "Bill-to Customer No." = '' then
                Validate("Bill-to Customer No.", ContBusinessRelation."No.")
            else
                CheckContactBillToCustomerBusRelation();
        end else
            ShowContactBillToCustomerBusRelationMissingError();
    end;

    local procedure CheckContactBillToCustomerBusRelation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContactBillToCustomerBusRelation(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if "Bill-to Customer No." <> ContBusinessRelation."No." then
            Error(ContactBusRelErr, Cont."No.", Cont.Name, "Bill-to Customer No.");
    end;

    local procedure ShowContactBillToCustomerBusRelationMissingError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowContactBillToCustomerBusRelationMissingError(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        Error(ContactBusRelMissingErr, Cont."No.", Cont.Name);
    end;

    procedure UpdateCust()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCust(Rec, xRec, IsHandled);
        If IsHandled then
            exit;

        if "Bill-to Customer No." <> '' then begin
            Cust.Get("Bill-to Customer No.");
            Cust.TestField("Customer Posting Group");
            IsHandled := false;
            OnUpdateCustOnBeforeTestBillToCustomerNo(Rec, Cust, IsHandled);
            if not IsHandled then
                Cust.TestField("Bill-to Customer No.", '');
            if Cust."Privacy Blocked" then
                Error(Cust.GetPrivacyBlockedGenericErrorText(Cust));
            if Cust.Blocked = Cust.Blocked::All then
                Error(
                  BlockedCustErr,
                  FieldCaption("Bill-to Customer No."),
                  "Bill-to Customer No.",
                  Cust.TableCaption,
                  FieldCaption(Blocked),
                  Cust.Blocked);
            "Bill-to Name" := Cust.Name;
            "Bill-to Name 2" := Cust."Name 2";
            "Bill-to Address" := Cust.Address;
            "Bill-to Address 2" := Cust."Address 2";
            "Bill-to City" := Cust.City;
            "Bill-to Post Code" := Cust."Post Code";
            "Bill-to Country/Region Code" := Cust."Country/Region Code";
            IsHandled := false;
            OnUpdateCustOnBeforeAssignIncoiceCurrencyCode(Rec, xRec, Cust, IsHandled);
            if not IsHandled then
                "Invoice Currency Code" := Cust."Currency Code";
            if "Invoice Currency Code" <> '' then
                Validate("Currency Code", '');
            "Customer Disc. Group" := Cust."Customer Disc. Group";
            "Customer Price Group" := Cust."Customer Price Group";
            "Language Code" := Cust."Language Code";
            "Bill-to County" := Cust.County;
            Reserve := Cust.Reserve;
            UpdateBillToContact("Bill-to Customer No.");
            CopyDefaultDimensionsFromCustomer();
        end else begin
            "Bill-to Name" := '';
            "Bill-to Name 2" := '';
            "Bill-to Address" := '';
            "Bill-to Address 2" := '';
            "Bill-to City" := '';
            "Bill-to Post Code" := '';
            "Bill-to Country/Region Code" := '';
            "Invoice Currency Code" := '';
            "Customer Disc. Group" := '';
            "Customer Price Group" := '';
            "Language Code" := '';
            "Bill-to County" := '';
            Validate("Bill-to Contact No.", '');
        end;

        OnAfterUpdateBillToCust(Rec);
    end;

    procedure InitWIPFields()
    begin
        "WIP Posting Date" := 0D;
        "WIP G/L Posting Date" := 0D;
    end;

    local procedure InitGlobalDimFromDefalutDim()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitGlobalDimFromDefalutDim(Rec, IsHandled);
        if IsHandled then
            exit;

        DimMgt.UpdateDefaultDim(
            DATABASE::Job, "No.",
            "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    procedure TestBlocked()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestBlocked(Rec, IsHandled);
        If IsHandled then
            exit;

        if Blocked = Blocked::" " then
            exit;
        Error(TestBlockedErr, TableCaption, "No.", Blocked);
    end;

    procedure CurrencyUpdatePlanningLines()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", "No.");
        JobPlanningLine.SetAutoCalcFields("Qty. Transferred to Invoice");
        JobPlanningLine.LockTable();
        if JobPlanningLine.Find('-') then
            repeat
                if JobPlanningLine."Qty. Transferred to Invoice" <> 0 then
                    Error(AssociatedEntriesExistErr, FieldCaption("Currency Code"), TableCaption);
                JobPlanningLine.Validate("Currency Code", "Currency Code");
                JobPlanningLine.Validate("Currency Date");
                JobPlanningLine.Modify();
            until JobPlanningLine.Next() = 0;
    end;

    local procedure CurrencyUpdatePurchLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        Modify;
        PurchLine.SetRange("Job No.", "No.");
        if PurchLine.FindSet then
            repeat
                PurchLine.Validate("Job Currency Code", "Currency Code");
                PurchLine.Validate("Job Task No.");
                PurchLine.Modify();
            until PurchLine.Next() = 0;
    end;

    local procedure ChangeJobCompletionStatus()
    var
        JobCalcWIP: Codeunit "Job Calculate WIP";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeJobCompletionStatus(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if Complete then begin
            Validate("Ending Date", CalcEndingDate);
            Message(EndingDateChangedMsg, FieldCaption("Ending Date"), "Ending Date");
        end else begin
            JobCalcWIP.ReOpenJob("No.");
            "WIP Posting Date" := 0D;
            Message(ReverseCompletionEntriesMsg, GetReportCaption(REPORT::"Job Post WIP to G/L"));
        end;

        OnAfterChangeJobCompletionStatus(Rec, xRec);
    end;

    procedure DisplayMap()
    var
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        if OnlineMapSetup.FindFirst() then
            OnlineMapManagement.MakeSelection(DATABASE::Job, GetPosition)
        else
            Message(OnlineMapMsg);
    end;

    procedure GetQuantityAvailable(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; InEntryType: Option Usage,Sale,Both; Direction: Option Positive,Negative,Both): Decimal
    var
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        Clear(JobLedgEntry);
        JobLedgEntry.SetCurrentKey("Job No.", "Entry Type", Type, "No.");
        JobLedgEntry.SetRange("Job No.", "No.");
        if not (InEntryType = InEntryType::Both) then
            JobLedgEntry.SetRange("Entry Type", InEntryType);
        JobLedgEntry.SetRange(Type, JobLedgEntry.Type::Item);
        JobLedgEntry.SetRange("No.", ItemNo);
        case Direction of
            Direction::Both:
                begin
                    JobLedgEntry.SetRange("Location Code", LocationCode);
                    JobLedgEntry.SetRange("Variant Code", VariantCode);
                end;
            Direction::Positive:
                JobLedgEntry.SetFilter("Quantity (Base)", '>0');
            Direction::Negative:
                JobLedgEntry.SetFilter("Quantity (Base)", '<0');
        end;
        JobLedgEntry.CalcSums("Quantity (Base)");
        exit(JobLedgEntry."Quantity (Base)");
    end;

    local procedure CheckDate()
    begin
        if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
            Error(CheckDateErr, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
    end;

    procedure CalcAccWIPCostsAmount(): Decimal
    begin
        exit("Total WIP Cost Amount" + "Applied Costs G/L Amount");
    end;

    procedure CalcAccWIPSalesAmount(): Decimal
    begin
        exit("Total WIP Sales Amount" - "Applied Sales G/L Amount");
    end;

    procedure CalcRecognizedProfitAmount() Result: Decimal
    begin
        Result := "Calc. Recog. Sales Amount" - "Calc. Recog. Costs Amount";
        OnAfterCalcRecognizedProfitAmount(Result);
    end;

    procedure CalcRecognizedProfitPercentage(): Decimal
    begin
        if "Calc. Recog. Sales Amount" <> 0 then
            exit((CalcRecognizedProfitAmount / "Calc. Recog. Sales Amount") * 100);
        exit(0);
    end;

    procedure CalcRecognizedProfitGLAmount(): Decimal
    begin
        exit("Calc. Recog. Sales G/L Amount" - "Calc. Recog. Costs G/L Amount");
    end;

    procedure CalcRecognProfitGLPercentage(): Decimal
    begin
        if "Calc. Recog. Sales G/L Amount" <> 0 then
            exit((CalcRecognizedProfitGLAmount / "Calc. Recog. Sales G/L Amount") * 100);
        exit(0);
    end;

    procedure CopyDefaultDimensionsFromCustomer()
    var
        CustDefaultDimension: Record "Default Dimension";
        JobDefaultDimension: Record "Default Dimension";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDefaultDimensionsFromCustomer(Rec, IsHandled);
        if IsHandled then
            exit;

        JobDefaultDimension.SetRange("Table ID", DATABASE::Job);
        JobDefaultDimension.SetRange("No.", "No.");
        if JobDefaultDimension.FindSet then
            repeat
                DimMgt.DefaultDimOnDelete(JobDefaultDimension);
                JobDefaultDimension.Delete();
            until JobDefaultDimension.Next() = 0;

        CustDefaultDimension.SetRange("Table ID", DATABASE::Customer);
        CustDefaultDimension.SetRange("No.", "Bill-to Customer No.");
        if CustDefaultDimension.FindSet then
            repeat
                JobDefaultDimension.Init();
                JobDefaultDimension.TransferFields(CustDefaultDimension);
                JobDefaultDimension."Table ID" := DATABASE::Job;
                JobDefaultDimension."No." := "No.";
                JobDefaultDimension.Insert();
                DimMgt.DefaultDimOnInsert(JobDefaultDimension);
            until CustDefaultDimension.Next() = 0;

        DimMgt.UpdateDefaultDim(DATABASE::Job, "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    procedure PercentCompleted(): Decimal
    var
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        CL: array[16] of Decimal;
    begin
        JobCalcStatistics.JobCalculateCommonFilters(Rec);
        JobCalcStatistics.CalculateAmounts;
        JobCalcStatistics.GetLCYCostAmounts(CL);
        if CL[4] <> 0 then
            exit((CL[8] / CL[4]) * 100);
        exit(0);
    end;

    procedure PercentInvoiced(): Decimal
    var
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        PL: array[16] of Decimal;
    begin
        JobCalcStatistics.JobCalculateCommonFilters(Rec);
        JobCalcStatistics.CalculateAmounts;
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        if PL[12] <> 0 then
            exit((PL[16] / PL[12]) * 100);
        exit(0);
    end;

    procedure PercentOverdue(): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
        QtyOverdue: Decimal;
        QtyTotal: Decimal;
    begin
        JobPlanningLine.SetRange("Job No.", "No.");
        QtyTotal := JobPlanningLine.Count();
        if QtyTotal = 0 then
            exit(0);
        JobPlanningLine.SetFilter("Planning Date", '<%1', WorkDate);
        JobPlanningLine.SetFilter("Remaining Qty.", '>%1', 0);
        QtyOverdue := JobPlanningLine.Count();
        exit((QtyOverdue / QtyTotal) * 100);
    end;

    local procedure UpdateJobNoInReservationEntries()
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetFilter("Source Type", '%1|%2', DATABASE::"Job Planning Line", DATABASE::"Job Journal Line");
        ReservEntry.SetRange("Source ID", xRec."No.");
        ReservEntry.ModifyAll("Source ID", "No.", true);
    end;

    local procedure CheckReservationEntries(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        ReservationToDeleteExists: Boolean;
    begin
        ReservationToDeleteExists := false;

        if Status <> Status::Open then begin
            ReservEntry.SetRange("Source Type", DATABASE::"Job Planning Line");
            ReservEntry.SetRange("Source ID", "No.");
            ReservationToDeleteExists := not ReservEntry.IsEmpty();
            if ReservationToDeleteExists then
                if not ConfirmManagement.GetResponseOrDefault(ReservationEntriesDeleteQst, false) then
                    Error(ReservationEntriesExistErr, Status);
        end;

        exit(ReservationToDeleteExists);
    end;

    local procedure PerformAutoReserve(var JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        FullAutoReservation: Boolean;
        AutoReservePossible: Boolean;
    begin
        JobPlanningLine.SetRange(Status, JobPlanningLine.Status::Order);
        JobPlanningLine.SetRange(Reserve, JobPlanningLine.Reserve::Always);
        JobPlanningLine.SetFilter("Remaining Qty. (Base)", '<>%1', 0);
        AutoReservePossible := JobPlanningLine.FindSet();
        if AutoReservePossible then begin
            repeat
                JobPlanningLineReserve.ReservQuantity(JobPlanningLine, QtyToReserve, QtyToReserveBase);
                ReservationManagement.SetReservSource(JobPlanningLine);
                ReservationManagement.AutoReserve(FullAutoReservation, '', JobPlanningLine."Planning Date", QtyToReserve, QtyToReserveBase);
                AutoReservePossible := AutoReservePossible and FullAutoReservation;
                JobPlanningLine.UpdatePlanned();
            until JobPlanningLine.Next() = 0;
            if not AutoReservePossible then
                Message(AutoReserveNotPossibleMsg);
        end;
    end;

    local procedure UpdateJobTaskDimension(FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobTaskDimension(Rec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed then
            if not Confirm(UpdateJobTaskDimQst, false) then
                exit;

        JobTask.SetRange("Job No.", "No.");
        if JobTask.FindSet(true) then
            repeat
                case FieldNumber of
                    1:
                        JobTask.Validate("Global Dimension 1 Code", ShortcutDimCode);
                    2:
                        JobTask.Validate("Global Dimension 2 Code", ShortcutDimCode);
                end;
                JobTask.Modify();
            until JobTask.Next() = 0;
    end;

    procedure UpdateOverBudgetValue(JobNo: Code[20]; Usage: Boolean; Cost: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        UsageCost: Decimal;
        ScheduleCost: Decimal;
        NewOverBudget: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateOverBudgetValue(Rec, JobNo, Usage, Cost, IsHandled);
        if IsHandled then
            exit;

        if "No." <> JobNo then
            if not Get(JobNo) then
                exit;

        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.CalcSums("Total Cost (LCY)");
        if JobLedgerEntry."Total Cost (LCY)" = 0 then
            exit;

        UsageCost := JobLedgerEntry."Total Cost (LCY)";

        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.CalcSums("Total Cost (LCY)");
        ScheduleCost := JobPlanningLine."Total Cost (LCY)";

        if Usage then
            UsageCost += Cost
        else
            ScheduleCost += Cost;
        NewOverBudget := UsageCost > ScheduleCost;
        if NewOverBudget <> "Over Budget" then begin
            "Over Budget" := NewOverBudget;
            Modify;
        end;
    end;

    procedure IsJobSimplificationAvailable(): Boolean
    begin
        exit(true);
    end;

    local procedure AddToMyJobs(ProjectManager: Code[50])
    var
        MyJob: Record "My Job";
    begin
        if Status <> Status::Open then
            exit;

        if MyJob.Get(ProjectManager, "No.") then begin
            MyJob.Description := Description;
            MyJob."Bill-to Name" := "Bill-to Name";
            MyJob."Percent Completed" := PercentCompleted();
            MyJob."Percent Invoiced" := PercentInvoiced();
            MyJob.Modify();
        end else begin
            MyJob.Init();
            MyJob."User ID" := ProjectManager;
            MyJob."Job No." := "No.";
            MyJob.Description := Description;
            MyJob.Status := Status;
            MyJob."Bill-to Name" := "Bill-to Name";
            MyJob."Percent Completed" := PercentCompleted();
            MyJob."Percent Invoiced" := PercentInvoiced();
            MyJob."Exclude from Business Chart" := false;
            MyJob.Insert();
        end;
    end;

    local procedure RemoveFromMyJobs()
    var
        MyJob: Record "My Job";
    begin
        MyJob.SetFilter("Job No.", '=%1', "No.");
        if MyJob.FindSet then
            repeat
                MyJob.Delete();
            until MyJob.Next() = 0;
    end;

    procedure ToPriceSource(var PriceSource: Record "Price Source"; PriceType: Enum "Price Type")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceType;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Job);
        PriceSource.Validate("Source No.", "No.");
    end;

    [Scope('OnPrem')]
    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        DocumentSendingProfile.SendCustomerRecords(
          DummyReportSelections.Usage::JQ.AsInteger(), Rec, ReportDistributionMgt.GetFullDocumentTypeText(Rec),
          "Bill-to Customer No.", "No.", FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    procedure SendProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    var
        ReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        DocumentSendingProfile.Send(
          ReportSelections.Usage::JQ.AsInteger(), Rec, "No.", "Bill-to Customer No.",
          ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
    begin
        DocumentSendingProfile.TrySendToPrinter(
          ReportSelections.Usage::JQ.AsInteger(), Rec, FieldNo("Bill-to Customer No."), ShowRequestForm);
    end;

    [Scope('OnPrem')]
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        DocumentSendingProfile.TrySendToEMail(
          ReportSelections.Usage::JQ.AsInteger(), Rec, FieldNo("No."),
          ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Bill-to Customer No."), ShowDialog);
    end;

    procedure RecalculateJobWIP()
    var
        Job: Record Job;
        Confirmed: Boolean;
        WIPQst: Text;
        IsHandled: Boolean;
    begin
        OnBeforeRecalculateJobWIP(Rec, IsHandled);
        if IsHandled then
            exit;

        Job.Get("No.");
        if Job."WIP Method" = '' then
            exit;

        Job.SetRecFilter;
        WIPQst := StrSubstNo(RunWIPFunctionsQst, GetReportCaption(REPORT::"Job Calculate WIP"));
        Confirmed := Confirm(WIPQst);
        Commit();
        REPORT.RunModal(REPORT::"Job Calculate WIP", not Confirmed, false, Job);
    end;

    local procedure GetReportCaption(ReportID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID);
        exit(AllObjWithCaption."Object Caption");
    end;

    local procedure CalcEndingDate() EndingDate: Date
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if "Ending Date" = 0D then
            EndingDate := WorkDate
        else
            EndingDate := "Ending Date";

        JobLedgerEntry.SetRange("Job No.", "No.");
        JobLedgerEntry.SetCurrentKey("Job No.", "Posting Date");
        if JobLedgerEntry.FindLast then
            if JobLedgerEntry."Posting Date" > EndingDate then
                EndingDate := JobLedgerEntry."Posting Date";

        if "Ending Date" >= EndingDate then
            EndingDate := "Ending Date";
    end;

    procedure UpdateReferencedIds()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled then
            exit;

        TimeSheetLine.SetCurrentKey(Type, "Job No.");
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.SetRange("Job No.", "No.");
        if not TimeSheetLine.IsEmpty() then
            TimeSheetLine.ModifyAll("Job Id", SystemId);

        TimeSheetDetail.SetCurrentKey(Type, "Job No.");
        TimeSheetDetail.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetDetail.SetRange("Job No.", "No.");
        if not TimeSheetDetail.IsEmpty() then
            TimeSheetDetail.ModifyAll("Job Id", SystemId);
    end;

    procedure BilltoContactLookup(): Boolean
    begin
        if ("Bill-to Customer No." <> '') and Cont.Get("Bill-to Contact No.") then
            Cont.SetRange("Company No.", Cont."Company No.")
        else
            if Cust.Get("Bill-to Customer No.") then begin
                if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                    Cont.SetRange("Company No.", ContBusinessRelation."Contact No.");
            end else
                Cont.SetFilter("Company No.", '<>%1', '''');

        if "Bill-to Contact No." <> '' then
            if Cont.Get("Bill-to Contact No.") then;
        if Page.RunModal(0, Cont) = Action::LookupOK then begin
            xRec := Rec;
            Validate("Bill-to Contact No.", Cont."No.");
            exit(true);
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCust(var Job: Record Job)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalcRecognizedProfitAmount(var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Job: Record Job; var xJob: Record Job; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangeJobCompletionStatus(var Job: Record Job; var xJob: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeJobCompletionStatus(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContactBillToCustomerBusRelation(var Job: Record Job; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowContactBillToCustomerBusRelationMissingError(var Job: Record Job; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRemoveFromMyJobsFromModify(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDefaultDimensionsFromCustomer(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitJobNo(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGlobalDimFromDefalutDim(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitBillToCustomerNo(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateJobWIP(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestBlocked(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobTaskDimension(var Job: Record Job; FieldNumber: Integer; ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCustomerNo(var Job: Record Job; var IsHandled: Boolean; xJob: Record Job; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToContactNo(var Job: Record Job; xJob: Record Job; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Job: Record Job; var xJob: Record Job; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCust(var Job: Record Job; xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOverBudgetValue(var Job: Record Job; JobNo: Code[20]; Usage: Boolean; Cost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnAfterAssignBillToContact(var Job: Record Job; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustOnBeforeTestBillToCustomerNo(var Job: Record Job; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustOnBeforeAssignIncoiceCurrencyCode(var Job: Record Job; xJob: Record Job; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;
}


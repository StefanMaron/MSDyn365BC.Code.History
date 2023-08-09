table 1001 "Job Task"
{
    Caption = 'Job Task';
    DrillDownPageID = "Job Task Lines";
    LookupPageID = "Job Task Lines";

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            NotBlank = true;
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            NotBlank = true;

            trigger OnValidate()
            var
                Job: Record Job;
                Cust: Record Customer;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobTaskNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Job Task No." = '' then
                    exit;
                Job.Get("Job No.");
                Job.TestField("Bill-to Customer No.");
                Cust.Get(Job."Bill-to Customer No.");
                "Job Posting Group" := Job."Job Posting Group";
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Job Task Type"; Enum "Job Task Type")
        {
            Caption = 'Job Task Type';

            trigger OnValidate()
            begin
                if (xRec."Job Task Type" = "Job Task Type"::Posting) and
                   ("Job Task Type" <> "Job Task Type"::Posting)
                then
                    if JobLedgEntriesExist() or JobPlanningLinesExist() then
                        Error(CannotChangeAssociatedEntriesErr, FieldCaption("Job Task Type"), TableCaption);

                if "Job Task Type" <> "Job Task Type"::Posting then begin
                    "Job Posting Group" := '';
                    if "WIP-Total" = "WIP-Total"::Excluded then
                        "WIP-Total" := "WIP-Total"::" ";
                end;

                Totaling := '';
            end;
        }
        field(6; "WIP-Total"; Option)
        {
            Caption = 'WIP-Total';
            OptionCaption = ' ,Total,Excluded';
            OptionMembers = " ",Total,Excluded;

            trigger OnValidate()
            var
                Job: Record Job;
            begin
                case "WIP-Total" of
                    "WIP-Total"::Total:
                        begin
                            Job.Get("Job No.");
                            "WIP Method" := Job."WIP Method";
                        end;
                    "WIP-Total"::Excluded:
                        begin
                            TestField("Job Task Type", "Job Task Type"::Posting);
                            "WIP Method" := ''
                        end;
                    else
                        "WIP Method" := ''
                end;
            end;
        }
        field(7; "Job Posting Group"; Code[20])
        {
            Caption = 'Job Posting Group';
            TableRelation = "Job Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobPostingGroup(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Job Posting Group" <> '' then
                    TestField("Job Task Type", "Job Task Type"::Posting);
            end;
        }
        field(9; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            TableRelation = "Job WIP Method".Code WHERE(Valid = CONST(true));

            trigger OnValidate()
            begin
                if "WIP Method" <> '' then
                    TestField("WIP-Total", "WIP-Total"::Total);
            end;
        }
        field(10; "Schedule (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Planning Line"."Total Cost (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                            "Job Task No." = FIELD("Job Task No."),
                                                                            "Job Task No." = FIELD(FILTER(Totaling)),
                                                                            "Schedule Line" = CONST(true),
                                                                            "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Budget (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Schedule (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Planning Line"."Line Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                             "Job Task No." = FIELD("Job Task No."),
                                                                             "Job Task No." = FIELD(FILTER(Totaling)),
                                                                             "Schedule Line" = CONST(true),
                                                                             "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Budget (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Usage (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Ledger Entry"."Total Cost (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                           "Job Task No." = FIELD("Job Task No."),
                                                                           "Job Task No." = FIELD(FILTER(Totaling)),
                                                                           "Entry Type" = CONST(Usage),
                                                                           "Posting Date" = FIELD("Posting Date Filter")));
            Caption = 'Actual (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Usage (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Ledger Entry"."Line Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                            "Job Task No." = FIELD("Job Task No."),
                                                                            "Job Task No." = FIELD(FILTER(Totaling)),
                                                                            "Entry Type" = CONST(Usage),
                                                                            "Posting Date" = FIELD("Posting Date Filter")));
            Caption = 'Actual (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Contract (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Planning Line"."Total Cost (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                            "Job Task No." = FIELD("Job Task No."),
                                                                            "Job Task No." = FIELD(FILTER(Totaling)),
                                                                            "Contract Line" = CONST(true),
                                                                            "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Billable (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Contract (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Planning Line"."Line Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                             "Job Task No." = FIELD("Job Task No."),
                                                                             "Job Task No." = FIELD(FILTER(Totaling)),
                                                                             "Contract Line" = CONST(true),
                                                                             "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Billable (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Contract (Invoiced Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = - Sum("Job Ledger Entry"."Line Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                             "Job Task No." = FIELD("Job Task No."),
                                                                             "Job Task No." = FIELD(FILTER(Totaling)),
                                                                             "Entry Type" = CONST(Sale),
                                                                             "Posting Date" = FIELD("Posting Date Filter")));
            Caption = 'Invoiced (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Contract (Invoiced Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = - Sum("Job Ledger Entry"."Total Cost (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                            "Job Task No." = FIELD("Job Task No."),
                                                                            "Job Task No." = FIELD(FILTER(Totaling)),
                                                                            "Entry Type" = CONST(Sale),
                                                                            "Posting Date" = FIELD("Posting Date Filter")));
            Caption = 'Invoiced (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Planning Date Filter"; Date)
        {
            Caption = 'Planning Date Filter';
            FieldClass = FlowFilter;
        }
        field(21; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if Totaling <> '' then
                    if not ("Job Task Type" in ["Job Task Type"::Total, "Job Task Type"::"End-Total"]) then
                        FieldError("Job Task Type");
                Validate("WIP-Total");
                CalcFields(
                  "Schedule (Total Cost)",
                  "Schedule (Total Price)",
                  "Usage (Total Cost)",
                  "Usage (Total Price)",
                  "Contract (Total Cost)",
                  "Contract (Total Price)",
                  "Contract (Invoiced Price)",
                  "Contract (Invoiced Cost)");
            end;
        }
        field(22; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(23; "No. of Blank Lines"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Blank Lines';
            MinValue = 0;
        }
        field(24; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(34; "Recognized Sales Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Sales Amount';
            Editable = false;
        }
        field(37; "Recognized Costs Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Costs Amount';
            Editable = false;
        }
        field(56; "Recognized Sales G/L Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Sales G/L Amount';
            Editable = false;
        }
        field(57; "Recognized Costs G/L Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Costs G/L Amount';
            Editable = false;
        }
        field(60; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(61; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(62; "Outstanding Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum("Purchase Line"."Outstanding Amt. Ex. VAT (LCY)" WHERE("Document Type" = CONST(Order),
                                                                                      "Job No." = FIELD("Job No."),
                                                                                      "Job Task No." = FIELD("Job Task No."),
                                                                                      "Job Task No." = FIELD(FILTER(Totaling))));
            Caption = 'Outstanding Orders';
            FieldClass = FlowField;
        }
        field(63; "Amt. Rcd. Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum("Purchase Line"."A. Rcd. Not Inv. Ex. VAT (LCY)" WHERE("Document Type" = CONST(Order),
                                                                                      "Job No." = FIELD("Job No."),
                                                                                      "Job Task No." = FIELD("Job Task No."),
                                                                                      "Job Task No." = FIELD(FILTER(Totaling))));
            Caption = 'Amt. Rcd. Not Invoiced';
            FieldClass = FlowField;
        }
        field(64; "Remaining (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Planning Line"."Remaining Total Cost (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                                      "Job Task No." = FIELD("Job Task No."),
                                                                                      "Job Task No." = FIELD(FILTER(Totaling)),
                                                                                      "Schedule Line" = CONST(true),
                                                                                      "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Remaining (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "Remaining (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Job Planning Line"."Remaining Line Amount (LCY)" WHERE("Job No." = FIELD("Job No."),
                                                                                       "Job Task No." = FIELD("Job Task No."),
                                                                                       "Job Task No." = FIELD(FILTER(Totaling)),
                                                                                       "Schedule Line" = CONST(true),
                                                                                       "Planning Date" = FIELD("Planning Date Filter")));
            Caption = 'Remaining (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Start Date"; Date)
        {
            CalcFormula = Min("Job Planning Line"."Planning Date" WHERE("Job No." = FIELD("Job No."),
                                                                         "Job Task No." = FIELD("Job Task No.")));
            Caption = 'Start Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(67; "End Date"; Date)
        {
            CalcFormula = Max("Job Planning Line"."Planning Date" WHERE("Job No." = FIELD("Job No."),
                                                                         "Job Task No." = FIELD("Job Task No.")));
            Caption = 'End Date';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.")
        {
            Clustered = true;
        }
        key(Key2; "Job Task No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", Description, "Job Task Type")
        {
        }
        fieldgroup(Brick; "Job Task No.", Description)
        {
        }
    }

    trigger OnDelete()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobWIPTotal: Record "Job WIP Total";
        JobTaskDim: Record "Job Task Dimension";
    begin
        if JobLedgEntriesExist() then
            Error(CannotDeleteAssociatedEntriesErr, TableCaption);

        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobPlanningLine.SetRange("Job No.", "Job No.");
        JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
        JobPlanningLine.DeleteAll(true);

        JobWIPTotal.DeleteEntriesForJobTask(Rec);

        JobTaskDim.SetRange("Job No.", "Job No.");
        JobTaskDim.SetRange("Job Task No.", "Job Task No.");
        if not JobTaskDim.IsEmpty() then
            JobTaskDim.DeleteAll();

        CalcFields("Schedule (Total Cost)", "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", true, "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", false, "Schedule (Total Cost)");
    end;

    trigger OnInsert()
    var
        Job: Record Job;
        Cust: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        LockTable();
        Job.Get("Job No.");
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked();
        Job.TestField("Bill-to Customer No.");
        Cust.Get(Job."Bill-to Customer No.");

        DimMgt.InsertJobTaskDim("Job No.", "Job Task No.", "Global Dimension 1 Code", "Global Dimension 2 Code");

        CalcFields("Schedule (Total Cost)", "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", true, "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", false, "Schedule (Total Cost)");

        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Schedule (Total Cost)", "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", true, "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", false, "Schedule (Total Cost)");
    end;

    var
        Job: Record Job;
        DimMgt: Codeunit DimensionManagement;

        CannotDeleteAssociatedEntriesErr: Label 'You cannot delete %1 because one or more entries are associated.', Comment = '%1=The job task table name.';
        CannotChangeAssociatedEntriesErr: Label 'You cannot change %1 because one or more entries are associated with this %2.', Comment = '%1 = The field name you are trying to change; %2 = The job task table name.';

    procedure CalcEACTotalCost(): Decimal
    begin
        if "Job No." <> Job."No." then
            if not Job.Get("Job No.") then
                exit(0);

        if Job."Apply Usage Link" then
            exit("Usage (Total Cost)" + "Remaining (Total Cost)");

        exit(0);
    end;

    procedure CalcEACTotalPrice(): Decimal
    begin
        if "Job No." <> Job."No." then
            if not Job.Get("Job No.") then
                exit(0);

        if Job."Apply Usage Link" then
            exit("Usage (Total Price)" + "Remaining (Total Price)");

        exit(0);
    end;

    local procedure JobLedgEntriesExist(): Boolean
    var
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        JobLedgEntry.SetCurrentKey("Job No.", "Job Task No.");
        JobLedgEntry.SetRange("Job No.", "Job No.");
        JobLedgEntry.SetRange("Job Task No.", "Job Task No.");
        OnJobLedgEntriesExistOnAfterSetFilter(Rec, JobLedgEntry);
        exit(JobLedgEntry.FindFirst());
    end;

    local procedure JobPlanningLinesExist(): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobPlanningLine.SetRange("Job No.", "Job No.");
        JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
        exit(JobPlanningLine.FindFirst());
    end;

    procedure Caption(): Text
    var
        Job: Record Job;
        Result: Text;
        IsHandled: Boolean;
    begin
        Result := '';
        IsHandled := false;
        OnBeforeCaption(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if not Job.Get("Job No.") then
            exit('');
        exit(StrSubstNo('%1 %2 %3 %4',
            Job."No.",
            Job.Description,
            "Job Task No.",
            Description));
    end;

    procedure InitWIPFields()
    var
        JobWIPTotal: Record "Job WIP Total";
    begin
        JobWIPTotal.SetRange("Job No.", "Job No.");
        JobWIPTotal.SetRange("Job Task No.", "Job Task No.");
        JobWIPTotal.SetRange("Posted to G/L", false);
        JobWIPTotal.DeleteAll(true);

        "Recognized Sales Amount" := 0;
        "Recognized Costs Amount" := 0;

        OnInitWIPFieldsOnBeforeModify(Rec);
        Modify();
    end;

    procedure ToPriceSource(var PriceSource: Record "Price Source"; PriceType: Enum "Price Type")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceType;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.Validate("Parent Source No.", "Job No.");
        PriceSource.Validate("Source No.", "Job Task No.");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        JobTask2: Record "Job Task";
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, JobTask2);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if JobTask2.Get("Job No.", "Job Task No.") then begin
            DimMgt.SaveJobTaskDim("Job No.", "Job Task No.", FieldNumber, ShortcutDimCode);
            Modify();
        end else
            DimMgt.SaveJobTaskTempDim(FieldNumber, ShortcutDimCode);

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ClearTempDim()
    begin
        DimMgt.DeleteJobTaskTempDim();
    end;

    procedure ApplyPurchaseLineFilters(var PurchLine: Record "Purchase Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        PurchLine.SetCurrentKey("Document Type", "Job No.", "Job Task No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Job No.", JobNo);
        if "Job Task Type" in ["Job Task Type"::Total, "Job Task Type"::"End-Total"] then
            PurchLine.SetFilter("Job Task No.", Totaling)
        else
            PurchLine.SetRange("Job Task No.", JobTaskNo);
        OnAfterApplyPurchaseLineFilters(Rec, PurchLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPurchaseLineFilters(var JobTask: Record "Job Task"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var JobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobTaskNo(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobPostingGroup(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; JobTask2: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWIPFieldsOnBeforeModify(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobLedgEntriesExistOnAfterSetFilter(var JobTask: Record "Job Task"; var JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCaption(JobTask: Record "Job Task"; var IsHandled: Boolean; var Result: Text)
    begin
    end;
}


table 1022 "Job Planning Line Invoice"
{
    Caption = 'Job Planning Line Invoice';
    DrillDownPageID = "Job Invoices";
    LookupPageID = "Job Invoices";

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            Editable = false;
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(3; "Job Planning Line No."; Integer)
        {
            Caption = 'Job Planning Line No.';
            Editable = false;
            TableRelation = "Job Planning Line"."Line No." WHERE("Job No." = FIELD("Job No."),
                                                                  "Job Task No." = FIELD("Job Task No."));
        }
        field(4; "Document Type"; Enum "Job Planning Line Invoice Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; "Quantity Transferred"; Decimal)
        {
            Caption = 'Quantity Transferred';
            Editable = false;
        }
        field(8; "Transferred Date"; Date)
        {
            Caption = 'Transferred Date';
            Editable = false;
        }
        field(9; "Invoiced Date"; Date)
        {
            Caption = 'Invoiced Date';
            Editable = false;
        }
        field(10; "Invoiced Amount (LCY)"; Decimal)
        {
            Caption = 'Invoiced Amount (LCY)';
            Editable = false;
        }
        field(11; "Invoiced Cost Amount (LCY)"; Decimal)
        {
            Caption = 'Invoiced Cost Amount (LCY)';
            Editable = false;
        }
        field(12; "Job Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Job Ledger Entry No.';
            Editable = false;
            TableRelation = "Job Ledger Entry";
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Job Planning Line No.", "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Job Ledger Entry No.")
        {
        }
        key(Key3; "Job No.", "Job Planning Line No.", "Job Task No.", "Document Type")
        {
            MaintainSqlIndex = false;
            SumIndexFields = "Quantity Transferred", "Invoiced Amount (LCY)", "Invoiced Cost Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    procedure InitFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        "Job No." := JobPlanningLine."Job No.";
        "Job Task No." := JobPlanningLine."Job Task No.";
        "Job Planning Line No." := JobPlanningLine."Line No.";
        "Quantity Transferred" := JobPlanningLine."Qty. to Transfer to Invoice";

        OnAfterInitFromJobPlanningLine(Rec, JobPlanningLine);
    end;

    procedure InitFromSales(SalesHeader: Record "Sales Header"; PostingDate: Date; LineNo: Integer)
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            "Document Type" := "Document Type"::Invoice;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            "Document Type" := "Document Type"::"Credit Memo";
        "Document No." := SalesHeader."No.";
        "Line No." := LineNo;
        "Transferred Date" := PostingDate
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobPlanningLine(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;
}


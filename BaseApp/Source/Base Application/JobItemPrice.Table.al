table 1013 "Job Item Price"
{
    Caption = 'Job Item Price';
    DrillDownPageID = "Job Item Prices";
    LookupPageID = "Job Item Prices";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            NotBlank = true;
            TableRelation = Job;

            trigger OnValidate()
            begin
                GetJob;
                "Currency Code" := Job."Currency Code";
            end;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));

            trigger OnValidate()
            begin
                if "Job Task No." <> '' then begin
                    JT.Get("Job No.", "Job Task No.");
                    JT.TestField("Job Task Type", JT."Job Task Type"::Posting);
                end;
            end;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                Item.Get("Item No.");
                Validate("Unit of Measure Code", Item."Sales Unit of Measure");
            end;
        }
        field(4; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                "Unit Cost Factor" := 0;
            end;
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> xRec."Currency Code" then begin
                    "Unit Cost Factor" := 0;
                    "Line Discount %" := 0;
                    "Unit Price" := 0;
                end;
            end;
        }
        field(7; "Unit Cost Factor"; Decimal)
        {
            Caption = 'Unit Cost Factor';

            trigger OnValidate()
            begin
                "Unit Price" := 0;
            end;
        }
        field(8; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
        }
        field(9; Description; Text[100])
        {
            CalcFormula = Lookup (Item.Description WHERE("No." = FIELD("Item No.")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(11; "Apply Job Price"; Boolean)
        {
            Caption = 'Apply Job Price';
            InitValue = true;
        }
        field(12; "Apply Job Discount"; Boolean)
        {
            Caption = 'Apply Job Discount';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Item No.", "Variant Code", "Unit of Measure Code", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        Job.Get("Job No.");
        TestField("Item No.");
    end;

    var
        Item: Record Item;
        Job: Record Job;
        JT: Record "Job Task";

    local procedure GetJob()
    begin
        TestField("Job No.");
        Job.Get("Job No.");
    end;
}


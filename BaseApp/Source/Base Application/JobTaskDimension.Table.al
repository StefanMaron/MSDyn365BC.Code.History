table 1002 "Job Task Dimension"
{
    Caption = 'Job Task Dimension';

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Job Task"."Job No.";
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            NotBlank = true;
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            TableRelation = Dimension.Code;

            trigger OnValidate()
            begin
                if not DimMgt.CheckDim("Dimension Code") then
                    Error(DimMgt.GetDimErr);
                "Dimension Value Code" := '';
            end;
        }
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Dimension Code"));

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr);
            end;
        }
        field(5; "Multiple Selection Action"; Option)
        {
            Caption = 'Multiple Selection Action';
            OptionCaption = ' ,Change,Delete';
            OptionMembers = " ",Change,Delete;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        UpdateGlobalDim('');
    end;

    trigger OnInsert()
    begin
        if "Dimension Value Code" = '' then
            Error(Text001, TableCaption);

        UpdateGlobalDim("Dimension Value Code");
    end;

    trigger OnModify()
    begin
        UpdateGlobalDim("Dimension Value Code");
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'At least one dimension value code must have a value. Enter a value or delete the %1. ';

    procedure UpdateGlobalDim(DimensionValue: Code[20])
    var
        JobTask: Record "Job Task";
        GLSEtup: Record "General Ledger Setup";
    begin
        GLSEtup.Get();
        if "Dimension Code" = GLSEtup."Global Dimension 1 Code" then begin
            JobTask.Get("Job No.", "Job Task No.");
            JobTask."Global Dimension 1 Code" := DimensionValue;
            JobTask.Modify(true);
        end else
            if "Dimension Code" = GLSEtup."Global Dimension 2 Code" then begin
                JobTask.Get("Job No.", "Job Task No.");
                JobTask."Global Dimension 2 Code" := DimensionValue;
                JobTask.Modify(true);
            end;
    end;
}


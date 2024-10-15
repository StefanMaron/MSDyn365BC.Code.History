namespace Microsoft.Manufacturing.Routing;

table 99000778 "Standard Task"
{
    Caption = 'Standard Task';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Standard Tasks";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StdTaskTool: Record "Standard Task Tool";
        StdTaskPersonnel: Record "Standard Task Personnel";
        StdTaskDescript: Record "Standard Task Description";
        StdTaskQltyMeasure: Record "Standard Task Quality Measure";
    begin
        StdTaskTool.SetRange("Standard Task Code", Code);
        StdTaskTool.DeleteAll();

        StdTaskPersonnel.SetRange("Standard Task Code", Code);
        StdTaskPersonnel.DeleteAll();

        StdTaskDescript.SetRange("Standard Task Code", Code);
        StdTaskDescript.DeleteAll();

        StdTaskQltyMeasure.SetRange("Standard Task Code", Code);
        StdTaskQltyMeasure.DeleteAll();
    end;
}


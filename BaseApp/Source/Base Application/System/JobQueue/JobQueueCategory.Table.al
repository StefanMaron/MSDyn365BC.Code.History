namespace System.Threading;

table 471 "Job Queue Category"
{
    Caption = 'Job Queue Category';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Job Queue Category List";
    LookupPageID = "Job Queue Category List";
    Permissions = TableData "Job Queue Category" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
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

    procedure InsertRec(CodeToInsert: Code[10]; DescriptionToInsert: Text[30])
    begin
        if Get(CodeToInsert) then
            exit;

        Code := CodeToInsert;
        Description := DescriptionToInsert;
        Insert();
    end;
}


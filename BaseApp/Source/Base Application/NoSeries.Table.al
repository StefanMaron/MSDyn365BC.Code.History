table 308 "No. Series"
{
    Caption = 'No. Series';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "No. Series List";
    LookupPageID = "No. Series List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Nos."; Boolean)
        {
            Caption = 'Default Nos.';

            trigger OnValidate()
            begin
                if ("Default Nos." = false) and (xRec."Default Nos." <> "Default Nos.") and ("Manual Nos." = false) then
                    Validate("Manual Nos.", true);
            end;
        }
        field(4; "Manual Nos."; Boolean)
        {
            Caption = 'Manual Nos.';

            trigger OnValidate()
            begin
                if ("Manual Nos." = false) and (xRec."Manual Nos." <> "Manual Nos.") and ("Default Nos." = false) then
                    Validate("Default Nos.", true);
            end;
        }
        field(5; "Date Order"; Boolean)
        {
            Caption = 'Date Order';

            trigger OnValidate()
            var
                NoSeriesLine: Record "No. Series Line";
            begin
                if not "Date Order" then
                    exit;
                FindNoSeriesLineToShow(NoSeriesLine);
                if not NoSeriesLine.FindFirst then
                    exit;
                if NoSeriesLine."Allow Gaps in Nos." then
                    Error(AllowGapsNotAllowedWithDateOrderErr);
            end;
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
    begin
        NoSeriesLine.SetRange("Series Code", Code);
        NoSeriesLine.DeleteAll();

        NoSeriesRelationship.SetRange(Code, Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange(Code);

        NoSeriesRelationship.SetRange("Series Code", Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange("Series Code");
    end;

    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
        AllowGapsNotAllowedWithDateOrderErr: Label 'The Date Order setting is not possible for this number series because the Allow Gaps in Nos. check box is selected on one of the number series lines.';

    procedure DrillDown()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        FindNoSeriesLineToShow(NoSeriesLine);
        if NoSeriesLine.Find('-') then;
        NoSeriesLine.SetRange("Starting Date");
        NoSeriesLine.SetRange(Open);
        PAGE.RunModal(0, NoSeriesLine);
    end;

    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        FindNoSeriesLineToShow(NoSeriesLine);
        if not NoSeriesLine.Find('-') then
            NoSeriesLine.Init();
        StartDate := NoSeriesLine."Starting Date";
        StartNo := NoSeriesLine."Starting No.";
        EndNo := NoSeriesLine."Ending No.";
        LastNoUsed := NoSeriesLine.GetLastNoUsed;
        WarningNo := NoSeriesLine."Warning No.";
        IncrementByNo := NoSeriesLine."Increment-by No.";
        LastDateUsed := NoSeriesLine."Last Date Used";
    end;

    local procedure FindNoSeriesLineToShow(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, Code, 0D);

        if NoSeriesLine.FindLast then
            exit;

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", Code);
    end;
}


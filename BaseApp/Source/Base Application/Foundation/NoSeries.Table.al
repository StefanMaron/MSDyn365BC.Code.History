table 308 "No. Series"
{
    Caption = 'No. Series';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "No. Series";
    LookupPageID = "No. Series";

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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDefaultNos(Rec, IsHandled);
                if not IsHandled then
                    if ("Default Nos." = false) and (xRec."Default Nos." <> "Default Nos.") and ("Manual Nos." = false) then
                        Validate("Manual Nos.", true);
            end;
        }
        field(4; "Manual Nos."; Boolean)
        {
            Caption = 'Manual Nos.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateManualNos(Rec, IsHandled);
                if not IsHandled then
                    if ("Manual Nos." = false) and (xRec."Manual Nos." <> "Manual Nos.") and ("Default Nos." = false) then
                        Validate("Default Nos.", true);
            end;
        }
        field(5; "Date Order"; Boolean)
        {
            Caption = 'Date Order';
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
        fieldgroup(DropDown; Code, Description)
        {
        }
    }

    trigger OnDelete()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
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
        AllowGaps: Boolean;
    begin
        UpdateLine(StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;

    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        FindNoSeriesLineToShow(NoSeriesLine);
        if not NoSeriesLine.Find('-') then
            NoSeriesLine.Init();
        StartDate := NoSeriesLine."Starting Date";
        StartNo := NoSeriesLine."Starting No.";
        EndNo := NoSeriesLine."Ending No.";
        LastNoUsed := NoSeriesLine.GetLastNoUsed();
        WarningNo := NoSeriesLine."Warning No.";
        IncrementByNo := NoSeriesLine."Increment-by No.";
        LastDateUsed := NoSeriesLine."Last Date Used";
        AllowGaps := NoSeriesLine."Allow Gaps in Nos.";
    end;

    procedure FindNoSeriesLineToShow(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeriesManagement.SetNoSeriesLineFilter(NoSeriesLine, Code, 0D);

        if NoSeriesLine.FindLast() then
            exit;

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", Code);
    end;

    internal procedure SetAllowGaps(AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        StartDate: Date;
    begin
        FindNoSeriesLineToShow(NoSeriesLine);
        StartDate := NoSeriesLine."Starting Date";
        NoSeriesLine.SetRange("Allow Gaps in Nos.", not AllowGaps);
        NoSeriesLine.SetFilter("Starting Date", '>=%1', StartDate);
        NoSeriesLine.LockTable();
        if NoSeriesLine.FindSet() then
            repeat
                NoSeriesLine.Validate("Allow Gaps in Nos.", AllowGaps);
                NoSeriesLine.Modify();
            until NoSeriesLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDefaultNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateManualNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;
}


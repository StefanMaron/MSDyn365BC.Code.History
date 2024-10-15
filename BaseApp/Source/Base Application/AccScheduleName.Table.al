table 84 "Acc. Schedule Name"
{
    Caption = 'Acc. Schedule Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Account Schedule Names";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(3; "Default Column Layout"; Code[10])
        {
            Caption = 'Default Column Layout';
            TableRelation = "Column Layout Name";
        }
        field(4; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View Name';
            TableRelation = "Analysis View";
        }
        field(31080; "Acc. Schedule Type"; Option)
        {
            Caption = 'Acc. Schedule Type';
            OptionCaption = ' ,Balance Sheet,Income Statement';
            OptionMembers = " ","Balance Sheet","Income Statement";
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AccScheduleResultHeader: Record "Acc. Schedule Result Header";
    begin
        // NAVCZ
        if IsResultsExist(Name) then
            if Confirm(Text26570, false, GetRecordDescription(Name)) then begin
                AccScheduleResultHeader.SetRange("Acc. Schedule Name", Name);
                AccScheduleResultHeader.DeleteAll(true);
            end;
        // NAVCZ

        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll();
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        Text26570: Label '%1 has results. Do you want to delete it anyway?';

    [Scope('OnPrem')]
    procedure IsResultsExist(AccSchedName: Code[10]): Boolean
    var
        AccScheduleResultHeader: Record "Acc. Schedule Result Header";
    begin
        // NAVCZ
        AccScheduleResultHeader.SetRange("Acc. Schedule Name", AccSchedName);
        exit(not AccScheduleResultHeader.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetRecordDescription(AccSchedName: Code[10]): Text[100]
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        // NAVCZ
        AccScheduleName.Get(AccSchedName);
        exit(StrSubstNo('%1 %2=''%3''', AccScheduleName.TableCaption, FieldCaption(Name), AccSchedName));
    end;

    procedure Print()
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrint(Rec, IsHandled);
        if IsHandled then
            exit;

        AccountSchedule.SetAccSchedName(Name);
        AccountSchedule.SetColumnLayoutName("Default Column Layout");
        AccountSchedule.Run;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var AccScheduleName: Record "Acc. Schedule Name"; var IsHandled: Boolean)
    begin
    end;
}


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
        field(10700; Standardized; Boolean)
        {
            Caption = 'Standardized';
        }
        field(10720; "Acc. No. Referred to old Acc."; Boolean)
        {
            Caption = 'Acc. No. Referred to old Acc.';
            ObsoleteReason = 'Obsolete features';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
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
    begin
        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll;
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";

    procedure Print()
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrint(Rec, IsHandled);
        if IsHandled then
            exit;

        if Standardized then
            REPORT.Run(REPORT::"Normalized Account Schedule", true, false, Rec)
        else begin
            AccountSchedule.SetAccSchedName(Name);
            AccountSchedule.SetColumnLayoutName("Default Column Layout");
            AccountSchedule.Run;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var AccScheduleName: Record "Acc. Schedule Name"; var IsHandled: Boolean)
    begin
    end;
}


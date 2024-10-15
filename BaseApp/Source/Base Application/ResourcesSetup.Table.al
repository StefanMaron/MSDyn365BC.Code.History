table 314 "Resources Setup"
{
    Caption = 'Resources Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Resource Nos."; Code[20])
        {
            Caption = 'Resource Nos.';
            TableRelation = "No. Series";
        }
        field(950; "Time Sheet Nos."; Code[20])
        {
            Caption = 'Time Sheet Nos.';
            TableRelation = "No. Series";
        }
        field(951; "Time Sheet First Weekday"; Option)
        {
            Caption = 'Time Sheet First Weekday';
            OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;

            trigger OnValidate()
            begin
                if "Time Sheet First Weekday" <> xRec."Time Sheet First Weekday" then begin
                    TimeSheetHeader.Reset();
                    if not TimeSheetHeader.IsEmpty then
                        Error(Text002, FieldCaption("Time Sheet First Weekday"));
                end;
            end;
        }
        field(952; "Time Sheet by Job Approval"; Option)
        {
            Caption = 'Time Sheet by Job Approval';
            OptionCaption = 'Never,Machine Only,Always';
            OptionMembers = Never,"Machine Only",Always;

            trigger OnValidate()
            begin
                if "Time Sheet by Job Approval" <> xRec."Time Sheet by Job Approval" then begin
                    TimeSheetLine.Reset();
                    TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
                    TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Submitted);
                    if not TimeSheetLine.IsEmpty then
                        Error(Text001, FieldCaption("Time Sheet by Job Approval"));
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Text001: Label '%1 cannot be changed, because there is at least one submitted time sheet line with Type=Job.';
        Text002: Label '%1 cannot be changed, because there is at least one time sheet.';
}


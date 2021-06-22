table 7600 "Base Calendar"
{
    Caption = 'Base Calendar';
    DataCaptionFields = "Code", Name;
    LookupPageID = "Base Calendar List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; "Customized Changes Exist"; Boolean)
        {
            CalcFormula = Exist ("Customized Calendar Change" WHERE("Base Calendar Code" = FIELD(Code)));
            Caption = 'Customized Changes Exist';
            Editable = false;
            FieldClass = FlowField;
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
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        CustomizedCalendarChange.SetRange("Base Calendar Code", Code);
        if not CustomizedCalendarChange.IsEmpty then
            Error(Text001, Code);

        BaseCalendarLine.Reset();
        BaseCalendarLine.SetRange("Base Calendar Code", Code);
        BaseCalendarLine.DeleteAll();
    end;

    var
        BaseCalendarLine: Record "Base Calendar Change";
        Text001: Label 'You cannot delete this record. Customized calendar changes exist for calendar code=<%1>.';
}


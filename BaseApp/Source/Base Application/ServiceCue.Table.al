table 9052 "Service Cue"
{
    Caption = 'Service Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Service Orders - in Process"; Integer)
        {
            CalcFormula = Count ("Service Header" WHERE("Document Type" = FILTER(Order),
                                                        Status = FILTER("In Process"),
                                                        "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Service Orders - in Process';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Service Orders - Finished"; Integer)
        {
            CalcFormula = Count ("Service Header" WHERE("Document Type" = FILTER(Order),
                                                        Status = FILTER(Finished),
                                                        "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Service Orders - Finished';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Service Orders - Inactive"; Integer)
        {
            CalcFormula = Count ("Service Header" WHERE("Document Type" = FILTER(Order),
                                                        Status = FILTER(Pending | "On Hold"),
                                                        "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Service Orders - Inactive';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Open Service Quotes"; Integer)
        {
            CalcFormula = Count ("Service Header" WHERE("Document Type" = FILTER(Quote),
                                                        Status = FILTER(Pending | "On Hold"),
                                                        "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Open Service Quotes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Open Service Contract Quotes"; Integer)
        {
            CalcFormula = Count ("Service Contract Header" WHERE("Contract Type" = FILTER(Quote),
                                                                 Status = FILTER(" "),
                                                                 "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Open Service Contract Quotes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Service Contracts to Expire"; Integer)
        {
            CalcFormula = Count ("Service Contract Header" WHERE("Contract Type" = FILTER(Contract),
                                                                 "Expiration Date" = FIELD("Date Filter"),
                                                                 "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Service Contracts to Expire';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Service Orders - Today"; Integer)
        {
            CalcFormula = Count ("Service Header" WHERE("Document Type" = FILTER(Order),
                                                        "Response Date" = FIELD("Date Filter"),
                                                        "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Service Orders - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Service Orders - to Follow-up"; Integer)
        {
            CalcFormula = Count ("Service Header" WHERE("Document Type" = FILTER(Order),
                                                        Status = FILTER("In Process"),
                                                        "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Service Orders - to Follow-up';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Responsibility Center Filter"; Code[10])
        {
            Caption = 'Responsibility Center Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
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

    procedure SetRespCenterFilter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        RespCenterCode: Code[10];
    begin
        RespCenterCode := UserSetupMgt.GetServiceFilter;
        if RespCenterCode <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center Filter", RespCenterCode);
            FilterGroup(0);
        end;
    end;
}


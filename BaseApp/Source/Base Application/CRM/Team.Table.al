table 5083 Team
{
    Caption = 'Team';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = Teams;
    LookupPageID = Teams;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Next Task Date"; Date)
        {
            CalcFormula = Min("To-do".Date WHERE("Team Code" = FIELD(Code),
                                                  Closed = CONST(false)));
            Caption = 'Next Task Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(6; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(7; "Task Status Filter"; Enum "Task Status")
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
        }
        field(8; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(11; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(12; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(13; "Task Entry Exists"; Boolean)
        {
            CalcFormula = Exist("To-do" WHERE("Team Code" = FIELD(Code),
                                               "Contact No." = FIELD("Contact Filter"),
                                               "Contact Company No." = FIELD("Contact Company Filter"),
                                               "Salesperson Code" = FIELD("Salesperson Filter"),
                                               "Campaign No." = FIELD("Campaign Filter"),
                                               Status = FIELD("Task Status Filter"),
                                               Closed = FIELD("Task Closed Filter"),
                                               Priority = FIELD("Priority Filter"),
                                               Date = FIELD("Date Filter")));
            Caption = 'Task Entry Exists';
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
        TeamSalesperson: Record "Team Salesperson";
    begin
        TeamSalesperson.Reset();
        TeamSalesperson.SetRange("Team Code", Code);
        TeamSalesperson.DeleteAll();
    end;
}


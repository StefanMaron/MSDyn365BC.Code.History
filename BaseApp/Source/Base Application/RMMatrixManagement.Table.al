table 5102 "RM Matrix Management"
{
    Caption = 'RM Matrix Management';

    fields
    {
        field(1; "Company Name"; Text[50])
        {
            Caption = 'Company Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Company,Person';
            OptionMembers = Company,Person;
        }
        field(5; "No. of Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE(Active = CONST(true),
                                                           "Salesperson Code" = FIELD("Salesperson Filter"),
                                                           "Campaign No." = FIELD("Campaign Filter"),
                                                           "Contact No." = FIELD("Contact Filter"),
                                                           "Contact Company No." = FIELD("Contact Company Filter"),
                                                           "Estimated Close Date" = FIELD("Date Filter"),
                                                           "Action Taken" = FIELD("Action Taken Filter"),
                                                           "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                           "Probability %" = FIELD("Probability % Filter"),
                                                           "Completed %" = FIELD("Completed % Filter"),
                                                           "Chances of Success %" = FIELD("Chances of Success % Filter"),
                                                           "Close Opportunity Code" = FIELD("Close Opportunity Filter"),
                                                           "Estimated Value (LCY)" = FIELD("Estimated Value Filter"),
                                                           "Calcd. Current Value (LCY)" = FIELD("Calcd. Current Value Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Estimated Value (LCY)" WHERE(Active = CONST(true),
                                                                                 "Salesperson Code" = FIELD("Salesperson Filter"),
                                                                                 "Campaign No." = FIELD("Campaign Filter"),
                                                                                 "Contact No." = FIELD("Contact Filter"),
                                                                                 "Contact Company No." = FIELD("Contact Company Filter"),
                                                                                 "Estimated Close Date" = FIELD("Date Filter"),
                                                                                 "Action Taken" = FIELD("Action Taken Filter"),
                                                                                 "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                 "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                 "Probability %" = FIELD("Probability % Filter"),
                                                                                 "Completed %" = FIELD("Completed % Filter"),
                                                                                 "Chances of Success %" = FIELD("Chances of Success % Filter"),
                                                                                 "Close Opportunity Code" = FIELD("Close Opportunity Filter"),
                                                                                 "Estimated Value (LCY)" = FIELD("Estimated Value Filter"),
                                                                                 "Calcd. Current Value (LCY)" = FIELD("Calcd. Current Value Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE(Active = CONST(true),
                                                                                      "Salesperson Code" = FIELD("Salesperson Filter"),
                                                                                      "Campaign No." = FIELD("Campaign Filter"),
                                                                                      "Contact No." = FIELD("Contact Filter"),
                                                                                      "Contact Company No." = FIELD("Contact Company Filter"),
                                                                                      "Estimated Close Date" = FIELD("Date Filter"),
                                                                                      "Action Taken" = FIELD("Action Taken Filter"),
                                                                                      "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                      "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                      "Probability %" = FIELD("Probability % Filter"),
                                                                                      "Completed %" = FIELD("Completed % Filter"),
                                                                                      "Chances of Success %" = FIELD("Chances of Success % Filter"),
                                                                                      "Close Opportunity Code" = FIELD("Close Opportunity Filter"),
                                                                                      "Estimated Value (LCY)" = FIELD("Estimated Value Filter"),
                                                                                      "Calcd. Current Value (LCY)" = FIELD("Calcd. Current Value Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Avg. Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Average ("Opportunity Entry"."Estimated Value (LCY)" WHERE(Active = CONST(true),
                                                                                     "Salesperson Code" = FIELD("Salesperson Filter"),
                                                                                     "Campaign No." = FIELD("Campaign Filter"),
                                                                                     "Contact No." = FIELD("Contact Filter"),
                                                                                     "Contact Company No." = FIELD("Contact Company Filter"),
                                                                                     "Estimated Close Date" = FIELD("Date Filter"),
                                                                                     "Action Taken" = FIELD("Action Taken Filter"),
                                                                                     "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                     "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                     "Probability %" = FIELD("Probability % Filter"),
                                                                                     "Completed %" = FIELD("Completed % Filter"),
                                                                                     "Chances of Success %" = FIELD("Chances of Success % Filter"),
                                                                                     "Close Opportunity Code" = FIELD("Close Opportunity Filter"),
                                                                                     "Estimated Value (LCY)" = FIELD("Estimated Value Filter"),
                                                                                     "Calcd. Current Value (LCY)" = FIELD("Calcd. Current Value Filter")));
            Caption = 'Avg. Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Avg.Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Average ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE(Active = CONST(true),
                                                                                          "Salesperson Code" = FIELD("Salesperson Filter"),
                                                                                          "Campaign No." = FIELD("Campaign Filter"),
                                                                                          "Contact No." = FIELD("Contact Filter"),
                                                                                          "Contact Company No." = FIELD("Contact Company Filter"),
                                                                                          "Estimated Close Date" = FIELD("Date Filter"),
                                                                                          "Action Taken" = FIELD("Action Taken Filter"),
                                                                                          "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                          "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                          "Probability %" = FIELD("Probability % Filter"),
                                                                                          "Completed %" = FIELD("Completed % Filter"),
                                                                                          "Close Opportunity Code" = FIELD("Close Opportunity Filter"),
                                                                                          "Chances of Success %" = FIELD("Chances of Success % Filter"),
                                                                                          "Estimated Value (LCY)" = FIELD("Estimated Value Filter"),
                                                                                          "Calcd. Current Value (LCY)" = FIELD("Calcd. Current Value Filter")));
            Caption = 'Avg.Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(11; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(12; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Action Taken Filter"; Option)
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Next,Previous,Updated,Jumped,Won,Lost';
            OptionMembers = " ",Next,Previous,Updated,Jumped,Won,Lost;
        }
        field(15; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(16; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage WHERE("Sales Cycle Code" = FIELD("Sales Cycle Filter"));
        }
        field(17; "Probability % Filter"; Decimal)
        {
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(18; "Completed % Filter"; Decimal)
        {
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(19; "Company No."; Code[20])
        {
            Caption = 'Company No.';
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(20; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(21; "Task Status Filter"; Option)
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Not Started,In Progress,Completed,Waiting,Postponed';
            OptionMembers = "Not Started","In Progress",Completed,Waiting,Postponed;
        }
        field(22; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(23; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(24; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(25; "No. of Tasks"; Integer)
        {
            CalcFormula = Count ("To-do" WHERE(Date = FIELD("Date Filter"),
                                               "Salesperson Code" = FIELD("Salesperson Filter"),
                                               "Team Code" = FIELD("Team Filter"),
                                               "Campaign No." = FIELD("Campaign Filter"),
                                               "Contact No." = FIELD("Contact Filter"),
                                               "Contact Company No." = FIELD("Contact Company Filter"),
                                               Status = FIELD("Task Status Filter"),
                                               Closed = FIELD("Task Closed Filter"),
                                               Priority = FIELD("Priority Filter"),
                                               "System To-do Type" = FIELD("System Task Type Filter")));
            Caption = 'No. of Tasks';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Estimated Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(27; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(28; "Chances of Success % Filter"; Decimal)
        {
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(29; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(30; "System Task Type Filter"; Option)
        {
            Caption = 'System Task Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Organizer,Salesperson Attendee,Contact Attendee,Team';
            OptionMembers = Organizer,"Salesperson Attendee","Contact Attendee",Team;
        }
    }

    keys
    {
        key(Key1; "Company Name", Type, Name, "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


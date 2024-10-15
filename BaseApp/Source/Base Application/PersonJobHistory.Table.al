table 17354 "Person Job History"
{
    Caption = 'Person Job History';

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if "Insured Period Starting Date" = 0D then
                    Validate("Insured Period Starting Date", "Starting Date");
            end;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if "Insured Period Ending Date" = 0D then
                    Validate("Insured Period Ending Date", "Ending Date");
            end;
        }
        field(8; "Employer Name"; Text[50])
        {
            Caption = 'Employer Name';
        }
        field(20; "Insured Period Starting Date"; Date)
        {
            Caption = 'Insured Period Starting Date';

            trigger OnValidate()
            begin
                if ("Insured Period Starting Date" <> 0D) and ("Insured Period Starting Date" < "Starting Date") then
                    Error(Text000,
                      FieldCaption("Insured Period Starting Date"),
                      FieldCaption("Starting Date"));
            end;
        }
        field(21; "Insured Period Ending Date"; Date)
        {
            Caption = 'Insured Period Ending Date';

            trigger OnValidate()
            begin
                if ("Insured Period Ending Date" <> 0D) and ("Insured Period Ending Date" > "Ending Date") then
                    Error(Text001,
                      FieldCaption("Insured Period Ending Date"),
                      FieldCaption("Ending Date"));
            end;
        }
        field(30; "Unbroken Record of Service"; Boolean)
        {
            Caption = 'Unbroken Record of Service';
        }
        field(33; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(34; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(35; "Speciality Code"; Code[10])
        {
            Caption = 'Speciality Code';
        }
        field(36; "Speciality Name"; Text[50])
        {
            Caption = 'Speciality Name';
        }
        field(50; "Hire Conditions"; Code[20])
        {
            Caption = 'Hire Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Hire Condition"));
        }
        field(51; "Kind of Work"; Option)
        {
            Caption = 'Kind of Work';
            OptionCaption = ' ,Permanent,Temporary,Seasonal';
            OptionMembers = " ",Permanent,"Temporary",Seasonal;
        }
        field(52; "Work Mode"; Option)
        {
            Caption = 'Work Mode';
            OptionCaption = 'Primary Job,Internal Co-work,External Co-work';
            OptionMembers = "Primary Job","Internal Co-work","External Co-work";
        }
        field(53; "Conditions of Work"; Option)
        {
            Caption = 'Conditions of Work';
            OptionCaption = ' ,Regular,Heavy,Unhealthy,Very Heavy';
            OptionMembers = " ",Regular,Heavy,Unhealthy,"Very Heavy";
        }
        field(56; "Territorial Conditions"; Code[20])
        {
            Caption = 'Territorial Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Territor. Condition"));
        }
        field(57; "Special Conditions"; Code[20])
        {
            Caption = 'Special Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Special Work Condition"));
        }
        field(59; "Record of Service Reason"; Code[20])
        {
            Caption = 'Calc Seniority: Reason';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Countable Service Reason"));
        }
        field(60; "Record of Service Additional"; Code[20])
        {
            Caption = 'Calc Seniority: Addition';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Countable Service Addition"));
        }
        field(61; "Service Years Reason"; Code[20])
        {
            Caption = 'Long Service: Reason';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Long Service Reason"));
        }
    }

    keys
    {
        key(Key1; "Person No.", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '%1 should not be earlier than %2.';
        Text001: Label '%1 should not be later than %2.';
}


table 17425 "Payroll Directory"
{
    Caption = 'Payroll Directory';
    LookupPageID = "Payroll Directory";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(11; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(23; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Income,Allowance,Tax Deduction,Tax';
            OptionMembers = " ",Income,Allowance,"Tax Deduction",Tax;
        }
        field(25; "Income Type"; Option)
        {
            Caption = 'Income Type';
            OptionCaption = ' ,Full Include,Part Include,Business Undertakings,Authoring Fee,With Individual Impose';
            OptionMembers = " ","Full Include","Part Include","Business Undertakings","Authoring Fee","With Individual Impose";
        }
        field(26; "Tax Deduction Type"; Option)
        {
            Caption = 'Tax Deduction Type';
            OptionCaption = ' ,Standart,Social,Material,Professional,Individual,On Legislation';
            OptionMembers = " ",Standart,Social,Material,Professional,Individual,"On Legislation";
        }
        field(27; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(28; "Tax Deduction Code"; Code[10])
        {
            Caption = 'Tax Deduction Code';
            TableRelation = "Payroll Directory".Code WHERE(Type = FILTER(Allowance | "Tax Deduction"));
        }
        field(29; "Income Tax Percent"; Option)
        {
            Caption = 'Income Tax Percent';
            OptionCaption = ' ,13,30,35,9';
            OptionMembers = " ","13","30","35","9";
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


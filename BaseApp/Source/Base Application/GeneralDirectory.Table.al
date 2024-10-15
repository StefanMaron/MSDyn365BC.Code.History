table 17359 "General Directory"
{
    Caption = 'General Directory';
    LookupPageID = "General Directory";

    fields
    {
        field(1; "Code"; Text[20])
        {
            Caption = 'Code';
            NotBlank = false;
        }
        field(2; Name; Text[90])
        {
            Caption = 'Name';
        }
        field(3; Note; Text[120])
        {
            Caption = 'Note';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,,,,,,Hire Condition,,,,Military Agency,Military Composition,Military Office,Anketa Print,Special,Tax Payer Category,,,Additional Tariff,Territor. Condition,Special Work Condition,Countable Service Reason,Countable Service Addition,Long Service Reason,Long Service Addition,Other Absence';
            OptionMembers = " ",,,,,,"Hire Condition",,,,"Military Agency","Military Composition","Military Office","Anketa Print",Special,"Tax Payer Category",,,"Additional Tariff","Territor. Condition","Special Work Condition","Countable Service Reason","Countable Service Addition","Long Service Reason","Long Service Addition","Other Absence";
        }
        field(5; "Document Name Pension Fund"; Text[100])
        {
            Caption = 'Document Name Pension Fund';
        }
        field(8; Introduction; Text[40])
        {
            Caption = 'Introduction';
        }
        field(11; "Making Date"; Date)
        {
            Caption = 'Making Date';
        }
        field(12; Abbreviation; Text[30])
        {
            Caption = 'Abbreviation';
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(13; "Full Name"; Text[110])
        {
            Caption = 'Full Name';
        }
        field(14; "Region Directory"; Text[30])
        {
            Caption = 'Region Directory';
        }
        field(15; Export; Boolean)
        {
            Caption = 'Export';
        }
        field(16; "XML Element Type"; Option)
        {
            Caption = 'XML Element Type';
            OptionCaption = ' ,Territorial Conditions,Special Conditions,Countable Service Reason,Maternity Leave,Long Service';
            OptionMembers = " ","Territorial Conditions","Special Conditions","Countable Service Reason","Maternity Leave","Long Service";
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Full Name", Name)
        {
            Clustered = true;
        }
        key(Key2; Type, "Code", Name)
        {
        }
        key(Key3; Type, Abbreviation, "Full Name")
        {
        }
        key(Key4; Type, "Full Name", Abbreviation)
        {
        }
    }

    fieldgroups
    {
    }
}


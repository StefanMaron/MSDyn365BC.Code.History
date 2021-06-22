table 5069 "Salutation Formula"
{
    Caption = 'Salutation Formula';

    fields
    {
        field(1; "Salutation Code"; Code[10])
        {
            Caption = 'Salutation Code';
            NotBlank = true;
            TableRelation = Salutation;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; "Salutation Type"; Option)
        {
            Caption = 'Salutation Type';
            OptionCaption = 'Formal,Informal';
            OptionMembers = Formal,Informal;
        }
        field(4; Salutation; Text[50])
        {
            Caption = 'Salutation';
        }
        field(5; "Name 1"; Option)
        {
            Caption = 'Name 1';
            OptionCaption = ' ,Job Title,First Name,Middle Name,Surname,Initials,Company Name';
            OptionMembers = " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name";
        }
        field(6; "Name 2"; Option)
        {
            Caption = 'Name 2';
            OptionCaption = ' ,Job Title,First Name,Middle Name,Surname,Initials,Company Name';
            OptionMembers = " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name";
        }
        field(7; "Name 3"; Option)
        {
            Caption = 'Name 3';
            OptionCaption = ' ,Job Title,First Name,Middle Name,Surname,Initials,Company Name';
            OptionMembers = " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name";
        }
        field(8; "Name 4"; Option)
        {
            Caption = 'Name 4';
            OptionCaption = ' ,Job Title,First Name,Middle Name,Surname,Initials,Company Name';
            OptionMembers = " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name";
        }
        field(9; "Name 5"; Option)
        {
            Caption = 'Name 5';
            OptionCaption = ' ,Job Title,First Name,Middle Name,Surname,Initials,Company Name';
            OptionMembers = " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name";
        }
        field(10; "Contact No. Filter"; Code[20])
        {
            Caption = 'Contact No. Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
    }

    keys
    {
        key(Key1; "Salutation Code", "Language Code", "Salutation Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetContactSalutation(): Text[260]
    var
        Cont: Record Contact;
    begin
        Cont.Get(GetFilter("Contact No. Filter"));
        exit(Cont.GetSalutation("Salutation Type", "Language Code"));
    end;
}


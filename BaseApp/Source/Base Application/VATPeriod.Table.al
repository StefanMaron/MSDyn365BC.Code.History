table 11780 "VAT Period"
{
    Caption = 'VAT Period';
#if CLEAN17
    ObsoleteState = Removed;
#else
    LookupPageID = "VAT Periods";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                Name := Format("Starting Date", 0, MonthTxt);
            end;
        }
        field(2; Name; Text[10])
        {
            Caption = 'Name';
        }
        field(3; "New VAT Year"; Boolean)
        {
            Caption = 'New VAT Year';
        }
        field(4; Closed; Boolean)
        {
            Caption = 'Closed';
        }
    }

    keys
    {
        key(Key1; "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "New VAT Year")
        {
        }
        key(Key3; Closed)
        {
        }
    }

    fieldgroups
    {
    }

    var
        MonthTxt: Label '<Month Text>', Locked = true;
}


table 28003 "Address ID"
{
    Caption = 'Address ID';

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Table Key"; Text[200])
        {
            Caption = 'Table Key';
        }
        field(3; "Address Type"; Option)
        {
            Caption = 'Address Type';
            OptionCaption = 'Main,Bill-to,Ship-to,Sell-to,Pay-to,Buy-from,Transfer-from,Transfer-to';
            OptionMembers = Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to";
        }
        field(4; "Address ID"; Text[10])
        {
            Caption = 'Address ID';
            Numeric = true;

            trigger OnValidate()
            begin
                "Address ID Check Date" := WorkDate();
            end;
        }
        field(5; "Address Sort Plan"; Text[10])
        {
            Caption = 'Address Sort Plan';
        }
        field(6; "Bar Code"; Text[100])
        {
            Caption = 'Bar Code';
        }
        field(7; "Bar Code System"; Option)
        {
            Caption = 'Bar Code System';
            OptionCaption = ' ,4-State Bar Code';
            OptionMembers = " ","4-State Bar Code";
        }
        field(10; "Error Flag No."; Text[2])
        {
            Caption = 'Error Flag No.';
        }
        field(11; "Address ID Check Date"; Date)
        {
            Caption = 'Address ID Check Date';
        }
    }

    keys
    {
        key(Key1; "Table No.", "Table Key", "Address Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


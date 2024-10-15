namespace Microsoft.Inventory.Availability;

table 390 "Availability at Date"
{
    Caption = 'Availability at Date';

    fields
    {
        field(1; "Period Start"; Date)
        {
            Caption = 'Period Start';
        }
        field(2; "Scheduled Receipt"; Decimal)
        {
            Caption = 'Scheduled Receipt';
            DecimalPlaces = 0 : 5;
        }
        field(3; "Gross Requirement"; Decimal)
        {
            Caption = 'Gross Requirement';
            DecimalPlaces = 0 : 5;
        }
        field(4; "Period End"; Date)
        {
            Caption = 'Period End';
        }
    }

    keys
    {
        key(Key1; "Period Start")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


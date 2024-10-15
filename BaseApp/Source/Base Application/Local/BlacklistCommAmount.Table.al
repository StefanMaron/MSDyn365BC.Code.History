table 12194 "Blacklist Comm. Amount"
{
    Caption = 'Blacklist Comm. Amount';

    fields
    {
        field(1; "Start Date"; Date)
        {
            Caption = 'Start Date';
            NotBlank = true;
        }
        field(2; "Threshold Amount"; Decimal)
        {
            Caption = 'Threshold Amount';
        }
    }

    keys
    {
        key(Key1; "Start Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetAmountAtDate(Date: Date): Decimal
    begin
        Reset();
        SetFilter("Start Date", '<=%1', Date);
        if FindLast() then
            exit("Threshold Amount");
        exit(0);
    end;
}


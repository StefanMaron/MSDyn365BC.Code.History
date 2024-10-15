table 143000 "Test 347 Declaration Parameter"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Code[10])
        {
        }
        field(3; MinAmount; Decimal)
        {
        }
        field(4; MinAmountCash; Decimal)
        {
        }
        field(5; ContactName; Text[20])
        {
        }
        field(6; TelephoneNumber; Text[9])
        {
        }
        field(7; DeclarationNumber; Text[4])
        {
        }
        field(8; PostingDate; Date)
        {
        }
        field(9; GLAccForPaymentsInCash; Text[30])
        {
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}


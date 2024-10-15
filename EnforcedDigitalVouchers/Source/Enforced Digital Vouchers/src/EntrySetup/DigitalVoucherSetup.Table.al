table 5581 "Digital Voucher Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Boolean)
        {
        }
        field(2; Enabled; Boolean)
        {
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure InitSetup()
    begin
        if not Rec.Get() then
            Rec.Insert(true);
    end;
}

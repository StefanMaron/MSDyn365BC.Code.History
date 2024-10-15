table 10538 "MTD-Session Fraud Prev. Hdr"
{
    Caption = 'HMRC Missing Fraud Prevention Header';
    ObsoleteReason = 'Moved to extension Making Tax Digital';
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';

    fields
    {
        field(1; Header; Code[100])
        {
            Caption = 'Header';
            DataClassification = SystemMetadata;
        }
        field(2; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; Header)
        {
            Clustered = true;
        }
    }
}

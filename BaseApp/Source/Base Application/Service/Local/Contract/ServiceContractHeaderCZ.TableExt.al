namespace Microsoft.Service.Contract;

tableextension 11800 "Service Contract Header CZ" extends "Service Contract Header"
{
    fields
    {
        field(11792; "Original User ID"; Code[50])
        {
            Caption = 'Original User ID';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteState = Removed;
            ObsoleteReason = 'This field is not needed and it should not be used.';
            ObsoleteTag = '18.0';
        }
    }
}
namespace Microsoft.Service.Document;

tableextension 11550 "Service Line CH" extends "Service Line"
{
    fields
    {
        field(3010501; "Customer Line Reference"; Integer)
        {
            Caption = 'Customer Line Reference';
            DataClassification = CustomerContent;
        }
    }
}
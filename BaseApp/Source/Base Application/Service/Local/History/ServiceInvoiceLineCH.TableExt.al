namespace Microsoft.Service.History;

tableextension 11551 "Service Invoice Line CH" extends "Service Invoice Line"
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
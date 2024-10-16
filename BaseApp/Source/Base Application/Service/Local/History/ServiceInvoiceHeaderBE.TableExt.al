namespace Microsoft.Service.History;

tableextension 11303 "Service Invoice Header BE" extends "Service Invoice Header"
{
    fields
    {
        field(11310; "Enterprise No."; Text[50])
        {
            Caption = 'Enterprise No.';
            DataClassification = CustomerContent;
        }
    }
}
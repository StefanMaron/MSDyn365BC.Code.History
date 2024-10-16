namespace Microsoft.Service.History;

tableextension 11301 "Service Cr.Memo Header BE" extends "Service Cr.Memo Header"
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
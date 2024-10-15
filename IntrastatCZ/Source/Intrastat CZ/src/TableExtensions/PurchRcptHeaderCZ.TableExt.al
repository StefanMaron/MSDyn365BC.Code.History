tableextension 31335 "Purch. Rcpt. Header CZ" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(31305; "Physical Transfer CZ"; Boolean)
        {
            Caption = 'Physical Transfer';
            DataClassification = CustomerContent;
        }
    }
}
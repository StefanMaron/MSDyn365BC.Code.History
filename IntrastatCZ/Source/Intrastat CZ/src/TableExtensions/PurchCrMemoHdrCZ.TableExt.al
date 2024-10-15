tableextension 31333 "Purch. Cr. Memo Hdr. CZ" extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(31305; "Physical Transfer CZ"; Boolean)
        {
            Caption = 'Physical Transfer';
            DataClassification = CustomerContent;
        }
        field(31310; "Intrastat Exclude CZ"; Boolean)
        {
            Caption = 'Intrastat Exclude';
            DataClassification = CustomerContent;
        }
    }
}
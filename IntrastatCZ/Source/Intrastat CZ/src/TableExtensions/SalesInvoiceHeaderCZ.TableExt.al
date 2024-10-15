tableextension 31340 "Sales Invoice Header CZ" extends "Sales Invoice Header"
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
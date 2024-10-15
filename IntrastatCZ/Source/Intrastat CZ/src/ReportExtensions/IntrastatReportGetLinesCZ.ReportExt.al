reportextension 31300 "Intrastat Report Get Lines CZ" extends "Intrastat Report Get Lines"
{
    requestpage
    {
        trigger OnOpenPage()
        begin
            ShowItemCharges := true;
        end;
    }
}
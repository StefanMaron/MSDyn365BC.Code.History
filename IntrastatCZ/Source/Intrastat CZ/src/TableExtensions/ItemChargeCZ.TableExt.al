tableextension 31325 "Item Charge CZ" extends "Item Charge"
{
    fields
    {
        field(31300; "Incl. in Intrastat Amount CZ"; Boolean)
        {
            Caption = 'Incl. in Intrastat Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Incl. in Intrastat Amount CZ" then begin
                    IntrastatReportSetup.Get();
                    IntrastatReportSetup.TestField("No Item Charges in Int. CZ", false);
                end;
            end;
        }
    }

    var
        IntrastatReportSetup: Record "Intrastat Report Setup";
}
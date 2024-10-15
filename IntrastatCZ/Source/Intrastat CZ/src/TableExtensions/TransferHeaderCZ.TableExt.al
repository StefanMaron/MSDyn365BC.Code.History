tableextension 31329 "Transfer Header CZ" extends "Transfer Header"
{
    fields
    {
        field(31310; "Intrastat Exclude CZ"; Boolean)
        {
            Caption = 'Intrastat Exclude';
            DataClassification = CustomerContent;
        }
    }

    procedure CheckIntrastatMandatoryFieldsCZ()
    var
        IntrastatReportSetup: Record "Intrastat Report Setup";
    begin
        if IsIntrastatTransactionCZL() and ShipOrReceiveInventoriableTypeItemsCZL() then begin
            IntrastatReportSetup.Get();
            if IntrastatReportSetup."Transaction Type Mandatory CZ" then
                TestField("Transaction Type");
            if IntrastatReportSetup."Transaction Spec. Mandatory CZ" then
                TestField("Transaction Specification");
            if IntrastatReportSetup."Transport Method Mandatory CZ" then
                TestField("Transport Method");
            if IntrastatReportSetup."Shipment Method Mandatory CZ" then
                TestField("Shipment Method Code");
        end;
    end;
}
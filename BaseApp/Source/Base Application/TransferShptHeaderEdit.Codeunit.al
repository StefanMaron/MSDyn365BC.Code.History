codeunit 10461 "Transfer Shpt. Header - Edit"
{
    Permissions = TableData "Transfer Shipment Header" = rm;
    TableNo = "Transfer Shipment Header";

    trigger OnRun()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader := Rec;
        TransferShipmentHeader.LockTable();
        TransferShipmentHeader.Find();
        TransferShipmentHeader."CFDI Cancellation Reason Code" := "CFDI Cancellation Reason Code";
        TransferShipmentHeader."Substitution Document No." := "Substitution Document No.";
        TransferShipmentHeader.TestField("No.", "No.");
        TransferShipmentHeader.Modify();
        Rec := TransferShipmentHeader;
    end;
}


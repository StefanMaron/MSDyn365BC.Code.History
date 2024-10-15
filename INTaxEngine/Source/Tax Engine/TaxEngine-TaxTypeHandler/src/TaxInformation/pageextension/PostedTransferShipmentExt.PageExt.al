pageextension 20248 "Posted Transfer Shipment Ext" extends "Posted Transfer Shipment"
{
    layout
    {
        addbefore(Control1900383207)
        {
            part(TaxInformation; "Tax Information Factbox")
            {
                Provider = TransferShipmentLines;
                SubPageLink = "Table ID Filter" = const(5745), "Document No. Filter" = field("Document No."), "Line No. Filter" = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
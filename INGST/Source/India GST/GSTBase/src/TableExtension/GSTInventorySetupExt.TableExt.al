tableextension 18006 "GST Inventory Setup Ext" extends "Inventory Setup"
{
    fields
    {
        field(18000; "Service Transfer Order Nos."; code[10])
        {
            caption = 'Service Transfer Order Nos.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }

        field(18001; "Posted Serv. Trans. Shpt. Nos."; code[10])
        {
            Caption = 'Posted Serv. Trans. Shpt. Nos.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
        field(18002; "Posted Serv. Trans. Rcpt. Nos."; code[10])
        {
            Caption = 'Posted Serv. Trans. Rcpt. Nos.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "No. Series";
        }
    }
}
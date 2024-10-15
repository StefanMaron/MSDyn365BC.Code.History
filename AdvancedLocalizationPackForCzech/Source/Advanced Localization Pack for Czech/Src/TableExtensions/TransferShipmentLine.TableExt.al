tableextension 31242 "Transfer Shipment Line CZA" extends "Transfer Shipment Line"
{
    fields
    {
        field(31238; "Gen.Bus.Post.Group Ship CZA"; Code[20])
        {
            Caption = 'Gen. Bus. Post. Group Ship';
            TableRelation = "Gen. Business Posting Group";
            DataClassification = CustomerContent;
        }
        field(31239; "Gen.Bus.Post.Group Receive CZA"; Code[20])
        {
            Caption = 'Gen. Bus. Post. Group Receive';
            TableRelation = "Gen. Business Posting Group";
            DataClassification = CustomerContent;
        }
    }
}
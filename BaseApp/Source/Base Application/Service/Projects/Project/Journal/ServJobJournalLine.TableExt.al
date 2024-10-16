namespace Microsoft.Projects.Project.Journal;

tableextension 6458 "Serv. Job Journal Line" extends "Job Journal Line"
{
    fields
    {
        field(5900; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            DataClassification = CustomerContent;
        }
        field(5901; "Posted Service Shipment No."; Code[20])
        {
            Caption = 'Posted Service Shipment No.';
            DataClassification = CustomerContent;
        }
    }
}
namespace Microsoft.Projects.Project.Archive;

tableextension 6461 "Serv. Job Planning Line Arch." extends "Job Planning Line Archive"
{
    fields
    {
        field(5900; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            DataClassification = CustomerContent;
        }
    }
}
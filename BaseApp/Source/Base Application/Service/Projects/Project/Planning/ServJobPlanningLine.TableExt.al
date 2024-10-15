namespace Microsoft.Projects.Project.Planning;

tableextension 6460 "Serv. Job Planning Line" extends "Job Planning Line"
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
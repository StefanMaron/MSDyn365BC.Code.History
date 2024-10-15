namespace Microsoft.Projects.Resources.Analysis;

using Microsoft.Service.Resources;

pageextension 6460 "Serv. Resource Capacity Matrix" extends "Resource Capacity Matrix"
{
    actions
    {
        addafter("Resource A&vailability")
        {
            action("&Set Capacity")
            {
                ApplicationArea = Jobs;
                Caption = '&Set Capacity';
                RunObject = Page "Resource Capacity Settings";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Change the capacity of the resource, such as a technician.';
            }
        }
    }
}
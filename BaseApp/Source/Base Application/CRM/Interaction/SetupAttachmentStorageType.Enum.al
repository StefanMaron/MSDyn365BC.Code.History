namespace Microsoft.CRM.Interaction;

enum 5079 "Setup Attachment Storage Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Embedded") { Caption = 'Embedded'; }
    value(1; "Disk File") { Caption = 'Disk File'; }
}
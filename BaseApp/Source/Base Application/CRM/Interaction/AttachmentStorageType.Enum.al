namespace Microsoft.CRM.Interaction;

enum 5062 "Attachment Storage Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Embedded") { Caption = 'Embedded'; }
    value(1; "Disk File") { Caption = 'Disk File'; }
    value(2; "Exchange Storage") { Caption = 'Exchange Storage'; }
}
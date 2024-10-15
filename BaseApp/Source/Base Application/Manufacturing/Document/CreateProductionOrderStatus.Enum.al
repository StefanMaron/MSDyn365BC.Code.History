namespace Microsoft.Manufacturing.Document;

enum 99000885 "Create Production Order Status"
{
    AssignmentCompatibility = true;

    value(0; "") { Caption = ''; }
    value(1; "Planned") { Caption = 'Planned'; }
    value(2; "Firm Planned") { Caption = 'Firm Planned'; }
    value(3; "Released") { Caption = 'Released'; }
}
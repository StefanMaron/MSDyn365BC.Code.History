﻿namespace Microsoft.CRM.Interaction;

enum 5083 "Interaction Delivery Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "In Progress") { Caption = 'In Progress'; }
    value(2; "Error") { Caption = 'Error'; }
}

﻿namespace Microsoft.Service.Resources;

enum 5956 "Resource Skill Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Resource)
    {
        Caption = 'Resource';
    }
    value(1; "Service Item Group")
    {
        Caption = 'Service Item Group';
    }
    value(2; Item)
    {
        Caption = 'Item';
    }
    value(3; "Service Item")
    {
        Caption = 'Service Item';
    }
}

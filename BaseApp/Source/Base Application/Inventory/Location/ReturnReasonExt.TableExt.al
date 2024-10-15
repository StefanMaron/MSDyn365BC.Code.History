namespace Microsoft.Inventory.Location;

using Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 6637 ReturnReasonExt extends "Return Reason"
{
    fields
    {
        field(3; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location where("Use As In-Transit" = const(false));
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
        field(4; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';
            DataClassification = CustomerContent;
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
    }

    fieldgroups
    {
        addlast(DropDown; "Default Location Code", "Inventory Value Zero")
        {
        }
    }
}
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;

table 5106 "Interaction Merge Data"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
        }

        field(2; "Contact No."; Code[20])
        {
            TableRelation = Contact."No.";
        }

        field(3; "Salesperson Code"; Code[20])
        {
            TableRelation = "Salesperson/Purchaser".Code;
        }

        field(4; "Log Entry Number"; Integer)
        {
            TableRelation = "Interaction Log Entry"."Entry No.";
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

}
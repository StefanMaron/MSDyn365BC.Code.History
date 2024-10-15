namespace Microsoft.Foundation.AuditCodes;

tableextension 6467 "Serv. Source Code Setup" extends "Source Code Setup"
{
    fields
    {
#pragma warning disable AS0125        
        field(5900; "Service Management"; Code[10])
        {
            Caption = 'Service Management';
            DataClassification = CustomerContent;
            TableRelation = "Source Code";
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
#pragma warning restore AS0125        
    }
}
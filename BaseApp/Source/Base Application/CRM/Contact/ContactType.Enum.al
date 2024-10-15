namespace Microsoft.CRM.Contact;

enum 5050 "Contact Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Company") { Caption = 'Company'; }
    value(1; "Person") { Caption = 'Person'; }
}
enum 5338 "Integration Update Conflict Resolution"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = ' '; }
    value(1; "Send Update to Integration") { Caption = 'Send data update to integration table'; }
    value(2; "Get Update from Integration") { Caption = 'Get data update from integration table'; }
}
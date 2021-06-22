page 20050 "APIV1 - Jobs"
{
    APIVersion = 'v1.0';
    Caption = 'projects', Locked = true;
    DelayedInsert = true;
    EntityName = 'project';
    EntitySetName = 'projects';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = Job;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
            }
        }
    }
}
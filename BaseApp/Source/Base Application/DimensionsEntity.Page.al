page 5487 "Dimensions Entity"
{
    Caption = 'dimensions', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'dimension';
    EntitySetName = 'dimensions';
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = Dimension;
    ObsoleteState = Pending;
    ObsoleteReason = 'API version beta will be deprecated.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
                part(dimensionValues; "Dimension Values Entity API")
                {
                    ApplicationArea = All;
                    Caption = 'DimensionValues', Locked = true;
                    EntityName = 'dimensionValue';
                    EntitySetName = 'dimensionValues';
                    SubPageLink = "Dimension Code" = FIELD(Code);
                }
            }
        }
    }

    actions
    {
    }
}


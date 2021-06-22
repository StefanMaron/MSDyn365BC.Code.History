page 5504 "Tax Area Entity"
{
    Caption = 'taxAreas', Locked = true;
    DelayedInsert = true;
    EntityName = 'taxArea';
    EntitySetName = 'taxAreas';
    PageType = API;
    SourceTable = "Tax Area Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(taxType; Type)
                {
                    ApplicationArea = All;
                    Caption = 'taxType', Locked = true;
                    Editable = false;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        PropagateDelete;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        PropagateInsert;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        PropagateModify;
    end;

    trigger OnOpenPage()
    begin
        LoadRecords;
    end;
}


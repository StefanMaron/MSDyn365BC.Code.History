page 5481 "Tax Group Entity"
{
    Caption = 'taxGroups', Locked = true;
    DelayedInsert = true;
    EntityName = 'taxGroup';
    EntitySetName = 'taxGroups';
    PageType = API;
    SourceTable = "Tax Group Buffer";
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
                    Caption = 'Id', Locked = true;
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
                    Caption = 'DisplayName', Locked = true;
                }
                field(taxType; Type)
                {
                    ApplicationArea = All;
                    Caption = 'taxType', Locked = true;
                    Editable = false;
                }
                field(lastModifiedDateTime; "Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
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


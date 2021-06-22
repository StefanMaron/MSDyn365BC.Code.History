page 2866 "Native - VAT Setup"
{
    Caption = 'Native - VAT Setup';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Native - API Tax Setup";
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
                }
                field(default; Default)
                {
                    ApplicationArea = All;
                    Caption = 'default';
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName';
                }
                field(vatPercentage; "VAT Percentage")
                {
                    ApplicationArea = All;
                    Caption = 'vatPercentage';
                }
                field(vatRegulationDescription; "VAT Regulation Description")
                {
                    ApplicationArea = All;
                    Caption = 'vatRegulationDescription';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SaveChanges(xRec);
        ReloadRecord;

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        SaveChanges(xRec);
        ReloadRecord;

        exit(false);
    end;

    trigger OnOpenPage()
    begin
        LoadSetupRecords;

        if Type = Type::"Sales Tax" then
            DeleteAll();
    end;
}


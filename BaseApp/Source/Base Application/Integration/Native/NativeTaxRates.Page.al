#if not CLEAN20
page 2876 "Native - Tax Rates"
{
    Caption = 'Native - Tax Rates';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Tax Rate Buffer";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(taxAreaId; "Tax Area ID")
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaId', Locked = true;
                }
                field(taxGroupId; "Tax Group ID")
                {
                    ApplicationArea = All;
                    Caption = 'taxGroupId', Locked = true;
                }
                field(taxRate; "Tax Rate")
                {
                    ApplicationArea = All;
                    Caption = 'taxRate', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        LoadRecords();
    end;
}
#endif

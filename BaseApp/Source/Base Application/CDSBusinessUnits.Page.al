page 7203 "CDS Business Units"
{
    Caption = 'Common Data Service Business Units', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "CRM Businessunit";
    SourceTableTemporary = true;
    SourceTableView = SORTING(Name);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(BusinessUnitId; BusinessUnitId)
                {
                    ApplicationArea = Suite;
                    Caption = 'Id';
                    ToolTip = 'Specifies the ID of the business unit.';
                    Visible = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the Name of the business unit.';
                }
            }
        }
    }
}

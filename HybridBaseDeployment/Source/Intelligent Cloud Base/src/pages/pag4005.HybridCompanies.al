page 4005 "Hybrid Companies"
{
    SourceTable = "Hybrid Company";
    SourceTableTemporary = false;
    PageType = ListPart;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    Caption = 'Select companies to migrate';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(Companies)
            {
                ShowCaption = false;
                field("Replicate"; "Replicate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Migrate';
                    Visible = true;
                    Tooltip = 'Check this box if you want to migrate this company''s data';
                    Width = 5;
                    Editable = true;
                }
                field("Name"; "Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                    Editable = false;
                }
                field("Display Name"; "Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                    Editable = false;
                }
            }
        }
    }
}
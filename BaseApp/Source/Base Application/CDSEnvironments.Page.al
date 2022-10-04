page 7207 "CDS Environments"
{
    Extensible = false;
    Caption = 'Dataverse User Environments', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    Editable = false;
    PageType = List;
    SourceTable = "CDS Environment";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Environment Name");

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Environment Name"; Rec."Environment Name")
                {
                    Caption = 'Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
                field(Url; Url)
                {
                    Caption = 'URL';
                    ApplicationArea = All;
                    ToolTip = ' Specifies the URL of the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
            }
        }
    }

}
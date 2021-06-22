page 7207 "CDS Environments"
{
    Extensible = false;
    Caption = 'Common Data Service User environments', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
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
                field("Environment Name"; "Environment Name")
                {
                    Caption = 'Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Common Data Service environment.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                }
                field(Url; Url)
                {
                    Caption = 'URL';
                    ApplicationArea = All;
                    ToolTip = ' Specifies the URL of the Common Data Service environment.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
                }
            }
        }
    }

}
namespace Microsoft.CRM.Duplicates;

using System.Environment;

page 5138 "Duplicate Search String Setup"
{
    Caption = 'Duplicate Search String Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Duplicate Search String Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the field to use to generate the search string.';

                    trigger OnAssistEdit()
                    var
                        ClientTypeManagement: Codeunit "Client Type Management";
                    begin
                        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop] then
                            Rec.LookupFieldName();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ClientTypeManagement: Codeunit "Client Type Management";
                    begin
                        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Windows then
                            Rec.LookupFieldName();
                    end;
                }
                field("Part of Field"; Rec."Part of Field")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the part of the field to use to generate the search string. There are two options: First and Last.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies how many characters the search string will contain. You can enter a number from 2 to 10. The program automatically enters 5 as a default value.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}


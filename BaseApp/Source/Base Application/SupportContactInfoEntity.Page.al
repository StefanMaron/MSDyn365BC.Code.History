page 9166 "Support Contact Info. Entity"
{
    APIGroup = 'admin';
    APIPublisher = 'microsoft';
    Caption = 'supportContactInformation', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'supportContactInformation';
    EntitySetName = 'supportContactInformation';
    InsertAllowed = false;
    ODataKeyFields = ID;
    PageType = API;
    Permissions = TableData "Support Contact Information" = rim;
    SaveValues = true;
    SourceTable = "Support Contact Information";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; ID)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;

                    trigger OnValidate()
                    var
                        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                    begin
                        if xRec.ID <> ID then
                            GraphMgtGeneralTools.ErrorIdImmutable();
                    end;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'name', Locked = true;
                }
                field(email; Email)
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;
                }
                field(url; URL)
                {
                    ApplicationArea = All;
                    Caption = 'url', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        SupportContactInformation: Record "Support Contact Information";
    begin
        if SupportContactInformation.IsEmpty() then begin
            SupportContactInformation.Init();
            SupportContactInformation.Insert(true);
        end;
    end;
}


#if not CLEAN19
page 8451 "Intrastat Checklist Setup"
{
    Caption = 'Intrastat Checklist Setup';
    PageType = List;
    SourceTable = "Intrastat Checklist Setup";
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
    ObsoleteReason = 'Replaced by Advanced Intrastat Checklist';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    ToolTip = 'Specifies the field that will be verified by the Intrastat journal check.';

                    trigger OnAssistEdit()
                    var
                        ClientTypeManagement: Codeunit "Client Type Management";
                    begin
                        if ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop] then
                            LookupFieldName;
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ClientTypeManagement: Codeunit "Client Type Management";
                    begin
                        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Windows then
                            LookupFieldName;
                    end;
                }
            }
        }
    }

    actions
    {
    }
}
#endif

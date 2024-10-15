page 8618 "Config. Template Header"
{
    Caption = 'Config. Template Header';
    PageType = ListPlus;
    PopulateAllFields = true;
    SourceTable = "Config. Template Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the data template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the data template.';
                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table on which the data template is based.';
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the table on which the data template is based.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the template is ready to be used.';
                }
            }
            part(ConfigTemplateSubform; "Config. Template Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Data Template Code" = FIELD(Code);
                SubPageView = SORTING("Data Template Code", "Line No.")
                              ORDER(Ascending);
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateInstance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Instance';
                    Image = New;
                    ToolTip = 'Convert your information into records in the database. This is a miniature version of the data migration process and can be useful for prototyping or treating smaller data creation tasks.';

                    trigger OnAction()
                    var
                        ConfigTemplateMgt: Codeunit "Config. Template Management";
                        RecRef: RecordRef;
                    begin
                        if "Table ID" <> 0 then begin
                            RecRef.Open("Table ID");
                            ConfigTemplateMgt.UpdateRecord(Rec, RecRef);
                            ConfirmNewInstance(RecRef);
                        end;
                    end;
                }
                action(CopyConfigTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Config. Template';
                    Image = Copy;
                    Promoted = true;
                    PromotedIsBig = true;
                    ToolTip = 'Copies all information to the current configuration template from the selected one.';

                    trigger OnAction()
                    var
                        ConfigTemplateHeader: Record "Config. Template Header";
                        ConfigTemplateList: Page "Config. Template List";
                    begin
                        ConfigTemplateHeader.SetFilter(Code, '<>%1', Code);
                        ConfigTemplateList.LookupMode(true);
                        ConfigTemplateList.SetTableView(ConfigTemplateHeader);
                        if ConfigTemplateList.RunModal = ACTION::LookupOK then begin
                            ConfigTemplateList.GetRecord(ConfigTemplateHeader);
                            CopyConfigTemplate(ConfigTemplateHeader.Code);
                        end;
                    end;
                }
            }
        }
    }
}


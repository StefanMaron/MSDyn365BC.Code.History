report 11112 "Update VAT Statement Template"
{
    Caption = 'Update VAT Statement Template';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                UpdateVATAT: Codeunit "Update VAT-AT";
            begin
                if TemplateName <> '' then
                    UpdateVATAT.UpdateVATStatementTemplate(TemplateName, TemplateDescription, AgricultureVATProdPostingGroups)
                else
                    Error(SpecifyVATStatementTemplateNameErr);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(VATStatementTemplateName; TemplateName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Template Name';
                        TableRelation = "VAT Statement Template";
                        ToolTip = 'Specifies the VAT statement template name that you want to update, such as UVA-2009 or VAT-2010.';

                        trigger OnValidate()
                        begin
                            TemplateNameOnAfterValidate;
                        end;
                    }
                    field(Description; TemplateDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the record.';
                    }
                    field("Agriculture VAT Prod. Post. Gr."; AgricultureVATProdPostingGroups)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Product Posting Groups for fixed rate agricultural and forestry businesses';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            VATProductPostingGroup: Record "VAT Product Posting Group";
                        begin
                            VATProductPostingGroup.LookupVATProductPostingGroupFilter(AgricultureVATProdPostingGroups);
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        TemplateName := 'UVA-2020';
        TemplateDescription := 'Österreichische USt ab 2020';
    end;

    var
        SpecifyVATStatementTemplateNameErr: Label 'Please specify a VAT Statement Template Name.';
        TemplateName: Code[10];
        TemplateDescription: Text[80];
        AgricultureVATProdPostingGroups: Text;

    local procedure TemplateNameOnAfterValidate()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        if VATStatementTemplate.Get(TemplateName) then
            TemplateDescription := VATStatementTemplate.Description;
    end;
}

